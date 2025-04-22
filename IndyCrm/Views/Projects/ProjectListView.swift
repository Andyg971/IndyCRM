import SwiftUI

// Vue pour afficher la liste des projets
struct ProjectListView: View {
    // Gestionnaire de projets injecté via l'environnement
    @EnvironmentObject var projectManager: ProjectManager
    // Inject ContactsManager from Managers directory (Class name is ContactsManager)
    @EnvironmentObject var contactsManager: ContactsManager

    // État pour la recherche et le filtrage
    @State private var searchText = ""
    @State private var selectedStatus: ProjectStatus? = nil
    @State private var showingFilters = false

    // État pour afficher le formulaire d'ajout/modification
    @State private var showingProjectForm = false
    @State private var projectToEdit: Project? = nil

    // Colonnes pour la grille adaptative
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Décomposition de la vue principale
    var body: some View {
        NavigationView {
            mainContentView
                .navigationTitle(NSLocalizedString("Projects", comment: "Navigation title for Projects list"))
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingProjectForm) {
                    ProjectFormView(
                        projectManager: projectManager,
                        contactsManager: contactsManager,
                        editingProject: projectToEdit
                    )
                }
        }
    }
    
    // Contenu principal extrait
    private var mainContentView: some View {
        VStack {
            searchBarView
            filterControlsView
            projectsContentView
        }
    }
    
    // Barre de recherche
    private var searchBarView: some View {
        SearchBar(
            text: $searchText,
            placeholder: NSLocalizedString("SearchProjects", comment: "Placeholder for project search bar")
        )
    }
    
    // Contrôles de filtrage
    private var filterControlsView: some View {
        VStack {
            filterToggleBarView
            
            if showingFilters {
                FilterView(selectedStatus: $selectedStatus)
                    .padding(.horizontal)
            }
        }
    }
    
    // Barre de toggle pour les filtres
    private var filterToggleBarView: some View {
        HStack {
            Button {
                showingFilters.toggle()
            } label: {
                Label(
                    NSLocalizedString("Filters", comment: "Filters button label"),
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
            
            Spacer()
            
            if let status = selectedStatus {
                activeFilterView(status: status)
            }
        }
        .padding(.horizontal)
    }
    
    // Vue du filtre actif
    private func activeFilterView(status: ProjectStatus) -> some View {
        HStack(spacing: 6) {
            Text("\(NSLocalizedString("Status", comment: "Status filter label")): \(status.rawValue)")
                .accessibilityLabel(NSLocalizedString("Active filter", comment: "Accessibility label for active filter"))
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedStatus = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .accessibilityLabel(NSLocalizedString("Clear filter", comment: "Accessibility label for clear filter button"))
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    // Contenu principal des projets (grille ou message vide)
    private var projectsContentView: some View {
        Group {
            if filteredProjects.isEmpty {
                emptyProjectsView
            } else {
                projectsGridView
            }
        }
    }
    
    // Vue quand aucun projet ne correspond
    private var emptyProjectsView: some View {
        VStack {
            Text(NSLocalizedString("NoProjectsFound", comment: "Message when no projects match search/filter"))
                .foregroundColor(.secondary)
                .padding(.top, 50)
            Spacer()
        }
    }
    
    // Grille des projets
    private var projectsGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredProjects) { project in
                    ProjectGridCell(
                        project: project,
                        projectManager: projectManager,
                        contactsManager: contactsManager,
                        projectToEdit: $projectToEdit,
                        showingProjectForm: $showingProjectForm
                    )
                }
            }
            .padding()
        }
    }
    
    // Contenu de la toolbar
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                projectToEdit = nil
                showingProjectForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // Fonctions de filtrage simplifiées
    private var filteredProjects: [Project] {
        applyProjectsSorting(
            applyProjectsTextFilter(
                applyProjectsStatusFilter(projectManager.projects)
            )
        )
    }
    
    // Applique le filtre de statut
    private func applyProjectsStatusFilter(_ projects: [Project]) -> [Project] {
        guard let status = selectedStatus else { return projects }
        return projects.filter { $0.status == status }
    }
    
    // Applique le filtre de texte (recherche)
    private func applyProjectsTextFilter(_ projects: [Project]) -> [Project] {
        guard !searchText.isEmpty else { return projects }
        
        let lowercasedSearchText = searchText.lowercased()
        return projects.filter { project in
            let clientName = findClientName(for: project.clientId)
            return project.name.lowercased().contains(lowercasedSearchText) ||
                   clientName.lowercased().contains(lowercasedSearchText)
        }
    }
    
    // Récupère le nom du client à partir de son ID
    private func findClientName(for clientId: UUID) -> String {
        contactsManager.contacts.first { $0.id == clientId }?.fullName ?? ""
    }
    
    // Applique le tri (favoris en premier, puis par date)
    private func applyProjectsSorting(_ projects: [Project]) -> [Project] {
        projects.sorted { p1, p2 in
            if p1.isFavorite != p2.isFavorite {
                return p1.isFavorite
            }
            return p1.startDate > p2.startDate
        }
    }

    // Fonctions d'action simplifiées
    private func deleteProject(_ project: Project) {
        Task { await projectManager.deleteProject(project) }
    }

    private func toggleFavorite(_ project: Project) {
        var updatedProject = project
        updatedProject.isFavorite.toggle()
        Task { await projectManager.updateProject(updatedProject) }
    }
}

