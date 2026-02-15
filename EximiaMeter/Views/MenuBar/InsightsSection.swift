import SwiftUI

struct InsightsSection: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var isExpanded = true

    private var usage: UsageViewModel {
        appViewModel.usageViewModel
    }

    private var hasAnyInsight: Bool {
        usage.estimatedWeeklyCostUSD > 0 ||
        usage.usageStreak > 1 ||
        usage.peakDetectionMessage != nil ||
        usage.modelSuggestion != nil ||
        usage.weekOverWeekChange != nil ||
        !usage.last7DaysTokens.isEmpty
    }

    var body: some View {
        if hasAnyInsight {
            VStack(spacing: ExTokens.Spacing._8) {
                // Header
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ExTokens.Colors.textMuted)

                        Text("INSIGHTS")
                            .font(ExTokens.Typography.label)
                            .tracking(1.5)
                            .foregroundColor(ExTokens.Colors.textMuted)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(HoverableButtonStyle())

                if isExpanded {
                    VStack(spacing: ExTokens.Spacing._8) {
                        // Top row: Cost + Streak + Week comparison
                        HStack(spacing: ExTokens.Spacing._8) {
                            if usage.estimatedWeeklyCostUSD > 0 {
                                InsightPill(
                                    icon: "dollarsign.circle.fill",
                                    label: "Custo 7d",
                                    value: usage.formattedWeeklyCost,
                                    color: ExTokens.Colors.statusWarning
                                )
                            }

                            if usage.usageStreak > 1 {
                                InsightPill(
                                    icon: "flame.fill",
                                    label: "Streak",
                                    value: "\(usage.usageStreak) dias",
                                    color: ExTokens.Colors.accentPrimary
                                )
                            }

                            if let wow = usage.weekOverWeekChange {
                                InsightPill(
                                    icon: usage.weekOverWeekIsUp ? "arrow.up.right" : "arrow.down.right",
                                    label: "Semana",
                                    value: wow,
                                    color: usage.weekOverWeekIsUp ? ExTokens.Colors.statusWarning : ExTokens.Colors.statusSuccess
                                )
                            }
                        }

                        // Sparkline (7 days)
                        if !usage.last7DaysTokens.isEmpty && usage.last7DaysTokens.contains(where: { $0.1 > 0 }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOKENS POR DIA (7D)")
                                    .font(.system(size: 8, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(ExTokens.Colors.textMuted)

                                SparklineView(data: usage.last7DaysTokens)
                            }
                        }

                        // Activity heatmap
                        if !usage.hourCounts.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ATIVIDADE POR HORA")
                                    .font(.system(size: 8, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(ExTokens.Colors.textMuted)

                                HeatmapView(hourCounts: usage.hourCounts)
                            }
                        }

                        // Peak detection alert
                        if let peak = usage.peakDetectionMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(ExTokens.Colors.statusWarning)
                                Text(peak)
                                    .font(ExTokens.Typography.caption)
                                    .foregroundColor(ExTokens.Colors.statusWarning)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(ExTokens.Colors.statusWarning.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                        }

                        // Model suggestion
                        if let suggestion = usage.modelSuggestion {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(ExTokens.Colors.accentPrimary)
                                Text(suggestion)
                                    .font(ExTokens.Typography.caption)
                                    .foregroundColor(ExTokens.Colors.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(ExTokens.Colors.accentPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                        }
                    }
                }
            }
            .padding(.horizontal, ExTokens.Spacing.popoverPadding)
        }
    }
}

// MARK: - Insight Pill

struct InsightPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(ExTokens.Colors.textMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(ExTokens.Colors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
        )
    }
}
