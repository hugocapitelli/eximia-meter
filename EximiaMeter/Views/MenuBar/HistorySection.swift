import SwiftUI

enum TimePeriod: String, CaseIterable, Identifiable {
    case last24h = "24h"
    case last7d = "7d"
    case last30d = "30d"
    case allTime = "All"

    var id: String { rawValue }
}

struct HistorySection: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedPeriod: TimePeriod = .last24h

    private var usage: UsageViewModel {
        appViewModel.usageViewModel
    }

    var body: some View {
        VStack(spacing: ExTokens.Spacing._8) {
            // Divider
            Rectangle()
                .fill(ExTokens.Colors.borderDefault)
                .frame(height: 1)
                .padding(.horizontal, ExTokens.Spacing.popoverPadding)

            VStack(spacing: ExTokens.Spacing._12) {
                // Period selector
                HStack {
                    Text("USAGE BY PERIOD")
                        .font(ExTokens.Typography.label)
                        .tracking(1.5)
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Spacer()

                    // Segmented picker
                    HStack(spacing: 2) {
                        ForEach(TimePeriod.allCases) { period in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedPeriod = period
                                }
                            } label: {
                                Text(period.rawValue)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(
                                        selectedPeriod == period
                                            ? ExTokens.Colors.accentPrimary
                                            : ExTokens.Colors.textTertiary
                                    )
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedPeriod == period
                                            ? ExTokens.Colors.accentPrimary.opacity(0.1)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(HoverableButtonStyle())
                        }
                    }
                    .padding(2)
                    .background(ExTokens.Colors.backgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                            .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
                    )
                }

                // Stats grid
                HStack(spacing: ExTokens.Spacing._12) {
                    StatCard(icon: "doc.text", label: "Tokens", value: formatTokens(tokensForPeriod))
                    StatCard(icon: "bubble.left.fill", label: "Messages", value: formatNumber(messagesForPeriod))
                    StatCard(icon: "terminal.fill", label: "Sessions", value: "\(sessionsForPeriod)")
                }

                // Peak hour (if available)
                if !usage.hourCounts.isEmpty {
                    if let peak = usage.hourCounts.max(by: { $0.value < $1.value }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                                .foregroundColor(ExTokens.Colors.accentPrimary)
                            Text("Peak hour: \(peak.key):00")
                                .font(ExTokens.Typography.caption)
                                .foregroundColor(ExTokens.Colors.textTertiary)
                            Text("(\(peak.value) sessions)")
                                .font(ExTokens.Typography.micro)
                                .foregroundColor(ExTokens.Colors.textMuted)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, ExTokens.Spacing.popoverPadding)
        }
    }

    private var tokensForPeriod: Int {
        switch selectedPeriod {
        case .last24h: return usage.tokens24h
        case .last7d: return usage.tokens7d
        case .last30d: return usage.tokens30d
        case .allTime: return usage.tokensAllTime
        }
    }

    private var messagesForPeriod: Int {
        switch selectedPeriod {
        case .last24h: return usage.messages24h
        case .last7d: return usage.messages7d
        case .last30d: return usage.messages30d
        case .allTime: return usage.messagesAllTime
        }
    }

    private var sessionsForPeriod: Int {
        switch selectedPeriod {
        case .last24h: return usage.sessions24h
        case .last7d: return usage.sessions7d
        case .last30d: return usage.sessions30d
        case .allTime: return usage.sessionsAllTime
        }
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.2fB", Double(count) / 1_000_000_000)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func formatNumber(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.2fB", Double(count) / 1_000_000_000)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(ExTokens.Colors.accentPrimary)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textPrimary)

            Text(label)
                .font(ExTokens.Typography.micro)
                .foregroundColor(ExTokens.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ExTokens.Colors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
        )
    }
}
