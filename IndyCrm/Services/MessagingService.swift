import Foundation
import MessageUI

@MainActor
class MessagingService: ObservableObject {
    @Published private(set) var messages: [Message] = []
    private let saveKey = "SavedMessages"
    
    struct Message: Identifiable, Codable {
        var id: UUID
        var senderId: UUID
        var recipientIds: [UUID]
        var subject: String
        var content: String
        var date: Date
        var isPublic: Bool
        var attachments: [Attachment]
    }
    
    struct Attachment: Identifiable, Codable {
        var id: UUID
        var name: String
        var url: URL
        var type: AttachmentType
    }
    
    enum AttachmentType: String, Codable {
        case document, image, pdf
    }
    
    func sendMessage(_ message: Message) {
        messages.append(message)
        saveMessages()
        
        if !message.isPublic {
            sendEmailNotification(for: message)
        }
    }
    
    private func sendEmailNotification(for message: Message) {
        // Implémenter l'envoi d'email via MessageUI
    }
    
    private func saveMessages() {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Erreur de sauvegarde des messages: \(error)")
        }
    }
    
    // ... Autres méthodes de gestion des messages
} 