import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var globalModel: ClaudeModel = .opus
    @Published var usageViewModel = UsageViewModel()
    @Published var projectsViewModel = ProjectsViewModel()
    @Published var settingsViewModel = SettingsViewModel()

    let monitorService = CLIMonitorService()
    private let projectUsage = ProjectUsageService.shared
    private let apiService = AnthropicUsageService.shared

    private var updateTimer: Timer?
    private var cacheCleanupTimer: Timer?

    func start() {
        monitorService.start()
        projectsViewModel.load()

        if settingsViewModel.notificationsEnabled {
            NotificationService.shared.requestPermission()
        }

        refreshUsageData()

        // Main refresh: 60s interval (was 5s — major perf improvement)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshUsageData()
        }

        // Prune stale cache entries every 30 minutes
        cacheCleanupTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.projectUsage.pruneCache()
        }
    }

    func stop() {
        monitorService.stop()
        updateTimer?.invalidate()
        updateTimer = nil
        cacheCleanupTimer?.invalidate()
        cacheCleanupTimer = nil
    }

    func refresh() {
        monitorService.refresh()
        refreshUsageData()
    }

    private func refreshUsageData() {
        let limits = UsageCalculatorService.Limits(
            weeklyTokenLimit: settingsViewModel.weeklyTokenLimit,
            dailyTokenLimit: settingsViewModel.weeklyTokenLimit / 7,
            sessionTokenLimit: settingsViewModel.sessionTokenLimit
        )

        let historyEntries = monitorService.historyEntries
        let statsCache = monitorService.statsCache
        let currentSessionId = historyEntries.last?.sessionId
        let notificationsEnabled = settingsViewModel.notificationsEnabled
        let thresholds = settingsViewModel.thresholds

        // All heavy work on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            // Layer 2: Exact tokens from .jsonl scan (cached — fast after first run)
            let weekAgo = Date().addingTimeInterval(-7 * 86400)
            let dayAgo = Calendar.current.startOfDay(for: Date())
            let exactWeekly = self.projectUsage.totalTokens(since: weekAgo)
            let exactDaily = self.projectUsage.totalTokens(since: dayAgo)
            let exactSession: Int? = currentSessionId.flatMap { sid in
                let tokens = self.projectUsage.currentSessionTokens(sessionId: sid)
                return tokens > 0 ? tokens : nil
            }

            let exactTokens = UsageCalculatorService.ExactTokenData(
                weeklyTokens: exactWeekly,
                dailyTokens: exactDaily,
                sessionTokens: exactSession
            )

            // Per-project usage (uses same cache — almost free after totalTokens call)
            let perProject = self.projectUsage.scanAllProjects()

            // Layer 1: API call (async, non-blocking)
            // Run API fetch concurrently with local data processing
            let apiGroup = DispatchGroup()
            var apiUsage: UsageCalculatorService.APIUsageData?

            apiGroup.enter()
            Task {
                if let response = await self.apiService.fetchUsage() {
                    apiUsage = UsageCalculatorService.APIUsageData(
                        weeklyUtilization: response.weeklyUtilization,
                        weeklyResetsAt: response.weeklyResetsAt,
                        sessionUtilization: response.sessionUtilization,
                        sessionResetsAt: response.sessionResetsAt
                    )
                }
                apiGroup.leave()
            }

            // Wait for API (max 10s, then proceed with local data)
            _ = apiGroup.wait(timeout: .now() + 10)

            // Calculate with 3-layer hybrid
            var usageData = UsageCalculatorService.calculate(
                from: statsCache,
                limits: limits,
                historyEntries: historyEntries,
                apiUsage: apiUsage,
                exactTokens: exactTokens
            )

            usageData.perProjectTokens = perProject

            // Update UI on main thread
            DispatchQueue.main.async {
                self.usageViewModel.update(from: usageData)

                if notificationsEnabled {
                    NotificationService.shared.checkAndNotify(
                        usageData: usageData,
                        thresholds: thresholds
                    )
                }
            }
        }
    }
}
