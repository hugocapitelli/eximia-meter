import Foundation

struct UsageCalculatorService {
    struct Limits {
        var weeklyTokenLimit: Int = 2_000_000_000
        var dailyTokenLimit: Int = 300_000_000
        var sessionTokenLimit: Int = 200_000_000
        var weeklyResetDay: Int = 1
    }

    /// API usage data from Anthropic OAuth endpoint (Layer 1 — authoritative)
    struct APIUsageData {
        let weeklyUtilization: Double  // 0-100
        let weeklyResetsAt: Date?
        let sessionUtilization: Double // 0-100
        let sessionResetsAt: Date?
    }

    /// Exact token totals from .jsonl scan (Layer 2 — local exact)
    struct ExactTokenData {
        let weeklyTokens: Int
        let dailyTokens: Int
        let sessionTokens: Int?
    }

    static func calculate(
        from stats: StatsCache?,
        limits: Limits = Limits(),
        historyEntries: [HistoryEntry] = [],
        apiUsage: APIUsageData? = nil,
        exactTokens: ExactTokenData? = nil
    ) -> UsageData {
        var data = UsageData()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        // Total stats from stats-cache (lightweight metadata)
        if let stats {
            data.totalSessions = stats.totalSessions ?? 0
            data.totalMessages = stats.totalMessages ?? 0
            data.dailyActivity = stats.dailyActivity ?? []
            data.dailyModelTokens = stats.dailyModelTokens ?? []
            data.hourCounts = stats.hourCounts ?? [:]
            data.perModelUsage = calculatePerModelUsage(from: stats, formatter: dateFormatter)
            data.tokensAllTime = totalTokens(from: stats)
            data.messagesAllTime = stats.totalMessages ?? 0
            data.sessionsAllTime = stats.totalSessions ?? 0
            data.messages24h = messagesByPeriod(from: stats, days: 1, formatter: dateFormatter)
            data.messages7d = messagesByPeriod(from: stats, days: 7, formatter: dateFormatter)
            data.messages30d = messagesByPeriod(from: stats, days: 30, formatter: dateFormatter)
            data.sessions24h = sessionsByPeriod(from: stats, days: 1, formatter: dateFormatter)
            data.sessions7d = sessionsByPeriod(from: stats, days: 7, formatter: dateFormatter)
            data.sessions30d = sessionsByPeriod(from: stats, days: 30, formatter: dateFormatter)
        }

        // --- HYBRID 3-LAYER SYSTEM ---
        // Layer 1: API (authoritative, if available)
        // Layer 2: .jsonl exact scan (local, cached)
        // Layer 3: stats-cache × multiplier (fallback)

        if let api = apiUsage {
            // LAYER 1: API is authoritative — use utilization directly
            data.weeklyUsage = min(api.weeklyUtilization / 100.0, 1.0)
            data.sessionUsage = min(api.sessionUtilization / 100.0, 1.0)

            // Estimate token counts from percentage + limits (for display)
            data.totalTokensThisWeek = Int(data.weeklyUsage * Double(limits.weeklyTokenLimit))
            data.totalTokensThisSession = Int(data.sessionUsage * Double(limits.sessionTokenLimit))

            // Use API reset times
            if let weeklyResets = api.weeklyResetsAt {
                data.weeklyResetTimeRemaining = max(weeklyResets.timeIntervalSinceNow, 0)
            }
            if let sessionResets = api.sessionResetsAt {
                data.sessionResetTimeRemaining = max(sessionResets.timeIntervalSinceNow, 0)
            }

            data.usageSource = .api
        } else if let exact = exactTokens, exact.weeklyTokens > 0 {
            // LAYER 2: .jsonl exact scan
            data.totalTokensThisWeek = exact.weeklyTokens
            data.weeklyUsage = limits.weeklyTokenLimit > 0
                ? min(Double(exact.weeklyTokens) / Double(limits.weeklyTokenLimit), 1.0)
                : 0.0

            if let sessionTokens = exact.sessionTokens, sessionTokens > 0 {
                data.totalTokensThisSession = sessionTokens
                data.sessionUsage = limits.sessionTokenLimit > 0
                    ? min(Double(sessionTokens) / Double(limits.sessionTokenLimit), 1.0)
                    : 0.0
            }

            data.usageSource = .exactLocal
        } else if let stats {
            // LAYER 3: stats-cache × multiplier (fallback)
            let multiplier = cacheMultiplier(from: stats)
            let rawWeekly = rawTokensByPeriod(from: stats, days: 7, formatter: dateFormatter)
            let weeklyTokens = Int(Double(rawWeekly) * multiplier)
            data.totalTokensThisWeek = weeklyTokens
            data.weeklyUsage = limits.weeklyTokenLimit > 0
                ? min(Double(weeklyTokens) / Double(limits.weeklyTokenLimit), 1.0)
                : 0.0

            data.usageSource = .estimated
        }

        // Daily tokens — use exact if available, else multiplier
        if let exact = exactTokens, exact.dailyTokens > 0 {
            data.totalTokensToday = exact.dailyTokens
            data.dailyUsage = limits.dailyTokenLimit > 0
                ? min(Double(exact.dailyTokens) / Double(limits.dailyTokenLimit), 1.0)
                : 0.0
        } else if let stats {
            let multiplier = cacheMultiplier(from: stats)
            let rawToday = rawTokensByPeriod(from: stats, days: 1, formatter: dateFormatter)
            let todayTokens = Int(Double(rawToday) * multiplier)
            data.totalTokensToday = todayTokens
            data.dailyUsage = limits.dailyTokenLimit > 0
                ? min(Double(todayTokens) / Double(limits.dailyTokenLimit), 1.0)
                : 0.0
        }

        // Session fallback (if not set by API or exact)
        if data.totalTokensThisSession == 0, let stats {
            let multiplier = cacheMultiplier(from: stats)
            let rawToday = rawTokensByPeriod(from: stats, days: 1, formatter: dateFormatter)
            let todayTokens = Int(Double(rawToday) * multiplier)
            let sessionEstimate = estimateSessionTokens(todayTokens: todayTokens, historyEntries: historyEntries)
            data.totalTokensThisSession = sessionEstimate.tokens
            data.sessionUsage = limits.sessionTokenLimit > 0
                ? min(Double(sessionEstimate.tokens) / Double(limits.sessionTokenLimit), 1.0)
                : 0.0
            if data.sessionResetTimeRemaining == 0 {
                data.sessionResetTimeRemaining = calculateSessionReset(sessionStart: sessionEstimate.startTime)
            }
        }

        // Reset timers fallback (if not set by API)
        if data.weeklyResetTimeRemaining == 0 {
            data.weeklyResetTimeRemaining = calculateWeeklyReset(resetDay: limits.weeklyResetDay)
        }
        if data.sessionResetTimeRemaining == 0 {
            let sessionEstimate = estimateSessionTokens(todayTokens: data.totalTokensToday, historyEntries: historyEntries)
            data.sessionResetTimeRemaining = calculateSessionReset(sessionStart: sessionEstimate.startTime)
        }

        // Per-period token breakdowns
        data.tokens24h = data.totalTokensToday
        data.tokens7d = data.totalTokensThisWeek
        if let stats {
            let multiplier = cacheMultiplier(from: stats)
            data.tokens30d = Int(Double(rawTokensByPeriod(from: stats, days: 30, formatter: dateFormatter)) * multiplier)
        }

        data.lastUpdated = Date()
        return data
    }

