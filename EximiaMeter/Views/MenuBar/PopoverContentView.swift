import SwiftUI

// MARK: - Popover Tab

enum PopoverTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case projects = "Projects"
    case insights = "Insights"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .projects:  return "folder.fill"
        case .insights:  return "chart.bar.fill"
        }
    }
}

struct PopoverContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var alertBanner: AlertBannerData?
    @State private var autoDismissTask: DispatchWorkItem?
    @State private var updateAvailable = false
    @State private var remoteVersion: String?
    @State private var showUpdateConfirmation = false
    @State private var isUpdating = false
    @State private var selectedTab: PopoverTab = .dashboard

    private var popoverSize: PopoverSize {
        appViewModel.settingsViewModel.popoverSize
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            // Subtle amber gradient separator
            LinearGradient(
                colors: [.clear, ExTokens.Colors.accentPrimary.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            // ─── Topbar Navigation ───────────────────────
            topBar

            // Update banner
            if updateAvailable {
                Button {
                    showUpdateConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isUpdating ? "arrow.triangle.2.circlepath" : "arrow.down.circle.fill")
                            .font(.system(size: 10))
                        Text(isUpdating ? "Atualizando..." : "v\(remoteVersion ?? "?") disponível")
                            .font(.system(size: 10, weight: .semibold))
                        Spacer()
                        if !isUpdating {
                            Text("Atualizar")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(ExTokens.Colors.accentPrimary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
                        } else {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        }
                    }
                    .foregroundColor(ExTokens.Colors.accentPrimary)
                    .padding(.horizontal, ExTokens.Spacing.popoverPadding)
                    .padding(.vertical, 6)
                    .background(ExTokens.Colors.accentPrimary.opacity(0.08))
                }
                .buttonStyle(.plain)
                .disabled(isUpdating)
                .alert("Atualizar exímIA Meter?", isPresented: $showUpdateConfirmation) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Atualizar") {
                        performUpdate()
                    }
                } message: {
                    Text("Será baixada e instalada a versão v\(remoteVersion ?? "?"). O app reiniciará automaticamente.")
                }
            }

            // Alert banner overlay
            if let banner = alertBanner {
                AlertBannerView(data: banner) {
                    dismissBanner()
                }
            }

            // ─── Tab Content ─────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                switch selectedTab {
                case .dashboard:
                    dashboardContent
                case .projects:
                    projectsContent
                case .insights:
                    insightsContent
                }
            }

            Rectangle()
                .fill(ExTokens.Colors.borderDefault)
                .frame(height: 1)

            FooterView()
        }
        .frame(width: popoverSize.dimensions.width, height: popoverSize.dimensions.height)
        .background(ExTokens.Colors.backgroundPrimary)
        .animation(.easeInOut(duration: 0.3), value: alertBanner)
        .animation(.easeInOut(duration: 0.2), value: updateAvailable)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.willShowNotification)) { _ in
            appViewModel.projectsViewModel.refreshAIOSStatus()
            AnthropicUsageService.shared.refreshCredentials()
            checkForUpdates()
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationService.alertTriggeredNotification)) { notification in
            guard let userInfo = notification.userInfo,
                  let type = userInfo["type"] as? String,
                  let severity = userInfo["severity"] as? String,
                  let message = userInfo["message"] as? String else { return }

            showBanner(AlertBannerData(type: type, severity: severity, message: message))
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 2) {
            ForEach(PopoverTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 9))
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(
                        selectedTab == tab
                            ? ExTokens.Colors.accentPrimary
                            : ExTokens.Colors.textMuted
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        selectedTab == tab
                            ? ExTokens.Colors.accentPrimary.opacity(0.1)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    .contentShape(Rectangle())
                }
                .buttonStyle(HoverableButtonStyle())
            }
        }
        .padding(.horizontal, ExTokens.Spacing._8)
        .padding(.vertical, ExTokens.Spacing._4)
        .background(ExTokens.Colors.backgroundDeep)
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        VStack(spacing: ExTokens.Spacing._12) {
            UsageMetersSection()
                .padding(.top, ExTokens.Spacing._8)

            ProjectCarouselView()

            // History only on normal+ sizes
            if popoverSize != .compact {
                HistorySection()
            }
        }
        .padding(.bottom, ExTokens.Spacing._12)
    }

    // MARK: - Projects Content

    private var projectsContent: some View {
        VStack(spacing: ExTokens.Spacing._4) {
            let grouped = appViewModel.projectsViewModel.groupedProjects()

            ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                let (groupName, groupProjects) = group

                VStack(alignment: .leading, spacing: ExTokens.Spacing._4) {
                    // Group header
                    HStack(spacing: 6) {
                        Image(systemName: groupName.isEmpty ? "tray.fill" : "folder.fill")
                            .font(.system(size: 9))
                        Text(groupName.isEmpty ? "Sem grupo" : groupName)
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()

                        Text("\(groupProjects.count)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(ExTokens.Colors.accentPrimary)
                    }
                    .foregroundColor(ExTokens.Colors.textMuted)
                    .padding(.horizontal, ExTokens.Spacing.popoverPadding)
                    .padding(.top, ExTokens.Spacing._8)

                    // Project rows
                    ForEach(groupProjects) { project in
                        popoverProjectRow(project)
                    }
                }
            }

            // Per-project usage
            if !appViewModel.usageViewModel.perProjectTokens.isEmpty && popoverSize != .compact {
                Rectangle()
                    .fill(ExTokens.Colors.borderDefault)
                    .frame(height: 1)
                    .padding(.horizontal, ExTokens.Spacing.popoverPadding)
                    .padding(.top, ExTokens.Spacing._8)

                ProjectUsageSection(
                    perProjectTokens: appViewModel.usageViewModel.perProjectTokens,
                    weeklyLimit: appViewModel.settingsViewModel.weeklyTokenLimit,
                    projects: appViewModel.projectsViewModel.projects
                )
                .padding(.horizontal, ExTokens.Spacing.popoverPadding)
            }
        }
        .padding(.bottom, ExTokens.Spacing._12)
    }

    private func popoverProjectRow(_ project: Project) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: project.colorHex))
                .frame(width: 8, height: 8)

            Text(project.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ExTokens.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Token usage
            let tokens = appViewModel.usageViewModel.perProjectTokens[project.path] ?? 0
            if tokens > 0 {
                Text(popoverFormatTokens(tokens))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(ExTokens.Colors.textTertiary)
            }

            // Model badge
            Text(project.selectedModel.shortName)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(ExTokens.Colors.accentPrimary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 3))

            // Launch button
            Button {
                TerminalLauncherService.launch(
                    project: project,
                    terminal: appViewModel.settingsViewModel.preferredTerminal
                )
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.black)
                    .frame(width: 22, height: 22)
                    .background(ExTokens.Colors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
            }
            .buttonStyle(HoverableButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ExTokens.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
        .padding(.horizontal, ExTokens.Spacing._8)
    }

    private func popoverFormatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.0fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: ExTokens.Spacing._12) {
            InsightsSection()
                .padding(.top, ExTokens.Spacing._4)

            // Model Distribution (moved from dashboard for insights focus)
            if !sortedModelUsage.isEmpty {
                VStack(alignment: .leading, spacing: ExTokens.Spacing._8) {
                    Text("MODEL DISTRIBUTION (7D)")
                        .font(ExTokens.Typography.label)
                        .tracking(1.5)
                        .foregroundColor(ExTokens.Colors.textMuted)

                    ModelDistributionBar(models: sortedModelUsage)
                }
                .padding(.horizontal, ExTokens.Spacing.popoverPadding)
            }

            // Weekly Projection
            if !appViewModel.usageViewModel.weeklyProjection.isEmpty {
                VStack(alignment: .leading, spacing: ExTokens.Spacing._6) {
                    Text("PROJEÇÃO SEMANAL")
                        .font(ExTokens.Typography.label)
                        .tracking(1.5)
                        .foregroundColor(ExTokens.Colors.textMuted)

                    HStack(spacing: 6) {
                        Image(systemName: appViewModel.usageViewModel.projectionIsWarning ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .font(.system(size: 11))

                        Text(appViewModel.usageViewModel.weeklyProjection)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(
                        appViewModel.usageViewModel.projectionIsWarning
                            ? ExTokens.Colors.statusWarning
                            : ExTokens.Colors.statusSuccess
                    )
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        (appViewModel.usageViewModel.projectionIsWarning
                            ? ExTokens.Colors.statusWarning
                            : ExTokens.Colors.statusSuccess
                        ).opacity(0.08)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                            .stroke(
                                (appViewModel.usageViewModel.projectionIsWarning
                                    ? ExTokens.Colors.statusWarning
                                    : ExTokens.Colors.statusSuccess
                                ).opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
                .padding(.horizontal, ExTokens.Spacing.popoverPadding)
            }

            // Burn Rate
            if appViewModel.usageViewModel.burnRatePerHour > 0 {
                VStack(alignment: .leading, spacing: ExTokens.Spacing._6) {
                    Text("BURN RATE")
                        .font(ExTokens.Typography.label)
                        .tracking(1.5)
                        .foregroundColor(ExTokens.Colors.textMuted)

                    HStack(spacing: 12) {
                        burnRateStat(label: "POR HORA", value: String(format: "%.2f%%", appViewModel.usageViewModel.burnRatePerHour * 100))
                        burnRateStat(label: "POR DIA", value: String(format: "%.1f%%", appViewModel.usageViewModel.burnRatePerHour * 24 * 100))
                    }
                }
                .padding(.horizontal, ExTokens.Spacing.popoverPadding)
            }
        }
        .padding(.bottom, ExTokens.Spacing._12)
    }

    private func burnRateStat(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textPrimary)
            Text(label)
                .font(.system(size: 7, weight: .medium))
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

    private var sortedModelUsage: [(String, Double)] {
        appViewModel.usageViewModel.perModelUsage
            .sorted { $0.value > $1.value }
            .filter { $0.value > 0.001 }
    }

    // MARK: - Perform Update

    private func performUpdate() {
        isUpdating = true

        let appPath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/bash
        set -e
        while kill -0 \(pid) 2>/dev/null; do sleep 0.3; done
        REPO_URL="https://github.com/hugocapitelli/eximia-meter.git"
        TMPDIR_PATH=$(mktemp -d)
        SRC_DIR="$TMPDIR_PATH/eximia-meter"
        trap "rm -rf $TMPDIR_PATH" EXIT
        git clone --depth 1 "$REPO_URL" "$SRC_DIR" 2>/dev/null
        cd "$SRC_DIR" && swift build -c release 2>/dev/null
        BINARY="$SRC_DIR/.build/release/EximiaMeter"
        APP_BUNDLE="$TMPDIR_PATH/exímIA Meter.app"
        mkdir -p "$APP_BUNDLE/Contents/MacOS"
        mkdir -p "$APP_BUNDLE/Contents/Resources"
        cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/EximiaMeter"
        chmod +x "$APP_BUNDLE/Contents/MacOS/EximiaMeter"
        cp "$SRC_DIR/Info.plist" "$APP_BUNDLE/Contents/"
        cp "$SRC_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
        echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
        codesign --force --deep --sign - "$APP_BUNDLE"
        rm -rf "\(appPath)"
        cp -R "$APP_BUNDLE" "/Applications/"
        sleep 0.5
        open "/Applications/exímIA Meter.app"
        """

        let scriptPath = "/tmp/eximia-updater.sh"
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)

        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = ["-c", "nohup /bin/bash \(scriptPath) > /tmp/eximia-update.log 2>&1 &"]
        launcher.standardOutput = FileHandle.nullDevice
        launcher.standardError = FileHandle.nullDevice

        do {
            try launcher.run()
            launcher.waitUntilExit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        } catch {
            isUpdating = false
        }
    }

    // MARK: - Update Check

    private func checkForUpdates() {
        let url = URL(string: "https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/Info.plist")!
        URLSession.shared.dataTask(with: url) { data, response, _ in
            DispatchQueue.main.async {
                guard let data,
                      let content = String(data: data, encoding: .utf8),
                      let http = response as? HTTPURLResponse,
                      http.statusCode == 200 else { return }

                if let range = content.range(of: "<key>CFBundleShortVersionString</key>"),
                   let start = content.range(of: "<string>", range: range.upperBound..<content.endIndex),
                   let end = content.range(of: "</string>", range: start.upperBound..<content.endIndex) {
                    let version = String(content[start.upperBound..<end.lowerBound])
                    let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    remoteVersion = version
                    let isNewer = !version.isEmpty && AboutTabView.isNewer(remote: version, local: local)
                    updateAvailable = isNewer

                    // Send macOS push notification for update
                    if isNewer {
                        NotificationService.shared.sendUpdateNotification(version: version)
                    }
                }
            }
        }.resume()
    }

    private func showBanner(_ data: AlertBannerData) {
        // Cancel previous auto-dismiss
        autoDismissTask?.cancel()

        alertBanner = data

        // Auto-dismiss after 8 seconds
        let task = DispatchWorkItem { [self] in
            dismissBanner()
        }
        autoDismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: task)
    }

    private func dismissBanner() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        withAnimation {
            alertBanner = nil
        }
    }
}
