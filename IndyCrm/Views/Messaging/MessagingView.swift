import SwiftUI

struct MessagingView: View {
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var contactsManager: ContactsManager
    @State private var showingNewMessage = false
    @State private var searchText = ""
    @State private var showingPublicOnly = false
    
    var filteredMessages: [MessagingService.Message] {
        var messages = messagingService.messages
        
        if showingPublicOnly {
            messages = messages.filter { $0.isPublic }
        }
        
        if !searchText.isEmpty {
            messages = messages.filter {
                $0.subject.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return messages.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            Toggle("Messages publics uniquement", isOn: $showingPublicOnly)
            
            ForEach(filteredMessages) { message in
                NavigationLink(destination: MessageDetailView(message: message, contactsManager: contactsManager)) {
                    MessageRowView(message: message, contactsManager: contactsManager)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher un message")
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewMessage = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewMessage) {
            NavigationView {
                NewMessageView(messagingService: messagingService, contactsManager: contactsManager)
            }
        }
    }
}

struct MessageRowView: View {
    let message: MessagingService.Message
    @ObservedObject var contactsManager: ContactsManager
    
    var sender: Contact? {
        contactsManager.contacts.first { $0.id == message.senderId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(message.subject)
                    .font(.headline)
                Spacer()
                if message.isPublic {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text(sender?.fullName ?? "Utilisateur inconnu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(message.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !message.attachments.isEmpty {
                HStack {
                    Image(systemName: "paperclip")
                    Text("\(message.attachments.count) pièce(s) jointe(s)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
} 