import SwiftUI

struct TimeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let task: ProjectTask
    let onSave: (ProjectTask) -> Void
    
    @State private var additionalHours: Double = 0
    @State private var showingAlert = false
    @State private var comment: String = ""
    @State private var selectedTimeEntry: TimeEntry?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            TimeEntryInputSection(
                task: task,
                additionalHours: $additionalHours,
                comment: $comment
            )
            
            if !task.timeEntries.isEmpty {
                TimeEntryHistorySection(
                    task: task,
                    selectedTimeEntry: $selectedTimeEntry,
                    showingDeleteAlert: $showingDeleteAlert
                )
            }
            
            Section {
                Button(action: saveTime) {
                    Text("Enregistrer le temps")
                        .frame(maxWidth: .infinity)
                }
                .disabled(additionalHours == 0)
            }
        }
        .navigationTitle("Gestion du temps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
        .alert("Dépassement du temps estimé", isPresented: $showingAlert) {
            Button("Continuer", role: .destructive) {
                saveTimeForced()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Le temps total dépassera le temps estimé. Voulez-vous continuer ?")
        }
        .alert("Supprimer l'entrée ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                if let entry = selectedTimeEntry {
                    deleteTimeEntry(entry)
                }
            }
        }
    }
    
    private func saveTime() {
        if let estimated = task.estimatedHours,
           task.workedHours + additionalHours > estimated {
            showingAlert = true
            return
        }
        saveTimeForced()
    }
    
    private func saveTimeForced() {
        var updatedTask = task
        updatedTask.workedHours += additionalHours
        
        let entry = TimeEntry(
            hours: additionalHours,
            comment: comment
        )
        updatedTask.timeEntries.append(entry)
        
        onSave(updatedTask)
        dismiss()
    }
    
    private func deleteTimeEntry(_ entry: TimeEntry) {
        var updatedTask = task
        updatedTask.timeEntries.removeAll { $0.id == entry.id }
        updatedTask.workedHours -= entry.hours
        onSave(updatedTask)
    }
} 