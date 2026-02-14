import SwiftUI

@Observable
class ProjectsViewModel {
    var projects: [Project] = []

    private let store = ProjectStore()

    func load() {
        projects = store.loadProjects()
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
        reindex()
        save()
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

    /// Projects visible on the main popover page
    func mainPageProjects() -> [Project] {
        projects
            .filter(\.showOnMainPage)
            .sorted { $0.sortOrder < $1.sortOrder }
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
