import SwiftUI

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
            }
            .buttonStyle(.plain)
            .help("Click to refresh")

            Spacer()

            Button {
                NSApplication.shared.terminate(self)
            } label: {
                Text("Quit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ExTokens.Colors.statusCritical)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ExTokens.Colors.statusCritical.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ExTokens.Spacing.popoverPadding)
        .padding(.vertical, ExTokens.Spacing._6)
    }
}
