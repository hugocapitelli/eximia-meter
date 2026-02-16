import SwiftUI

struct GeneralTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    private var settings: SettingsViewModel {
        appViewModel.settingsViewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ExTokens.Spacing._24) {
                // Section header
                sectionHeader(
                    title: "General",
                    subtitle: "App behavior and preferences"
                )

                // Popover Size
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        premiumCardHeader(icon: "rectangle.dashed", title: "Popover Size", badge: settings.popoverSize.rawValue)

                        HStack(spacing: 6) {
                            ForEach(PopoverSize.allCases) { size in
                                sizeButton(size)
                            }
                        }

                        // Size preview
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 9))
                                .foregroundColor(ExTokens.Colors.textMuted)
                            Text("\(Int(settings.popoverSize.dimensions.width))×\(Int(settings.popoverSize.dimensions.height)) px")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(ExTokens.Colors.textMuted)
                        }
                    }
                }

                // Menu Bar Style
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        premiumCardHeader(icon: "menubar.rectangle", title: "Menu Bar", badge: settings.menuBarStyle.shortLabel)

                        HStack(spacing: 6) {
                            ForEach(MenuBarStyle.allCases) { style in
                                menuBarStyleButton(style)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 9))
                                .foregroundColor(ExTokens.Colors.textMuted)
                            Text(settings.menuBarStyle == .logoOnly
                                 ? "Apenas o ícone exímIA na barra de menus"
                                 : "Ícone + indicadores de uso da sessão e semanal")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(ExTokens.Colors.textMuted)
                        }
                    }
                }

                // App Behavior
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        premiumCardHeader(icon: "gearshape", title: "Behavior")

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
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        premiumCardHeader(icon: "arrow.clockwise", title: "Refresh Interval", badge: intervalLabel(settings.refreshInterval))

                        HStack(spacing: 4) {
                            ForEach([10.0, 30.0, 60.0, 120.0], id: \.self) { interval in
                                intervalButton(interval)
                            }
                        }
                    }
                }

                // Terminal
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        premiumCardHeader(icon: "terminal", title: "Preferred Terminal", badge: settings.preferredTerminal.rawValue)

                        HStack(spacing: 6) {
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

    // MARK: - Section Header

    private func sectionHeader(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(ExTokens.Typography.caption)
                    .foregroundColor(ExTokens.Colors.textTertiary)
            }
            Spacer()
        }
    }

    // MARK: - Premium Card Header

    private func premiumCardHeader(icon: String, title: String, badge: String? = nil) -> some View {
        HStack(spacing: 6) {
            // Icon with subtle background
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ExTokens.Colors.accentPrimary)
                .frame(width: 22, height: 22)
                .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ExTokens.Colors.textPrimary)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(ExTokens.Colors.accentPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
            }
        }
    }

    // MARK: - Size Button

    private func sizeButton(_ size: PopoverSize) -> some View {
        let isSelected = settings.popoverSize == size

        return Button {
            settings.popoverSize = size
        } label: {
            VStack(spacing: 4) {
                Image(systemName: size.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : ExTokens.Colors.textMuted)

                Text(size.shortLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .black : ExTokens.Colors.textSecondary)

                Text(size.rawValue)
                    .font(.system(size: 7))
                    .foregroundColor(isSelected ? .black.opacity(0.6) : ExTokens.Colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? ExTokens.Colors.accentPrimary
                    : ExTokens.Colors.backgroundElevated
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                    .stroke(
                        isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.borderDefault,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverableButtonStyle())
    }

    // MARK: - Interval button

    private func intervalLabel(_ interval: Double) -> String {
        interval < 60 ? "\(Int(interval))s" : "\(Int(interval / 60))m"
    }

    private func intervalButton(_ interval: Double) -> some View {
        let isSelected = settings.refreshInterval == interval
        let label = intervalLabel(interval)

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

    // MARK: - Menu Bar Style Button

    private func menuBarStyleButton(_ style: MenuBarStyle) -> some View {
        let isSelected = settings.menuBarStyle == style

        return Button {
            settings.menuBarStyle = style
        } label: {
            VStack(spacing: 4) {
                Image(systemName: style.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : ExTokens.Colors.textMuted)

                Text(style.shortLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .black : ExTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? ExTokens.Colors.accentPrimary
                    : ExTokens.Colors.backgroundElevated
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                    .stroke(
                        isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.borderDefault,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverableButtonStyle())
    }

    // MARK: - Terminal button with description

    private func terminalButton(_ terminal: TerminalLauncherService.Terminal) -> some View {
        let isSelected = settings.preferredTerminal == terminal

        return Button {
            settings.preferredTerminal = terminal
        } label: {
            VStack(spacing: 3) {
                Text(terminal.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .black : ExTokens.Colors.textTertiary)

                Text(terminalDescription(terminal))
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .black.opacity(0.6) : ExTokens.Colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
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

    private func terminalDescription(_ terminal: TerminalLauncherService.Terminal) -> String {
        switch terminal {
        case .terminalApp: return "macOS built-in"
        case .iTerm2:      return "Advanced terminal"
        case .warp:        return "AI-powered"
        }
    }
}
