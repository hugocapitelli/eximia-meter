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

    // MARK: - Burn Rate / Projection

    /// Total week duration (7 days in seconds)
    private var totalWeekDuration: TimeInterval { 7 * 86400 }

    /// Time elapsed since the start of the current week
    var weeklyTimeElapsed: TimeInterval {
        totalWeekDuration - weeklyResetTimeRemaining
    }

    /// Consumption rate per hour (requires at least 1h of data)
    var burnRatePerHour: Double {
        guard weeklyTimeElapsed > 3600 else { return 0 }
        return weeklyUsage / (weeklyTimeElapsed / 3600)
    }

    /// Projected usage at weekly reset (0.0 - 1.0+)
    var projectedUsageAtReset: Double {
        guard burnRatePerHour > 0 else { return weeklyUsage }
        return weeklyUsage + (burnRatePerHour * (weeklyResetTimeRemaining / 3600))
    }

    /// Formatted projection for the UI — always shows remaining % at reset
    var weeklyProjection: String {
        if weeklyUsage >= 1.0 {
            return "Limite atingido. Reseta em \(weeklyResetFormatted)"
        }
        if weeklyUsage == 0 || burnRatePerHour == 0 {
            return ""
        }

        let projected = projectedUsageAtReset
        let freePercent = max(0, Int((1.0 - min(projected, 1.0)) * 100))

        if projected >= 1.0 {
            // Will hit limit before reset
            let hoursToLimit = (1.0 - weeklyUsage) / burnRatePerHour
            return "Limite em ~\(formatTimeInterval(hoursToLimit * 3600)) · 0% livre no reset"
        } else {
            return "No reset, sobrará \(freePercent)% para uso"
        }
    }

    /// True if projected to hit limit before weekly reset
    var projectionIsWarning: Bool {
        guard burnRatePerHour > 0, weeklyUsage < 1.0 else { return weeklyUsage >= 1.0 }
        let hoursToLimit = (1.0 - weeklyUsage) / burnRatePerHour
        return (hoursToLimit * 3600) < weeklyResetTimeRemaining
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
