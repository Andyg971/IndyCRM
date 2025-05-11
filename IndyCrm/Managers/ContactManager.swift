import Foundation
import SwiftUI

@MainActor
public class ContactsManager: ObservableObject {
    @Published public private(set) var contacts: [Contact] = []
    private let saveKey = "SavedContacts"
    
    // Ajout du CacheService
    private let cacheService = CacheService.shared
    private let cacheKey = "CachedContacts" // Clé pour le cache
    
    public init() {
        // Ne plus charger ici, le chargement se fera à la demande avec cache
        // loadContacts()
        
        // Charger les contacts au démarrage (avec cache)
        Task {
            await loadContacts()
        }
    }
    
    private var saveURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("\(saveKey).json")
    }
    
    // Rendre la fonction de chargement asynchrone pour le cache
    public func loadContacts() async {
        // 1. Essayer de charger depuis le cache
        do {
            let cachedContacts: [Contact] = try cacheService.object(forKey: cacheKey)
            self.contacts = cachedContacts
            print("👤 Contacts chargés depuis le cache")
            return // Sortir si chargé depuis le cache
        } catch {
            print("👤 Cache des contacts non trouvé ou expiré: \(error.localizedDescription)")
        }

        // 2. Charger depuis le fichier si le cache est vide ou invalide
        do {
            let data = try Data(contentsOf: saveURL)
            let loadedContacts = try JSONDecoder().decode([Contact].self, from: data)
            self.contacts = loadedContacts
            print("👤 Contacts chargés depuis le fichier")

            // 3. Mettre les contacts chargés dans le cache
            try cacheService.cache(loadedContacts, forKey: cacheKey)
            print("👤 Contacts mis en cache")

        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            // Si le fichier n'existe pas (premier lancement)
            self.contacts = []
            print("👤 Fichier \(saveKey).json non trouvé, initialisation à vide.")
        } catch {
            // Autre erreur de chargement
            self.contacts = []
            print("Erreur de chargement des contacts depuis le fichier: \(error)")
        }
    }

    // Rendre la fonction de sauvegarde asynchrone pour le cache
    private func saveContacts() async {
        do {
            // Sauvegarde sur disque
            let data = try JSONEncoder().encode(contacts)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
            print("👤 Contacts sauvegardés sur disque")

            // Mise à jour du cache
            try cacheService.cache(contacts, forKey: cacheKey)
            print("👤 Cache des contacts mis à jour")
        } catch {
            print("Erreur de sauvegarde des contacts: \(error)")
        }
    }
    
    public func addContact(_ contact: Contact) async {
        contacts.append(contact)
        await saveContacts()
    }
    
    public func updateContact(_ contact: Contact) async {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
            await saveContacts()
        }
    }
    
    public func deleteContact(_ contact: Contact) async {
        // Suppression définitive du contact de la collection
        contacts.removeAll { $0.id == contact.id }
        
        // Sauvegarde immédiate des changements dans le stockage persistant
        // Pas de soft delete, les données sont complètement supprimées
        await saveContacts()
        
        // Invalider explicitement le cache pour assurer que les données supprimées ne sont pas rechargées
        cacheService.invalidateCache(forKey: cacheKey)
        print("👤 Cache des contacts invalidé après suppression")
    }
    
    public func deleteContacts(at offsets: IndexSet) async {
        contacts.remove(atOffsets: offsets)
        await saveContacts()
        
        // Invalider explicitement le cache pour assurer que les données supprimées ne sont pas rechargées
        cacheService.invalidateCache(forKey: cacheKey)
        print("👤 Cache des contacts invalidé après suppression multiple")
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
    public func safeDeleteContact(_ contact: Contact, projectManager: ProjectManager) async -> Bool {
        if canDeleteContact(contact, projectManager: projectManager) {
            Task {
                await deleteContact(contact)
            }
            return true
        }
        return false
    }
    
    // --- Ajout des fonctions pour BackupService ---

    /// Retourne les données brutes des contacts pour la sauvegarde
    func getContactsDataForBackup() throws -> Data {
        return try JSONEncoder().encode(contacts)
    }

    /// Remplace les contacts actuels avec les données restaurées et met à jour le cache
    func restoreContacts(from data: Data) async throws {
        let restoredContacts = try JSONDecoder().decode([Contact].self, from: data)
        self.contacts = restoredContacts
        // Sauvegarder immédiatement les contacts restaurés sur disque et dans le cache
        await saveContacts()
        print("👤 Contacts restaurés depuis la sauvegarde")
    }

    /// Supprime un contact et toutes ses données associées (projets, factures)
    public func deleteContactAndCascade(_ contact: Contact, projectManager: ProjectManager, invoiceManager: InvoiceManager) async {
        // 1. Supprimer toutes les factures liées à ce contact
        let invoicesToDelete = invoiceManager.invoices.filter { $0.clientId == contact.id }
        for invoice in invoicesToDelete {
            await invoiceManager.deleteInvoice(invoice)
        }
        // 2. Supprimer tous les projets liés à ce contact
        let projectsToDelete = projectManager.projects.filter { $0.clientId == contact.id }
        for project in projectsToDelete {
            await projectManager.deleteProject(project)
        }
        // 3. Supprimer le contact lui-même
        await deleteContact(contact)
    }
} 