    // MARK: - Session Estimation

    struct SessionEstimate {
        let tokens: Int
        let startTime: Date?
    }

    static func estimateSessionTokens(todayTokens: Int, historyEntries: [HistoryEntry]) -> SessionEstimate {
        guard !historyEntries.isEmpty else {
            return SessionEstimate(tokens: todayTokens, startTime: nil)
        }

        guard let lastEntry = historyEntries.last,
              let currentSessionId = lastEntry.sessionId else {
            return SessionEstimate(tokens: todayTokens, startTime: nil)
        }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let todayEntries = historyEntries.filter { entry in
            guard let ts = entry.timestamp else { return false }
            return Date(timeIntervalSince1970: Double(ts) / 1000.0) >= startOfToday
        }
        let sessionEntries = historyEntries.filter { $0.sessionId == currentSessionId }

        let todayCount = max(todayEntries.count, 1)
        let sessionCount = sessionEntries.count

        let sessionStart: Date? = sessionEntries.first.flatMap { entry in
            guard let ts = entry.timestamp else { return nil }
            return Date(timeIntervalSince1970: Double(ts) / 1000.0)
        }

        let ratio = min(Double(sessionCount) / Double(todayCount), 1.0)
        let sessionTokens = Int(Double(todayTokens) * ratio)

        return SessionEstimate(tokens: sessionTokens, startTime: sessionStart)
    }

