import Foundation

struct ProjectDiscoveryService {
    private static let projectsDir = NSString(string: "~/.claude/projects").expandingTildeInPath

    static func discoverProjects() -> [Project] {
        let fm = FileManager.default

        guard fm.fileExists(atPath: projectsDir) else { return [] }

        do {
            let contents = try fm.contentsOfDirectory(atPath: projectsDir)
            return contents.compactMap { dirName -> Project? in
                let fullPath = "\(projectsDir)/\(dirName)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: fullPath, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }

                let decodedPath = decodePath(dirName)
                let name = extractProjectName(from: decodedPath)
                let sessionCount = countSessions(in: fullPath)
                let isAIOS = checkIsAIOSProject(at: decodedPath)

                // Skip projects whose decoded path doesn't exist on disk
                guard fm.fileExists(atPath: decodedPath) else { return nil }

                return Project(
                    name: name,
                    path: decodedPath,
                    isAIOSProject: isAIOS,
                    totalSessions: sessionCount
                )
            }
            .sorted { $0.totalSessions > $1.totalSessions }
        } catch {
            return []
        }
    }

    /// Decode Claude Code project directory name back to real filesystem path.
    ///
    /// Claude Code encodes paths by:
    /// 1. Replacing "/" with "-"
    /// 2. Normalizing unicode (removing accents like í → i)
    /// 3. Replacing spaces with "-"
    ///
    /// We reconstruct the path by walking the filesystem from root,
    /// matching each segment against actual directory names using
    /// a normalized comparison.
    static func decodePath(_ dirName: String) -> String {
        guard dirName.hasPrefix("-") else { return dirName }

        // Split encoded name into tokens (removing leading dash = root /)
        let tokens = dirName.dropFirst().split(separator: "-", omittingEmptySubsequences: true).map(String.init)
        guard !tokens.isEmpty else { return "/" }

        return resolvePathGreedy(tokens: tokens)
    }

    /// Walk from "/" greedily matching tokens against real filesystem entries.
    /// Tokens may need to be joined with "-" or " " to match real names.
    private static func resolvePathGreedy(tokens: [String]) -> String {
        let fm = FileManager.default
        var currentPath = ""
        var i = 0

        while i < tokens.count {
            guard let realEntries = try? fm.contentsOfDirectory(atPath: currentPath.isEmpty ? "/" : currentPath) else {
                // Can't list directory — take remaining tokens as-is
                let remaining = tokens[i...].joined(separator: "-")
                return currentPath + "/" + remaining
            }

            // Try increasingly longer sequences of tokens joined with various separators
            var matched = false

            // Try from longest possible match down to single token
            let maxLookahead = min(tokens.count - i, 8) // reasonable max segment length
            for length in stride(from: maxLookahead, through: 1, by: -1) {
                let candidateTokens = Array(tokens[i..<(i + length)])

                // Try to find a filesystem entry that matches these tokens
                if let matchedEntry = findMatchingEntry(candidateTokens, in: realEntries) {
                    currentPath += "/" + matchedEntry
                    i += length
                    matched = true
                    break
                }
            }

            if !matched {
                // No match found — try consuming ALL remaining tokens as one entry
                // This handles cases where the last directory name contains many hyphens
                if i < tokens.count {
                    let remainingTokens = Array(tokens[i...])
                    if let matchedEntry = findMatchingEntry(remainingTokens, in: realEntries) {
                        currentPath += "/" + matchedEntry
                        i = tokens.count
                        matched = true
                    }
                }

                if !matched {
                    // Still no match — use single token as-is
                    currentPath += "/" + tokens[i]
                    i += 1
                }
            }
        }

        return currentPath
    }

