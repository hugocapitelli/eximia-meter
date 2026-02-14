import SwiftUI

// MARK: - Step 1: Welcome

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: ExTokens.Spacing._24) {
            Spacer()

            ExLogoIcon(size: 64)

            VStack(spacing: ExTokens.Spacing._8) {
                Text("exímIA Meter")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text("Monitor your Claude Code usage in real-time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ExTokens.Colors.accentPrimary)
            }

            Text("Track token consumption, monitor per-project usage, and get notified before hitting your limits — all from your menu bar.")
                .font(ExTokens.Typography.settingsBody)
                .foregroundColor(ExTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, ExTokens.Spacing._32)

            Spacer()
        }
    }
}

// MARK: - Step 2: Select Plan

struct OnboardingPlanStep: View {
    @Bindable var settings: SettingsViewModel

    var body: some View {
        VStack(spacing: ExTokens.Spacing._24) {
            VStack(spacing: ExTokens.Spacing._6) {
                Text("Select Your Plan")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text("Choose your Claude subscription to calibrate usage limits")
                    .font(ExTokens.Typography.settingsBody)
                    .foregroundColor(ExTokens.Colors.textSecondary)
            }

            VStack(spacing: ExTokens.Spacing._12) {
                ForEach(ClaudePlan.allCases) { plan in
                    planCard(plan)
                }
            }
            .padding(.horizontal, ExTokens.Spacing._8)
        }
    }

    private func planCard(_ plan: ClaudePlan) -> some View {
        let isSelected = settings.claudePlan == plan

        return Button {
            settings.claudePlan = plan
        } label: {
            HStack(spacing: ExTokens.Spacing._12) {
                VStack(alignment: .leading, spacing: ExTokens.Spacing._4) {
                    Text(plan.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textPrimary)

                    Text(plan.description)
                        .font(.system(size: 11))
                        .foregroundColor(ExTokens.Colors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: ExTokens.Spacing._2) {
                    Text(formatTokens(plan.weeklyTokenLimit) + "/week")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textSecondary)

                    Text(formatTokens(plan.sessionTokenLimit) + "/session")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)
            }
            .padding(ExTokens.Spacing._16)
            .background(ExTokens.Colors.backgroundCard)
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                    .stroke(
                        isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.borderDefault,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000_000 {
            return String(format: "%.1fB", Double(tokens) / 1_000_000_000)
        } else if tokens >= 1_000_000 {
            return String(format: "%.0fM", Double(tokens) / 1_000_000)
        } else {
            return "\(tokens)"
        }
    }
}

// MARK: - Step 3: Features Tour

struct OnboardingFeaturesStep: View {
    var body: some View {
        VStack(spacing: ExTokens.Spacing._24) {
            VStack(spacing: ExTokens.Spacing._6) {
                Text("What You Get")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text("Everything you need to stay in control")
                    .font(ExTokens.Typography.settingsBody)
                    .foregroundColor(ExTokens.Colors.textSecondary)
            }

            VStack(spacing: ExTokens.Spacing._12) {
                featureCard(
                    icon: "gauge.medium",
                    title: "Weekly & Session Meters",
                    description: "Real-time progress bars showing token consumption against your plan limits"
                )

                featureCard(
                    icon: "folder.fill",
                    title: "Per-Project Breakdown",
                    description: "See which projects consume the most tokens with detailed breakdowns"
                )

                featureCard(
                    icon: "chart.pie.fill",
                    title: "Model Distribution",
                    description: "Track usage across Opus, Sonnet, and Haiku models"
                )

                featureCard(
                    icon: "bell.badge.fill",
                    title: "Smart Notifications",
                    description: "Get alerted before hitting warning and critical thresholds"
                )
            }
            .padding(.horizontal, ExTokens.Spacing._8)
        }
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: ExTokens.Spacing._12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(ExTokens.Colors.accentPrimary)
                .frame(width: 36, height: 36)
                .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))

            VStack(alignment: .leading, spacing: ExTokens.Spacing._2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(ExTokens.Colors.textTertiary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(ExTokens.Spacing._12)
        .background(ExTokens.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))
    }
}

// MARK: - Step 4: Select Projects

struct OnboardingProjectsStep: View {
    let projectsViewModel: ProjectsViewModel
    @Binding var selectedProjectNames: Set<String>
    @State private var available: [Project] = []

