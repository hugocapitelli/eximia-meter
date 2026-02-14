import SwiftUI

struct AccountTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    private var settings: SettingsViewModel {
        appViewModel.settingsViewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ExTokens.Spacing._16) {
                // Section header
                sectionHeader(
                    title: "Account",
                    subtitle: "API connection status and Claude plan"
                )

                // Connection Status
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        cardHeader(icon: "link", title: "Connection Status")

                        HStack(spacing: ExTokens.Spacing._8) {
                            Circle()
                                .fill(settings.isApiConnected ? ExTokens.Colors.statusSuccess : ExTokens.Colors.statusWarning)
                                .frame(width: 8, height: 8)

                            Text(settings.isApiConnected ? "Connected" : "Not Connected")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(settings.isApiConnected ? ExTokens.Colors.statusSuccess : ExTokens.Colors.statusWarning)

                            Spacer()

                            if settings.accountInfo.tokenExpired {
                                Text("Token Expired")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(ExTokens.Colors.statusCritical)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ExTokens.Colors.statusCritical.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
                            }
                        }

                        if !settings.isApiConnected {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(ExTokens.Colors.textMuted)

                                Text("Authenticate with `claude` CLI to enable auto-detection")
                                    .font(.system(size: 10))
                                    .foregroundColor(ExTokens.Colors.textMuted)
                            }
                        }

                        if let tier = settings.accountInfo.rateLimitTier {
                            HStack(spacing: 6) {
                                Text("Rate Limit Tier:")
                                    .font(.system(size: 10))
                                    .foregroundColor(ExTokens.Colors.textMuted)
                                Text(tier)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(ExTokens.Colors.textTertiary)
                            }
                        }
                    }
                }

                // Claude Plan
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        HStack {
                            cardHeader(icon: "cpu", title: "Claude Plan")
                            Spacer()
                            if settings.isPlanAutoDetected {
                                badge("Auto-detected", color: ExTokens.Colors.statusSuccess)
                            } else {
                                badge("Manual", color: ExTokens.Colors.textMuted)
                            }
                        }

                        HStack(spacing: 6) {
                            ForEach(ClaudePlan.allCases) { plan in
                                planButton(plan)
                            }
                        }
                        .allowsHitTesting(!settings.isPlanAutoDetected)
                        .opacity(settings.isPlanAutoDetected ? 0.7 : 1.0)

                        if settings.isPlanAutoDetected {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(ExTokens.Colors.textMuted)

                                Text("Plan detected from Keychain credentials. Disconnect to select manually.")
                                    .font(.system(size: 10))
                                    .foregroundColor(ExTokens.Colors.textMuted)
                            }
                        }
                    }
                }

                // Token Limits
                settingsCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                        cardHeader(icon: "chart.bar", title: "Token Limits")

                        HStack(spacing: ExTokens.Spacing._24) {
                            limitBadge(label: "Weekly", value: formatTokens(settings.weeklyTokenLimit))
                            limitBadge(label: "Session", value: formatTokens(settings.sessionTokenLimit))
                        }
                    }
                }
            }
            .padding(ExTokens.Spacing._24)
        }
    }

    // MARK: - Components

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
    }

    private func planButton(_ plan: ClaudePlan) -> some View {
        let isSelected = settings.claudePlan == plan
        return Button {
            settings.claudePlan = plan
        } label: {
            VStack(spacing: 3) {
                Text(plan.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .black : ExTokens.Colors.textSecondary)

                Text(plan.description)
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .black.opacity(0.6) : ExTokens.Colors.textMuted)
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

    private func limitBadge(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(ExTokens.Colors.textMuted)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textTertiary)
        }
    }

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000_000 {
            let value = Double(tokens) / 1_000_000_000
            return String(format: "%.1fB tokens", value)
        } else if tokens >= 1_000_000 {
            let value = Double(tokens) / 1_000_000
            return String(format: "%.0fM tokens", value)
        } else {
            return "\(tokens) tokens"
        }
    }

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
}
