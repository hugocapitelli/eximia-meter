import Foundation

enum UsageSource {
    case api        // Layer 1: Anthropic OAuth API (authoritative)
    case exactLocal // Layer 2: .jsonl exact scan
    case estimated  // Layer 3: stats-cache × multiplier
}

struct UsageData {
    var weeklyUsage: Double = 0.0
    var dailyUsage: Double = 0.0
    var sessionUsage: Double = 0.0
    var perModelUsage: [String: Double] = [:]

    var weeklyResetTimeRemaining: TimeInterval = 0
    var sessionResetTimeRemaining: TimeInterval = 0

    var totalTokensThisWeek: Int = 0
    var totalTokensToday: Int = 0
    var totalTokensThisSession: Int = 0
    var totalSessions: Int = 0
    var totalMessages: Int = 0

    var usageSource: UsageSource = .estimated

    // Per-period stats
    var tokens24h: Int = 0
    var tokens7d: Int = 0
    var tokens30d: Int = 0
    var tokensAllTime: Int = 0
    var messages24h: Int = 0
    var messages7d: Int = 0
    var messages30d: Int = 0
    var messagesAllTime: Int = 0
    var sessions24h: Int = 0
    var sessions7d: Int = 0
    var sessions30d: Int = 0
    var sessionsAllTime: Int = 0

    // Per-project tokens (path -> tokens this week)
    var perProjectTokens: [String: Int] = [:]

    var dailyActivity: [DailyActivity] = []
    var dailyModelTokens: [DailyModelTokens] = []
    var hourCounts: [String: Int] = [:]

    var lastUpdated: Date = Date()

    var weeklyResetFormatted: String {
        formatTimeInterval(weeklyResetTimeRemaining)
    }

    var sessionResetFormatted: String {
        formatTimeInterval(sessionResetTimeRemaining)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "now" }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
