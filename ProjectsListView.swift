import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @StateObject private var collaborationService = CollaborationService()
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingNewProject = false
    @State private var searchText = ""
    @State private var selectedStatus: ProjectStatus?
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: Project?
    
    // Identifiant unique pour la vue
    private let viewID = UUID()
    
    var filteredProjects: [Project] {
        var projects = projectManager.projects
        
        if !searchText.isEmpty {
            projects = projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                contactsManager.contacts.first { $0.id == project.clientId }?.fullName.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        if let status = selectedStatus {
            projects = projects.filter { $0.status == status }
        }
        
        return projects
    }
    
    var body: some View {
        VStack(spacing: 0) {
            StatusFilterBar(selectedStatus: $selectedStatus)
                .environmentObject(languageManager)
            
            ProjectListContent(
                filteredProjects: filteredProjects,
                projectManager: projectManager,
                contactsManager: contactsManager,
                collaborationService: collaborationService,
                showingDeleteAlert: $showingDeleteAlert,
                projectToDelete: $projectToDelete,
                onDelete: deleteProject
            )
            .environmentObject(languageManager)
        }
        .id(viewID) // Identifiant stable pour la vue
        .searchable(text: $searchText, prompt: "projects.search".localized)
        .navigationTitle("projects.title".localized)
        .toolbar {
            ProjectToolbarItems(showingNewProject: $showingNewProject)
                .environmentObject(languageManager)
        }
        .sheet(isPresented: $showingNewProject) {
            NavigationStack {
                ProjectFormView(projectManager: projectManager, contactsManager: contactsManager)
                    .navigationTitle("projects.new".localized)
                    .environmentObject(languageManager)
            }
        }
        .alert("message.confirm".localized, isPresented: $showingDeleteAlert) {
            DeleteConfirmationButtons(projectToDelete: projectToDelete, onDelete: deleteProject)
                .environmentObject(languageManager)
        } message: {
            Text("message.delete_confirm".localized)
        }
        .onAppear {
            // Réinitialiser l'état lors de l'apparition de la vue
            selectedStatus = nil
            searchText = ""
        }
    }
    
    private func deleteProject(_ project: Project) {
        projectManager.deleteProject(project)
        projectToDelete = nil
    }
}

// MARK: - Sous-composants
private struct ProjectListContent: View {
    @EnvironmentObject private var languageManager: LanguageManager
    let filteredProjects: [Project]
    let projectManager: ProjectManager
    let contactsManager: ContactsManager
    let collaborationService: CollaborationService
    @Binding var showingDeleteAlert: Bool
    @Binding var projectToDelete: Project?
    let onDelete: (Project) -> Void
    
    var body: some View {
        List {
            if filteredProjects.isEmpty {
                Text("projects.empty".localized)
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(
                        project: project,
                        projectManager: projectManager,
                        contactsManager: contactsManager,
                        collaborationService: collaborationService
                    ).environmentObject(languageManager)) {
                        ProjectRowView(
                            project: project,
                            contact: contactsManager.contacts.first { $0.id == project.clientId }
                        )
                        .environmentObject(languageManager)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        projectToDelete = filteredProjects[index]
                        showingDeleteAlert = true
                    }
                }
            }
        }
    }
} 