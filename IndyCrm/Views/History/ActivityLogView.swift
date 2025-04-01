import SwiftUI

struct ActivityLogView: View {
    @ObservedObject var activityLogService: ActivityLogService
    @ObservedObject var contactsManager: ContactsManager
    let entityType: ActivityLog.EntityType
    let entityId: UUID
    
    var logs: [ActivityLog] {
        activityLogService.logsForEntity(type: entityType, id: entityId)
    }
    
    var body: some View {
        List(logs) { log in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: iconForAction(log.action))
                        .foregroundColor(colorForAction(log.action))
                    Text(log.action.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !log.details.isEmpty {
                    Text(log.details)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let user = contactsManager.contacts.first(where: { $0.id == log.userId }) {
                    Text("Par \(user.fullName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Historique")
    }
    
    private func iconForAction(_ action: ActivityLog.Action) -> String {
        switch action {
        case .created: return "plus.circle"
        case .updated: return "pencil"
        case .deleted: return "trash"
        case .statusChanged: return "arrow.triangle.2.circlepath"
        }
    }
    
    private func colorForAction(_ action: ActivityLog.Action) -> Color {
        switch action {
        case .created: return .green
        case .updated: return .blue
        case .deleted: return .red
        case .statusChanged: return .orange
        }
    }
} 