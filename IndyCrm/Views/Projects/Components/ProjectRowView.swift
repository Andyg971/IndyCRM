import SwiftUI

struct ProjectRowView: View {
    let project: Project
    let contact: Contact?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let contact = contact {
                        Text(contact.fullName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: project.status)
            }
            
            // Barre de progression mise à jour
            if !project.tasks.isEmpty {
                ModernProgressBar(
                    progress: project.progress,
                    isPaused: project.status == .onHold
                )
                .frame(height: 16)
            }
            
            // Dates et tâches
            HStack(spacing: 16) {
                Label("\(project.tasks.count) tâches", systemImage: "checklist")
                
                if let deadline = project.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 