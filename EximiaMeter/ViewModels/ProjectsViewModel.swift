import SwiftUI
import UserNotifications

@Observable
class ProjectsViewModel {
    var projects: [Project] = []
    var pendingRenames: [PendingRename] = []

    private let store = ProjectStore()
    private let kPendingRenames = "ExProjects.pendingRenames"

    struct PendingRename: Identifiable, Codable {
        let id: UUID
        let projectId: UUID
        let oldPath: String
        let newPath: String
        let newName: String

        init(projectId: UUID, oldPath: String, newPath: String, newName: String) {
            self.id = UUID()
            self.projectId = projectId
            self.oldPath = oldPath
            self.newPath = newPath
            self.newName = newName
        }
    }

    func load() {
        projects = store.loadProjects()
        loadPendingRenames()
        detectRenamesAndPrune()
        refreshAIOSStatus()
    }

    /// Returns projects discovered in ~/.claude/projects/ that are NOT already in the user's list
    func availableProjects() -> [Project] {
        let discovered = ProjectDiscoveryService.discoverProjects()
        let existingNames = Set(projects.map(\.name))
        return discovered.filter { !existingNames.contains($0.name) }
    }

    /// Adds user-selected projects from discovery
    func addDiscoveredProjects(_ selected: [Project]) {
        for project in selected {
            var newProject = project
            newProject.sortOrder = projects.count
            projects.append(newProject)
        }
        save()
    }

    func addProject(path: String) {
        let name = URL(fileURLWithPath: path).lastPathComponent
        let isAIOS = FileManager.default.fileExists(atPath: "\(path)/.aios-core")

        let project = Project(
            name: name,
            path: path,
            sortOrder: projects.count,
            isAIOSProject: isAIOS
        )

        projects.append(project)
        save()
    }

