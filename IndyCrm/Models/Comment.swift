import Foundation

// Conforme à Hashable pour permettre son utilisation dans des collections comme Set ou comme clé de dictionnaire,
// et pour permettre la conformité automatique de `Milestone` à Hashable.
public struct Comment: Identifiable, Codable, Hashable {
    public let id: UUID
    public let text: String
    public let date: Date
    public let authorId: UUID
    
    public init(id: UUID = UUID(), text: String, date: Date = Date(), authorId: UUID) {
        self.id = id
        self.text = text
        self.date = date
        self.authorId = authorId
    }
} 