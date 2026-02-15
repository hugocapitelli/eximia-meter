import Foundation

struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var selectedModel: ClaudeModel
    var optimizationLevel: OptimizationLevel
    var sortOrder: Int
    var isAIOSProject: Bool
    var lastOpened: Date?
    var totalSessions: Int
    var colorHex: String
    var showOnMainPage: Bool
    var weeklyTokenBudget: Int?
    var group: String?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        selectedModel: ClaudeModel = .opus,
        optimizationLevel: OptimizationLevel = .med,
        sortOrder: Int = 0,
        isAIOSProject: Bool = false,
        lastOpened: Date? = nil,
        totalSessions: Int = 0,
        colorHex: String = "#F59E0B",
        showOnMainPage: Bool = true,
        weeklyTokenBudget: Int? = nil,
        group: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.selectedModel = selectedModel
        self.optimizationLevel = optimizationLevel
        self.sortOrder = sortOrder
        self.isAIOSProject = isAIOSProject
        self.lastOpened = lastOpened
        self.totalSessions = totalSessions
        self.colorHex = colorHex
        self.showOnMainPage = showOnMainPage
        self.weeklyTokenBudget = weeklyTokenBudget
        self.group = group
    }

    /// Encoded directory name in ~/.claude/projects/
    var claudeProjectDirName: String {
        path.replacingOccurrences(of: "/", with: "-")
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}
