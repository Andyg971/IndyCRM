import SwiftUI

public struct HelpView: View {
    @ObservedObject var helpService: HelpService
    @Environment(\.dismiss) private var dismiss
    
    public init(helpService: HelpService) {
        self.helpService = helpService
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(helpService.helpMessages) { message in
                    HelpMessageRow(message: message)
                }
            }
            .navigationTitle("Aide & Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Effacer tout") {
                        helpService.clearMessages()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpMessageRow: View {
    let message: HelpService.HelpMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: message.type.icon)
                    .foregroundColor(message.type.color)
                Text(message.title)
                    .font(.headline)
            }
            
            Text(message.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(message.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 