import Foundation
import SwiftUI

public struct Invoice: Identifiable, Codable {
    public var id: UUID
    public var number: String
    public var clientId: UUID
    public var date: Date
    public var dueDate: Date
    public var items: [InvoiceItem]
    public var status: InvoiceStatus
    public var notes: String
    
    public var total: Double {
        items.reduce(0) { $0 + ($1.quantity * $1.unitPrice) }
    }
}

public struct InvoiceItem: Identifiable, Codable {
    public var id: UUID
    public var description: String
    public var quantity: Double
    public var unitPrice: Double
    public var notes: String
} 