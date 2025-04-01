import SwiftUI

struct AlertsView: View {
    @ObservedObject var alertService: AlertService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(alertService.currentAlerts) { alert in
                    AlertRow(alert: alert)
                        .swipeActions {
                            Button {
                                alertService.markAsRead(alert.id)
                            } label: {
                                Label("Marquer comme lu", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                }
            }
            .navigationTitle("Alertes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: AlertService.Alert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(alert.severity.color)
                    .frame(width: 8, height: 8)
                
                Text(alert.title)
                    .font(.headline)
                
                Spacer()
                
                if !alert.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(alert.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(alert.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .opacity(alert.isRead ? 0.6 : 1)
    }
} 