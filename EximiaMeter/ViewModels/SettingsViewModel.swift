import SwiftUI

@Observable
class SettingsViewModel {
    var thresholds: ThresholdConfig {
        didSet { saveThresholds() }
    }

    var claudePlan: ClaudePlan = .max20x {
        didSet {
            UserDefaults.standard.set(claudePlan.rawValue, forKey: "claudePlan")
            // Auto-update limits when plan changes
            weeklyTokenLimit = claudePlan.weeklyTokenLimit
            sessionTokenLimit = claudePlan.sessionTokenLimit
        }
    }

    var refreshInterval: TimeInterval = 30 {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }

    var launchAtLogin: Bool = false {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    var preferredTerminal: TerminalLauncherService.Terminal = .terminalApp {
        didSet { UserDefaults.standard.set(preferredTerminal.rawValue, forKey: "preferredTerminal") }
    }

    var notificationsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    var soundEnabled: Bool = true {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    var inAppPopupEnabled: Bool = true {
        didSet { UserDefaults.standard.set(inAppPopupEnabled, forKey: "inAppPopupEnabled") }
    }

    var alertSound: AlertSound = .default {
        didSet { UserDefaults.standard.set(alertSound.rawValue, forKey: "alertSound") }
    }

    var systemNotificationsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(systemNotificationsEnabled, forKey: "systemNotificationsEnabled") }
    }

    var hasCompletedOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var weeklyTokenLimit: Int = 2_000_000_000 {
        didSet { UserDefaults.standard.set(weeklyTokenLimit, forKey: "weeklyTokenLimit") }
    }

    var sessionTokenLimit: Int = 200_000_000 {
        didSet { UserDefaults.standard.set(sessionTokenLimit, forKey: "sessionTokenLimit") }
    }

    // MARK: - Account / Auto-detect

    var isPlanAutoDetected: Bool = false

    var isApiConnected: Bool {
        AnthropicUsageService.shared.getAccountInfo().isConnected
    }

    var accountInfo: AnthropicUsageService.AccountInfo {
        AnthropicUsageService.shared.getAccountInfo()
    }

    init() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: "thresholds"),
           let decoded = try? JSONDecoder().decode(ThresholdConfig.self, from: data) {
            thresholds = decoded
        } else {
            thresholds = .default
        }

        // Load plan first
        if let planRaw = defaults.string(forKey: "claudePlan"),
           let plan = ClaudePlan(rawValue: planRaw) {
            claudePlan = plan
        }

        refreshInterval = defaults.double(forKey: "refreshInterval").nonZero ?? 30
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
        soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        inAppPopupEnabled = defaults.object(forKey: "inAppPopupEnabled") as? Bool ?? true
        systemNotificationsEnabled = defaults.object(forKey: "systemNotificationsEnabled") as? Bool ?? true
        if let soundRaw = defaults.string(forKey: "alertSound"),
           let sound = AlertSound(rawValue: soundRaw) {
            alertSound = sound
        }
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")

        // Use plan defaults if no custom limits saved
        weeklyTokenLimit = (defaults.integer(forKey: "weeklyTokenLimit")).nonZero ?? claudePlan.weeklyTokenLimit
        sessionTokenLimit = (defaults.integer(forKey: "sessionTokenLimit")).nonZero ?? claudePlan.sessionTokenLimit

        if let terminalRaw = defaults.string(forKey: "preferredTerminal"),
           let terminal = TerminalLauncherService.Terminal(rawValue: terminalRaw) {
            preferredTerminal = terminal
        }

        // Auto-detect plan from Keychain credentials
        autoDetectPlan()
    }

    private func autoDetectPlan() {
        let info = AnthropicUsageService.shared.getAccountInfo()
        guard info.isConnected, let tier = info.rateLimitTier else { return }

        let detected: ClaudePlan?
        switch tier.lowercased() {
        case "free", "standard", "tier1":
            detected = .pro
        case "scale", "tier2", "5x":
            detected = .max5x
        case "tier3", "20x":
            detected = .max20x
        default:
            // Log unknown tier for debugging
            print("[SettingsVM] Unknown rateLimitTier: \(tier)")
            detected = nil
        }

        if let plan = detected {
            isPlanAutoDetected = true
            claudePlan = plan
        }
    }

    private func saveThresholds() {
        if let data = try? JSONEncoder().encode(thresholds) {
            UserDefaults.standard.set(data, forKey: "thresholds")
        }
    }
}

// Helpers
private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
