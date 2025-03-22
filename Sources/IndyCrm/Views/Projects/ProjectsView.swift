import SwiftUI

struct ProjectsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.dateCreated, ascending: false)],
                  animation: .default)
    private var projects: FetchedResults<Project>
    
    @State private var searchText = ""
    @State private var showingAddProject = false
    @State private var selectedProject: Project?
    @State private var filterStatus = ProjectStatus.all
    
    enum ProjectStatus: String, CaseIterable {
        case all = "Tous"
        case active = "En cours"
        case completed = "Terminés"
        case cancelled = "Annulés"
    }
    
    var body: some View {
        VStack {
            // Filtres
            Picker("Statut", selection: $filterStatus) {
                ForEach(ProjectStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Liste des projets
            List {
                ForEach(filteredProjects) { project in
                    ProjectRow(project: project)
                        .onTapGesture {
                            selectedProject = project
                        }
                }
                .onDelete(perform: deleteProjects)
            }
            .searchable(text: $searchText, prompt: "Rechercher un projet")
        }
        .navigationTitle("Projets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddProject = true }) {
                    Label("Ajouter", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView()
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project)
        }
    }
    
    private var filteredProjects: [Project] {
        var result = projects
        
        // Filtre par statut
        if filterStatus != .all {
            result = result.filter { $0.status == filterStatus.rawValue }
        }
        
        // Filtre par recherche
        if !searchText.isEmpty {
            result = result.filter { project in
                project.title?.localizedCaseInsensitiveContains(searchText) == true ||
                project.client?.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return Array(result)
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredProjects[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Erreur lors de la suppression : \(error)")
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.title ?? "")
                    .font(.headline)
                Spacer()
                StatusBadge(status: project.status ?? "")
            }
            
            if let client = project.client {
                Text(client.name ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let deadline = project.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                }
                
                if let tasks = project.tasks?.count {
                    Label("\(tasks) tâches", systemImage: "checklist")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: String
    
    var color: Color {
        switch status {
        case "En cours": return .blue
        case "Terminé": return .green
        case "Annulé": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct AddProjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var details = ""
    @State private var selectedClient: Client?
    @State private var deadline = Date()
    @State private var status = "En cours"
    
    let statusOptions = ["En cours", "Terminé", "Annulé"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations générales")) {
                    TextField("Titre", text: $title)
                    TextEditor(text: $details)
                        .frame(height: 100)
                }
                
                Section(header: Text("Client")) {
                    ClientPicker(selectedClient: $selectedClient)
                }
                
                Section(header: Text("Détails")) {
                    DatePicker("Date limite",
                              selection: $deadline,
                              displayedComponents: [.date])
                    
                    Picker("Statut", selection: $status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Nouveau projet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        addProject()
                    }
                    .disabled(title.isEmpty || selectedClient == nil)
                }
            }
        }
    }
    
    private func addProject() {
        withAnimation {
            let newProject = Project(context: viewContext)
            newProject.id = UUID()
            newProject.title = title
            newProject.details = details
            newProject.client = selectedClient
            newProject.deadline = deadline
            newProject.status = status
            newProject.dateCreated = Date()
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Erreur lors de la création du projet : \(error)")
            }
        }
    }
}

struct ClientPicker: View {
    @Binding var selectedClient: Client?
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)])
    private var clients: FetchedResults<Client>
    
    var body: some View {
        Picker("Client", selection: $selectedClient) {
            Text("Sélectionner un client").tag(Client?.none)
            ForEach(clients) { client in
                Text(client.name ?? "").tag(Client?.some(client))
            }
        }
    }
}

struct ProjectDetailView: View {
    let project: Project
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isEditing = false
    
    var body: some View {
        List {
            Section(header: Text("Informations")) {
                DetailRow(title: "Client", value: project.client?.name ?? "")
                DetailRow(title: "Statut", value: project.status ?? "")
                if let deadline = project.deadline {
                    DetailRow(title: "Date limite", value: deadline.formatted())
                }
            }
            
            if let details = project.details, !details.isEmpty {
                Section(header: Text("Détails")) {
                    Text(details)
                }
            }
            
            Section(header: Text("Tâches")) {
                if let tasks = project.tasks?.allObjects as? [Task], !tasks.isEmpty {
                    ForEach(tasks) { task in
                        TaskRow(task: task)
                    }
                } else {
                    Text("Aucune tâche")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Factures")) {
                if let invoices = project.invoices?.allObjects as? [Invoice], !invoices.isEmpty {
                    ForEach(invoices) { invoice in
                        InvoiceRow(invoice: invoice)
                    }
                } else {
                    Text("Aucune facture")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(project.title ?? "Projet")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifier") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProjectView(project: project)
        }
    }
}

struct TaskRow: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : .secondary)
            
            VStack(alignment: .leading) {
                Text(task.title ?? "")
                if let deadline = task.deadline {
                    Text(deadline.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
