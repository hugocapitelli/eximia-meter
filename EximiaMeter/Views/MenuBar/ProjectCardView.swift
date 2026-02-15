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
    @State private var isUpdatingAIOS = false
    @State private var aiosUpdateResult: Bool? = nil

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
            }

            // ─── Token Usage Inline ───────────────────────
            if weeklyTokens > 0 {
                HStack(spacing: 0) {
                    // Mini progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(tokenBarColor)
                                .frame(width: geo.size.width * min(usagePct, 1.0), height: 3)
                        }
                    }
                    .frame(height: 3)

                    Spacer().frame(width: 8)

                    Text(formatTokens(weeklyTokens))
                        .font(ExTokens.Typography.micro)
                        .foregroundColor(tokenBarColor)
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

                    // Detailed usage bar
                    if weeklyTokens > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(ExTokens.Colors.borderDefault)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(tokenBarColor)
                                    .frame(width: geo.size.width * min(usagePct, 1.0), height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(formatTokens(weeklyTokens)) tokens")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(ExTokens.Colors.textTertiary)
                            Spacer()
                            Text("\(Int(usagePct * 100))%")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(tokenBarColor)
                        }
                    }

                    // Sessions & AIOS badge + update
                    HStack(spacing: 12) {
                        Label("\(project.totalSessions)", systemImage: "terminal.fill")
                            .font(.system(size: 8))
                            .foregroundColor(ExTokens.Colors.textTertiary)
                        if project.isAIOSProject {
                            Button {
                                runAIOSUpdate()
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "cpu")
                                        .font(.system(size: 7))
                                    Text("AIOS")
                                        .font(.system(size: 8, weight: .bold))

                                    if isUpdatingAIOS {
                                        ProgressView()
                                            .controlSize(.mini)
                                            .scaleEffect(0.5)
                                    } else if let result = aiosUpdateResult {
                                        Image(systemName: result ? "checkmark" : "xmark")
                                            .font(.system(size: 7, weight: .bold))
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 7))
                                    }
                                }
                                .foregroundColor(aiosButtonColor)
                            }
                            .buttonStyle(HoverableButtonStyle())
                            .disabled(isUpdatingAIOS)
                            .help("Update AIOS (npx aios-core@latest install)")
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
        .frame(width: 180, height: isExpanded ? 220 : 130)
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

    // MARK: - Computed

    private var usagePct: CGFloat {
        CGFloat(weeklyTokens) / 10_000_000.0
    }

    private var tokenBarColor: Color {
        if usagePct >= 0.8 {
            return ExTokens.Colors.statusCritical
        } else if usagePct >= 0.5 {
            return ExTokens.Colors.statusWarning
        } else {
            return ExTokens.Colors.accentPrimary
        }
    }

    private var aiosButtonColor: Color {
        if let result = aiosUpdateResult {
            return result ? ExTokens.Colors.statusSuccess : ExTokens.Colors.statusCritical
        }
        return ExTokens.Colors.accentPrimary
    }

    private func runAIOSUpdate() {
        isUpdatingAIOS = true
        aiosUpdateResult = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["npx", "aios-core@latest", "install"]
            process.currentDirectoryURL = URL(fileURLWithPath: project.path)
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            var success = false
            do {
                try process.run()
                process.waitUntilExit()
                success = process.terminationStatus == 0
            } catch {
                print("[AIOS] update failed for \(project.name): \(error)")
            }

            DispatchQueue.main.async {
                isUpdatingAIOS = false
                aiosUpdateResult = success
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    aiosUpdateResult = nil
                }
            }
        }
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
