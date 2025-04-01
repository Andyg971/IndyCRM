import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var collaborationService: CollaborationService
    @State private var showingEditSheet = false
    @State private var showingAddTask = false
    @State private var showingAddComment = false
    @State private var selectedTask: ProjectTask?
    @State private var showingHistory = false
    @State private var showingShareSheet = false
    @State private var showingStats = false
    @EnvironmentObject var helpService: HelpService
    @EnvironmentObject var alertService: AlertService
    
    var client: Contact? {
        contactsManager.contacts.first(where: { $0.id == project.clientId })
    }
    
    var body: some View {
        List {
            Section(header: Text("Informations")) {
                LabeledContent("Client", value: client?.fullName ?? "Client inconnu")
                LabeledContent("Date de début", value: project.startDate.formatted(date: .long, time: .omitted))
                if let deadline = project.deadline {
                    LabeledContent("Date limite", value: deadline.formatted(date: .long, time: .omitted))
                }
                LabeledContent("Statut", value: project.status.rawValue)
                
                if !project.notes.isEmpty {
                    Text("Description du projet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Text(project.notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Progression")) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.indigo)
                        Text("\(project.tasks.filter { $0.isCompleted }.count)/\(project.tasks.count) tâches complétées")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    ModernProgressBar(progress: project.progress)
                        .frame(height: 24)
                }
            }
            
            Section(header: Text("Tâches")) {
                ForEach(project.tasks) { task in
                    TaskRowView(
                        task: task,
                        onToggleComplete: { isCompleted in
                            var updatedProject = project
                            if let taskIndex = updatedProject.tasks.firstIndex(where: { $0.id == task.id }) {
                                updatedProject.tasks[taskIndex].isCompleted = isCompleted
                                projectManager.updateProject(updatedProject)
                            }
                        }
                    )
                }
                
                Button("Ajouter une tâche") {
                    showingAddTask = true
                }
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Modifier") {
                        showingEditSheet = true
                    }
                    
                    if project.status != .completed {
                        Button("Marquer comme terminé") {
                            updateStatus(.completed)
                        }
                    }
                    
                    if project.status == .onHold {
                        Button("Reprendre le projet") {
                            updateStatus(.inProgress)
                            alertService.createAlert(
                                type: .success,
                                title: "Projet repris",
                                message: "Le projet \"\(project.name)\" a été remis en cours.",
                                severity: .low
                            )
                        }
                    } else if project.status != .completed {
                        Button("Mettre en pause") {
                            updateStatus(.onHold)
                            alertService.createAlert(
                                type: .info,
                                title: "Projet en pause",
                                message: "Le projet \"\(project.name)\" a été mis en pause.",
                                severity: .low
                            )
                        }
                    }
                    
                    Button("Voir l'historique") {
                        showingHistory = true
                    }
                    
                    Button {
                        showingStats = true
                    } label: {
                        Label("Statistiques", systemImage: "chart.bar")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: TaskBoardView(
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    project: project
                )) {
                    Label("Tableau des tâches", systemImage: "square.grid.2x2")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ProjectFormView(
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    editingProject: project
                )
            }
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                TaskFormView(contactsManager: contactsManager) { task in
                    var updatedProject = project
                    updatedProject.tasks.append(task)
                    projectManager.updateProject(updatedProject)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            NavigationView {
                TaskDetailView(
                    task: task,
                    project: project,
                    projectManager: projectManager,
                    contactsManager: contactsManager
                )
            }
        }
        .sheet(isPresented: $showingHistory) {
            NavigationView {
                ActivityLogView(
                    activityLogService: ActivityLogService(),
                    contactsManager: contactsManager,
                    entityType: .project,
                    entityId: project.id
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let projectData = try? JSONEncoder().encode(project) {
                ShareSheet(items: [projectData])
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationView {
                ProjectStatsView(project: project, contactsManager: contactsManager)
            }
        }
        .onAppear {
            helpService.checkProject(project)
        }
    }
    
    private func updateStatus(_ status: ProjectStatus) {
        var updatedProject = project
        updatedProject.status = status
        projectManager.updateProject(updatedProject)
    }
}

struct TaskDetailRow: View {
    let task: ProjectTask
    let contact: Contact?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                
                Text(task.title)
                    .strikethrough(task.isCompleted)
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let contact = contact {
                Text("Assigné à: \(contact.fullName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        ProjectDetailView(
            project: Project.example,
            projectManager: ProjectManager(),
            contactsManager: ContactsManager(),
            collaborationService: CollaborationService()
        )
    }
} 