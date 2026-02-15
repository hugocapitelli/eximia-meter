import SwiftUI

struct ProjectsTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showingDiscovery = false
    @State private var showingResetConfirmation = false
    @State private var editingGroup: String? = nil
    @State private var editGroupText = ""
    @State private var showingNewGroup = false
    @State private var newGroupText = ""

    private var projects: ProjectsViewModel {
        appViewModel.projectsViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: ExTokens.Spacing._8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Projects")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ExTokens.Colors.textPrimary)

                        Text("Toggle visibility, reorder, and group projects")
                            .font(ExTokens.Typography.caption)
                            .foregroundColor(ExTokens.Colors.textTertiary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        actionButton(icon: "arrow.counterclockwise", label: "Reset Colors") {
                            showingResetConfirmation = true
                        }

                        actionButton(icon: "magnifyingglass", label: "Discover") {
                            showingDiscovery = true
                        }

                        actionButton(icon: "plus", label: "Add") {
                            addProject()
                        }
                    }
                }
            }
            .padding(.horizontal, ExTokens.Spacing._24)
            .padding(.top, ExTokens.Spacing._24)
            .padding(.bottom, ExTokens.Spacing._12)

            // Divider
            Rectangle()
                .fill(ExTokens.Colors.borderDefault)
                .frame(height: 1)
                .padding(.horizontal, ExTokens.Spacing._16)

            // Rename banners
            if !projects.pendingRenames.isEmpty {
                VStack(spacing: ExTokens.Spacing._6) {
                    ForEach(projects.pendingRenames) { rename in
                        RenameBanner(rename: rename, onAccept: {
                            projects.acceptRename(rename)
                        }, onDismiss: {
                            projects.dismissRename(rename)
                        })
                    }
                }
                .padding(.horizontal, ExTokens.Spacing._16)
                .padding(.top, ExTokens.Spacing._8)
            }

            // Content
            if projects.projects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 28))
                        .foregroundColor(ExTokens.Colors.textMuted)

                    Text("No projects configured")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ExTokens.Colors.textTertiary)

                    Text("Click Discover to find projects or Add to choose a folder")
                        .font(.system(size: 10))
                        .foregroundColor(ExTokens.Colors.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Project list
                    ForEach(projects.projects.indices, id: \.self) { index in
                        let project = projects.projects[index]
                        let isVisible = project.showOnMainPage
                        ProjectSettingsRow(
                            index: index + 1,
                            project: project,
                            isVisible: isVisible,
                            allGroups: projects.allGroups,
                            onToggleVisibility: {
                                projects.toggleMainPage(for: project)
                            },
                            onModelChange: { model in
                                projects.updateModel(for: project, model: model)
                            },
                            onColorChange: { hex in
                                projects.updateColor(for: project, hex: hex)
                            },
                            onGroupChange: { group in
                                projects.updateGroup(for: project, group: group)
                            },
                            onRemove: {
                                projects.removeProject(project)
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    }
                    .onMove { source, destination in
                        projects.moveProject(from: source, to: destination)
                    }

                    // Group Management section
                    if !projects.allGroups.isEmpty {
                        Section {
                            ForEach(projects.allGroups, id: \.self) { group in
                                groupManagementRow(group)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 10))
                                Text("GERENCIAR GRUPOS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(ExTokens.Colors.textMuted)
                            .padding(.top, ExTokens.Spacing._8)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $showingDiscovery) {
            DiscoverProjectsSheet(projectsViewModel: projects)
        }
        .alert("Resetar Cores", isPresented: $showingResetConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Resetar", role: .destructive) {
                projects.resetAllColors()
            }
        } message: {
            Text("Todas as cores de projeto serão restauradas para o padrão (amber). Esta ação não pode ser desfeita.")
        }
        .alert("Renomear Grupo", isPresented: Binding(
            get: { editingGroup != nil },
            set: { if !$0 { editingGroup = nil; editGroupText = "" } }
        )) {
            TextField("Novo nome", text: $editGroupText)
            Button("Cancelar", role: .cancel) { editingGroup = nil; editGroupText = "" }
            Button("Renomear") {
                if let group = editingGroup {
                    projects.renameGroup(from: group, to: editGroupText)
                }
                editingGroup = nil
                editGroupText = ""
            }
        } message: {
            Text("Digite o novo nome para o grupo \"\(editingGroup ?? "")\".")
        }
    }

    private func groupManagementRow(_ group: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundColor(ExTokens.Colors.accentSecondary)

            Text(group)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ExTokens.Colors.textPrimary)

            // Count of projects in group
            let count = projects.projects.filter { $0.group == group }.count
            Text("\(count)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textTertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(ExTokens.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Spacer()

            // Rename
            Button {
                editGroupText = group
                editingGroup = group
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(ExTokens.Colors.accentPrimary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HoverableButtonStyle())
            .help("Renomear grupo")

            // Delete
            Button {
                projects.deleteGroup(group)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(ExTokens.Colors.statusCritical)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HoverableButtonStyle())
            .help("Remover grupo (projetos voltam para 'Sem grupo')")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ExTokens.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundColor(ExTokens.Colors.accentPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(ExTokens.Colors.accentPrimary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                    .stroke(ExTokens.Colors.accentPrimary.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverableButtonStyle())
    }

    private func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project directory"

        if panel.runModal() == .OK, let url = panel.url {
            projects.addProject(path: url.path)
        }
    }
}

// MARK: - Discover Projects Sheet

struct DiscoverProjectsSheet: View {
    let projectsViewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var available: [Project] = []
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: ExTokens.Spacing._6) {
                Text("Discover Projects")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ExTokens.Colors.textPrimary)

                Text("Select projects from ~/.claude/projects/ to add")
                    .font(.system(size: 11))
                    .foregroundColor(ExTokens.Colors.textTertiary)
            }
            .padding(.top, ExTokens.Spacing._24)
            .padding(.bottom, ExTokens.Spacing._16)

            if available.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(ExTokens.Colors.statusSuccess)

                    Text("All discovered projects are already added")
                        .font(.system(size: 12))
                        .foregroundColor(ExTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: ExTokens.Spacing._6) {
                        ForEach(available) { project in
                            discoverRow(project)
                        }
                    }
                    .padding(.horizontal, ExTokens.Spacing._16)
                }
            }

            // Footer
            HStack(spacing: ExTokens.Spacing._12) {
                ExButton(title: "Cancel", variant: .outline, size: .md, fullWidth: true) {
                    dismiss()
                }

                if !available.isEmpty {
                    ExButton(
                        title: "Add \(selected.count) Project\(selected.count == 1 ? "" : "s")",
                        variant: .accent,
                        size: .md,
                        fullWidth: true
                    ) {
                        let toAdd = available.filter { selected.contains($0.name) }
                        projectsViewModel.addDiscoveredProjects(toAdd)
                        dismiss()
                    }
                }
            }
            .padding(ExTokens.Spacing._16)
        }
        .frame(width: 420, height: 360)
        .background(ExTokens.Colors.backgroundPrimary)
        .onAppear {
            available = projectsViewModel.availableProjects()
        }
    }

    private func discoverRow(_ project: Project) -> some View {
        let isSelected = selected.contains(project.name)

        return Button {
            if isSelected {
                selected.remove(project.name)
            } else {
                selected.insert(project.name)
            }
        } label: {
            HStack(spacing: ExTokens.Spacing._12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)

                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#3B82F6"))

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ExTokens.Colors.textPrimary)

                    Text(project.path)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                if project.totalSessions > 0 {
                    Text("\(project.totalSessions) sessions")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textTertiary)
                }
            }
            .padding(.horizontal, ExTokens.Spacing._12)
            .padding(.vertical, ExTokens.Spacing._8)
            .background(isSelected ? ExTokens.Colors.backgroundCard : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                    .stroke(isSelected ? ExTokens.Colors.accentPrimary.opacity(0.3) : ExTokens.Colors.borderDefault, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        }
        .buttonStyle(.plain)
    }
}

