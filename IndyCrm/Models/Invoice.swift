import Foundation
import SwiftUI

public struct Invoice: Identifiable, Codable, Hashable {
    public var id: UUID
    public var number: String
    public var clientId: UUID
    public var date: Date
    public var dueDate: Date
    public var items: [InvoiceItem]
    public var status: InvoiceStatus
    public var notes: String
    public var createdAt: Date?
    public var updatedAt: Date?
    
    public var total: Double {
        items.reduce(0) { $0 + ($1.quantity * $1.unitPrice) }
    }
    
    // MARK: - Hashable Implementation
    public static func == (lhs: Invoice, rhs: Invoice) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct InvoiceItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var description: String
    public var quantity: Double
    public var unitPrice: Double
    public var notes: String
    
    // MARK: - Hashable Implementation
    public static func == (lhs: InvoiceItem, rhs: InvoiceItem) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 