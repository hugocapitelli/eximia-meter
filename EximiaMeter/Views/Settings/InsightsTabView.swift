import SwiftUI

struct InsightsTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    private var usage: UsageViewModel {
        appViewModel.usageViewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ExTokens.Spacing._24) {
                // Section header
                sectionHeader(
                    title: "Insights",
                    subtitle: "Usage analytics and trends"
                )

                // Overview Stats
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._16) {
                        premiumCardHeader(icon: "chart.xyaxis.line", title: "Overview")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            insightStat(label: "TOKENS 7D", value: formatTokens(usage.tokens7d), color: ExTokens.Colors.accentPrimary)
                            insightStat(label: "TOKENS 30D", value: formatTokens(usage.tokens30d), color: ExTokens.Colors.accentSecondary)
                            insightStat(label: "ALL TIME", value: formatTokens(usage.tokensAllTime), color: ExTokens.Colors.accentCyan)
                            insightStat(label: "MSGS 7D", value: formatNumber(usage.messages7d), color: ExTokens.Colors.statusSuccess)
                            insightStat(label: "SESSIONS 7D", value: "\(usage.sessions7d)", color: ExTokens.Colors.statusWarning)
                            insightStat(label: "STREAK", value: "\(usage.usageStreak)d", color: ExTokens.Colors.accentPrimary)
                        }
                    }
                }

                // Cost & Projection
                HoverableCard {
                    VStack(alignment: .leading, spacing: ExTokens.Spacing._16) {
                        premiumCardHeader(icon: "dollarsign.circle", title: "Cost & Projection")

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CUSTO SEMANAL EST.")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(ExTokens.Colors.textMuted)
                                    .tracking(0.5)
                                Text(usage.formattedWeeklyCost.isEmpty ? "--" : usage.formattedWeeklyCost)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(ExTokens.Colors.statusWarning)
                            }

                            Spacer()

                            if usage.burnRatePerHour > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("BURN RATE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(ExTokens.Colors.textMuted)
                                        .tracking(0.5)
                                    Text(String(format: "%.2f%%/h", usage.burnRatePerHour * 100))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(ExTokens.Colors.textSecondary)
                                }
                            }
                        }

                        if !usage.weeklyProjection.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: usage.projectionIsWarning ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                                    .font(.system(size: 10))
                                Text(usage.weeklyProjection)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(usage.projectionIsWarning ? ExTokens.Colors.statusWarning : ExTokens.Colors.statusSuccess)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (usage.projectionIsWarning ? ExTokens.Colors.statusWarning : ExTokens.Colors.statusSuccess).opacity(0.08)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                        }
                    }
                }

                // Week over Week
                if let wow = usage.weekOverWeekChange {
                    HoverableCard {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                            premiumCardHeader(icon: "arrow.up.arrow.down", title: "Week over Week")

                            HStack(spacing: 12) {
                                Image(systemName: usage.weekOverWeekIsUp ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(usage.weekOverWeekIsUp ? ExTokens.Colors.statusWarning : ExTokens.Colors.statusSuccess)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wow)
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(usage.weekOverWeekIsUp ? ExTokens.Colors.statusWarning : ExTokens.Colors.statusSuccess)
                                    Text("vs semana anterior")
                                        .font(.system(size: 10))
                                        .foregroundColor(ExTokens.Colors.textMuted)
                                }

                                Spacer()

                                if usage.todayVsAverageRatio > 0 {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "%.0f%%", usage.todayVsAverageRatio * 100))
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(usage.todayVsAverageRatio > 1.2 ? ExTokens.Colors.statusWarning : ExTokens.Colors.textSecondary)
                                        Text("hoje vs média")
                                            .font(.system(size: 9))
                                            .foregroundColor(ExTokens.Colors.textMuted)
                                    }
                                }
                            }
                        }
                    }
                }

                // Sparkline (7 days)
                if !usage.last7DaysTokens.isEmpty && usage.last7DaysTokens.contains(where: { $0.1 > 0 }) {
                    HoverableCard {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                            premiumCardHeader(icon: "chart.line.uptrend.xyaxis", title: "Tokens por Dia (7D)")

                            SparklineView(data: usage.last7DaysTokens)
                        }
                    }
                }

                // Activity Heatmap
                if !usage.hourCounts.isEmpty {
                    HoverableCard {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                            premiumCardHeader(icon: "square.grid.3x3.fill", title: "Atividade por Hora")

                            HeatmapView(hourCounts: usage.hourCounts)

                            if let peak = usage.hourCounts.max(by: { $0.value < $1.value }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(ExTokens.Colors.accentPrimary)
                                    Text("Pico: \(peak.key):00 (\(peak.value) sessões)")
                                        .font(.system(size: 10))
                                        .foregroundColor(ExTokens.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }

                // Model Distribution
                if !sortedModelUsage.isEmpty {
                    HoverableCard {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                            premiumCardHeader(icon: "cpu", title: "Distribuição de Modelos (7D)")

                            ModelDistributionBar(models: sortedModelUsage)
                        }
                    }
                }

                // Alerts
                VStack(alignment: .leading, spacing: ExTokens.Spacing._8) {
                    if let peak = usage.peakDetectionMessage {
                        alertCard(icon: "bolt.fill", message: peak, color: ExTokens.Colors.statusWarning)
                    }
                    if let suggestion = usage.modelSuggestion {
                        alertCard(icon: "lightbulb.fill", message: suggestion, color: ExTokens.Colors.accentPrimary)
                    }
                }
            }
            .padding(ExTokens.Spacing._24)
        }
    }

    // MARK: - Components

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

    private func premiumCardHeader(icon: String, title: String) -> some View {
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

    private func insightStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textPrimary)
            Text(label)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(ExTokens.Colors.textMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(ExTokens.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func alertCard(icon: String, message: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(ExTokens.Colors.textSecondary)
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var sortedModelUsage: [(String, Double)] {
        usage.perModelUsage
            .sorted { $0.value > $1.value }
            .filter { $0.value > 0.001 }
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.2fB", Double(count) / 1_000_000_000)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.0fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func formatNumber(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