    func removeProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        pendingRenames.removeAll { $0.projectId == project.id }
        reindex()
        save()
        savePendingRenames()
    }

    func moveProject(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }

    func updateModel(for project: Project, model: ClaudeModel) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].selectedModel = model
        save()
    }

    func updateOptimization(for project: Project, level: OptimizationLevel) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].optimizationLevel = level
        save()
    }

    func toggleMainPage(for project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].showOnMainPage.toggle()
        save()
    }

    func updateColor(for project: Project, hex: String) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].colorHex = hex
        save()
    }

    func updateBudget(for project: Project, budget: Int?) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].weeklyTokenBudget = budget
        save()
    }

    func updateGroup(for project: Project, group: String?) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].group = group
        save()
    }

    /// All unique group names across projects
    var allGroups: [String] {
        Array(Set(projects.compactMap(\.group))).sorted()
    }

    /// Projects grouped by their group name (nil = "Sem grupo")
    func groupedProjects() -> [(String, [Project])] {
        let groups = Dictionary(grouping: projects) { $0.group ?? "" }
        return groups.sorted { a, b in
            if a.key.isEmpty { return false }
            if b.key.isEmpty { return true }
            return a.key < b.key
        }
    }

    /// Projects visible on the main popover page
    func mainPageProjects() -> [Project] {
        projects
            .filter(\.showOnMainPage)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Re-check AIOS status for all projects by verifying .aios-core directory existence
    func refreshAIOSStatus() {
        let fm = FileManager.default
        var changed = false
        for i in projects.indices {
            let hasAIOS = fm.fileExists(atPath: "\(projects[i].path)/.aios-core")
            if projects[i].isAIOSProject != hasAIOS {
                projects[i].isAIOSProject = hasAIOS
                changed = true
            }
        }
        if changed {
            save()
        }
    }

    // MARK: - Rename Detection

    /// Accept a pending rename: update the project's path and name
    func acceptRename(_ rename: PendingRename) {
        if let index = projects.firstIndex(where: { $0.id == rename.projectId }) {
            projects[index].path = rename.newPath
            projects[index].name = rename.newName
            save()
        }
        pendingRenames.removeAll { $0.id == rename.id }
        savePendingRenames()
    }

    /// Dismiss a pending rename: remove the project (prune)
    func dismissRename(_ rename: PendingRename) {
        projects.removeAll { $0.id == rename.projectId }
        pendingRenames.removeAll { $0.id == rename.id }
        reindex()
        save()
        savePendingRenames()
    }

    /// Detect renamed directories and prune truly deleted ones
    private func detectRenamesAndPrune() {
        let fm = FileManager.default
        var newRenames: [PendingRename] = []
        var toPrune: [UUID] = []

        for project in projects {
            guard !fm.fileExists(atPath: project.path) else { continue }

            // Already has a pending rename? Skip
            if pendingRenames.contains(where: { $0.projectId == project.id }) {
                continue
            }

            // Check sibling directories in the parent folder
            let parentURL = URL(fileURLWithPath: project.path).deletingLastPathComponent()
            let oldName = URL(fileURLWithPath: project.path).lastPathComponent

            if let candidate = findBestRenameCandidate(in: parentURL, oldName: oldName, fm: fm) {
                newRenames.append(PendingRename(
                    projectId: project.id,
                    oldPath: project.path,
                    newPath: candidate.path,
                    newName: candidate.lastPathComponent
                ))
            } else {
                toPrune.append(project.id)
            }
        }

        // Prune projects with no rename candidate
        if !toPrune.isEmpty {
            let before = projects.count
            projects.removeAll { toPrune.contains($0.id) }
            reindex()
            save()
            print("[Projects] pruned \(before - projects.count) project(s) with invalid paths")
        }

        // Add new renames
        if !newRenames.isEmpty {
            pendingRenames.append(contentsOf: newRenames)
            savePendingRenames()
            print("[Projects] detected \(newRenames.count) possible rename(s)")

            // Send macOS notification
            sendRenameNotification(count: newRenames.count)
        }

        // Clean up renames whose project no longer exists
        let projectIds = Set(projects.map(\.id))
        let beforeRenames = pendingRenames.count
        pendingRenames.removeAll { !projectIds.contains($0.projectId) }
        if pendingRenames.count != beforeRenames {
            savePendingRenames()
        }
    }

    /// Find best rename candidate in sibling directories using string similarity
    private func findBestRenameCandidate(in parentURL: URL, oldName: String, fm: FileManager) -> URL? {
        guard let siblings = try? fm.contentsOfDirectory(at: parentURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return nil
        }

        var bestCandidate: URL?
        var bestScore: Double = 0

        for sibling in siblings {
            guard let isDir = try? sibling.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDir else { continue }
            let siblingName = sibling.lastPathComponent
            if siblingName == oldName { continue }

            let score = stringSimilarity(oldName, siblingName)
            if score > 0.6 && score > bestScore {
                bestScore = score
                bestCandidate = sibling
            }
        }

        return bestCandidate
    }

    /// Simple string similarity based on longest common subsequence ratio
    private func stringSimilarity(_ a: String, _ b: String) -> Double {
        let aLower = a.lowercased()
        let bLower = b.lowercased()

        // Check common prefix ratio
        let commonPrefix = aLower.commonPrefix(with: bLower)
        let prefixRatio = Double(commonPrefix.count) / Double(max(aLower.count, bLower.count))
        if prefixRatio > 0.6 { return prefixRatio }

        // LCS-based similarity
        let aArr = Array(aLower)
        let bArr = Array(bLower)
        let m = aArr.count
        let n = bArr.count
        guard m > 0, n > 0 else { return 0 }

        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 1...m {
            for j in 1...n {
                if aArr[i - 1] == bArr[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        return Double(dp[m][n]) / Double(max(m, n))
    }

    private func sendRenameNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "exímIA Meter"
        content.body = count == 1
            ? "Um projeto parece ter sido renomeado. Verifique em Settings → Projects."
            : "\(count) projetos parecem ter sido renomeados. Verifique em Settings → Projects."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "project-rename-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Bulk Operations

    /// Reset all project colors to the default amber
    func resetAllColors() {
        let defaultColor = "#F59E0B"
        for i in projects.indices {
            projects[i].colorHex = defaultColor
        }
        save()
    }

    /// Rename a group across all projects
    func renameGroup(from oldName: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        for i in projects.indices {
            if projects[i].group == oldName {
                projects[i].group = trimmed
            }
        }
        save()
    }

    /// Delete a group (set all members to nil)
    func deleteGroup(_ name: String) {
        for i in projects.indices {
            if projects[i].group == name {
                projects[i].group = nil
            }
        }
        save()
    }

    // MARK: - Persistence

    private func savePendingRenames() {
        if let data = try? JSONEncoder().encode(pendingRenames) {
            UserDefaults.standard.set(data, forKey: kPendingRenames)
        }
    }

    private func loadPendingRenames() {
        if let data = UserDefaults.standard.data(forKey: kPendingRenames),
           let saved = try? JSONDecoder().decode([PendingRename].self, from: data) {
            pendingRenames = saved
        }
    }

    private func reindex() {
        for i in projects.indices {
            projects[i].sortOrder = i
        }
    }

    private func save() {
        store.saveProjects(projects)
    }
}
