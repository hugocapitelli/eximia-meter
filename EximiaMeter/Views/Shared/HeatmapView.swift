import SwiftUI

struct HeatmapView: View {
    let hourCounts: [String: Int]

    private let hours = Array(0..<24)
    private let hourLabels = ["0", "3", "6", "9", "12", "15", "18", "21"]

    private var maxCount: Int {
        hourCounts.values.max() ?? 1
    }

    var body: some View {
        VStack(spacing: 4) {
            // Hour blocks grid (single row of 24 blocks)
            HStack(spacing: 1) {
                ForEach(hours, id: \.self) { hour in
                    let key = String(format: "%02d", hour)
                    let count = hourCounts[key] ?? hourCounts["\(hour)"] ?? 0
                    let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(cellColor(intensity: intensity))
                        .frame(height: 12)
                        .help("\(key):00 — \(count) sessões")
                }
            }

            // Hour labels
            HStack(spacing: 0) {
                ForEach(hourLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func cellColor(intensity: Double) -> Color {
        if intensity == 0 {
            return ExTokens.Colors.borderDefault
        } else if intensity < 0.25 {
            return ExTokens.Colors.accentPrimary.opacity(0.2)
        } else if intensity < 0.5 {
            return ExTokens.Colors.accentPrimary.opacity(0.4)
        } else if intensity < 0.75 {
            return ExTokens.Colors.accentPrimary.opacity(0.7)
        } else {
            return ExTokens.Colors.accentPrimary
        }
    }
}
