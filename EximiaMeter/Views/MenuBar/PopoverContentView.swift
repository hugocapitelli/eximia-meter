import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var alertBanner: AlertBannerData?
    @State private var autoDismissTask: DispatchWorkItem?

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
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.willShowNotification)) { _ in
            appViewModel.projectsViewModel.refreshAIOSStatus()
            AnthropicUsageService.shared.refreshCredentials()
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationService.alertTriggeredNotification)) { notification in
            guard let userInfo = notification.userInfo,
                  let type = userInfo["type"] as? String,
                  let severity = userInfo["severity"] as? String,
                  let message = userInfo["message"] as? String else { return }

            showBanner(AlertBannerData(type: type, severity: severity, message: message))
        }
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
