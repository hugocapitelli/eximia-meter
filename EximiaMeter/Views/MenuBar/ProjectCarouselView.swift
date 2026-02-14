import SwiftUI

struct ProjectCarouselView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var currentPage = 0
    @State private var isExpanded = true
    @State private var dragOffset: CGFloat = 0

    private let cardsPerPage = 2
    private let swipeThreshold: CGFloat = 50

    private var visibleProjects: [Project] {
        appViewModel.projectsViewModel.mainPageProjects()
    }

    private var totalPages: Int {
        max(1, (visibleProjects.count + cardsPerPage - 1) / cardsPerPage)
    }

    private var currentPageProjects: [Project] {
        let start = currentPage * cardsPerPage
        let end = min(start + cardsPerPage, visibleProjects.count)
        guard start < visibleProjects.count else { return [] }
        return Array(visibleProjects[start..<end])
    }

    var body: some View {
        VStack(spacing: ExTokens.Spacing._8) {
            // Section header — collapsible
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Text("Projetos")
                        .font(ExTokens.Typography.subtitle)
                        .foregroundColor(ExTokens.Colors.textPrimary)

                    Spacer()
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(HoverableButtonStyle())
            .padding(.horizontal, ExTokens.Spacing.popoverPadding)

            if isExpanded {
                // Cards with navigation arrows + trackpad gesture
                HStack(spacing: 4) {
                    // Left arrow
                    Button {
                        navigatePage(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(currentPage > 0 ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted.opacity(0.3))
                            .frame(width: 24, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HoverableButtonStyle())
                    .disabled(currentPage == 0)

                    // Project cards — with swipe gesture
                    HStack(spacing: ExTokens.Spacing._6) {
                        ForEach(currentPageProjects) { project in
                            let projectTokens = appViewModel.usageViewModel.perProjectTokens[project.path] ?? 0
                            ProjectCardView(
                                project: project,
                                weeklyTokens: projectTokens,
                                onLaunch: {
                                    TerminalLauncherService.launch(
                                        project: project,
                                        terminal: appViewModel.settingsViewModel.preferredTerminal
                                    )
                                },
                                onInstallAIOS: {
                                    TerminalLauncherService.installAIOS(
                                        project: project,
                                        terminal: appViewModel.settingsViewModel.preferredTerminal
                                    )
                                },
                                onModelChange: { model in
                                    appViewModel.projectsViewModel.updateModel(for: project, model: model)
                                },
                                onOptimizationChange: { level in
                                    appViewModel.projectsViewModel.updateOptimization(for: project, level: level)
                                }
                            )
                        }
                    }
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width * 0.5
                            }
                            .onEnded { value in
                                let horizontal = value.translation.width
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dragOffset = 0
                                    if horizontal < -swipeThreshold {
                                        navigatePage(1)
                                    } else if horizontal > swipeThreshold {
                                        navigatePage(-1)
                                    }
                                }
                            }
                    )

                    // Right arrow
                    Button {
                        navigatePage(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(currentPage < totalPages - 1 ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted.opacity(0.3))
                            .frame(width: 24, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HoverableButtonStyle())
                    .disabled(currentPage >= totalPages - 1)
                }

                // Pagination dots
                if totalPages > 1 {
                    HStack(spacing: 10) {
                        ForEach(0..<totalPages, id: \.self) { page in
                            Circle()
                                .fill(page == currentPage ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)
                                .frame(width: 7, height: 7)
                                .padding(6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentPage = page
                                    }
                                }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func navigatePage(_ direction: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPage = max(0, min(totalPages - 1, currentPage + direction))
        }
    }
}
