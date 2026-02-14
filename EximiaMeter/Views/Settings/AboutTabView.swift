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
                            .buttonStyle(HoverableButtonStyle())
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
                            .buttonStyle(HoverableButtonStyle())
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
                    .buttonStyle(HoverableButtonStyle())

                    if showChangelog {
                        VStack(alignment: .leading, spacing: ExTokens.Spacing._8) {
                            changelogEntry("v1.6.0", items: [
                                "Update banner on home page when new version is available",
                                "Projects: eye toggle hides/shows on main page (with animation)",
                                "Projects: full path displayed, deleted projects auto-pruned",
                                "Reconnect button in Account tab when API disconnected",
                                "Token expired auto-refreshes from Keychain on each popover open",
                                "Check for Updates works inside .app (URLSession, no git needed)",
                                "Auto-update now code-signs the bundle (notifications preserved)",
                                "Force dark mode on all views (light mode Mac compatibility)"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.5.3", items: [
                                "Fix: macOS notifications now appear in preview (Settings → Alerts → Test)",
                                "Fix: notification permission requested on app start (not conditional)",
                                "Fix: UNUserNotificationCenter delegate set immediately on init"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.5.2", items: [
                                "macOS system notifications (Notification Center banners)",
                                "Notifications appear even when app is in foreground",
                                "Independent toggles: macOS notifications, in-app popup, sound",
                                "Test Notifications: preview fires both system + in-app alerts"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.5.1", items: [
                                "All 14 macOS system sounds available (Basso, Blow, Bottle, Frog, etc.)",
                                "Popup Preview: test warning/critical banners from Settings"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.5.0", items: [
                                "Notifications: sound toggle, in-app popup toggle, sound picker with preview",
                                "Notifications: 5-min cooldown, smart reset when usage drops below threshold",
                                "In-app alert banner at top of popover (auto-dismiss 8s)",
                                "Settings: hoverable cards with border highlight across all tabs",
                                "Alerts: redesigned with notification controls card and sound picker",
                                "Account: connection status pill badge, decorative plan icons",
                                "General: terminal descriptions under each option",
                                "Projects: inline token progress bar with color coding",
                                "Per-project section: total tokens pill badge",
                                "Usage meters: session now shows above weekly"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.4.1", items: [
                                "Fix: app now truly reopens after update (nohup detach)"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.4.0", items: [
                                "UX: hover & press feedback on all buttons",
                                "UX: increased hit targets (Apple HIG 44pt min)",
                                "UX: sidebar hover states in Settings",
                                "Fix: consistent chevron icons on expand/collapse",
                                "Fix: dropdown chevron position (text first)"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.3.0", items: [
                                "Model Distribution: Sonnet now appears via fuzzy matching",
                                "Per-Project: percentages show share of total usage",
                                "Per-Project: bar width relative to top project",
                                "Numbers: 1920M tokens now shows as 1.92B"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.2.1", items: [
                                "Fix: app now auto-reopens after updating"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.2.0", items: [
                                "Improved header: prominent Settings button, plan badge",
                                "Refresh integrated into footer timestamp",
                                "About: real ExLogoIcon, 2-step update flow, changelog",
                                "macOS 26 SDK compatibility fixes"
                            ])

                            Rectangle()
                                .fill(ExTokens.Colors.borderDefault)
                                .frame(height: 1)

                            changelogEntry("v1.1.0", items: [
                                "Sidebar navigation settings redesign",
                                "Account tab with API auto-detection",
                                "Merged Alerts tab (thresholds + notifications)",
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
                        .padding(.vertical, 8)
                        .background(ExTokens.Colors.accentPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    }
                    .buttonStyle(HoverableButtonStyle())

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
                        .padding(.vertical, 8)
                        .background(ExTokens.Colors.destructiveBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.destructive.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                    }
                    .buttonStyle(HoverableButtonStyle())
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

        // Use GitHub API (no git clone needed — faster and works without git in PATH)
        let url = URL(string: "https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/Info.plist")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isChecking = false

                guard let data,
                      let content = String(data: data, encoding: .utf8),
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("[Updates] fetch failed: \(error?.localizedDescription ?? "unknown")")
                    updateAvailable = false
                    return
                }

                // Parse version from plist XML
                if let range = content.range(of: "<key>CFBundleShortVersionString</key>"),
                   let stringStart = content.range(of: "<string>", range: range.upperBound..<content.endIndex),
                   let stringEnd = content.range(of: "</string>", range: stringStart.upperBound..<content.endIndex) {
                    let version = String(content[stringStart.upperBound..<stringEnd.lowerBound])
                    remoteVersion = version
                    updateAvailable = !version.isEmpty && version != appVersion
                    print("[Updates] remote: \(version), local: \(appVersion), available: \(updateAvailable ?? false)")
                } else {
                    updateAvailable = false
                }
            }
        }.resume()
    }

    // MARK: - Perform update

    private func performUpdate() {
        isUpdating = true

        // Write a standalone updater script to /tmp that survives app termination
        let appPath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/bash
        set -e

        # Wait for the current app to quit
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

        // Use launchctl to spawn a truly independent process that survives app death
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = ["-c", "nohup /bin/bash \(scriptPath) > /tmp/eximia-update.log 2>&1 &"]
        launcher.standardOutput = FileHandle.nullDevice
        launcher.standardError = FileHandle.nullDevice

        do {
            try launcher.run()
            launcher.waitUntilExit()
            // Quit the app — the nohup'd script will wait for us to die, then update and relaunch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(self)
            }
        } catch {
            isUpdating = false
            let alert = NSAlert()
            alert.messageText = "Update Failed"
            alert.informativeText = "Could not start the updater. Try reinstalling manually."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
