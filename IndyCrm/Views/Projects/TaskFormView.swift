import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var contactsManager: ContactsManager
    var editingTask: ProjectTask?
    var onSave: (ProjectTask) -> Void
    var onDelete: ((UUID) -> Void)?
    var onComplete: ((UUID) -> Void)?
    
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
    @State private var showingDeleteConfirmation = false
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var timeEntries: [TimeEntry] = []
    @State private var showingAddTimeSheet = false
    @State private var newTimeHours: Double = 1.0
    @State private var newTimeComment = ""
    
    private var isEditing: Bool { editingTask != nil }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête du formulaire avec statut
                headerView
                
                // Détails de la tâche
                taskDetailsSection
                
                // Planification
                schedulingSection
                
                // Visualisation de la progression
                progressSection
                
                // Heures travaillées
                timeEntriesSection
                
                // Paramètres
                settingsSection
                
                // Section des notes
                notesSection
                
                // BOUTON DE SUPPRESSION CLAIR ET SIMPLE
                if isEditing && onDelete != nil {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Text("Supprimer cette tâche")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 10)
                }
                
                // Boutons d'action
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? "Modifier la tâche" : "Nouvelle tâche")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                // Simplifier le menu pour n'avoir que le bouton Enregistrer
                Button("Enregistrer") {
                    saveTask()
                }
                .disabled(!isValid)
                .font(.headline)
            }
        }
        .onAppear {
            if let task = editingTask {
                loadTask(task)
            }
        }
        .alert("Confirmer la suppression", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cette tâche ? Cette action est irréversible.")
        }
        .sheet(isPresented: $showingAddTimeSheet) {
            AddTimeEntryView(hours: $newTimeHours, comment: $newTimeComment, onAdd: addTimeEntry)
        }
    }
    
    // MARK: - Section Views
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if isEditing {
                HStack {
                    StatusBadge(status: status)
                    Spacer()
                    TaskPriorityBadge(priority: priority)
                }
                .padding(.bottom, 4)
            }
            
            if isEditing && status == .done {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Tâche terminée")
                        .fontWeight(.medium)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Détails de la tâche")
                    .font(.headline)
                
                Spacer()
                
                if isEditing, let task = editingTask, let createdAt = task.createdAt {
                    Text("Créée le: \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            FormField(icon: "text.cursor", title: "Titre") {
                TextField("Titre de la tâche", text: $title)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            FormField(icon: "text.alignleft", title: "Description") {
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Planification")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Date limite
            FormField(icon: "calendar", title: "Date limite") {
                Button(action: { showingDatePicker.toggle() }) {
                    HStack {
                        if let dueDate = dueDate {
                            VStack(alignment: .leading) {
                                Text(dueDate.formatted(date: .long, time: .omitted))
                                
                                // Affichage conditionnel si la date est passée
                                if dueDate < Date() && status != .done {
                                    Text("En retard")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .cornerRadius(4)
                                }
                            }
                        } else {
                            Text("Non définie")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: dueDate == nil ? "plus.circle.fill" : "pencil.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    DatePickerView(selectedDate: $dueDate)
                }
            }
            
            // Assignation
            FormField(icon: "person.fill", title: "Assigné à") {
                Button(action: { showingContactPicker.toggle() }) {
                    HStack {
                        if let contactId = assignedTo,
                           let contact = contactsManager.contacts.first(where: { $0.id == contactId }) {
                            HStack {
                                Text(contact.fullName)
                                
                                if !contact.organization.isEmpty {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(contact.organization)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Non assigné")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: assignedTo == nil ? "plus.circle.fill" : "pencil.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
            FormField(icon: "clock.fill", title: "Heures estimées") {
                HStack {
                    TextField("Heures", value: $estimatedHours, format: .number)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if let estimatedHours = estimatedHours, editingTask != nil {
                        Spacer()
                        VStack(alignment: .trailing) {
                            let progress = min(editingTask!.workedHours / estimatedHours, 1.0)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("\(editingTask!.workedHours, specifier: "%.1f") sur \(estimatedHours, specifier: "%.1f") heures")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var progressSection: some View {
        Group {
            if isEditing, let task = editingTask, let estimatedHours = estimatedHours, estimatedHours > 0 {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Progression")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(Int(task.progress * 100))% terminé")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(task.workedHours, specifier: "%.1f") / \(estimatedHours, specifier: "%.1f") heures")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Barre de progression colorée
                        ProgressBar(value: task.progress)
                            .frame(height: 12)
                        
                        // Légende des étapes
                        HStack(spacing: 0) {
                            ForEach(TaskStatus.allCases, id: \.self) { taskStatus in
                                StatusLegendItem(status: taskStatus)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var timeEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Heures travaillées")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    newTimeHours = 1.0
                    newTimeComment = ""
                    showingAddTimeSheet = true
                }) {
                    Label("Ajouter du temps", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 4)
            
            if timeEntries.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Aucun temps enregistré")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    ForEach(timeEntries.sorted(by: { $0.date > $1.date })) { entry in
                        TimeEntryRowView(entry: entry) {
                            if let index = timeEntries.firstIndex(where: { $0.id == entry.id }) {
                                timeEntries.remove(at: index)
                            }
                        }
                    }
                }
                
                if !timeEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total: \(totalHours, specifier: "%.1f") heures")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let estimatedHours = estimatedHours, estimatedHours > 0 {
                            Text("\(Int(min(totalHours / estimatedHours, 1.0) * 100))% du temps estimé")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paramètres")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Priorité
            FormField(icon: "flag.fill", title: "Priorité") {
                Picker("", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Label(
                            priority.rawValue,
                            systemImage: priority.icon
                        )
                        .foregroundColor(priority.statusColor)
                        .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            
            // Statut
            FormField(icon: "arrow.triangle.2.circlepath", title: "Statut") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Label(
                                status.rawValue,
                                systemImage: status.icon
                            )
                            .foregroundColor(status.statusColor)
                            .tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Statut progression visuelle
                    HStack(spacing: 0) {
                        ForEach(TaskStatus.allCases, id: \.self) { taskStatus in
                            Rectangle()
                                .fill(taskStatus.statusColor)
                                .frame(height: 6)
                                .opacity(taskStatus == status ? 1.0 : 0.3)
                        }
                    }
                    .clipShape(Capsule())
                }
            }
            
            // Complétion
            Toggle(isOn: $isCompleted) {
                Label("Tâche terminée", systemImage: "checkmark.circle")
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .onChange(of: isCompleted) { _, newValue in
                if newValue {
                    status = .done
                } else if status == .done {
                    status = .inProgress
                }
            }
            .onChange(of: status) { _, newValue in
                isCompleted = (newValue == .done)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes et commentaires")
                .font(.headline)
                .padding(.bottom, 4)
            
            if comments.isEmpty {
                HStack {
                    Image(systemName: "text.bubble")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Aucun commentaire")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            } else {
                ForEach(comments) { comment in
                    CommentView(comment: comment)
                }
            }
            
            // Ajouter un nouveau commentaire
            VStack(alignment: .leading, spacing: 8) {
                Text("Ajouter un commentaire")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .top) {
                    TextEditor(text: $newComment)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    
                    Button(action: addComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isEditing {
                // Garder uniquement le bouton pour marquer comme terminé
                if status != .done && onComplete != nil {
                    Button {
                        if let task = editingTask {
                            onComplete?(task.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Marquer comme terminé")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            
            // Bouton principal pour enregistrer/créer la tâche
            Button {
                saveTask()
            } label: {
                HStack {
                    Image(systemName: isEditing ? "square.and.pencil" : "plus.circle.fill")
                        .font(.headline)
                    Text(isEditing ? "Enregistrer les modifications" : "Créer la tâche")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isValid)
            .padding(.top, isEditing ? 20 : 0)
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty
    }
    
    private var totalHours: Double {
        timeEntries.reduce(0) { $0 + $1.hours }
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
        comments = task.comments
        timeEntries = task.timeEntries
    }
    
    private func saveTask() {
        // Calculer le total des heures travaillées à partir des entrées de temps
        let totalWorkedHours = timeEntries.reduce(0) { $0 + $1.hours }
        
        // Si on édite une tâche existante, on conserve son ID
        // Sinon on en crée un nouveau
        let taskId = editingTask?.id ?? UUID()
        
        // Création de la tâche mise à jour
        let task = ProjectTask(
            id: taskId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            isCompleted: isCompleted,
            dueDate: dueDate,
            assignedTo: assignedTo,
            estimatedHours: estimatedHours,
            workedHours: totalWorkedHours,
            comments: comments,
            timeEntries: timeEntries,
            createdAt: editingTask?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        // Application de la mise à jour
        onSave(task)
        dismiss()
    }
    
    private func addComment() {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            // Création d'un nouveau commentaire
            let comment = Comment(
                id: UUID(),
                text: trimmedComment,
                date: Date(),
                authorId: UUID() // TODO: Remplacer par l'ID de l'utilisateur actuel
            )
            
            // Ajout du commentaire à la liste
            comments.append(comment)
            
            // Réinitialisation du champ de texte
            newComment = ""
        }
    }
    
    private func addTimeEntry() {
        // Création d'une nouvelle entrée de temps
        let entry = TimeEntry(
            id: UUID(),
            date: Date(),
            hours: newTimeHours,
            comment: newTimeComment
        )
        
        // Ajout de l'entrée à la liste
        timeEntries.append(entry)
        
        // Fermeture de la feuille modale
        showingAddTimeSheet = false
    }
    
    /// Gère la suppression d'une tâche en appelant le callback onDelete
    private func deleteTask() {
        if let task = editingTask {
            print("⚠️ SUPPRESSION TÂCHE: \(task.id)")
            
            guard let deleteCallback = onDelete else {
                print("❌ ERREUR: Callback onDelete est nil!")
                return
            }
            
            // Appelons la callback SANS dismiss() après
            deleteCallback(task.id)
            
            // AUCUN dismiss() ou redirection ici
        } else {
            print("❌ ERREUR: Aucune tâche à supprimer (editingTask est nil)")
        }
    }
}

// MARK: - Composants d'interface réutilisables

struct FormField<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            content
        }
    }
}

// Badge pour la priorité des tâches
struct TaskPriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        HStack {
            Image(systemName: priority.icon)
            Text(priority.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(priority.statusColor.opacity(0.2))
        .foregroundColor(priority.statusColor)
        .clipShape(Capsule())
    }
}

struct ProgressBar: View {
    var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.2)
                    .foregroundColor(.gray)
                    .cornerRadius(45)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(progressColor(for: value))
                    .cornerRadius(45)
            }
        }
    }
    
    private func progressColor(for value: Double) -> Color {
        if value < 0.25 {
            return .red
        } else if value < 0.5 {
            return .orange
        } else if value < 0.75 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct StatusLegendItem: View {
    let status: TaskStatus
    
    var body: some View {
        VStack(alignment: .center) {
            Rectangle()
                .fill(status.statusColor)
                .frame(height: 4)
            
            Text(status.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize()
                .frame(maxWidth: .infinity)
        }
    }
}

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(comment.text.prefix(1).uppercased()))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Utilisateur") // TODO: Remplacer par le nom de l'utilisateur
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(comment.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(comment.text)
                .font(.subheadline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

// Vue pour sélectionner un contact
struct ContactPickerView: View {
    let contacts: [Contact]
    @Binding var selectedContactId: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                // Simplifié pour éviter l'erreur de compilation
                contact.fullName.localizedCaseInsensitiveContains(searchText) ||
                contact.organization.localizedCaseInsensitiveContains(searchText) ||
                contact.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Rechercher un contact", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            List {
                ForEach(filteredContacts) { contact in
                    Button {
                        selectedContactId = contact.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.fullName)
                                    .fontWeight(.medium)
                                
                                if !contact.organization.isEmpty {
                                    Text(contact.organization)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if contact.id == selectedContactId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(InsetGroupedListStyle())
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
        List {
            Section {
                Toggle("Définir une date limite", isOn: $hasDate)
                    .tint(.blue)
            }
            
            if hasDate {
                Section {
                    DatePicker(
                        "Date limite",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(.blue)
                    
                    // Boutons rapides
                    HStack {
                        Button("Aujourd'hui") { date = Date() }
                            .buttonStyle(ChipButtonStyle())
                        
                        Button("Demain") { date = Calendar.current.date(byAdding: .day, value: 1, to: Date())! }
                            .buttonStyle(ChipButtonStyle())
                        
                        Button("+1 semaine") { date = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())! }
                            .buttonStyle(ChipButtonStyle())
                    }
                }
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
                .fontWeight(.bold)
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

struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color.blue : Color.blue.opacity(0.1))
            .foregroundColor(configuration.isPressed ? .white : .blue)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension String {
    var isNotEmpty: Bool {
        !self.isEmpty
    }
}

struct TimeEntryRowView: View {
    let entry: TimeEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.date.formatted(date: .numeric, time: .shortened))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !entry.comment.isEmpty {
                    Text(entry.comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text("\(entry.hours, specifier: "%.1f") h")
                .font(.headline)
                .foregroundColor(.blue)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AddTimeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hours: Double
    @Binding var comment: String
    let onAdd: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Temps travaillé")) {
                    Stepper(value: $hours, in: 0.1...24, step: 0.5) {
                        HStack {
                            Text("Heures:")
                            Spacer()
                            Text("\(hours, specifier: "%.1f")")
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        ForEach([0.5, 1.0, 2.0, 4.0, 8.0], id: \.self) { value in
                            Button("\(Int(value)) h") {
                                hours = value
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                }
                
                Section(header: Text("Commentaire (optionnel)")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Ajouter du temps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        onAdd()
                    }
                    .bold()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TaskFormView(
            contactsManager: ContactsManager(),
            onSave: { _ in },
            onDelete: { _ in },
            onComplete: { _ in }
        )
    }
} 
