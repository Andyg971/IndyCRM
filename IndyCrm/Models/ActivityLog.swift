import Foundation

public struct ActivityLog: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let userId: UUID
    public let action: Action
    public let entityType: EntityType
    public let entityId: UUID
    public let details: String
    
    public enum Action: String, Codable {
        case created
        case updated
        case deleted
        case statusChanged
    }
    
    public enum EntityType: String, Codable {
        case contact
        case project
        case task
        case invoice
    }
    
    public init(id: UUID = UUID(), date: Date = Date(), userId: UUID, action: Action, entityType: EntityType, entityId: UUID, details: String) {
        self.id = id
        self.date = date
        self.userId = userId
        self.action = action
        self.entityType = entityType
        self.entityId = entityId
        self.details = details
    }
} 