    var body: some View {
        VStack(spacing: ExTokens.Spacing._24) {
            VStack(spacing: ExTokens.Spacing._6) {
                Text("Select Your Projects")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text("Choose which projects to monitor")
                    .font(ExTokens.Typography.settingsBody)
                    .foregroundColor(ExTokens.Colors.textSecondary)
            }

            if available.isEmpty {
                VStack(spacing: ExTokens.Spacing._12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Text("No projects found in ~/.claude/projects/")
                        .font(.system(size: 12))
                        .foregroundColor(ExTokens.Colors.textTertiary)

                    Text("Add a project folder manually")
                        .font(.system(size: 11))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Button {
                        addProjectFolder()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                            Text("Add Folder")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(ExTokens.Colors.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: ExTokens.Spacing._6) {
                        ForEach(available) { project in
                            projectRow(project)
                        }
                    }
                }

                HStack {
                    Text("\(selectedProjectNames.count) of \(available.count) selected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ExTokens.Colors.textTertiary)

                    Spacer()

                    Button {
                        addProjectFolder()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 9))
                            Text("Add Folder")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(ExTokens.Colors.accentPrimary)
                    }
                    .buttonStyle(.plain)

                    Text("·")
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Button {
                        if selectedProjectNames.count == available.count {
                            selectedProjectNames.removeAll()
                        } else {
                            selectedProjectNames = Set(available.map(\.name))
                        }
                    } label: {
                        Text(selectedProjectNames.count == available.count ? "Deselect All" : "Select All")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ExTokens.Colors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            available = ProjectDiscoveryService.discoverProjects()
            if selectedProjectNames.isEmpty {
                // Pre-select all by default
                selectedProjectNames = Set(available.map(\.name))
            }
        }
    }

    private func removeProject(_ project: Project) {
        selectedProjectNames.remove(project.name)
        available.removeAll { $0.id == project.id }
    }

    private func addProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project directory"

        if panel.runModal() == .OK, let url = panel.url {
            let name = url.lastPathComponent
            let path = url.path
            let project = Project(name: name, path: path)
            if !available.contains(where: { $0.path == path }) {
                available.append(project)
                selectedProjectNames.insert(name)
            }
        }
    }

    private func projectRow(_ project: Project) -> some View {
        let isSelected = selectedProjectNames.contains(project.name)

        return Button {
            if isSelected {
                selectedProjectNames.remove(project.name)
            } else {
                selectedProjectNames.insert(project.name)
            }
        } label: {
            HStack(spacing: ExTokens.Spacing._12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)

                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#3B82F6"))

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ExTokens.Colors.textPrimary)

                    Text(project.path)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                if project.totalSessions > 0 {
                    Text("\(project.totalSessions) sessions")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textTertiary)
                }

                Button {
                    removeProject(project)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ExTokens.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Remove project")
            }
            .padding(.horizontal, ExTokens.Spacing._12)
            .padding(.vertical, ExTokens.Spacing._8)
            .background(isSelected ? ExTokens.Colors.backgroundCard : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                    .stroke(
                        isSelected ? ExTokens.Colors.accentPrimary.opacity(0.3) : ExTokens.Colors.borderDefault,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 5: Done

struct OnboardingDoneStep: View {
    let selectedPlan: ClaudePlan
    let projectCount: Int

    var body: some View {
        VStack(spacing: ExTokens.Spacing._24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ExTokens.Colors.statusSuccess.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ExTokens.Colors.statusSuccess)
            }

            VStack(spacing: ExTokens.Spacing._8) {
                Text("You're All Set!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text("exímIA Meter is ready to monitor your usage")
                    .font(ExTokens.Typography.settingsBody)
                    .foregroundColor(ExTokens.Colors.textSecondary)
            }

            // Summary
            VStack(spacing: ExTokens.Spacing._8) {
                summaryRow(label: "Plan", value: selectedPlan.displayName)
                summaryRow(label: "Weekly Limit", value: formatTokens(selectedPlan.weeklyTokenLimit))
                summaryRow(label: "Session Limit", value: formatTokens(selectedPlan.sessionTokenLimit))
                summaryRow(label: "Projects", value: "\(projectCount)")
            }
            .padding(ExTokens.Spacing._16)
            .background(ExTokens.Colors.backgroundCard)
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                    .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))
            .padding(.horizontal, ExTokens.Spacing._32)

            Spacer()
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(ExTokens.Colors.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textPrimary)
        }
    }

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000_000 {
            return String(format: "%.1fB tokens", Double(tokens) / 1_000_000_000)
        } else if tokens >= 1_000_000 {
            return String(format: "%.0fM tokens", Double(tokens) / 1_000_000)
        } else {
            return "\(tokens) tokens"
        }
    }
}
