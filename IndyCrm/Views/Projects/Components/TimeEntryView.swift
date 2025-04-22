import SwiftUI

struct TimeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
    let task: ProjectTask
    let onSave: (ProjectTask) -> Void
    
    @State private var hours: Double = 1.0
    @State private var comment: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Ajouter du temps")) {
                VStack(alignment: .leading) {
                    Text("Tâche: \(task.title)")
                        .font(.headline)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Heures")
                    Spacer()
                    Stepper(
                        value: $hours,
                        in: 0.5...24,
                        step: 0.5
                    ) {
                        Text("\(hours, specifier: "%.1f") h")
                            .monospacedDigit()
                    }
                }
                
                DatePicker(
                    "Date",
                    selection: $date,
                    displayedComponents: [.date, .hourAndMinute]
                )
                
                VStack(alignment: .leading) {
                    Text("Commentaire")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Ajouter du temps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") {
                    saveTimeEntry()
                }
                .disabled(hours <= 0)
            }
        }
    }
    
    private func saveTimeEntry() {
        // Créer une nouvelle entrée de temps
        let timeEntry = TimeEntry(
            date: date,
            hours: hours,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Mettre à jour la tâche avec la nouvelle entrée de temps
        var updatedTask = task
        updatedTask.timeEntries.append(timeEntry)
        updatedTask.workedHours += hours
        
        // Mettre à jour la date de modification
        updatedTask.updatedAt = Date()
        
        // Appeler la closure onSave
        onSave(updatedTask)
        
        // Fermer la vue
        dismiss()
    }
}

struct TimeEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimeEntryView(
                task: ProjectTask(
                    title: "Implémenter la fonctionnalité de commentaires",
                    description: "Ajouter la possibilité pour les utilisateurs de commenter les tâches",
                    status: .inProgress,
                    priority: .high,
                    isCompleted: false,
                    estimatedHours: 8,
                    workedHours: 3.5
                ),
                onSave: { _ in }
            )
        }
    }
} 