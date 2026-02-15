import SwiftUI
import AppKit

struct FooterView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        HStack(spacing: ExTokens.Spacing._8) {
            Button {
                appViewModel.refresh()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Text("Updated \(appViewModel.usageViewModel.timeSinceUpdate)")
                        .font(ExTokens.Typography.caption)
                        .foregroundColor(ExTokens.Colors.textMuted)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(HoverableButtonStyle())
            .help("Click to refresh")

            Spacer()

            Button {
                exportUsageData()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 9))
                    Text("Export")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(ExTokens.Colors.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(HoverableButtonStyle())
            .help("Export usage data as CSV")

            Button {
                NSApplication.shared.terminate(self)
            } label: {
                Text("Quit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ExTokens.Colors.statusCritical)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ExTokens.Colors.statusCritical.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
            }
            .buttonStyle(HoverableButtonStyle())
        }
        .padding(.horizontal, ExTokens.Spacing.popoverPadding)
        .padding(.vertical, ExTokens.Spacing._6)
    }

    // MARK: - Export CSV

    private func exportUsageData() {
        let usage = appViewModel.usageViewModel
        let projects = appViewModel.projectsViewModel.projects

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = dateFormatter.string(from: Date())

        var csv = "Category,Key,Value\n"
        csv += "Meta,Export Date,\(now)\n"
        csv += "Meta,Source,\(usage.usageSourceLabel)\n"
        csv += "Usage,Weekly %,\(String(format: "%.1f", usage.weeklyUsage * 100))\n"
        csv += "Usage,Daily %,\(String(format: "%.1f", usage.dailyUsage * 100))\n"
        csv += "Usage,Session %,\(String(format: "%.1f", usage.sessionUsage * 100))\n"
        csv += "Usage,Weekly Reset,\(usage.weeklyResetFormatted)\n"
        csv += "Usage,Session Reset,\(usage.sessionResetFormatted)\n"
        csv += "Tokens,24h,\(usage.tokens24h)\n"
        csv += "Tokens,7d,\(usage.tokens7d)\n"
        csv += "Tokens,30d,\(usage.tokens30d)\n"
        csv += "Tokens,All Time,\(usage.tokensAllTime)\n"
        csv += "Messages,24h,\(usage.messages24h)\n"
        csv += "Messages,7d,\(usage.messages7d)\n"
        csv += "Messages,30d,\(usage.messages30d)\n"
        csv += "Messages,All Time,\(usage.messagesAllTime)\n"
        csv += "Sessions,24h,\(usage.sessions24h)\n"
        csv += "Sessions,7d,\(usage.sessions7d)\n"
        csv += "Sessions,30d,\(usage.sessions30d)\n"
        csv += "Sessions,All Time,\(usage.sessionsAllTime)\n"
        csv += "Insights,Estimated Cost (7d),\(usage.formattedWeeklyCost)\n"
        csv += "Insights,Usage Streak,\(usage.usageStreak) days\n"
        csv += "Insights,Burn Rate/h,\(String(format: "%.4f", usage.burnRatePerHour))\n"
        csv += "Insights,Projection,\(usage.weeklyProjection)\n"

        // Model distribution
        for (model, pct) in usage.perModelUsage.sorted(by: { $0.value > $1.value }) {
            csv += "Model,\(model),\(String(format: "%.1f%%", pct * 100))\n"
        }

        // Per-project tokens
        for (path, tokens) in usage.perProjectTokens.sorted(by: { $0.value > $1.value }) {
            let name = projects.first(where: { $0.path == path })?.name ?? URL(fileURLWithPath: path).lastPathComponent
            csv += "Project,\(name),\(tokens)\n"
        }

        // Save dialog
        let panel = NSSavePanel()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "eximia-usage-\(dateFormatter.string(from: Date())).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
