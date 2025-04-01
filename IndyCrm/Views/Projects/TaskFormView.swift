import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var contactsManager: ContactsManager
    var editingTask: ProjectTask?
    var onSave: (ProjectTask) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate: Date?
    @State private var assignedTo: UUID?
    @State private var estimatedHours: Double?
    @State private var priority: Priority = .medium
    @State private var status: TaskStatus = .todo
    @State private var isCompleted = false
    @State private var showingContactPicker = false
    @State private var showingDatePicker = false
    
    private var isEditing: Bool { editingTask != nil }
    
    var body: some View {
        Form {
            Section(header: Text("Détails de la tâche")) {
                TextField("Titre", text: $title)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Section(header: Text("Planification")) {
                // Date limite
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Date limite")
                            .font(.subheadline)
                        
                        if let dueDate = dueDate {
                            Text(dueDate.formatted(date: .long, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Non définie")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showingDatePicker.toggle() }) {
                        Image(systemName: dueDate == nil ? "plus.circle.fill" : "pencil.circle.fill")
                    }
                }
                .sheet(isPresented: $showingDatePicker) {
                    NavigationView {
                        DatePickerView(selectedDate: $dueDate)
                    }
                }
                
                // Assignation
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Assigné à")
                            .font(.subheadline)
                        
                        if let contactId = assignedTo,
                           let contact = contactsManager.contacts.first(where: { $0.id == contactId }) {
                            Text(contact.fullName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Non assigné")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showingContactPicker.toggle() }) {
                        Image(systemName: assignedTo == nil ? "plus.circle.fill" : "pencil.circle.fill")
                    }
                }
                .sheet(isPresented: $showingContactPicker) {
                    NavigationView {
                        ContactPickerView(
                            contacts: contactsManager.contacts,
                            selectedContactId: $assignedTo
                        )
                    }
                }
                
                // Heures estimées
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    
                    TextField("Heures estimées", value: $estimatedHours, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            
            Section(header: Text("Paramètres")) {
                // Priorité
                Picker("Priorité", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Label(
                            priority.rawValue,
                            systemImage: priority.icon
                        )
                        .foregroundColor(priority.statusColor)
                        .tag(priority)
                    }
                }
                
                // Statut
                Picker("Statut", selection: $status) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Label(
                            status.rawValue,
                            systemImage: status.icon
                        )
                        .foregroundColor(status.statusColor)
                        .tag(status)
                    }
                }
                
                // Complétion
                Toggle("Tâche terminée", isOn: $isCompleted)
            }
        }
        .navigationTitle(isEditing ? "Modifier la tâche" : "Nouvelle tâche")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Enregistrer") {
                    saveTask()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if let task = editingTask {
                loadTask(task)
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty
    }
    
    private func loadTask(_ task: ProjectTask) {
        title = task.title
        description = task.description
        dueDate = task.dueDate
        assignedTo = task.assignedTo
        estimatedHours = task.estimatedHours
        priority = task.priority
        status = task.status
        isCompleted = task.isCompleted
    }
    
    private func saveTask() {
        let task = ProjectTask(
            id: editingTask?.id ?? UUID(),
            title: title,
            description: description,
            status: status,
            priority: priority,
            isCompleted: isCompleted,
            dueDate: dueDate,
            assignedTo: assignedTo,
            estimatedHours: estimatedHours,
            workedHours: editingTask?.workedHours ?? 0,
            comments: editingTask?.comments ?? []
        )
        onSave(task)
        dismiss()
    }
}

// Vue pour sélectionner un contact
struct ContactPickerView: View {
    let contacts: [Contact]
    @Binding var selectedContactId: UUID?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List(contacts) { contact in
            Button {
                selectedContactId = contact.id
                dismiss()
            } label: {
                HStack {
                    Text(contact.fullName)
                    Spacer()
                    if contact.id == selectedContactId {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)
        }
        .navigationTitle("Sélectionner un contact")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
    }
}

// Vue pour sélectionner une date
struct DatePickerView: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var hasDate = false
    
    var body: some View {
        Form {
            Toggle("Définir une date limite", isOn: $hasDate)
            
            if hasDate {
                DatePicker(
                    "Date limite",
                    selection: $date,
                    displayedComponents: .date
                )
            }
        }
        .navigationTitle("Choisir une date")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Valider") {
                    selectedDate = hasDate ? date : nil
                    dismiss()
                }
            }
        }
        .onAppear {
            if let existingDate = selectedDate {
                date = existingDate
                hasDate = true
            }
        }
    }
}

#Preview {
    NavigationView {
        TaskFormView(
            contactsManager: ContactsManager(),
            onSave: { _ in }
        )
    }
} 
