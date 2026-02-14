import SwiftUI

struct ProjectCardView: View {
    let project: Project
    let weeklyTokens: Int
    var onLaunch: () -> Void
    var onInstallAIOS: (() -> Void)?
    var onModelChange: (ClaudeModel) -> Void
    var onOptimizationChange: (OptimizationLevel) -> Void

    @State private var isHovered = false
    @State private var isExpanded = false
    @State private var selectedModel: ClaudeModel
    @State private var selectedOptimization: OptimizationLevel
    @State private var detailPeriod: CardPeriod = .week

    enum CardPeriod: String, CaseIterable {
        case day = "24h"
        case week = "7d"
        case month = "30d"
    }

    init(project: Project, weeklyTokens: Int = 0, onLaunch: @escaping () -> Void, onInstallAIOS: (() -> Void)? = nil, onModelChange: @escaping (ClaudeModel) -> Void, onOptimizationChange: @escaping (OptimizationLevel) -> Void = { _ in }) {
        self.project = project
        self.weeklyTokens = weeklyTokens
        self.onLaunch = onLaunch
        self.onInstallAIOS = onInstallAIOS
        self.onModelChange = onModelChange
        self.onOptimizationChange = onOptimizationChange
        self._selectedModel = State(initialValue: project.selectedModel)
        self._selectedOptimization = State(initialValue: project.optimizationLevel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ─── Header Row ─────────────────────────────
            HStack {
                Text(project.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                // Expand/collapse toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(ExTokens.Colors.accentPrimary.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HoverableButtonStyle())
            }

            // ─── Controls Row ───────────────────────────
            HStack(spacing: 8) {
                ModelPickerView(selectedModel: $selectedModel, compact: true)
                    .onChange(of: selectedModel) { _, newValue in
                        onModelChange(newValue)
                    }

                OptimizationPickerView(level: $selectedOptimization)
                    .onChange(of: selectedOptimization) { _, newValue in
                        onOptimizationChange(newValue)
                    }

                Spacer()

                if weeklyTokens > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 7))
                        Text(formatTokens(weeklyTokens))
                            .font(ExTokens.Typography.micro)
                    }
                    .foregroundColor(ExTokens.Colors.textMuted)
                }
            }

            // ─── Expanded Details ───────────────────────
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Path
                    Text(project.path)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    // Period filter
                    HStack(spacing: 2) {
                        ForEach(CardPeriod.allCases, id: \.rawValue) { period in
                            Button {
                                detailPeriod = period
                            } label: {
                                Text(period.rawValue)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(detailPeriod == period ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(detailPeriod == period ? ExTokens.Colors.accentPrimary.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(HoverableButtonStyle())
                        }
                    }

                    // Usage bar
                    if weeklyTokens > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ExTokens.Colors.borderDefault)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ExTokens.Colors.accentPrimary)
                                    .frame(width: geo.size.width * min(usagePct, 1.0), height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("\(formatTokens(weeklyTokens)) tokens used")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ExTokens.Colors.textTertiary)
                    }

                    // Sessions info
                    HStack(spacing: 12) {
                        Label("\(project.totalSessions)", systemImage: "terminal.fill")
                            .font(.system(size: 8))
                            .foregroundColor(ExTokens.Colors.textTertiary)
                        if project.isAIOSProject {
                            Label("AIOS", systemImage: "cpu")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(ExTokens.Colors.accentPrimary)
                        }
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            // ─── Action Buttons ─────────────────────────
            HStack(spacing: 4) {
                // Install AIOS button (only for non-AIOS projects)
                if !project.isAIOSProject, let onInstallAIOS {
                    Button(action: onInstallAIOS) {
                        HStack(spacing: 3) {
                            Image(systemName: "cpu")
                                .font(.system(size: 7))
                            Text("AIOS")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .foregroundColor(ExTokens.Colors.accentSecondary)
                        .background(ExTokens.Colors.accentSecondary.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.accentSecondary.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    }
                    .buttonStyle(HoverableButtonStyle())
                }

                // Launch button
                Button(action: onLaunch) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                        Text("Launch")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .foregroundColor(.black)
                    .background(ExTokens.Colors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                }
                .buttonStyle(HoverableButtonStyle())
            }
        }
        .padding(10)
        .frame(width: 180, height: isExpanded ? 210 : 120)
        .background(ExTokens.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                .stroke(
                    isHovered
                        ? ExTokens.Colors.accentPrimary.opacity(0.5)
                        : ExTokens.Colors.borderDefault,
                    lineWidth: 1
                )
        )
        .overlay(alignment: .top) {
            if isHovered {
                LinearGradient(
                    colors: [.clear, ExTokens.Colors.accentPrimary.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var usagePct: CGFloat {
        CGFloat(weeklyTokens) / 10_000_000.0
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
}
