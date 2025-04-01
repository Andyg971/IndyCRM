import Foundation
import SwiftUI

@MainActor
public class ContactsManager: ObservableObject {
    @Published public private(set) var contacts: [Contact] = []
    private let saveKey = "SavedContacts"
    
    public init() {
        loadContacts()
    }
    
    private var saveURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("\(saveKey).json")
    }
    
    private func loadContacts() {
        do {
            let data = try Data(contentsOf: saveURL)
            contacts = try JSONDecoder().decode([Contact].self, from: data)
        } catch {
            contacts = []
            print("Erreur de chargement des contacts: \(error)")
        }
    }
    
    private func saveContacts() {
        do {
            let data = try JSONEncoder().encode(contacts)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Erreur de sauvegarde des contacts: \(error)")
        }
    }
    
    public func addContact(_ contact: Contact) {
        contacts.append(contact)
        saveContacts()
    }
    
    public func updateContact(_ contact: Contact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
            saveContacts()
        }
    }
    
    public func deleteContact(_ contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
    
    public func deleteContacts(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
        saveContacts()
    }
    
    @MainActor
    public func canDeleteContact(_ contact: Contact, projectManager: ProjectManager) -> Bool {
        // Vérifier si le contact est utilisé dans des projets
        for project in projectManager.projects {
            // Contact est client du projet
            if project.clientId == contact.id {
                return false
            }
            
            // Contact est assigné à une tâche
            if project.tasks.contains(where: { $0.assignedTo == contact.id }) {
                return false
            }
            
            // Contact est assigné à un jalon
            if project.milestones.contains(where: { $0.assignedToContactId == contact.id }) {
                return false
            }
        }
        
        return true
    }
    
    @MainActor
    public func safeDeleteContact(_ contact: Contact, projectManager: ProjectManager) -> Bool {
        if canDeleteContact(contact, projectManager: projectManager) {
            withAnimation {
                deleteContact(contact)
            }
            return true
        }
        return false
    }
} 