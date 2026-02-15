import SwiftUI

struct SparklineView: View {
    let data: [(String, Int)]
    var barColor: Color = ExTokens.Colors.accentPrimary

    private var maxValue: Int {
        data.map(\.1).max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                let (label, value) = item
                let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0

                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(value == 0 ? ExTokens.Colors.borderDefault : barColor.opacity(0.3 + 0.7 * height))
                        .frame(height: max(2, 28 * height))

                    Text(label)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 42)
    }
}
