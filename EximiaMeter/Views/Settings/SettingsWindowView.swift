import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case account = "Account"
    case alerts = "Alerts"
    case projects = "Projects"
    case insights = "Insights"
    case general = "General"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .account:  return "person.circle"
        case .alerts:   return "bell.badge"
        case .projects: return "folder"
        case .insights: return "chart.bar.xaxis"
        case .general:  return "gearshape"
        case .about:    return "info.circle"
        }
    }
}

struct SettingsWindowView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedSection: SettingsSection = .account

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: ExTokens.Spacing._4) {
                ForEach(SettingsSection.allCases) { section in
                    sidebarItem(section)
                }
                Spacer()
            }
            .padding(.vertical, ExTokens.Spacing._16)
            .padding(.horizontal, ExTokens.Spacing._8)
            .frame(width: 180)
            .background(ExTokens.Colors.backgroundDeep)

            // Divider
            Rectangle()
                .fill(ExTokens.Colors.borderDefault)
                .frame(width: 1)

            // Content
            Group {
                switch selectedSection {
                case .account:  AccountTabView()
                case .alerts:   AlertsTabView()
                case .projects: ProjectsTabView()
                case .insights: InsightsTabView()
                case .general:  GeneralTabView()
                case .about:    AboutTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 680, height: 520)
        .background(ExTokens.Colors.backgroundPrimary)
    }

    private func sidebarItem(_ section: SettingsSection) -> some View {
        SidebarItemButton(
            section: section,
            isSelected: selectedSection == section,
            onSelect: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedSection = section
                }
            }
        )
    }
}

private struct SidebarItemButton: View {
    let section: SettingsSection
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ExTokens.Spacing._8) {
                // Accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? ExTokens.Colors.accentPrimary : Color.clear)
                    .frame(width: 3, height: 20)

                Image(systemName: section.icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? ExTokens.Colors.accentPrimary : isHovered ? ExTokens.Colors.textSecondary : ExTokens.Colors.textMuted)
                    .frame(width: 20)

                Text(section.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? ExTokens.Colors.textPrimary : isHovered ? ExTokens.Colors.textSecondary : ExTokens.Colors.textTertiary)

                Spacer()
            }
            .padding(.vertical, ExTokens.Spacing._6)
            .padding(.horizontal, ExTokens.Spacing._4)
            .background(
                isSelected
                    ? ExTokens.Colors.backgroundCard
                    : isHovered ? ExTokens.Colors.backgroundCard.opacity(0.5) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
