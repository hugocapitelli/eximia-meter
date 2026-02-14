import SwiftUI

struct GeneralTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    private var settings: SettingsViewModel {
        appViewModel.settingsViewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ExTokens.Spacing._16) {
                // Section header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("General")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ExTokens.Colors.textPrimary)

                        Text("App behavior and preferences")
                            .font(ExTokens.Typography.caption)
                            .foregroundColor(ExTokens.Colors.textTertiary)
                    }
                    Spacer()
                }

                // App Behavior
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        cardHeader(icon: "gearshape", title: "Behavior")

                        Toggle("Launch at Login", isOn: Binding(
                            get: { settings.launchAtLogin },
                            set: { settings.launchAtLogin = $0 }
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(ExTokens.Colors.textSecondary)
                        .tint(ExTokens.Colors.accentPrimary)
                    }
                }

                // Refresh Interval
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        cardHeader(icon: "arrow.clockwise", title: "Refresh Interval")

                        HStack(spacing: 4) {
                            ForEach([10.0, 30.0, 60.0, 120.0], id: \.self) { interval in
                                intervalButton(interval)
                            }
                        }
                    }
                }

                // Terminal
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        cardHeader(icon: "terminal", title: "Preferred Terminal")

                        HStack(spacing: 4) {
                            ForEach(TerminalLauncherService.Terminal.allCases) { terminal in
                                terminalButton(terminal)
                            }
                        }
                    }
                }
            }
            .padding(ExTokens.Spacing._24)
        }
    }

    // MARK: - Reusable card wrapper

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(ExTokens.Spacing._16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ExTokens.Colors.backgroundCard)
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                    .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))
    }

    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ExTokens.Colors.accentPrimary)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ExTokens.Colors.textPrimary)
        }
    }

    // MARK: - Interval button

    private func intervalButton(_ interval: Double) -> some View {
        let isSelected = settings.refreshInterval == interval
        let label = interval < 60 ? "\(Int(interval))s" : "\(Int(interval / 60))m"

        return Button {
            settings.refreshInterval = interval
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : ExTokens.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? ExTokens.Colors.accentPrimary
                        : ExTokens.Colors.backgroundElevated
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                        .stroke(
                            isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.borderDefault,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                .contentShape(Rectangle())
        }
        .buttonStyle(HoverableButtonStyle())
    }

    // MARK: - Terminal button

    private func terminalButton(_ terminal: TerminalLauncherService.Terminal) -> some View {
        let isSelected = settings.preferredTerminal == terminal

        return Button {
            settings.preferredTerminal = terminal
        } label: {
            Text(terminal.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isSelected ? .black : ExTokens.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? ExTokens.Colors.accentPrimary
                        : ExTokens.Colors.backgroundElevated
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                        .stroke(
                            isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.borderDefault,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                .contentShape(Rectangle())
        }
        .buttonStyle(HoverableButtonStyle())
    }
}
