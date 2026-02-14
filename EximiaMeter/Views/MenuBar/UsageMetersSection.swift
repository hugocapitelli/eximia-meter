import SwiftUI

struct UsageMetersSection: View {
    @EnvironmentObject var appViewModel: AppViewModel

    private var usage: UsageViewModel {
        appViewModel.usageViewModel
    }

    private var thresholds: ThresholdConfig {
        appViewModel.settingsViewModel.thresholds
    }

    var body: some View {
        VStack(spacing: ExTokens.Spacing._12) {
            // ─── Data Source Indicator ─────────────────────
            HStack {
                Spacer()
                Text("Source: \(usage.usageSourceLabel)")
                    .font(ExTokens.Typography.micro)
                    .foregroundColor(usage.usageSource == .api ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)
            }

            // ─── Weekly Usage (main meter) ──────────────────
            ExProgressBar(
                value: usage.weeklyUsage,
                label: "Weekly Usage",
                detail: "Resets in \(usage.weeklyResetFormatted)",
                warningThreshold: thresholds.weeklyWarning,
                criticalThreshold: thresholds.weeklyCritical
            )

            // ─── Current Session ─────────────────────────────
            ExProgressBar(
                value: usage.sessionUsage,
                label: "Current Session",
                detail: "Resets in \(usage.sessionResetFormatted)",
                warningThreshold: thresholds.sessionWarning,
                criticalThreshold: thresholds.sessionCritical
            )

            // ─── Model Distribution ─────────────────────────
            if !sortedModelUsage.isEmpty {
                Text("MODEL DISTRIBUTION (7D)")
                    .font(ExTokens.Typography.label)
                    .tracking(1.5)
                    .foregroundColor(ExTokens.Colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                ModelDistributionBar(models: sortedModelUsage)
            }

            // ─── Per-Project Usage ──────────────────────────
            if !usage.perProjectTokens.isEmpty {
                ProjectUsageSection(
                    perProjectTokens: usage.perProjectTokens,
                    weeklyLimit: appViewModel.settingsViewModel.weeklyTokenLimit,
                    projects: appViewModel.projectsViewModel.projects
                )
            }
        }
        .padding(.horizontal, ExTokens.Spacing.popoverPadding)
    }

    private var sortedModelUsage: [(String, Double)] {
        usage.perModelUsage
            .sorted { $0.value > $1.value }
            .filter { $0.value > 0.001 }
    }
}

// MARK: - Model Distribution Bar

struct ModelDistributionBar: View {
    let models: [(String, Double)]

    var body: some View {
        VStack(spacing: ExTokens.Spacing._6) {
            // Segmented bar
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(models, id: \.0) { modelId, pct in
                        let color = resolveModel(modelId)?.badgeColor ?? ExTokens.Colors.textMuted
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: max(geo.size.width * CGFloat(pct) - 1, 2))
                    }
                }
            }
            .frame(height: 8)
            .background(ExTokens.Colors.borderDefault)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Legend
            HStack(spacing: 12) {
                ForEach(models, id: \.0) { modelId, pct in
                    let model = resolveModel(modelId)
                    let name = model?.shortName ?? modelId
                    let color = model?.badgeColor ?? ExTokens.Colors.textMuted
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                        Text("\(name) \(Int(pct * 100))%")
                            .font(ExTokens.Typography.micro)
                            .foregroundColor(ExTokens.Colors.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    /// Fuzzy match model ID — handles variations like "claude-sonnet-4-5" or "sonnet"
    private func resolveModel(_ id: String) -> ClaudeModel? {
        if let exact = ClaudeModel(rawValue: id) { return exact }
        let lowered = id.lowercased()
        if lowered.contains("opus") { return .opus }
        if lowered.contains("sonnet") { return .sonnet }
        if lowered.contains("haiku") { return .haiku }
        return nil
    }
}

// MARK: - Project Progress Bar (separate bar value from display percentage)

struct ProjectProgressBar: View {
    let barValue: Double      // 0-1, controls the bar width (relative to max project)
    let displayPct: Double    // 0-1, the actual percentage shown as text (share of total)
    let label: String
    let detail: String?

    private var barColor: Color {
        if displayPct >= 0.30 {
            return ExTokens.Colors.statusCritical
        } else if displayPct >= 0.15 {
            return ExTokens.Colors.statusWarning
        } else {
            return ExTokens.Colors.statusSuccess
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(ExTokens.Typography.subtitle)
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Spacer()

                Text("\(Int(displayPct * 100))%")
                    .font(ExTokens.Typography.captionMono)
                    .foregroundColor(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: ExTokens.Radius.xs)
                        .fill(ExTokens.Colors.borderDefault)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: ExTokens.Radius.xs)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(min(barValue, 1.0)), height: 6)
                        .animation(.easeInOut(duration: 0.5), value: barValue)
                }
            }
            .frame(height: 6)

            if let detail {
                Text(detail)
                    .font(ExTokens.Typography.caption)
                    .foregroundColor(ExTokens.Colors.textMuted)
            }
        }
    }
}

// MARK: - Per-Project Usage

struct ProjectUsageSection: View {
    let perProjectTokens: [String: Int]
    let weeklyLimit: Int
    let projects: [Project]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: ExTokens.Spacing._8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Text("PER PROJECT (7D)")
                        .font(ExTokens.Typography.label)
                        .tracking(1.5)
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Spacer()

                    Text("\(perProjectTokens.count) projects")
                        .font(ExTokens.Typography.micro)
                        .foregroundColor(ExTokens.Colors.textMuted)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(HoverableButtonStyle())
            .padding(.top, 4)

            if isExpanded {
                let sorted = sortedProjects
                let maxTokens = sorted.first?.1 ?? 1

                ForEach(sorted, id: \.0) { name, tokens in
                    let barPct = maxTokens > 0 ? Double(tokens) / Double(maxTokens) : 0
                    let totalPct = perProjectTotal > 0 ? Double(tokens) / Double(perProjectTotal) : 0
                    ProjectProgressBar(
                        barValue: barPct,
                        displayPct: totalPct,
                        label: name,
                        detail: "\(formatTokens(tokens)) (\(Int(totalPct * 100))% of total)"
                    )
                }
            }
        }
    }

    private var perProjectTotal: Int {
        perProjectTokens.values.reduce(0, +)
    }

    private var sortedProjects: [(String, Int)] {
        perProjectTokens
            .map { dirName, tokens in
                let name = ProjectUsageService.displayName(forDirName: dirName)
                return (name, tokens)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(8)
            .map { ($0.0, $0.1) }
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.2fB tokens", Double(count) / 1_000_000_000)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM tokens", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK tokens", Double(count) / 1_000)
        }
        return "\(count) tokens"
    }
}
