import Foundation

/// Scans ALL directories in ~/.claude/projects/ and extracts exact token usage
/// from session .jsonl files. Uses file-level caching to avoid re-parsing unchanged files.
final class ProjectUsageService {
    static let shared = ProjectUsageService()

    private let projectsDir = NSString(string: "~/.claude/projects").expandingTildeInPath
    private let queue = DispatchQueue(label: "com.eximia.meter.projectUsage")

    // Cache: filePath → (modificationDate, tokens)
    private var fileCache: [String: (modDate: Date, tokens: Int)] = [:]

    // Session path cache: sessionId → filePath (avoids scanning all dirs every time)
    private var sessionPathCache: [String: String] = [:]

    private init() {}

    /// Scan all directories in ~/.claude/projects/ for token usage (cached)
    func scanAllProjects() -> [String: Int] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(atPath: projectsDir) else { return [:] }

        var result: [String: Int] = [:]
        let weekAgo = Date().addingTimeInterval(-7 * 86400)

        for dirName in dirs {
            let fullPath = "\(projectsDir)/\(dirName)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }

            let tokens = extractTokensFromSessions(in: fullPath, since: weekAgo)
            if tokens > 0 {
                result[dirName] = tokens
            }
        }

        return result
    }

    /// Total exact tokens across ALL projects for a given period
    func totalTokens(since date: Date) -> Int {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(atPath: projectsDir) else { return 0 }

        var total = 0
        for dirName in dirs {
            let fullPath = "\(projectsDir)/\(dirName)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }
            total += extractTokensFromSessions(in: fullPath, since: date)
        }
        return total
    }

    /// Get current session token usage (exact) by sessionId
    func currentSessionTokens(sessionId: String) -> Int {
        // Check cache first
        if let cachedPath = sessionPathCache[sessionId] {
            if FileManager.default.fileExists(atPath: cachedPath) {
                return parseSessionFile(at: cachedPath)
            }
            sessionPathCache.removeValue(forKey: sessionId)
        }

        // Scan dirs to find the session file
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(atPath: projectsDir) else { return 0 }

        for dirName in dirs {
            let sessionFile = "\(projectsDir)/\(dirName)/\(sessionId).jsonl"
            if fm.fileExists(atPath: sessionFile) {
                sessionPathCache[sessionId] = sessionFile
                return parseSessionFile(at: sessionFile)
            }
        }

        return 0
    }

    /// Evict stale entries from cache (files older than 8 days)
    func pruneCache() {
        let cutoff = Date().addingTimeInterval(-8 * 86400)
        fileCache = fileCache.filter { $0.value.modDate >= cutoff }
    }

    // MARK: - Parsing

    /// Parse session .jsonl files modified since a date, using cache
    private func extractTokensFromSessions(in dir: String, since: Date) -> Int {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: dir) else { return 0 }

        let sessionFiles = files.filter { $0.hasSuffix(".jsonl") }
        var totalTokens = 0

        for file in sessionFiles {
            let path = "\(dir)/\(file)"

            guard let attrs = try? fm.attributesOfItem(atPath: path),
                  let modDate = attrs[.modificationDate] as? Date,
                  modDate >= since else { continue }

            // Cache hit: file hasn't changed since last parse
            if let cached = fileCache[path], cached.modDate == modDate {
                totalTokens += cached.tokens
                continue
            }

            // Cache miss: parse and store
            let tokens = parseSessionFile(at: path)
            fileCache[path] = (modDate: modDate, tokens: tokens)
            totalTokens += tokens
        }

        return totalTokens
    }

    /// Parse a single session .jsonl file — extract token usage from assistant messages.
    /// Uses streaming line reading to avoid loading the entire file into memory.
    private func parseSessionFile(at path: String) -> Int {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return 0 }
        defer { fileHandle.closeFile() }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0

        // Small files (<1MB): load entirely (faster for small files)
        if fileSize < 1_048_576 {
            return parseFileContents(fileHandle.readDataToEndOfFile())
        }

        // Large files: read in chunks to limit memory
        var total = 0
        var leftover = Data()
        let chunkSize = 262_144 // 256KB chunks

        while true {
            let chunk = fileHandle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }

            let buffer = leftover + chunk

            // Find last newline to avoid splitting a line
            if let lastNewline = buffer.lastIndex(of: UInt8(ascii: "\n")) {
                let completeLines = buffer[buffer.startIndex...lastNewline]
                leftover = Data(buffer[buffer.index(after: lastNewline)...])
                total += parseDataLines(completeLines)
            } else {
                leftover = buffer
            }
        }

        // Process any remaining data
        if !leftover.isEmpty {
            total += parseDataLines(leftover)
        }

        return total
    }

    /// Parse complete file data (for small files)
    private func parseFileContents(_ data: Data) -> Int {
        guard let content = String(data: data, encoding: .utf8) else { return 0 }

        var total = 0
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard line.contains("\"usage\""),
                  line.contains("\"assistant\"") else { continue }
            total += parseJsonLine(line)
        }
        return total
    }

    /// Parse a chunk of data split into lines
    private func parseDataLines(_ data: Data) -> Int {
        guard let content = String(data: data, encoding: .utf8) else { return 0 }

        var total = 0
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard line.contains("\"usage\""),
                  line.contains("\"assistant\"") else { continue }
            total += parseJsonLine(line)
        }
        return total
    }

    /// Parse a single JSON line and extract token usage
    private func parseJsonLine(_ line: Substring) -> Int {
        guard let lineData = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
              json["type"] as? String == "assistant",
              let message = json["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any] else { return 0 }

        return (usage["input_tokens"] as? Int ?? 0)
             + (usage["output_tokens"] as? Int ?? 0)
             + (usage["cache_read_input_tokens"] as? Int ?? 0)
             + (usage["cache_creation_input_tokens"] as? Int ?? 0)
    }

    // MARK: - Display Name (static, no state needed)

    /// Decode a claude projects dir name to a readable project name
    static func displayName(forDirName dirName: String) -> String {
        let parts = dirName.split(separator: "-", omittingEmptySubsequences: false)

        let knownPrefixes = ["Users", "Dev", "dev"]
        var lastMeaningfulIndex = 0

        for (i, part) in parts.enumerated() {
            if knownPrefixes.contains(String(part)) {
                lastMeaningfulIndex = i + 2
            }
        }

        if lastMeaningfulIndex > 0 && lastMeaningfulIndex < parts.count {
            let meaningful = parts[lastMeaningfulIndex...]
            let name = meaningful.joined(separator: "-")
            if !name.isEmpty { return name }
        }

        if let lastSlash = dirName.lastIndex(of: "-") {
            let last = String(dirName[dirName.index(after: lastSlash)...])
            if !last.isEmpty { return last }
        }

        return dirName
    }
}