struct ProjectSettingsRow: View {
    let index: Int
    let project: Project
    let isVisible: Bool
    var allGroups: [String] = []
    var onToggleVisibility: () -> Void
    var onModelChange: (ClaudeModel) -> Void
    var onColorChange: ((String) -> Void)?
    var onGroupChange: ((String?) -> Void)?
    var onRemove: () -> Void

    @State private var selectedModel: ClaudeModel
    @State private var selectedColor: Color
    @State private var isHovered = false
    @State private var isUpdatingAIOS = false
    @State private var aiosUpdateResult: Bool? = nil
    @State private var showingNewGroup = false
    @State private var newGroupText = ""

    init(index: Int, project: Project, isVisible: Bool, allGroups: [String] = [], onToggleVisibility: @escaping () -> Void, onModelChange: @escaping (ClaudeModel) -> Void, onColorChange: ((String) -> Void)? = nil, onGroupChange: ((String?) -> Void)? = nil, onRemove: @escaping () -> Void) {
        self.index = index
        self.project = project
        self.isVisible = isVisible
        self.allGroups = allGroups
        self.onToggleVisibility = onToggleVisibility
        self.onModelChange = onModelChange
        self.onColorChange = onColorChange
        self.onGroupChange = onGroupChange
        self.onRemove = onRemove
        self._selectedModel = State(initialValue: project.selectedModel)
        self._selectedColor = State(initialValue: Color(hex: project.colorHex))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Visibility toggle
                Button(action: onToggleVisibility) {
                    Image(systemName: isVisible ? "eye.fill" : "eye.slash")
                        .font(.system(size: 11))
                        .foregroundColor(isVisible ? ExTokens.Colors.accentPrimary : ExTokens.Colors.textMuted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HoverableButtonStyle())
                .help(isVisible ? "Hide from main page" : "Show on main page")

                // Index
                Text("\(index)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(ExTokens.Colors.textMuted)
                    .frame(width: 14)

                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 8))
                    .foregroundColor(ExTokens.Colors.textMuted)

                // Color dot (clickable picker)
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 16, height: 16)
                    .onChange(of: selectedColor) { _, newColor in
                        if let hex = newColor.toHex() {
                            onColorChange?(hex)
                        }
                    }

