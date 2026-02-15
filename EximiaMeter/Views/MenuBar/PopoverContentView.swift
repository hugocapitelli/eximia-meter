import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var alertBanner: AlertBannerData?
    @State private var autoDismissTask: DispatchWorkItem?
    @State private var updateAvailable = false
    @State private var remoteVersion: String?
    @State private var showUpdateConfirmation = false
    @State private var isUpdating = false

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

            // Update banner
            if updateAvailable {
                Button {
                    showUpdateConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isUpdating ? "arrow.triangle.2.circlepath" : "arrow.down.circle.fill")
                            .font(.system(size: 10))
                        Text(isUpdating ? "Atualizando..." : "v\(remoteVersion ?? "?") available")
                            .font(.system(size: 10, weight: .semibold))
                        Spacer()
                        if !isUpdating {
                            Text("Update")
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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: ExTokens.Spacing._12) {
                    ProjectCarouselView()
                        .padding(.top, ExTokens.Spacing._8)

                    // Subtle divider
                    Rectangle()
                        .fill(ExTokens.Colors.borderDefault)
                        .frame(height: 1)
                        .padding(.horizontal, ExTokens.Spacing.popoverPadding)

                    UsageMetersSection()

                    InsightsSection()

                    HistorySection()
                }
                .padding(.bottom, ExTokens.Spacing._12)
            }

            Rectangle()
                .fill(ExTokens.Colors.borderDefault)
                .frame(height: 1)

            FooterView()
        }
        .frame(width: 420, height: 620)
        .background(ExTokens.Colors.backgroundPrimary)
        .animation(.easeInOut(duration: 0.3), value: alertBanner)
        .animation(.easeInOut(duration: 0.2), value: updateAvailable)
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
                    updateAvailable = !version.isEmpty && AboutTabView.isNewer(remote: version, local: local)
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
