import UserNotifications
import AppKit

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Notification posted when an in-app alert should be shown
    static let alertTriggeredNotification = Notification.Name("ExAlertTriggered")

    private var notifiedThresholds: Set<String> = []
    private var lastNotifiedAt: [String: Date] = [:]
    private var isAvailable = false

    private let cooldownInterval: TimeInterval = 300 // 5 minutes

    // Settings — updated from AppViewModel before each check
    var soundEnabled: Bool = true
    var inAppPopupEnabled: Bool = true
    var systemNotificationsEnabled: Bool = true
    var alertSound: AlertSound = .default

    func requestPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("Notifications unavailable: no bundle identifier (running via swift run?)")
            return
        }

        isAvailable = true

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
            if !granted {
                print("Notification permission not granted")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Allow system notifications to appear even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        var options: UNNotificationPresentationOptions = [.banner]
        if soundEnabled {
            options.insert(.sound)
        }
        completionHandler(options)
    }

    /// Handle notification tap (open popover)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // When user taps the notification, open the popover
        DispatchQueue.main.async {
            if let delegate = AppDelegate.shared,
               let popover = delegate.getPopover(),
               !popover.isShown {
                // Trigger the popover via the status bar button
                NSApp.activate()
            }
        }
        completionHandler()
    }

    // MARK: - Check & Notify

    func checkAndNotify(usageData: UsageData, thresholds: ThresholdConfig) {
        guard isAvailable else { return }

        // Smart reset: if usage drops below threshold, allow re-notification
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
    }

    /// Send a test system notification (for preview from Settings)
    func sendTestNotification(severity: String) {
        guard isAvailable, systemNotificationsEnabled else { return }

        let title = severity == "critical" ? "Session Critical" : "Session Warning"
        let body = severity == "critical"
            ? "Session usage at 95%! Near limit."
            : "Session usage at 65% — warning level"

        let content = UNMutableNotificationContent()
        content.title = "eximIA Meter — \(title)"
        content.body = body
        content.sound = soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: "preview-\(severity)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Private

    private func resetIfBelow(id: String, value: Double, threshold: Double) {
        if value < threshold {
            notifiedThresholds.remove(id)
        }
    }

    private func checkThreshold(id: String, value: Double, threshold: Double, title: String, body: String, severity: String) {
        guard value >= threshold else { return }
        guard !notifiedThresholds.contains(id) else { return }

        // Cooldown: don't re-fire the same alert within 5 minutes
        if let lastFired = lastNotifiedAt[id], Date().timeIntervalSince(lastFired) < cooldownInterval {
            return
        }

        notifiedThresholds.insert(id)
        lastNotifiedAt[id] = Date()

        // macOS system notification (Notification Center banner)
        if systemNotificationsEnabled {
            let content = UNMutableNotificationContent()
            content.title = "eximIA Meter — \(title)"
            content.body = body
            content.sound = soundEnabled ? .default : nil

            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
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
}
