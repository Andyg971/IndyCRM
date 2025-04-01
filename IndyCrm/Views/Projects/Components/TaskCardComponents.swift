import SwiftUI

struct TaskCardHeader: View {
    let title: String
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .strokeBorder(isCompleted ? Color.green : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct TaskDescription: View {
    let description: String
    
    var body: some View {
        Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
    }
}

struct TaskMetadata: View {
    let task: ProjectTask
    let contactsManager: ContactsManager
    
    var body: some View {
        HStack(spacing: 12) {
            if let assignedContact = task.assignedTo.flatMap({ id in
                contactsManager.contacts.first { $0.id == id }
            }) {
                Label(assignedContact.fullName, systemImage: "person.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let dueDate = task.dueDate {
                Label(dueDate.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TaskProgress: View {
    let task: ProjectTask
    let estimatedHours: Double
    @Binding var showingTimeSheet: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ProgressView(value: task.progress)
                .tint(progressColor(for: task.progress))
            
            HStack {
                Button(action: { showingTimeSheet = true }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("\(Int(task.workedHours))h / \(Int(estimatedHours))h")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(task.progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(progressColor(for: task.progress))
            }
        }
    }
    
    private func progressColor(for value: Double) -> Color {
        switch value {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
} 