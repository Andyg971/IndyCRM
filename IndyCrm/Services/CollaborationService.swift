import Foundation
import SwiftUI

@MainActor
public class CollaborationService: ObservableObject {
    @Published public private(set) var collaborations: [Collaboration] = []
    private let saveKey = "SavedCollaborations"
    
    @Published private(set) var sharedItems: [UUID: Set<UUID>] = [:]  // [entityId: Set<contactId>]
    
    private let fileManager = FileManager.default
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let savedCollaborationsURL: URL
    
    public init() {
        savedCollaborationsURL = documentsPath.appendingPathComponent("SavedCollaborations.json")
        createInitialFileIfNeeded()
        loadCollaborations()
    }
    
    private func createInitialFileIfNeeded() {
        if !fileManager.fileExists(atPath: savedCollaborationsURL.path) {
            do {
                let emptyCollaborations: [Collaboration] = []
                let data = try JSONEncoder().encode(emptyCollaborations)
                try data.write(to: savedCollaborationsURL)
            } catch {
                print("Erreur lors de la création du fichier initial SavedCollaborations.json: \(error)")
            }
        }
    }
    
    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(saveKey).json")
    }
    
    private func loadCollaborations() {
        do {
            let data = try Data(contentsOf: saveURL)
            collaborations = try JSONDecoder().decode([Collaboration].self, from: data)
        } catch {
            collaborations = []
            print("Erreur de chargement des collaborations: \(error)")
        }
    }
    
    private func saveCollaborations() {
        do {
            let data = try JSONEncoder().encode(collaborations)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Erreur de sauvegarde des collaborations: \(error)")
        }
    }
    
    public func shareEntity(_ entityType: Collaboration.EntityType, entityId: UUID, withUserIds: [UUID], permissions: Collaboration.Permissions) {
        let collaboration = Collaboration(
            id: UUID(),
            entityType: entityType,
            entityId: entityId,
            sharedWithUserIds: withUserIds,
            permissions: permissions,
            createdAt: Date(),
            updatedAt: Date()
        )
        collaborations.append(collaboration)
        saveCollaborations()
    }
    
    public func updateCollaboration(_ collaboration: Collaboration) {
        if let index = collaborations.firstIndex(where: { $0.id == collaboration.id }) {
            var updatedCollaboration = collaboration
            updatedCollaboration.updatedAt = Date()
            collaborations[index] = updatedCollaboration
            saveCollaborations()
        }
    }
    
    public func removeCollaboration(_ collaboration: Collaboration) {
        collaborations.removeAll { $0.id == collaboration.id }
        saveCollaborations()
    }
    
    public func getCollaborationsForEntity(_ entityType: Collaboration.EntityType, entityId: UUID) -> [Collaboration] {
        collaborations.filter { $0.entityType == entityType && $0.entityId == entityId }
    }
    
    public func hasPermission(_ permission: Collaboration.Permissions, forEntity entityType: Collaboration.EntityType, entityId: UUID, userId: UUID) -> Bool {
        collaborations.contains { collaboration in
            collaboration.entityType == entityType &&
            collaboration.entityId == entityId &&
            collaboration.sharedWithUserIds.contains(userId) &&
            collaboration.permissions.contains(permission)
        }
    }
    
    func share(entityType: EntityType, entityId: UUID, with contactId: UUID) {
        if sharedItems[entityId] == nil {
            sharedItems[entityId] = []
        }
        sharedItems[entityId]?.insert(contactId)
        
        // Simuler l'envoi d'une notification
        NotificationCenter.default.post(
            name: .didShareEntity,
            object: nil,
            userInfo: [
                "entityType": entityType,
                "entityId": entityId,
                "contactId": contactId
            ]
        )
    }
    
    func isShared(entityId: UUID, with contactId: UUID) -> Bool {
        sharedItems[entityId]?.contains(contactId) ?? false
    }
    
    func removeShare(entityId: UUID, for contactId: UUID) {
        sharedItems[entityId]?.remove(contactId)
        if sharedItems[entityId]?.isEmpty == true {
            sharedItems.removeValue(forKey: entityId)
        }
    }
}

extension Notification.Name {
    static let didShareEntity = Notification.Name("didShareEntity")
} 