import SwiftUI

struct ModelPickerView: View {
    @Binding var selectedModel: ClaudeModel
    var compact: Bool = false

    var body: some View {
        Menu {
            ForEach(ClaudeModel.allCases) { model in
                Button {
                    selectedModel = model
                } label: {
                    HStack {
                        Text(model.displayName)
                        if model == selectedModel {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(compact ? selectedModel.shortName : selectedModel.displayName)
                    .font(compact ? ExTokens.Typography.caption : ExTokens.Typography.subtitle)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7))
            }
            .foregroundColor(ExTokens.Colors.accentPrimary)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

struct OptimizationPickerView: View {
    @Binding var level: OptimizationLevel

    var body: some View {
        Menu {
            ForEach(OptimizationLevel.allCases) { opt in
                Button {
                    level = opt
                } label: {
                    HStack {
                        Text(opt.displayName)
                        if opt == level {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                Text(level.displayName)
                    .font(ExTokens.Typography.caption)
            }
            .foregroundColor(ExTokens.Colors.textTertiary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
