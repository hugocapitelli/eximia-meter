import SwiftUI

struct ChangelogPopupView: View {
    let version: String
    let items: [String]
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: ExTokens.Spacing._8) {
                ExLogoIcon(size: 36)

                VStack(spacing: 4) {
                    Text("Atualização concluída!")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ExTokens.Colors.textPrimary)

                    Text(version)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ExTokens.Colors.accentPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.xs))
                }
            }
            .padding(.top, ExTokens.Spacing._24)
            .padding(.bottom, ExTokens.Spacing._16)

            // Divider
            Rectangle()
                .fill(ExTokens.Colors.borderDefault)
                .frame(height: 1)
                .padding(.horizontal, ExTokens.Spacing._24)

            // Changelog items
            ScrollView {
                VStack(alignment: .leading, spacing: ExTokens.Spacing._8) {
                    Text("O que mudou")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ExTokens.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(ExTokens.Colors.statusSuccess)
                                .padding(.top, 1)

                            Text(item)
                                .font(.system(size: 11))
                                .foregroundColor(ExTokens.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(ExTokens.Spacing._24)
            }

            // Footer
            Button {
                onDismiss()
            } label: {
                Text("Entendi")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(ExTokens.Colors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
            }
            .buttonStyle(HoverableButtonStyle())
            .padding(ExTokens.Spacing._16)
        }
        .frame(width: 380, height: 400)
        .background(ExTokens.Colors.backgroundPrimary)
    }
}
