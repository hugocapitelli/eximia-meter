import UserNotifications
import AppKit

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Notification posted when an in-app alert should be shown
    static let alertTriggeredNotification = Notification.Name("ExAlertTriggered")

    private var notifiedThresholds: Set<String> = []
    private var lastNotifiedAt: [String: Date] = [:]
    private var permissionGranted = false

    /// Base cooldown (5 min) — after first fire, escalates to extended cooldown
    private let baseCooldown: TimeInterval = 300
    /// Extended cooldown (4 hours) — used while usage stays above threshold
    private let extendedCooldown: TimeInterval = 14400
    /// Hysteresis margin — usage must drop 5% below threshold to re-enable
    private let hysteresisMargin: Double = 0.05

    /// Track previous weekly usage to detect reset
    private var lastKnownWeeklyUsage: Double = 0.0

    // Persistence keys
    private let kNotifiedThresholds = "ExNotificationService.notifiedThresholds"
    private let kLastNotifiedAt = "ExNotificationService.lastNotifiedAt"
    private let kLastKnownWeeklyUsage = "ExNotificationService.lastKnownWeeklyUsage"
    private let kLastWeeklyReportDate = "ExNotificationService.lastWeeklyReportDate"
    private let kLastActivityDate = "ExNotificationService.lastActivityDate"

    // Settings — updated from AppViewModel before each check
    var soundEnabled: Bool = true
    var inAppPopupEnabled: Bool = true
    var systemNotificationsEnabled: Bool = true
    var alertSound: AlertSound = .default

    override init() {
        super.init()
        // Always set delegate immediately so foreground notifications work
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Restore persisted state
        loadPersistedState()
    }

    func requestPermission() {
        let bundleId = Bundle.main.bundleIdentifier ?? "nil"
        print("[Notifications] bundleIdentifier: \(bundleId)")

        guard Bundle.main.bundleIdentifier != nil else {
            print("[Notifications] unavailable: no bundle identifier (running via swift run?)")
            return
        }

        let center = UNUserNotificationCenter.current()

        // Check current authorization status first
        center.getNotificationSettings { settings in
            print("[Notifications] current status: \(settings.authorizationStatus.rawValue) (0=notDetermined, 1=denied, 2=authorized, 3=provisional)")
        }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
            }
            if let error {
                print("[Notifications] permission error: \(error)")
            }
            print("[Notifications] permission \(granted ? "granted" : "denied")")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Allow system notifications to appear even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        var options: UNNotificationPresentationOptions = [.banner, .list]
        if soundEnabled {
            options.insert(.sound)
        }
        completionHandler(options)
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            NSApp.activate()
        }
        completionHandler()
    }

    // MARK: - Check & Notify

    func checkAndNotify(usageData: UsageData, thresholds: ThresholdConfig) {
        // Detect weekly reset: if usage dropped by more than 50%, clear all weekly flags
        detectWeeklyReset(currentWeeklyUsage: usageData.weeklyUsage)

        // Smart reset with hysteresis: only clear flag when usage drops 5% below threshold
        resetIfBelow(id: "session-warning", value: usageData.sessionUsage, threshold: thresholds.sessionWarning)
        resetIfBelow(id: "session-critical", value: usageData.sessionUsage, threshold: thresholds.sessionCritical)
        resetIfBelow(id: "weekly-warning", value: usageData.weeklyUsage, threshold: thresholds.weeklyWarning)
        resetIfBelow(id: "weekly-critical", value: usageData.weeklyUsage, threshold: thresholds.weeklyCritical)

        checkThreshold(
            id: "session-warning",
            value: usageData.sessionUsage,
            threshold: thresholds.sessionWarning,
            title: "Session Warning",
            body: "Session usage at \(Int(usageData.sessionUsage * 100))%",
            severity: "warning"
        )

        checkThreshold(
            id: "session-critical",
            value: usageData.sessionUsage,
            threshold: thresholds.sessionCritical,
            title: "Session Critical",
            body: "Session usage at \(Int(usageData.sessionUsage * 100))%! Near limit.",
            severity: "critical"
        )

        checkThreshold(
            id: "weekly-warning",
            value: usageData.weeklyUsage,
            threshold: thresholds.weeklyWarning,
            title: "Weekly Warning",
            body: "Weekly usage at \(Int(usageData.weeklyUsage * 100))%",
            severity: "warning"
        )

        checkThreshold(
            id: "weekly-critical",
            value: usageData.weeklyUsage,
            threshold: thresholds.weeklyCritical,
            title: "Weekly Critical",
            body: "Weekly usage at \(Int(usageData.weeklyUsage * 100))%! Consider slowing down.",
            severity: "critical"
        )
    }

    func resetNotifications() {
        notifiedThresholds.removeAll()
        lastNotifiedAt.removeAll()
        persistState()
    }

    /// Send a test system notification (for preview from Settings)
    func sendTestNotification(severity: String) {
        let title = severity == "critical" ? "Session Critical" : "Session Warning"
        let body = severity == "critical"
            ? "Session usage at 95%! Near limit."
            : "Session usage at 65% — warning level"

        print("[Notifications] sendTestNotification(\(severity)) — bundleId: \(Bundle.main.bundleIdentifier ?? "nil"), permissionGranted: \(permissionGranted)")

        // Check permission status before sending
        UNUserNotificationCenter.current().getNotificationSettings { [self] settings in
            print("[Notifications] authStatus: \(settings.authorizationStatus.rawValue), alertSetting: \(settings.alertSetting.rawValue)")

            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                print("[Notifications] NOT authorized — requesting permission now")
                self.requestPermission()
                // Try sending anyway after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.doSendNotification(title: title, body: body, severity: severity)
                }
                return
            }

            self.doSendNotification(title: title, body: body, severity: severity)
        }
    }

    private func doSendNotification(title: String, body: String, severity: String) {
        let content = UNMutableNotificationContent()
        content.title = "eximIA Meter — \(title)"
        content.body = body
        content.sound = soundEnabled ? .default : nil

        let id = "preview-\(severity)-\(Int(Date().timeIntervalSince1970 * 1000))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[Notifications] test notification FAILED: \(error)")
            } else {
                print("[Notifications] test notification SENT OK: \(id)")
            }
        }
    }

    // MARK: - Private

    /// Only reset notification flag when usage drops MORE than hysteresis margin below threshold
    private func resetIfBelow(id: String, value: Double, threshold: Double) {
        if value < (threshold - hysteresisMargin) {
            if notifiedThresholds.contains(id) {
                notifiedThresholds.remove(id)
                lastNotifiedAt.removeValue(forKey: id)
                persistState()
            }
        }
    }

    /// Detect weekly reset: if weeklyUsage dropped by >50%, clear all weekly notification flags
    private func detectWeeklyReset(currentWeeklyUsage: Double) {
        if lastKnownWeeklyUsage > 0.3 && currentWeeklyUsage < lastKnownWeeklyUsage * 0.5 {
            print("[Notifications] weekly reset detected (\(Int(lastKnownWeeklyUsage * 100))% → \(Int(currentWeeklyUsage * 100))%), clearing weekly flags")
            notifiedThresholds.remove("weekly-warning")
            notifiedThresholds.remove("weekly-critical")
            lastNotifiedAt.removeValue(forKey: "weekly-warning")
            lastNotifiedAt.removeValue(forKey: "weekly-critical")
            persistState()
        }
        lastKnownWeeklyUsage = currentWeeklyUsage
        UserDefaults.standard.set(currentWeeklyUsage, forKey: kLastKnownWeeklyUsage)
    }

    private func checkThreshold(id: String, value: Double, threshold: Double, title: String, body: String, severity: String) {
        guard value >= threshold else { return }
        guard !notifiedThresholds.contains(id) else { return }

        // Adaptive cooldown: use extended cooldown if this alert was already fired before
        let cooldown = lastNotifiedAt[id] != nil ? extendedCooldown : baseCooldown
        if let lastFired = lastNotifiedAt[id], Date().timeIntervalSince(lastFired) < cooldown {
            return
        }

        notifiedThresholds.insert(id)
        lastNotifiedAt[id] = Date()
        persistState()

        // macOS system notification (Notification Center banner)
        if systemNotificationsEnabled {
            let content = UNMutableNotificationContent()
            content.title = "eximIA Meter — \(title)"
            content.body = body
            content.sound = soundEnabled ? .default : nil

            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("[Notifications] send failed: \(error)")
                }
            }
        }

        // Play custom sound (independent of system notification)
        if soundEnabled {
            alertSound.play()
        }

        // In-app popup event
        if inAppPopupEnabled {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NotificationService.alertTriggeredNotification,
                    object: nil,
                    userInfo: [
                        "type": id,
                        "severity": severity,
                        "message": body
                    ]
                )
            }
        }
    }

    // MARK: - Weekly Summary Report

    /// Send a weekly summary notification on Sundays (once per week)
    func checkWeeklyReport(usageData: UsageData) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Only fire on Sundays
        guard cal.component(.weekday, from: today) == 1 else { return }

        let lastReportStr = UserDefaults.standard.string(forKey: kLastWeeklyReportDate) ?? ""
        let todayStr = ISO8601DateFormatter().string(from: today)

        // Already sent today
        guard lastReportStr != todayStr else { return }

        let tokensK = usageData.tokens7d >= 1_000_000
            ? String(format: "%.1fM", Double(usageData.tokens7d) / 1_000_000)
            : String(format: "%.0fK", Double(usageData.tokens7d) / 1_000)
        let cost = usageData.formattedWeeklyCost
        let sessions = usageData.sessions7d
        let streak = usageData.usageStreak

        var body = "Semana: \(tokensK) tokens · \(sessions) sessões · \(cost)"
        if streak > 1 {
            body += " · \(streak) dias seguidos"
        }

        let content = UNMutableNotificationContent()
        content.title = "exímIA Meter — Resumo Semanal"
        content.body = body
        content.sound = soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: "weekly-report-\(todayStr)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        UserDefaults.standard.set(todayStr, forKey: kLastWeeklyReportDate)
    }

    // MARK: - Idle Detection

    /// Track activity and detect when user returns after being idle (>4h gap)
    func checkIdleReturn(usageData: UsageData) {
        let now = Date()
        let defaults = UserDefaults.standard

        // Only track if there's actual usage
        guard usageData.tokens24h > 0 else { return }

        if let lastActivityInterval = defaults.object(forKey: kLastActivityDate) as? Double {
            let lastActivity = Date(timeIntervalSince1970: lastActivityInterval)
            let gap = now.timeIntervalSince(lastActivity)

            // If gap > 4 hours, show a welcome-back notification with current state
            if gap > 14400 {
                let weeklyPct = Int(usageData.weeklyUsage * 100)
                let sessionPct = Int(usageData.sessionUsage * 100)
                let body = "Uso semanal: \(weeklyPct)% · Sessão: \(sessionPct)% · Reset em \(usageData.weeklyResetFormatted)"

                let content = UNMutableNotificationContent()
                content.title = "exímIA Meter — Bem-vindo de volta!"
                content.body = body
                content.sound = nil // Subtle — no sound

                let request = UNNotificationRequest(
                    identifier: "idle-return-\(Int(now.timeIntervalSince1970))",
                    content: content,
                    trigger: nil
                )
                UNUserNotificationCenter.current().add(request)
            }
        }

        defaults.set(now.timeIntervalSince1970, forKey: kLastActivityDate)
    }

    // MARK: - Update Available Notification

    /// Send a macOS notification when a new app version is available
    func sendUpdateNotification(version: String) {
        let lastNotifiedVersion = UserDefaults.standard.string(forKey: "ExNotificationService.lastUpdateNotifiedVersion") ?? ""
        guard version != lastNotifiedVersion else { return }

        let content = UNMutableNotificationContent()
        content.title = "exímIA Meter — Atualização Disponível"
        content.body = "Versão v\(version) está disponível. Abra o app para atualizar."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "update-available-\(version)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[Notifications] update notification failed: \(error)")
            } else {
                print("[Notifications] update notification sent for v\(version)")
            }
        }

        UserDefaults.standard.set(version, forKey: "ExNotificationService.lastUpdateNotifiedVersion")
    }

    // MARK: - Persistence

    private func persistState() {
        UserDefaults.standard.set(Array(notifiedThresholds), forKey: kNotifiedThresholds)

        // Convert [String: Date] → [String: Double] for UserDefaults
        let intervals = lastNotifiedAt.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(intervals, forKey: kLastNotifiedAt)
    }

    private func loadPersistedState() {
        if let saved = UserDefaults.standard.stringArray(forKey: kNotifiedThresholds) {
            notifiedThresholds = Set(saved)
        }

        if let saved = UserDefaults.standard.dictionary(forKey: kLastNotifiedAt) as? [String: Double] {
            lastNotifiedAt = saved.mapValues { Date(timeIntervalSince1970: $0) }
        }

        lastKnownWeeklyUsage = UserDefaults.standard.double(forKey: kLastKnownWeeklyUsage)
    }
}
