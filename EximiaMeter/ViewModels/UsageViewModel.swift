import SwiftUI
import Combine

@Observable
class UsageViewModel {
    var weeklyUsage: Double = 0.0
    var dailyUsage: Double = 0.0
    var sessionUsage: Double = 0.0
    var perModelUsage: [String: Double] = [:]

    var weeklyResetFormatted: String = "--"
    var sessionResetFormatted: String = "--"

    var totalTokensThisWeek: Int = 0
    var totalTokensToday: Int = 0
    var totalTokensThisSession: Int = 0
    var totalSessions: Int = 0
    var totalMessages: Int = 0

    // Per-period
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

    var perProjectTokens: [String: Int] = [:]

    var dailyActivity: [DailyActivity] = []
    var dailyModelTokens: [DailyModelTokens] = []
    var hourCounts: [String: Int] = [:]

    var usageSource: UsageSource = .estimated

    var lastUpdated: Date = Date()

    var usageSourceLabel: String {
        switch usageSource {
        case .api: return "API"
        case .exactLocal: return "Local"
        case .estimated: return "Est."
        }
    }

    var timeSinceUpdate: String {
        let interval = Date().timeIntervalSince(lastUpdated)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }

    func update(from usageData: UsageData) {
        weeklyUsage = usageData.weeklyUsage
        dailyUsage = usageData.dailyUsage
        sessionUsage = usageData.sessionUsage
        perModelUsage = usageData.perModelUsage
        weeklyResetFormatted = usageData.weeklyResetFormatted
        sessionResetFormatted = usageData.sessionResetFormatted
        totalTokensThisWeek = usageData.totalTokensThisWeek
        totalTokensToday = usageData.totalTokensToday
        totalTokensThisSession = usageData.totalTokensThisSession
        totalSessions = usageData.totalSessions
        totalMessages = usageData.totalMessages
        tokens24h = usageData.tokens24h
        tokens7d = usageData.tokens7d
        tokens30d = usageData.tokens30d
        tokensAllTime = usageData.tokensAllTime
        messages24h = usageData.messages24h
        messages7d = usageData.messages7d
        messages30d = usageData.messages30d
        messagesAllTime = usageData.messagesAllTime
        sessions24h = usageData.sessions24h
        sessions7d = usageData.sessions7d
        sessions30d = usageData.sessions30d
        sessionsAllTime = usageData.sessionsAllTime
        perProjectTokens = usageData.perProjectTokens
        dailyActivity = usageData.dailyActivity
        dailyModelTokens = usageData.dailyModelTokens
        hourCounts = usageData.hourCounts
        usageSource = usageData.usageSource
        lastUpdated = usageData.lastUpdated
    }
}