    /// Try to match an array of tokens against a real filesystem entry.
    /// The entry may have accents, spaces, mixed case, etc.
    private static func findMatchingEntry(_ tokens: [String], in entries: [String]) -> String? {
        // Build possible candidate strings from tokens
        let joinedDash = tokens.joined(separator: "-")     // ex-mIA-Academy
        let joinedSpace = tokens.joined(separator: " ")    // exímIA Academy
        let joinedEmpty = tokens.joined()                  // eximIAAcademy

        for entry in entries {
            let normalizedEntry = normalize(entry)

            if normalizedEntry == joinedDash { return entry }
            if normalizedEntry == joinedSpace { return entry }
            if normalizedEntry == joinedEmpty { return entry }

            // Also try: normalized entry with spaces→dashes
            let entryDashed = normalizedEntry.replacingOccurrences(of: " ", with: "-")
            if entryDashed == joinedDash { return entry }

            // Try case-insensitive
            if normalizedEntry.lowercased() == joinedDash.lowercased() { return entry }
            if entryDashed.lowercased() == joinedDash.lowercased() { return entry }

            // Reverse-encode match: encode the real entry the same way Claude Code does
            // and compare against the joined tokens
            let reverseEncoded = encodeSegment(normalizedEntry)
            if reverseEncoded == joinedDash { return entry }
            if reverseEncoded.lowercased() == joinedDash.lowercased() { return entry }
        }

        // Single token exact match (common for simple names like "Dev", "Users")
        if tokens.count == 1 {
            let token = tokens[0]
            for entry in entries {
                if normalize(entry) == token { return entry }
                if normalize(entry).lowercased() == token.lowercased() { return entry }
            }
        }

        // Subsequence match: all tokens appear in order within the entry.
        // Handles cases where directory was renamed (e.g. "ex-mIA Academy" → "exímIA Academy")
        // and the encoded name has tokens embedded within the real name.
        if tokens.count > 1 {
            var bestMatch: (entry: String, score: Int)?
            for entry in entries {
                let normalizedEntry = normalize(entry)
                if tokensAppearInSequence(tokens, in: normalizedEntry) {
                    // Score by how close the total token length is to the entry length
                    let tokenChars = tokens.reduce(0) { $0 + $1.count }
                    let entryChars = alphanumericOnly(normalizedEntry).count
                    let score = abs(entryChars - tokenChars)
                    if bestMatch == nil || score < bestMatch!.score {
                        bestMatch = (entry, score)
                    }
                }
            }
            // Accept if token chars cover at least 60% of entry chars
            if let match = bestMatch {
                let tokenChars = tokens.reduce(0) { $0 + $1.count }
                let entryChars = alphanumericOnly(normalize(match.entry)).count
                if entryChars > 0 && Double(tokenChars) / Double(entryChars) >= 0.6 {
                    return match.entry
                }
            }
        }

        return nil
    }

    /// Encode a directory name segment the way Claude Code does:
    /// replace spaces with "-"
    private static func encodeSegment(_ s: String) -> String {
        s.replacingOccurrences(of: " ", with: "-")
    }

    /// Check if all tokens appear in sequence within the given string.
    /// Case-insensitive search.
    private static func tokensAppearInSequence(_ tokens: [String], in text: String) -> Bool {
        let lower = text.lowercased()
        var searchStart = lower.startIndex
        for token in tokens {
            let tokenLower = token.lowercased()
            guard let range = lower.range(of: tokenLower, range: searchStart..<lower.endIndex) else {
                return false
            }
            searchStart = range.upperBound
        }
        return true
    }

    /// Strip non-alphanumeric characters from a string.
    private static func alphanumericOnly(_ s: String) -> String {
        s.filter { $0.isLetter || $0.isNumber }
    }

    /// Normalize a string by removing diacritics (accents) and folding case markers.
    /// "exímIA" → "eximIA", "plágio" → "plagio"
    private static func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
    }

    private static func extractProjectName(from path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    private static func countSessions(in projectDir: String) -> Int {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: projectDir) else { return 0 }
        return files.filter { $0.hasSuffix(".jsonl") }.count
    }

    private static func checkIsAIOSProject(at projectPath: String) -> Bool {
        FileManager.default.fileExists(atPath: "\(projectPath)/.aios-core")
    }
}
