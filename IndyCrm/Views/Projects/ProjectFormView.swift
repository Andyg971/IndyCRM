import SwiftUI

struct ProjectFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    
    // Form fields
    @State private var name = ""
    @State private var selectedClientId: UUID?
    @State private var startDate = Date()
    @State private var deadline: Date?
    @State private var status = ProjectStatus.inProgress
    @State private var notes = ""
    @State private var hasDeadline = false
    
    // Editing mode
    var editingProject: Project?
    
    init(projectManager: ProjectManager, contactsManager: ContactsManager, editingProject: Project? = nil) {
        self.projectManager = projectManager
        self.contactsManager = contactsManager
        self.editingProject = editingProject
        
        if let project = editingProject {
            _name = State(initialValue: project.name)
            _selectedClientId = State(initialValue: project.clientId)
            _startDate = State(initialValue: project.startDate)
            _deadline = State(initialValue: project.deadline)
            _hasDeadline = State(initialValue: project.deadline != nil)
            _status = State(initialValue: project.status)
            _notes = State(initialValue: project.notes)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Informations du projet")) {
                TextField("Nom du projet", text: $name)
                
                Picker("Client", selection: $selectedClientId) {
                    Text("Sélectionner un client")
                        .tag(Optional<UUID>.none)
                    ForEach(contactsManager.contacts.filter { $0.type == .client }) { contact in
                        Text(contact.fullName)
                            .tag(Optional(contact.id))
                    }
                }
                
                DatePicker(
                    "Date de début",
                    selection: $startDate,
                    displayedComponents: .date
                )
                
                Toggle("Date limite", isOn: $hasDeadline)
                    .onChange(of: hasDeadline, initial: false) { oldValue, newValue in
                        if newValue && deadline == nil {
                            deadline = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
                        } else if !newValue {
                            deadline = nil
                        }
                    }
                
                if hasDeadline {
                    DatePicker(
                        "Échéance",
                        selection: Binding(
                            get: { deadline ?? Date() },
                            set: { newDate in
                                if newDate >= startDate {
                                    deadline = newDate
                                }
                            }
                        ),
                        in: startDate...,
                        displayedComponents: .date
                    )
                }
                
                Picker("Statut", selection: $status) {
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
            
            Section {
                Button(action: saveProject) {
                    Text(editingProject == nil ? "Créer le projet" : "Mettre à jour")
                        .frame(maxWidth: .infinity)
                }
                .disabled(name.isEmpty || selectedClientId == nil)
            }
        }
        .navigationTitle(editingProject == nil ? "Nouveau projet" : "Modifier le projet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveProject() {
        let project = Project(
            id: editingProject?.id ?? UUID(),
            name: name,
            clientId: selectedClientId ?? UUID(),
            startDate: startDate,
            deadline: hasDeadline ? deadline : nil,
            status: status,
            tasks: editingProject?.tasks ?? [],
            notes: notes
        )
        
        if editingProject != nil {
            projectManager.updateProject(project)
        } else {
            projectManager.addProject(project)
        }
        
        dismiss()
    }
}

#Preview {
    NavigationView {
        ProjectFormView(
            projectManager: ProjectManager(),
            contactsManager: ContactsManager()
        )
    }
}
