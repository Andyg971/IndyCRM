import SwiftUI

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var contactsManager: ContactsManager
    
    @State private var subject = ""
    @State private var content = ""
    @State private var selectedRecipientIds: Set<UUID> = []
    @State private var isPublic = false
    @State private var attachments: [MessagingService.Attachment] = []
    @State private var showingAttachmentPicker = false
    
    var body: some View {
        Form {
            Section(header: Text("Message")) {
                TextField("Sujet", text: $subject)
                
                Toggle("Message public", isOn: $isPublic)
                
                if !isPublic {
                    NavigationLink("Destinataires (\(selectedRecipientIds.count))") {
                        RecipientSelectionView(
                            selectedIds: $selectedRecipientIds,
                            contacts: contactsManager.contacts
                        )
                    }
                }
            }
            
            Section {
                TextEditor(text: $content)
                    .frame(minHeight: 200)
            }
            
            Section(header: HStack {
                Text("Pièces jointes")
                Spacer()
                Button(action: { showingAttachmentPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }) {
                ForEach(attachments) { attachment in
                    AttachmentRow(attachment: attachment)
                }
                .onDelete { indexSet in
                    attachments.remove(atOffsets: indexSet)
                }
            }
        }
        .navigationTitle("Nouveau message")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Envoyer") {
                    sendMessage()
                }
                .disabled(!isValid)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAttachmentPicker) {
            // Implémenter le sélecteur de fichiers
        }
    }
    
    private var isValid: Bool {
        !subject.isEmpty && !content.isEmpty && (isPublic || !selectedRecipientIds.isEmpty)
    }
    
    private func sendMessage() {
        let message = MessagingService.Message(
            id: UUID(),
            senderId: UUID(), // À remplacer par l'ID de l'utilisateur actuel
            recipientIds: Array(selectedRecipientIds),
            subject: subject,
            content: content,
            date: Date(),
            isPublic: isPublic,
            attachments: attachments
        )
        
        messagingService.sendMessage(message)
        dismiss()
    }
}

struct RecipientSelectionView: View {
    @Binding var selectedIds: Set<UUID>
    let contacts: [Contact]
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredContacts) { contact in
            Button(action: { toggleSelection(contact.id) }) {
                HStack {
                    Text(contact.fullName)
                    Spacer()
                    if selectedIds.contains(contact.id) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher un contact")
        .navigationTitle("Sélectionner les destinataires")
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
} 