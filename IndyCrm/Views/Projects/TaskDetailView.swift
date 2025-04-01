import SwiftUI

struct TaskDetailView: View {
    let task: ProjectTask
    let project: Project
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var newCommentText = ""
    
    var assignedContact: Contact? {
        task.assignedTo.flatMap { id in
            contactsManager.contacts.first { $0.id == id }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Détails")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        // Bouton de complétion modernisé
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
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let contact = assignedContact {
                    LabeledContent("Assigné à", value: contact.fullName)
                }
                
                if let dueDate = task.dueDate {
                    LabeledContent("Date limite", value: dueDate.formatted(date: .long, time: .omitted))
                }
                
                // Statut de la tâche
                HStack {
                    Text("Statut")
                    Spacer()
                    StatusBadge(status: task.status)
                }
            }
            
            Section(header: Text("Commentaires")) {
                ForEach(task.comments) { comment in
                    CommentRow(
                        comment: comment,
                        author: contactsManager.contacts.first { $0.id == comment.authorId }
                    )
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
    
    private func addComment() {
        guard !newCommentText.isEmpty else { return }
        
        var updatedTask = task
        let comment = Comment(
            id: UUID(),
            text: newCommentText,
            date: Date(),
            authorId: UUID() // À remplacer par l'ID de l'utilisateur actuel
        )
        updatedTask.comments.append(comment)
        updateTask(updatedTask)
        newCommentText = ""
    }
    
    private func updateTask(_ updatedTask: ProjectTask) {
        var updatedProject = project
        if let index = updatedProject.tasks.firstIndex(where: { $0.id == task.id }) {
            updatedProject.tasks[index] = updatedTask
            projectManager.updateProject(updatedProject)
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let author: Contact?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(author?.fullName ?? "Utilisateur inconnu")
                    .font(.headline)
                Spacer()
                Text(comment.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.text)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
} 