import SwiftUI

struct MessageDetailView: View {
    let message: MessagingService.Message
    @ObservedObject var contactsManager: ContactsManager
    
    var sender: Contact? {
        contactsManager.contacts.first { $0.id == message.senderId }
    }
    
    var recipients: [Contact] {
        message.recipientIds.compactMap { id in
            contactsManager.contacts.first { $0.id == id }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Détails")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.subject)
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text("De: \(sender?.fullName ?? "Utilisateur inconnu")")
                        Spacer()
                        Text(message.date.formatted())
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    if !message.isPublic {
                        Text("À: \(recipients.map { $0.fullName }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Text(message.content)
                    .font(.body)
            }
            
            if !message.attachments.isEmpty {
                Section(header: Text("Pièces jointes")) {
                    ForEach(message.attachments) { attachment in
                        AttachmentRow(attachment: attachment)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Répondre") {
                        // Implémenter la réponse
                    }
                    
                    Button("Transférer") {
                        // Implémenter le transfert
                    }
                    
                    if !message.isPublic {
                        Button("Rendre public") {
                            // Implémenter le changement de visibilité
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct AttachmentRow: View {
    let attachment: MessagingService.Attachment
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
            VStack(alignment: .leading) {
                Text(attachment.name)
                Text(attachment.url.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { openAttachment() }) {
                Image(systemName: "arrow.down.circle")
            }
        }
    }
    
    var iconName: String {
        switch attachment.type {
        case .document: return "doc"
        case .image: return "photo"
        case .pdf: return "doc.text"
        }
    }
    
    private func openAttachment() {
        // Implémenter l'ouverture de la pièce jointe
    }
} 