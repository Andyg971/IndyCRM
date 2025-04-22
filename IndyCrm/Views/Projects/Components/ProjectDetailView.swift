import SwiftUI

struct ProjectDetailView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    @EnvironmentObject var projectManager: ProjectManager
    @EnvironmentObject var contactsManager: ContactsManager
    @State private var selectedTab = 0
    @State private var showingAddTaskSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // En-tête du projet
                projectHeader
                
                // Sélecteur d'onglets personnalisé
                CustomTabSelector(selectedTab: $selectedTab, titles: ["Aperçu", "Tâches", "Notes"])
                    .padding(.vertical, 8)
                
                // Contenu selon l'onglet sélectionné
                TabView(selection: $selectedTab) {
                    projectOverview
                        .tag(0)
                    
                    tasksList
                        .tag(1)
                    
                    projectNotes
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(minHeight: 400)
            }
            .padding()
        }
        .navigationTitle(viewModel.project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingAddTaskSheet = true
                }) {
                    Label("Ajouter une tâche", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTaskSheet) {
            TaskFormView(
                contactsManager: contactsManager,
                onSave: { task in
                    viewModel.addTask(task)
                }
            )
        }
    }
    
    // En-tête du projet avec statut et progression
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(viewModel.project.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                StatusBadge(status: viewModel.project.status)
            }
            
            if let client = contactsManager.contacts.first(where: { $0.id == viewModel.project.clientId }) {
                Label(client.fullName, systemImage: "person")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !viewModel.project.tasks.isEmpty {
                ModernProgressBar(
                    progress: viewModel.project.progress,
                    isPaused: viewModel.project.status == .onHold
                )
                .frame(height: 8)
                .padding(.top, 4)
                
                HStack {
                    Text("\(Int(viewModel.project.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let deadline = viewModel.project.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(deadline.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                        }
                        .foregroundColor(viewModel.project.isOverdue ? .red : .secondary)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                ActionButton(
                    title: viewModel.project.status == .completed ? "Rouvrir" : "Terminer",
                    icon: viewModel.project.status == .completed ? "arrow.counterclockwise" : "checkmark.circle",
                    color: viewModel.project.status == .completed ? .blue : .green
                ) {
                    viewModel.markProjectAsComplete()
                }
                
                Spacer()
                
                if viewModel.project.status != .completed {
                    ActionButton(
                        title: viewModel.project.status == .onHold ? "Reprendre" : "Suspendre",
                        icon: viewModel.project.status == .onHold ? "play.circle" : "pause.circle",
                        color: viewModel.project.status == .onHold ? .green : .orange
                    ) {
                        viewModel.toggleProjectHold()
                    }
                }
            }
        }
    }
    
    // Aperçu du projet
    private var projectOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Informations du projet
            Group {
                InfoRow(title: "Date de début", value: viewModel.project.startDate.formatted(date: .long, time: .omitted))
                
                if let deadline = viewModel.project.deadline {
                    InfoRow(title: "Date d'échéance", value: deadline.formatted(date: .long, time: .omitted))
                }
                
                if viewModel.project.totalEstimatedHours > 0 {
                    InfoRow(title: "Heures estimées", value: "\(viewModel.project.totalEstimatedHours.formatted()) h")
                }
                
                if viewModel.project.totalWorkedHours > 0 {
                    InfoRow(title: "Heures travaillées", value: "\(viewModel.project.totalWorkedHours.formatted()) h")
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Jalons du projet
            if !viewModel.project.milestones.isEmpty {
                Text("Jalons")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(viewModel.project.milestones) { milestone in
                    MilestoneRow(milestone: milestone)
                }
            }
            
            Spacer()
        }
    }
    
    // Liste des tâches
    private var tasksList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.project.tasks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Aucune tâche")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Ajoutez des tâches pour suivre votre progression sur ce projet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showingAddTaskSheet = true
                    }) {
                        Label("Ajouter une tâche", systemImage: "plus.circle.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
            } else {
                // Options de filtrage (peut être développé ultérieurement)
                HStack {
                    Text("\(viewModel.project.tasks.count) tâches")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Toutes", action: {})
                        Button("À faire", action: {})
                        Button("En cours", action: {})
                        Button("Terminées", action: {})
                    } label: {
                        Label("Filtrer", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 8)
                
                // Liste des tâches
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.project.tasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task, project: viewModel.project, projectManager: projectManager, contactsManager: contactsManager)) {
                            TaskCard(
                                task: task,
                                project: viewModel.project,
                                contactsManager: contactsManager,
                                onTaskStatusChanged: { isCompleted in
                                    viewModel.updateTaskStatus(task, isCompleted: isCompleted)
                                },
                                onTaskUpdated: { updatedTask in
                                    viewModel.updateTask(updatedTask)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // Notes du projet
    private var projectNotes: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.project.notes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "note.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Aucune note")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Ajoutez des notes pour garder des informations importantes sur ce projet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text(viewModel.project.notes)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.isCompleted ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if milestone.isCompleted, let lastUpdate = milestone.lastUpdate {
                Text(lastUpdate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyProject = Project.example
        let dummyProjectManager = ProjectManager()
        let dummyContactsManager = ContactsManager()

        NavigationView {
            ProjectDetailView(viewModel: ProjectDetailViewModel(project: dummyProject, projectManager: dummyProjectManager))
                .environmentObject(dummyProjectManager)
                .environmentObject(dummyContactsManager)
                .task {
                    if !dummyProjectManager.projects.contains(where: { $0.id == dummyProject.id }) {
                        await dummyProjectManager.addProject(dummyProject)
                    }
                }
        }
    }
} 