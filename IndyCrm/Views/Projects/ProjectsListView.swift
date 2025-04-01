import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @StateObject private var collaborationService = CollaborationService()
    @State private var showingNewProject = false
    @State private var searchText = ""
    @State private var selectedStatus: ProjectStatus?
    
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
        // Décomposons la vue en sous-vues plus petites
        ProjectListContainer(
            projects: filteredProjects,
            showingNewProject: $showingNewProject,
            selectedStatus: $selectedStatus,
            projectManager: projectManager,
            contactsManager: contactsManager,
            collaborationService: collaborationService
        )
        .searchable(text: $searchText, prompt: "Rechercher un projet")
        .navigationTitle("Projets")
        .sheet(isPresented: $showingNewProject) {
            NavigationView {
                ProjectFormView(projectManager: projectManager, contactsManager: contactsManager)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// Sous-vue pour le conteneur principal
private struct ProjectListContainer: View {
    let projects: [Project]
    @Binding var showingNewProject: Bool
    @Binding var selectedStatus: ProjectStatus?
    let projectManager: ProjectManager
    let contactsManager: ContactsManager
    let collaborationService: CollaborationService
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StatusFilterBar(selectedStatus: $selectedStatus)
                ProjectsList(
                    projects: projects,
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    collaborationService: collaborationService
                )
            }
            
            AddProjectButton(showingNewProject: $showingNewProject)
        }
    }
}

// Sous-vue pour la barre de filtres
private struct StatusFilterBar: View {
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

// Sous-vue pour la liste des projets
private struct ProjectsList: View {
    let projects: [Project]
    let projectManager: ProjectManager
    let contactsManager: ContactsManager
    let collaborationService: CollaborationService
    
    var body: some View {
        List {
            ForEach(projects) { project in
                NavigationLink(destination: ProjectDetailView(
                    project: project,
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    collaborationService: collaborationService
                )) {
                    ProjectRowView(
                        project: project,
                        contact: contactsManager.contacts.first { $0.id == project.clientId }
                    )
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    projectManager.deleteProject(projects[index])
                }
            }
        }
        .listStyle(.plain)
    }
}

// Sous-vue pour le bouton d'ajout
private struct AddProjectButton: View {
    @Binding var showingNewProject: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingNewProject = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.blue.gradient))
                        .shadow(radius: 4, y: 2)
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

// Sous-vue pour les boutons de filtre
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedStatus == status ? Color.blue : Color.gray.opacity(0.1))
                )
                .foregroundColor(selectedStatus == status ? .white : .primary)
        }
    }
}

#Preview {
    NavigationView {
        ProjectsListView(
            projectManager: ProjectManager(activityLogService: ActivityLogService()),
            contactsManager: ContactsManager()
        )
    }
}