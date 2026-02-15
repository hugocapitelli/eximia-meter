import SwiftUI

struct AlertsTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    private var settings: SettingsViewModel {
        appViewModel.settingsViewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ExTokens.Spacing._24) {
                // Section header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alerts")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ExTokens.Colors.textPrimary)

                        Text("Notifications, sounds, and usage thresholds")
                            .font(ExTokens.Typography.caption)
                            .foregroundColor(ExTokens.Colors.textTertiary)
                    }
                    Spacer()
                }

                // Notification Controls
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._16) {
                        cardHeader(icon: "bell.badge", title: "Notification Controls")

                        toggleRow(
                            icon: settings.notificationsEnabled ? "bell.fill" : "bell.slash",
                            iconColor: settings.notificationsEnabled ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted,
                            label: "Enable Notifications",
                            value: Binding(
                                get: { settings.notificationsEnabled },
                                set: { settings.notificationsEnabled = $0 }
                            )
                        )

                        if settings.notificationsEnabled {
                            Divider()
                                .background(ExTokens.Colors.borderDefault)

                            toggleRow(
                                icon: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                                iconColor: settings.soundEnabled ? ExTokens.Colors.statusSuccess : ExTokens.Colors.textMuted,
                                label: "Sound",
                                value: Binding(
                                    get: { settings.soundEnabled },
                                    set: { settings.soundEnabled = $0 }
                                )
                            )

                            toggleRow(
                                icon: settings.systemNotificationsEnabled ? "bell.and.waves.left.and.right.fill" : "bell.and.waves.left.and.right",
                                iconColor: settings.systemNotificationsEnabled ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted,
                                label: "macOS Notifications",
                                value: Binding(
                                    get: { settings.systemNotificationsEnabled },
                                    set: { settings.systemNotificationsEnabled = $0 }
                                )
                            )

                            toggleRow(
                                icon: "rectangle.topthird.inset.filled",
                                iconColor: settings.inAppPopupEnabled ? ExTokens.Colors.accentCyan : ExTokens.Colors.textMuted,
                                label: "In-App Popup",
                                value: Binding(
                                    get: { settings.inAppPopupEnabled },
                                    set: { settings.inAppPopupEnabled = $0 }
                                )
                            )
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: settings.notificationsEnabled)

                // Sound Picker
                if settings.notificationsEnabled && settings.soundEnabled {
                    settingsCard {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                            cardHeader(icon: "music.note", title: "Alert Sound")

                            HStack(spacing: ExTokens.Spacing._8) {
                                Picker("", selection: Binding(
                                    get: { settings.alertSound },
                                    set: { settings.alertSound = $0 }
                                )) {
                                    ForEach(AlertSound.allCases) { sound in
                                        Text("\(sound.emoji) \(sound.displayName)").tag(sound)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .tint(ExTokens.Colors.accentPrimary)

                                Button {
                                    settings.alertSound.play()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 9))
                                        Text("Play")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(ExTokens.Colors.accentPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                                }
                                .buttonStyle(HoverableButtonStyle())
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Preview
                if settings.notificationsEnabled && (settings.inAppPopupEnabled || settings.systemNotificationsEnabled) {
                    settingsCard {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                            cardHeader(icon: "eye", title: "Test Notifications")

                            Text("Preview how alerts look and sound")
                                .font(.system(size: 10))
                                .foregroundColor(ExTokens.Colors.textMuted)

                            HStack(spacing: ExTokens.Spacing._8) {
                                Button {
                                    firePreviewAlert(severity: "warning")
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 9))
                                        Text("Warning")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(ExTokens.Colors.statusWarning)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(ExTokens.Colors.statusWarning.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                            .stroke(ExTokens.Colors.statusWarning.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                                }
                                .buttonStyle(HoverableButtonStyle())

                                Button {
                                    firePreviewAlert(severity: "critical")
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.octagon.fill")
                                            .font(.system(size: 9))
                                        Text("Critical")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(ExTokens.Colors.statusCritical)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(ExTokens.Colors.statusCritical.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                            .stroke(ExTokens.Colors.statusCritical.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                                }
                                .buttonStyle(HoverableButtonStyle())
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Session thresholds
                thresholdCard(
                    icon: "bolt.fill",
                    title: "Session Thresholds",
                    subtitle: "5-hour rolling window",
                    warningValue: Binding(
                        get: { settings.thresholds.sessionWarning },
                        set: { settings.thresholds.sessionWarning = $0 }
                    ),
                    criticalValue: Binding(
                        get: { settings.thresholds.sessionCritical },
                        set: { settings.thresholds.sessionCritical = $0 }
                    )
                )

                // Weekly thresholds
                thresholdCard(
                    icon: "calendar",
                    title: "Weekly Thresholds",
                    subtitle: "7-day rolling window",
                    warningValue: Binding(
                        get: { settings.thresholds.weeklyWarning },
                        set: { settings.thresholds.weeklyWarning = $0 }
                    ),
                    criticalValue: Binding(
                        get: { settings.thresholds.weeklyCritical },
                        set: { settings.thresholds.weeklyCritical = $0 }
                    )
                )

                // Active Alerts summary
                if settings.notificationsEnabled {
                    activeAlertsSummary
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(ExTokens.Spacing._24)
            .animation(.easeInOut(duration: 0.2), value: settings.notificationsEnabled)
            .animation(.easeInOut(duration: 0.2), value: settings.soundEnabled)
        }
    }

    // MARK: - Preview Alert

    private func firePreviewAlert(severity: String) {
        let message = severity == "critical"
            ? "Session usage at 95%! Near limit."
            : "Session usage at 65% — warning level"

        // Sync settings to service before firing
        let service = NotificationService.shared
        service.soundEnabled = settings.soundEnabled
        service.inAppPopupEnabled = settings.inAppPopupEnabled
        service.systemNotificationsEnabled = settings.systemNotificationsEnabled
        service.alertSound = settings.alertSound

        // Ensure permission is requested
        service.requestPermission()

        // Play custom sound
        if settings.soundEnabled {
            settings.alertSound.play()
        }

        // In-app banner
        if settings.inAppPopupEnabled {
            NotificationCenter.default.post(
                name: NotificationService.alertTriggeredNotification,
                object: nil,
                userInfo: [
                    "type": "preview-\(severity)",
                    "severity": severity,
                    "message": message
                ]
            )
        }

        // macOS system notification
        if settings.systemNotificationsEnabled {
            service.sendTestNotification(severity: severity)
        }
    }

    // MARK: - Toggle Row

    private func toggleRow(icon: String, iconColor: Color, label: String, value: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ExTokens.Colors.textPrimary)

            Spacer()

            Toggle("", isOn: value)
                .toggleStyle(.switch)
                .tint(ExTokens.Colors.accentPrimary)
                .labelsHidden()
        }
    }

    // MARK: - Active Alerts Summary

    private var activeAlertsSummary: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                cardHeader(icon: "list.bullet", title: "Active Alerts")

                alertRow(
                    color: ExTokens.Colors.statusWarning,
                    icon: "exclamationmark.triangle.fill",
                    text: "Session warning",
                    value: "\(Int(settings.thresholds.sessionWarning * 100))%"
                )

                alertRow(
                    color: ExTokens.Colors.statusCritical,
                    icon: "exclamationmark.octagon.fill",
                    text: "Session critical",
                    value: "\(Int(settings.thresholds.sessionCritical * 100))%"
                )

                Rectangle()
                    .fill(ExTokens.Colors.borderDefault)
                    .frame(height: 1)

                alertRow(
                    color: ExTokens.Colors.statusWarning,
                    icon: "exclamationmark.triangle.fill",
                    text: "Weekly warning",
                    value: "\(Int(settings.thresholds.weeklyWarning * 100))%"
                )

                alertRow(
                    color: ExTokens.Colors.statusCritical,
                    icon: "exclamationmark.octagon.fill",
                    text: "Weekly critical",
                    value: "\(Int(settings.thresholds.weeklyCritical * 100))%"
                )
            }
        }
    }

    // MARK: - Threshold Card

    private func thresholdCard(
        icon: String,
        title: String,
        subtitle: String,
        warningValue: Binding<Double>,
        criticalValue: Binding<Double>
    ) -> some View {
        settingsCard {
            VStack(alignment: .leading, spacing: ExTokens.Spacing._16) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ExTokens.Colors.accentPrimary)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ExTokens.Colors.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(ExTokens.Colors.textMuted)
                    }
                }

                previewBar(warning: warningValue.wrappedValue, critical: criticalValue.wrappedValue)

                sliderRow(
                    color: ExTokens.Colors.statusWarning,
                    label: "Warning",
                    value: warningValue
                )

                sliderRow(
                    color: ExTokens.Colors.statusCritical,
                    label: "Critical",
                    value: criticalValue
                )
            }
        }
    }

    // MARK: - Helpers

    private func previewBar(warning: Double, critical: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ExTokens.Colors.backgroundElevated)

                RoundedRectangle(cornerRadius: 3)
                    .fill(ExTokens.Colors.statusSuccess.opacity(0.3))
                    .frame(width: geo.size.width * warning)

                Rectangle()
                    .fill(ExTokens.Colors.statusWarning)
                    .frame(width: 2)
                    .offset(x: geo.size.width * warning - 1)

                Rectangle()
                    .fill(ExTokens.Colors.statusCritical)
                    .frame(width: 2)
                    .offset(x: geo.size.width * critical - 1)
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func sliderRow(color: Color, label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ExTokens.Colors.textSecondary)
                .frame(width: 55, alignment: .leading)

            Slider(value: value, in: 0.1...0.99)
                .tint(color)

            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func alertRow(color: Color, icon: String, text: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 11))
                .foregroundColor(ExTokens.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    // MARK: - Shared Components

    private func settingsCard<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        HoverableCard {
            content()
        }
    }

    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ExTokens.Colors.accentPrimary)
                .frame(width: 22, height: 22)
                .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ExTokens.Colors.textPrimary)
        }
    }
}

// MARK: - Hoverable Card (shared across settings tabs)

struct HoverableCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var isHovered = false

    var body: some View {
        content()
            .padding(ExTokens.Spacing._16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    ExTokens.Colors.backgroundCard
                    // Subtle top gradient on hover
                    if isHovered {
                        LinearGradient(
                            colors: [ExTokens.Colors.accentPrimary.opacity(0.03), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                    .stroke(
                        isHovered ? ExTokens.Colors.accentPrimary.opacity(0.3) : ExTokens.Colors.borderDefault,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))
            .shadow(color: isHovered ? ExTokens.Colors.accentPrimary.opacity(0.05) : .clear, radius: 8, y: 2)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}
