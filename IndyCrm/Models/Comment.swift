import Foundation

public struct Comment: Identifiable, Codable {
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