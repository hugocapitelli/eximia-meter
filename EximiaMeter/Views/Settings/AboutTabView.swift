import SwiftUI

struct AboutTabView: View {
    @State private var isChecking = false
    @State private var isUpdating = false
    @State private var updateAvailable: Bool? = nil // nil = not checked, true/false = result
    @State private var remoteVersion: String? = nil
    @State private var showChangelog = false

    var body: some View {
        ScrollView {
            VStack(spacing: ExTokens.Spacing._24) {
                // App identity
                VStack(spacing: ExTokens.Spacing._12) {
                    ExLogoIcon(size: 48)

                    VStack(spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 5) {
                            Text("exímIA")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(ExTokens.Colors.textPrimary)

                            Text("Meter")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ExTokens.Colors.accentPrimary)
                        }

                        Text("v\(appVersion) (build \(buildNumber))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ExTokens.Colors.textTertiary)
                    }

                    Text("macOS menu bar app for monitoring\nClaude Code usage in real-time")
                        .font(.system(size: 11))
                        .foregroundColor(ExTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(copyright)
                        .font(.system(size: 10))
                        .foregroundColor(ExTokens.Colors.textMuted)
                }
                .padding(.top, ExTokens.Spacing._16)

                // Version & Updates card
                VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ExTokens.Colors.accentPrimary)

                        Text("Updates")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ExTokens.Colors.textPrimary)

                        Spacer()

                        versionBadge
                    }

                    // Status row
                    if let available = updateAvailable {
                        HStack(spacing: 8) {
                            Image(systemName: available ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(available ? ExTokens.Colors.accentPrimary : ExTokens.Colors.statusSuccess)

                            if available {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("New version available: v\(remoteVersion ?? "?")")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(ExTokens.Colors.textPrimary)

                                    Text("Current: v\(appVersion)")
                                        .font(.system(size: 9))
                                        .foregroundColor(ExTokens.Colors.textMuted)
                                }
                            } else {
                                Text("You're on the latest version")
                                    .font(.system(size: 11))
                                    .foregroundColor(ExTokens.Colors.statusSuccess)
                            }

                            Spacer()
                        }
                    }

                    // Action buttons
                    HStack(spacing: 8) {
                        if updateAvailable == true {
                            // Update button
                            Button {
                                performUpdate()
                            } label: {
                                HStack(spacing: 4) {
                                    if isUpdating {
                                        ProgressView()
                                            .controlSize(.small)
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 10))
                                    }
                                    Text(isUpdating ? "Updating..." : "Update Now")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(ExTokens.Colors.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                            }
                            .buttonStyle(.plain)
                            .disabled(isUpdating)
                        } else {
                            // Check button
                            Button {
                                checkForUpdates()
                            } label: {
                                HStack(spacing: 4) {
                                    if isChecking {
                                        ProgressView()
                                            .controlSize(.small)
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 10))
                                    }
                                    Text(isChecking ? "Checking..." : "Check for Updates")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(ExTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(ExTokens.Colors.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                        .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                            }
                            .buttonStyle(.plain)
                            .disabled(isChecking)
                        }
                    }
                }
                .padding(ExTokens.Spacing._16)
                .background(ExTokens.Colors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                        .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))

                // Changelog card
                VStack(alignment: .leading, spacing: ExTokens.Spacing._12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showChangelog.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ExTokens.Colors.accentPrimary)

                            Text("What's New")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ExTokens.Colors.textPrimary)

                            Spacer()

                            Image(systemName: showChangelog ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ExTokens.Colors.textMuted)
                        }
                    }
                    .buttonStyle(.plain)

                    if showChangelog {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._8) {
                            changelogEntry("v1.1.0", items: [
                                "Sidebar navigation settings redesign",
                                "Account tab with API auto-detection",
                                "Merged Alerts tab (thresholds + notifications)",
                                "About tab with update checker & changelog",
                                "Onboarding: add/remove project folders"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.0.0", items: [
                                "Initial release",
                                "Real-time token usage monitoring",
                                "Per-project tracking with model breakdown",
                                "Menu bar app with popover dashboard"
                            ])
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(ExTokens.Spacing._16)
                .background(ExTokens.Colors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: ExTokens.Radius.lg)
                        .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.lg))

                // Links
                HStack(spacing: ExTokens.Spacing._8) {
                    Button {
                        if let url = URL(string: "https://github.com/hugocapitelli/eximia-meter") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text("GitHub")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(ExTokens.Colors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    }
                    .buttonStyle(.plain)

                    Button {
                        AppDelegate.shared?.uninstallApp()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Uninstall")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(ExTokens.Colors.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(ExTokens.Colors.destructiveBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.destructive.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(ExTokens.Spacing._24)
        }
    }

    // MARK: - Version badge

    private var versionBadge: some View {
        Text("v\(appVersion)")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(ExTokens.Colors.accentPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(ExTokens.Colors.accentPrimary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
    }

    // MARK: - Changelog entry

    private func changelogEntry(_ version: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: ExTokens.Spacing._4) {
            Text(version)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.accentPrimary)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("·")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Text(item)
                        .font(.system(size: 10))
                        .foregroundColor(ExTokens.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Info.plist values

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var copyright: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright 2026 exímIA"
    }

    // MARK: - Check for updates

    private func checkForUpdates() {
        isChecking = true
        updateAvailable = nil

        let script = """
        TMPDIR_PATH=$(mktemp -d)
        trap "rm -rf $TMPDIR_PATH" EXIT
        git clone --depth 1 https://github.com/hugocapitelli/eximia-meter.git "$TMPDIR_PATH/repo" 2>/dev/null
        /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$TMPDIR_PATH/repo/Info.plist" 2>/dev/null
        """

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        process.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let version = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            DispatchQueue.main.async {
                isChecking = false
                remoteVersion = version
                updateAvailable = !version.isEmpty && version != appVersion
            }
        }

        try? process.run()
    }

    // MARK: - Perform update

    private func performUpdate() {
        isUpdating = true

        let appPath = Bundle.main.bundlePath
        let script = """
        set -e
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
        rm -rf "\(appPath)"
        cp -R "$APP_BUNDLE" "/Applications/"
        sleep 0.5
        open "/Applications/exímIA Meter.app"
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]

        process.terminationHandler = { proc in
            DispatchQueue.main.async {
                if proc.terminationStatus == 0 {
                    // Give the new app time to launch before quitting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NSApp.terminate(self)
                    }
                } else {
                    isUpdating = false
                    let alert = NSAlert()
                    alert.messageText = "Update Failed"
                    alert.informativeText = "Could not update exímIA Meter. Check your internet connection and try again."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }

        try? process.run()
    }
}
