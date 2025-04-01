import SwiftUI

struct TaskCard: View {
    let task: ProjectTask
    let project: Project
    let contactsManager: ContactsManager
    @State private var isCompleted: Bool
    @State private var showingTimeSheet = false
    let onTaskStatusChanged: (Bool) -> Void
    let onTaskUpdated: (ProjectTask) -> Void
    
    init(task: ProjectTask, project: Project, contactsManager: ContactsManager, onTaskStatusChanged: @escaping (Bool) -> Void, onTaskUpdated: @escaping (ProjectTask) -> Void) {
        self.task = task
        self.project = project
        self.contactsManager = contactsManager
        self._isCompleted = State(initialValue: task.isCompleted)
        self.onTaskStatusChanged = onTaskStatusChanged
        self.onTaskUpdated = onTaskUpdated
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TaskCardHeader(
                title: task.title,
                isCompleted: isCompleted,
                onToggleComplete: {
                    withAnimation(.spring(response: 0.3)) {
                        isCompleted.toggle()
                        onTaskStatusChanged(isCompleted)
                    }
                }
            )
            
            if !task.description.isEmpty {
                TaskDescription(description: task.description)
            }
            
            TaskMetadata(task: task, contactsManager: contactsManager)
            
            if let estimatedHours = task.estimatedHours {
                TaskProgress(
                    task: task,
                    estimatedHours: estimatedHours,
                    showingTimeSheet: $showingTimeSheet
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .sheet(isPresented: $showingTimeSheet) {
            NavigationView {
                TimeEntryView(task: task, onSave: onTaskUpdated)
            }
        }
    }
} 