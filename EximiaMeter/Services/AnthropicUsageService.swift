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

        // If token is expired, re-read from Keychain — CLI may have refreshed it
        if expired {
            cachedCredentials = readCredentials()
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

        // If token expired, re-read from Keychain (CLI may have refreshed)
        if let expiresAt = credentials.expiresAt, Date().timeIntervalSince1970 * 1000 > Double(expiresAt) {
            cachedCredentials = readCredentials()
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

    // MARK: - Keychain

    private struct Credentials {
        let accessToken: String?
        let expiresAt: Int64?
        let subscriptionType: String?
        let rateLimitTier: String?
    }

    private func readCredentials() -> Credentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else { return nil }

        // Parse the JSON credential string
        guard let jsonData = password.data(using: .utf8),
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
