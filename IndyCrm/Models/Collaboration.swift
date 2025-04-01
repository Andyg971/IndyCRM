import Foundation

public struct Collaboration: Identifiable, Codable {
    public var id: UUID
    public var entityType: EntityType
    public var entityId: UUID
    public var sharedWithUserIds: [UUID]
    public var permissions: Permissions
    public var createdAt: Date
    public var updatedAt: Date
    
    public enum EntityType: String, Codable {
        case contact, project, task, invoice
    }
    
    public struct Permissions: OptionSet, Codable {
        public let rawValue: Int
        
        public static let view = Permissions(rawValue: 1 << 0)
        public static let edit = Permissions(rawValue: 1 << 1)
        public static let delete = Permissions(rawValue: 1 << 2)
        public static let share = Permissions(rawValue: 1 << 3)
        
        public static let all: Permissions = [.view, .edit, .delete, .share]
        public static let readOnly: Permissions = [.view]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
} 