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

    private init() {}

    struct UsageResponse {
        let sessionUtilization: Double   // 0-100 percentage
        let sessionResetsAt: Date?
        let weeklyUtilization: Double    // 0-100 percentage
        let weeklyResetsAt: Date?
    }

    /// Fetch usage from Anthropic API. Returns nil if token unavailable or request fails.
    func fetchUsage() async -> UsageResponse? {
        guard let credentials = readCredentials(),
              let accessToken = credentials.accessToken else { return nil }

        // Check if token is expired
        if let expiresAt = credentials.expiresAt, Date().timeIntervalSince1970 * 1000 > Double(expiresAt) {
            return nil
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
