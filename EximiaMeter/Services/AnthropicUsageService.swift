import Foundation
import Security

/// Fetches real-time usage data from Anthropic's OAuth API.
/// Returns exact utilization percentages for session (5h) and weekly (7d) windows.
final class AnthropicUsageService {
    static let shared = AnthropicUsageService()

    private let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let session = URLSession(configuration: {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return config
    }())

    private var cachedCredentials: Credentials?
    private var credentialsFetched = false

    /// Keychain service names
    private let originalService = "Claude Code-credentials"
    private let cachedService = "EximiaMeter-cached-credentials"

    private init() {}

    // MARK: - Account Info

    struct AccountInfo {
        let isConnected: Bool
        let tokenExpired: Bool
        let subscriptionType: String?
        let rateLimitTier: String?
    }

    /// Force re-read credentials from Keychain (call when user clicks Reconnect or popover opens).
    func refreshCredentials() {
        credentialsFetched = true
        cachedCredentials = readCredentials()
    }

    /// Returns account connection info from cached/Keychain credentials.
    func getAccountInfo() -> AccountInfo {
        if !credentialsFetched {
            credentialsFetched = true
            cachedCredentials = readCredentials()
        }

        guard let credentials = cachedCredentials else {
            return AccountInfo(isConnected: false, tokenExpired: false, subscriptionType: nil, rateLimitTier: nil)
        }

        let hasToken = credentials.accessToken != nil
        var expired = false
        if let expiresAt = credentials.expiresAt {
            expired = Date().timeIntervalSince1970 * 1000 > Double(expiresAt)
        }

        // If token is expired, re-read from original Keychain — CLI may have refreshed it
        if expired {
            cachedCredentials = readFromOriginalAndCache()
            if let refreshed = cachedCredentials {
                let stillExpired: Bool
                if let newExpiry = refreshed.expiresAt {
                    stillExpired = Date().timeIntervalSince1970 * 1000 > Double(newExpiry)
                } else {
                    stillExpired = false
                }
                return AccountInfo(
                    isConnected: refreshed.accessToken != nil && !stillExpired,
                    tokenExpired: stillExpired,
                    subscriptionType: refreshed.subscriptionType,
                    rateLimitTier: refreshed.rateLimitTier
                )
            }
        }

        return AccountInfo(
            isConnected: hasToken && !expired,
            tokenExpired: expired,
            subscriptionType: credentials.subscriptionType,
            rateLimitTier: credentials.rateLimitTier
        )
    }

    struct UsageResponse {
        let sessionUtilization: Double   // 0-100 percentage
        let sessionResetsAt: Date?
        let weeklyUtilization: Double    // 0-100 percentage
        let weeklyResetsAt: Date?
    }

    /// Fetch usage from Anthropic API. Returns nil if token unavailable or request fails.
    func fetchUsage() async -> UsageResponse? {
        if !credentialsFetched {
            credentialsFetched = true
            cachedCredentials = readCredentials()
        }

        guard var credentials = cachedCredentials,
              var accessToken = credentials.accessToken else { return nil }

        // If token expired, re-read from original Keychain (CLI may have refreshed)
        if let expiresAt = credentials.expiresAt, Date().timeIntervalSince1970 * 1000 > Double(expiresAt) {
            cachedCredentials = readFromOriginalAndCache()
            guard let refreshed = cachedCredentials,
                  let newToken = refreshed.accessToken else { return nil }
            if let newExpiry = refreshed.expiresAt, Date().timeIntervalSince1970 * 1000 > Double(newExpiry) {
                return nil // still expired
            }
            credentials = refreshed
            accessToken = newToken
        }

        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        guard let (data, response) = try? await session.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }

        return parseResponse(data)
    }

    // MARK: - Keychain (with cache layer)

    private struct Credentials {
        let accessToken: String?
        let expiresAt: Int64?
        let subscriptionType: String?
        let rateLimitTier: String?
    }

    /// Primary read: try app's own cache first, fall back to original (which may prompt).
    private func readCredentials() -> Credentials? {
        // 1. Try app's own cached entry (no prompt)
        if let cached = readFromKeychain(service: cachedService) {
            let creds = parseKeychainJSON(cached)
            // Only use if token is not expired
            if let creds, let expiresAt = creds.expiresAt {
                if Date().timeIntervalSince1970 * 1000 <= Double(expiresAt) {
                    return creds
                }
                // Expired — fall through to original
            } else if creds?.accessToken != nil {
                return creds
            }
        }

        // 2. Fall back to original "Claude Code-credentials" (may prompt once)
        return readFromOriginalAndCache()
    }

    /// Read from original Claude Code keychain entry and save a copy in app's own entry.
    /// Uses the `security` CLI tool to avoid Keychain GUI prompts — "Always Allow" on the
    /// system binary persists permanently, unlike our ad-hoc signed app.
    private func readFromOriginalAndCache() -> Credentials? {
        guard let raw = readViaSecurityCLI(service: originalService) else { return nil }
        let creds = parseKeychainJSON(raw)

        // Cache the raw JSON in app's own keychain entry (future reads won't prompt)
        if creds?.accessToken != nil {
            saveToKeychain(service: cachedService, data: raw)
        }

        return creds
    }

    /// Read keychain item using /usr/bin/security CLI (Apple-signed, stable "Always Allow").
    private func readViaSecurityCLI(service: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", service, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else { return nil }
        return output
    }

    /// Low-level keychain read for app's own entries (no prompt for items we created).
    private func readFromKeychain(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else { return nil }
        return password
    }

    /// Save (or update) data in app's own keychain entry.
    private func saveToKeychain(service: String, data: String) {
        guard let passwordData = data.data(using: .utf8) else { return }

        // Try to update existing
        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let updateAttrs: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let updateStatus = SecItemUpdate(searchQuery as CFDictionary, updateAttrs as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Create new entry
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "eximia-meter",
                kSecValueData as String: passwordData
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    /// Parse the JSON credential string from keychain.
    private func parseKeychainJSON(_ raw: String) -> Credentials? {
        guard let jsonData = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any] else { return nil }

        return Credentials(
            accessToken: oauth["accessToken"] as? String,
            expiresAt: oauth["expiresAt"] as? Int64,
            subscriptionType: oauth["subscriptionType"] as? String,
            rateLimitTier: oauth["rateLimitTier"] as? String
        )
    }

    // MARK: - Response Parsing

    private func parseResponse(_ data: Data) -> UsageResponse? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let fiveHour = json["five_hour"] as? [String: Any]
        let sevenDay = json["seven_day"] as? [String: Any]

        let sessionUtil = fiveHour?["utilization"] as? Double ?? 0
        let weeklyUtil = sevenDay?["utilization"] as? Double ?? 0

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let sessionResets = (fiveHour?["resets_at"] as? String).flatMap { isoFormatter.date(from: $0) }
        let weeklyResets = (sevenDay?["resets_at"] as? String).flatMap { isoFormatter.date(from: $0) }

        return UsageResponse(
            sessionUtilization: sessionUtil,
            sessionResetsAt: sessionResets,
            weeklyUtilization: weeklyUtil,
            weeklyResetsAt: weeklyResets
        )
    }
}