// MARK: - Extracted Subview for Grid Cell
private struct ProjectGridCell: View {
    let project: Project
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @Binding var projectToEdit: Project?
    @Binding var showingProjectForm: Bool
    
    // Préparation des données à l'avance pour éviter les expressions complexes
    private var viewModel: ProjectDetailViewModel {
        ProjectDetailViewModel(project: project, projectManager: projectManager)
    }
    
    private var contact: Contact? {
        contactsManager.contacts.first { $0.id == project.clientId }
    }

    var body: some View {
        // Diviser le corps en parties plus simples
        cellContent
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                contextMenuContent
            }
    }
    
    // Extrait pour simplifier le corps principal
    private var cellContent: some View {
        // Navigation directe vers TaskBoardView
        NavigationLink {
            TaskBoardView(
                projectManager: projectManager,
                contactsManager: contactsManager,
                project: project
            )
        } label: {
            ProjectRowView(project: project, contact: contact)
        }
    }
    
    // Contenu du menu contextuel regroupé pour simplifier
    private var contextMenuContent: some View {
        Group {
            editButton
            deleteButton
            favoriteButton
        }
    }
    
    // Boutons extraits (laissés inchangés)
    private var editButton: some View {
        Button {
            projectToEdit = project
            showingProjectForm = true
        } label: {
            Label(NSLocalizedString("Edit", comment: "Edit action"), systemImage: "pencil")
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteProject(project)
        } label: {
            Label(NSLocalizedString("Delete", comment: "Delete action"), systemImage: "trash")
        }
    }
    
    private var favoriteButton: some View {
        Button {
            toggleFavorite(project)
        } label: {
            let text = project.isFavorite ? NSLocalizedString("RemoveFavorite", comment:"") : NSLocalizedString("AddToFavorites", comment: "")
            let icon = project.isFavorite ? "heart.slash" : "heart"
            Label(text, systemImage: icon)
        }
    }

    // Helper methods (inchangés)
    private func deleteProject(_ project: Project) {
        Task {
            await projectManager.deleteProject(project)
        }
    }

    private func toggleFavorite(_ project: Project) {
        var updatedProject = project
        updatedProject.isFavorite.toggle()
        Task {
             await projectManager.updateProject(updatedProject)
        }
    }
}

// Vue pour les filtres simplifiée
struct FilterView: View {
    @Binding var selectedStatus: ProjectStatus?
    
    // Extraction de la création du FilterChip pour simplifier
    private func makeFilterChip(for status: ProjectStatus) -> some View {
        FilterChip(
            title: status.rawValue,
            isSelected: status == selectedStatus
        ) {
            // L'action est simplifiée
            if selectedStatus == status {
                selectedStatus = nil
            } else {
                selectedStatus = status
            }
        }
    }
    
    // Extraction du contenu HStack pour simplifier
    private var filterChipsRow: some View {
        HStack {
            ForEach(ProjectStatus.allCases, id: \.self) { status in
                makeFilterChip(for: status)
            }
        }
        .padding(.vertical, 4)
    }

    var body: some View {
        // Corps simplifié qui délègue aux sous-vues extraites
        ScrollView(.horizontal, showsIndicators: false) {
            filterChipsRow
        }
        .accessibilityLabel(NSLocalizedString("Status filters", comment: "Accessibility label for status filters"))
    }
}


// Fournisseur de prévisualisation pour ProjectListView
struct ProjectListView_Previews: PreviewProvider {
    // Extraire les méthodes statiques pour créer les dépendances
    static var projectManager: ProjectManager {
        let manager = ProjectManager()
        return manager
    }
    
    static var contactsManager: ContactsManager {
        let manager = ContactsManager()
        return manager
    }
    
    // Simplifier la méthode previews pour éviter les expressions complexes
    static var previews: some View {
        // Éviter les tâches asynchrones dans la prévisualisation
        ProjectListView()
            .environmentObject(projectManager)
            .environmentObject(contactsManager)
            .previewDisplayName("Liste des projets")
    }
}
