import SwiftUI

struct ShareSheetView: View {
    let collaborationService: CollaborationService
    let contactsManager: ContactsManager
    let entityType: EntityType
    let entityId: UUID
    let entityName: String
    
    var body: some View {
        // Interface de partage
        List {
            Section("Partager avec") {
                ForEach(contactsManager.contacts) { contact in
                    Button {
                        collaborationService.share(
                            entityType: entityType,
                            entityId: entityId,
                            with: contact.id
                        )
                    } label: {
                        HStack {
                            Text(contact.fullName)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .navigationTitle("Partager \(entityName)")
    }
}

enum EntityType {
    case invoice
    case project
    case contact
}