    // MARK: - Cache Multiplier (Layer 3 fallback)

    static func cacheMultiplier(from stats: StatsCache) -> Double {
        guard let modelUsage = stats.modelUsage, !modelUsage.isEmpty else { return 1.0 }

        var totalAllTokens: Double = 0
        var totalIOTokens: Double = 0

        for (_, usage) in modelUsage {
            let io = Double((usage.inputTokens ?? 0) + (usage.outputTokens ?? 0))
            let all = Double(usage.totalTokens)
            totalIOTokens += io
            totalAllTokens += all
        }

        guard totalIOTokens > 0 else { return 1.0 }
        return min(max(totalAllTokens / totalIOTokens, 1.0), 10000.0)
    }

    // MARK: - Raw token calculations

    static func rawTokensByPeriod(from stats: StatsCache, days: Int, formatter: DateFormatter) -> Int {
        guard let dailyTokens = stats.dailyModelTokens else { return 0 }
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date())) ?? Date()

        return dailyTokens
            .filter { formatter.date(from: $0.date).map { $0 >= cutoff } ?? false }
            .reduce(0) { $0 + ($1.tokensByModel?.values.reduce(0, +) ?? 0) }
    }

    private static func totalTokens(from stats: StatsCache) -> Int {
        if let modelUsage = stats.modelUsage {
            return modelUsage.values.reduce(0) { $0 + $1.totalTokens }
        }
        guard let dailyTokens = stats.dailyModelTokens else { return 0 }
        return dailyTokens.reduce(0) { $0 + ($1.tokensByModel?.values.reduce(0, +) ?? 0) }
    }

    private static func messagesByPeriod(from stats: StatsCache, days: Int, formatter: DateFormatter) -> Int {
        guard let activity = stats.dailyActivity else { return 0 }
        let cutoff = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        return activity
            .filter { formatter.date(from: $0.date).map { $0 >= cutoff } ?? false }
            .reduce(0) { $0 + ($1.messageCount ?? 0) }
    }

    private static func sessionsByPeriod(from stats: StatsCache, days: Int, formatter: DateFormatter) -> Int {
        guard let activity = stats.dailyActivity else { return 0 }
        let cutoff = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        return activity
            .filter { formatter.date(from: $0.date).map { $0 >= cutoff } ?? false }
            .reduce(0) { $0 + ($1.sessionCount ?? 0) }
    }

    private static func calculatePerModelUsage(from stats: StatsCache, formatter: DateFormatter) -> [String: Double] {
        guard let dailyTokens = stats.dailyModelTokens else { return [:] }
        let weekAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())
        var modelTotals: [String: Int] = [:]

        for entry in dailyTokens {
            guard let date = formatter.date(from: entry.date), date >= weekAgo,
                  let tokensByModel = entry.tokensByModel else { continue }
            for (model, tokens) in tokensByModel {
                modelTotals[model, default: 0] += tokens
            }
        }

        let total = modelTotals.values.reduce(0, +)
        guard total > 0 else { return [:] }
        return modelTotals.mapValues { Double($0) / Double(total) }
    }

    private static func calculateWeeklyReset(resetDay: Int) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        var daysUntilReset = (resetDay - currentWeekday + 7) % 7
        if daysUntilReset == 0 { daysUntilReset = 7 }
        guard let resetDate = calendar.date(byAdding: .day, value: daysUntilReset, to: calendar.startOfDay(for: now)) else { return 0 }
        return resetDate.timeIntervalSince(now)
    }

    private static func calculateSessionReset(sessionStart: Date? = nil) -> TimeInterval {
        let sessionDuration: TimeInterval = 5 * 3600
        guard let start = sessionStart else { return sessionDuration }
        return max(sessionDuration - Date().timeIntervalSince(start), 0)
    }
}