                // Project info
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(project.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isVisible ? ExTokens.Colors.textPrimary : ExTokens.Colors.textTertiary)

                        if let group = project.group, !group.isEmpty {
                            Text(group)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(ExTokens.Colors.accentSecondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(ExTokens.Colors.accentSecondary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    Text(project.path)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(ExTokens.Colors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Group menu
                Menu {
                    Button("Sem grupo") {
                        onGroupChange?(nil)
                    }

                    if !allGroups.isEmpty {
                        Divider()
                        ForEach(allGroups, id: \.self) { group in
                            Button(group) {
                                onGroupChange?(group)
                            }
                        }
                    }

                    Divider()
                    Button("Novo grupo...") {
                        showingNewGroup = true
                    }
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 10))
                        .foregroundColor(project.group != nil ? ExTokens.Colors.accentSecondary : ExTokens.Colors.textMuted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
                .help("Grupo: \(project.group ?? "nenhum")")

                // Model picker
                ModelPickerView(selectedModel: $selectedModel, compact: true)
                    .onChange(of: selectedModel) { _, newValue in
                        onModelChange(newValue)
                    }

                // AIOS update button (only for AIOS projects)
                if project.isAIOSProject {
                    Button {
                        updateAIOS()
                    } label: {
                        Group {
                            if isUpdatingAIOS {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.6)
                            } else if let result = aiosUpdateResult {
                                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(result ? ExTokens.Colors.statusSuccess : ExTokens.Colors.statusCritical)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11))
                                    .foregroundColor(ExTokens.Colors.accentPrimary)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HoverableButtonStyle())
                    .disabled(isUpdatingAIOS)
                    .help("Update AIOS (npx aios-core@latest install)")
                }

                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isHovered ? ExTokens.Colors.statusCritical : ExTokens.Colors.textMuted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hovering in isHovered = hovering }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .opacity(isVisible ? 1.0 : 0.5)
        .background(
            isVisible
                ? ExTokens.Colors.backgroundCard
                : Color.clear
        )
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(
                    isVisible ? ExTokens.Colors.borderDefault : Color.clear,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
        .animation(.easeInOut(duration: 0.15), value: isVisible)
        .alert("Novo Grupo", isPresented: $showingNewGroup) {
            TextField("Nome do grupo", text: $newGroupText)
            Button("Cancelar", role: .cancel) { newGroupText = "" }
            Button("Criar") {
                let trimmed = newGroupText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    onGroupChange?(trimmed)
                }
                newGroupText = ""
            }
        } message: {
            Text("Digite o nome do novo grupo para este projeto.")
        }
    }

    private func updateAIOS() {
        isUpdatingAIOS = true
        aiosUpdateResult = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["npx", "aios-core@latest", "install"]
            process.currentDirectoryURL = URL(fileURLWithPath: project.path)
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            var success = false
            do {
                try process.run()
                process.waitUntilExit()
                success = process.terminationStatus == 0
            } catch {
                print("[AIOS] update failed for \(project.name): \(error)")
            }

            DispatchQueue.main.async {
                isUpdatingAIOS = false
                aiosUpdateResult = success

                // Clear result after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    aiosUpdateResult = nil
                }
            }
        }
    }
}

// MARK: - Rename Banner

struct RenameBanner: View {
    let rename: ProjectsViewModel.PendingRename
    var onAccept: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ExTokens.Spacing._6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(ExTokens.Colors.statusWarning)

                Text("\"\(URL(fileURLWithPath: rename.oldPath).lastPathComponent)\" parece ter sido renomeado para \"\(rename.newName)\"")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ExTokens.Colors.textPrimary)
                    .lineLimit(2)

                Spacer()
            }

            Text("\(rename.oldPath) → \(rename.newPath)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(ExTokens.Colors.textMuted)
                .lineLimit(1)
                .truncationMode(.middle)

            HStack(spacing: 8) {
                Button {
                    withAnimation { onAccept() }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 9))
                        Text("Atualizar")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ExTokens.Colors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                }
                .buttonStyle(HoverableButtonStyle())

                Button {
                    withAnimation { onDismiss() }
                } label: {
                    Text("Ignorar")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ExTokens.Colors.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ExTokens.Colors.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: ExTokens.Radius.sm)
                                .stroke(ExTokens.Colors.borderDefault, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.sm))
                }
                .buttonStyle(HoverableButtonStyle())
            }
        }
        .padding(ExTokens.Spacing._12)
        .background(ExTokens.Colors.statusWarning.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: ExTokens.Radius.md)
                .stroke(ExTokens.Colors.statusWarning.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ExTokens.Radius.md))
    }
}
