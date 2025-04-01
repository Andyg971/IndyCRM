import SwiftUI

struct TaskRowView: View {
    let task: ProjectTask
    let onToggleComplete: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Bouton de complétion
                Button(action: {
                    onToggleComplete(!task.isCompleted)
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .font(.system(size: 20))
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Prévisualisation
#Preview {
    TaskRowView(
        task: ProjectTask(
            title: "Tâche exemple",
            description: "Description de la tâche"
        ),
        onToggleComplete: { _ in }
    )
} 