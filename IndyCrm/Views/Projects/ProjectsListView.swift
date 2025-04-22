import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var collaborationService: CollaborationService
    @ObservedObject var helpService: HelpService
    @ObservedObject var alertService: AlertService
    @State private var searchText = ""
    @State private var selectedStatus: ProjectStatus?
    @State private var showingNewProject = false
    @State private var showingExportOptions = false
    @StateObject private var exportService = ExportService()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    // Variables d'état pour les actions swipe
    @State private var projectToDelete: Project? = nil
    @State private var showingDeleteConfirm = false
    @State private var editingProject: Project? = nil // Pour la sheet d'édition
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                FilterBarView(searchText: $searchText, selectedStatus: $selectedStatus)
                
                List {
                    ForEach(filteredProjects) { project in
                        NavigationLink(destination: ProjectDetailView(viewModel: ProjectDetailViewModel(project: project, projectManager: projectManager))) {
                            ProjectRow(
                                project: project,
                                projectManager: projectManager,
                                contactsManager: contactsManager,
                                collaborationService: collaborationService,
                                helpService: helpService,
                                alertService: alertService
                            )
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                toggleFavoriteStatus(project: project)
                            } label: {
                                Label(project.isFavorite ? "Unfavorite" : "Favorite", systemImage: project.isFavorite ? "heart.slash.fill" : "heart.fill")
                            }
                            .tint(project.isFavorite ? .gray : .pink)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                projectToDelete = project // Définir le projet pour confirmation
                                showingDeleteConfirm = true // Afficher l'alerte de confirmation
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingProject = project // Définir le projet pour la sheet d'édition
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.indigo)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Projets")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: exportToCSV) {
                        Label("Exporter en CSV", systemImage: "doc.text")
                    }
                    
                    Button(action: exportToVCard) {
                        Label("Exporter en vCard", systemImage: "person.crop.rectangle")
                    }
                    
                    Button(action: exportToExcel) {
                        Label("Exporter en Excel", systemImage: "tablecells")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .accentColor(.indigo)
        .sheet(isPresented: $showingNewProject) {
            NavigationView {
                ProjectFormView(
                    projectManager: projectManager,
                    contactsManager: contactsManager
                )
            }
        }
        // Sheet pour éditer un projet existant
        .sheet(item: $editingProject) { projectToEdit in
             NavigationView {
                 ProjectFormView(
                     projectManager: projectManager,
                     contactsManager: contactsManager,
                     editingProject: projectToEdit // Pass the unwrapped project using the correct parameter name
                 )
             }
         }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                SystemShareSheet(items: [url])
            }
        }
        .alert("Confirmer la suppression", isPresented: $showingDeleteConfirm) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                if let project = projectToDelete {
                    Task {
                        // Utiliser await pour s'assurer que l'opération asynchrone se termine correctement
                        await projectManager.deleteProject(project)
                        // Réinitialiser l'état après la suppression
                        projectToDelete = nil
                    }
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce projet ? Cette action est irréversible.")
        }
    }
    
    private var filteredProjects: [Project] {
        var projects = projectManager.projects
        
        if let selectedStatus = selectedStatus {
            projects = projects.filter { $0.status == selectedStatus }
        }
        
        if !searchText.isEmpty {
            projects = projects.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return projects.sorted { $0.name < $1.name }
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        let projectsToDelete = offsets.map { filteredProjects[$0] }
        Task {
            for project in projectsToDelete {
                // Utiliser await pour s'assurer que chaque suppression se termine correctement
                await projectManager.deleteProject(project)
            }
        }
    }
    
    private func exportToCSV() {
        if let url = exportService.exportToCSV(.projects, projects: projectManager.projects) {
            exportURL = url
            showingShareSheet = true
        } else {
            alertService.createAlert(
                type: .error,
                title: "Erreur d'export",
                message: "Une erreur est survenue lors de l'export CSV",
                severity: .medium
            )
        }
    }
    
    private func exportToVCard() {
        if let url = exportService.exportToVCard(contacts: contactsManager.contacts) {
            exportURL = url
            showingShareSheet = true
        } else {
            alertService.createAlert(
                type: .error,
                title: "Erreur d'export",
                message: "Une erreur est survenue lors de l'export vCard",
                severity: .medium
            )
        }
    }
    
    private func exportToExcel() {
        if let url = exportService.exportToExcel(.projects, projects: projectManager.projects) {
            exportURL = url
            showingShareSheet = true
        } else {
            alertService.createAlert(
                type: .error,
                title: "Erreur d'export",
                message: "Une erreur est survenue lors de l'export Excel",
                severity: .medium
            )
        }
    }
    
    // Fonction pour basculer le statut favori
    private func toggleFavoriteStatus(project: Project) {
        Task {
            var updatedProject = project
            updatedProject.isFavorite.toggle()
            updatedProject.updatedAt = Date()
            await projectManager.updateProject(updatedProject)
            // Gérer les erreurs si nécessaire avec alertService
        }
    }
}

// MARK: - Sous-composants
private struct FilterBarView: View {
    @Binding var searchText: String
    @Binding var selectedStatus: ProjectStatus?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(title: "Tous", status: nil, selectedStatus: $selectedStatus)
                
                ForEach(ProjectStatus.allCases, id: \.self) { status in
                    FilterButton(title: status.rawValue, status: status, selectedStatus: $selectedStatus)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
    }
}

private struct FilterButton: View {
    let title: String
    let status: ProjectStatus?
    @Binding var selectedStatus: ProjectStatus?
    
    var body: some View {
        Button {
            withAnimation {
                selectedStatus = status
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(status == selectedStatus ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(status == selectedStatus ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

#Preview {
    NavigationView {
        ProjectsListView(
            projectManager: ProjectManager(activityLogService: ActivityLogService()),
            contactsManager: ContactsManager(),
            collaborationService: CollaborationService(),
            helpService: HelpService(),
            alertService: AlertService()
        )
    }
}
