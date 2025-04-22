import SwiftUI

struct TaskDetailView: View {
    let task: ProjectTask
    let project: Project
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var showingTimeEntrySheet = false
    @State private var newCommentText = ""
    
    var assignedContact: Contact? {
        task.assignedTo.flatMap { id in
            contactsManager.contacts.first { $0.id == id }
        }
    }
    
    var body: some View {
        List {
            // Informations principales
            Section(header: Text("Détails")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        // Bouton de complétion
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                toggleTaskCompletion()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(task.isCompleted ? Color.green : Color.clear)
                                    .frame(width: 24, height: 24)
                                
                                Circle()
                                    .strokeBorder(task.isCompleted ? Color.green : Color.gray, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if task.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    HStack {
                        Label {
                            Text(task.status.statusTitle)
                        } icon: {
                            Image(systemName: task.status.icon)
                                .foregroundColor(task.status.statusColor)
                        }
                        .font(.subheadline)
                        
                        Spacer()
                        
                        Label {
                            Text(task.priority.statusTitle)
                        } icon: {
                            Image(systemName: task.priority.icon)
                                .foregroundColor(task.priority.statusColor)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.body)
                            .padding(.vertical, 8)
                    }
                }
            }
            
            // Informations supplémentaires
            Section(header: Text("Informations")) {
                if let assignedContact = assignedContact {
                    InfoRow(title: "Assigné à", value: assignedContact.fullName, fontStyle: .subheadline)
                }
                
                if let dueDate = task.dueDate {
                    InfoRow(title: "Date d'échéance", value: dueDate.formatted(date: .long, time: .omitted), fontStyle: .subheadline)
                }
                
                if let estimatedHours = task.estimatedHours {
                    InfoRow(title: "Temps estimé", value: "\(estimatedHours.formatted()) h", fontStyle: .subheadline)
                }
                
                InfoRow(title: "Temps travaillé", value: "\(task.workedHours.formatted()) h", fontStyle: .subheadline)
                
                Button(action: {
                    showingTimeEntrySheet = true
                }) {
                    Label("Ajouter du temps", systemImage: "clock.arrow.circlepath")
                }
            }
            
            // Section des entrées de temps
            if !task.timeEntries.isEmpty {
                Section(header: Text("Entrées de temps")) {
                    ForEach(task.timeEntries.sorted(by: { $0.date > $1.date })) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(entry.hours.formatted()) heures")
                                    .font(.subheadline)
                                
                                if !entry.comment.isEmpty {
                                    Text(entry.comment)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Section des commentaires
            Section(header: Text("Commentaires")) {
                if task.comments.isEmpty {
                    Text("Aucun commentaire")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(task.comments.sorted(by: { $0.date > $1.date })) { comment in
                        CommentRow(
                            comment: comment,
                            author: contactsManager.contacts.first { $0.id == comment.authorId }
                        )
                    }
                }
                
                HStack {
                    TextField("Ajouter un commentaire", text: $newCommentText)
                    Button("Envoyer") {
                        addComment()
                    }
                    .disabled(newCommentText.isEmpty)
                }
            }
        }
        .navigationTitle("Tâche")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Modifier") {
                        showingEditSheet = true
                    }
                    
                    Button(task.isCompleted ? "Marquer comme non terminée" : "Marquer comme terminée") {
                        toggleTaskCompletion()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                TaskFormView(
                    contactsManager: contactsManager,
                    editingTask: task
                ) { updatedTask in
                    updateTask(updatedTask)
                }
                .navigationTitle("Modifier la tâche")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showingTimeEntrySheet) {
            NavigationView {
                TimeEntryView(task: task) { updatedTask in
                    updateTask(updatedTask)
                }
                .navigationTitle("Ajouter du temps")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        if updatedTask.isCompleted {
            updatedTask.status = .done
        } else if updatedTask.status == .done {
            updatedTask.status = .inProgress
        }
        updateTask(updatedTask)
    }
    
    private func updateTask(_ updatedTask: ProjectTask) {
        var updatedProject = project
        if let index = updatedProject.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            updatedProject.tasks[index] = updatedTask
            Task {
                // Mettre à jour le projet dans le ProjectManager
                await projectManager.updateProject(updatedProject)
            }
        }
    }
    
    private func addComment() {
        guard !newCommentText.isEmpty else { return }
        
        // Créer un nouveau commentaire
        let comment = Comment(
            text: newCommentText,
            // Utilisez l'ID utilisateur actuel ou un ID par défaut si non disponible
            authorId: UUID() // Dans un environnement réel, utilisez l'ID de l'utilisateur connecté
        )
        
        // Mettre à jour la tâche avec le nouveau commentaire
        var updatedTask = task
        updatedTask.comments.append(comment)
        updateTask(updatedTask)
        
        // Réinitialiser le champ de texte
        newCommentText = ""
    }
}

struct CommentRow: View {
    let comment: Comment
    let author: Contact?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(author?.fullName ?? "Utilisateur inconnu")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(comment.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.text)
                .font(.body)
                .padding(.vertical, 2)
        }
        .padding(.vertical, 4)
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(
                task: ProjectTask(
                    title: "Implémenter la fonctionnalité de commentaires",
                    description: "Ajouter la possibilité pour les utilisateurs de commenter les tâches",
                    status: .inProgress,
                    priority: .high,
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(86400 * 3),
                    estimatedHours: 8,
                    workedHours: 3.5,
                    comments: [
                        Comment(text: "J'ai commencé à travailler sur cette fonctionnalité", authorId: UUID())
                    ],
                    timeEntries: [
                        TimeEntry(hours: 2.5, comment: "Mise en place de la structure")
                    ]
                ),
                project: Project(
                    name: "Application mobile",
                    clientId: UUID(),
                    startDate: Date()
                ),
                projectManager: ProjectManager(),
                contactsManager: ContactsManager()
            )
        }
    }
} 