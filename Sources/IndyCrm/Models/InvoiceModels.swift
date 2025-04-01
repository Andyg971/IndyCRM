import Foundation

struct Client: Identifiable {
    let id: UUID
    let name: String
    let email: String
}

struct InvoiceItem: Identifiable {
    let id = UUID()
    let description: String
    let quantity: Int
    let unitPrice: Double
    let taxRate: Double
}

enum InvoiceStatus: String {
    case pending = "En attente"
    case paid = "Payée"
    case overdue = "En retard"
}

enum InvoiceFrequency: String {
    case monthly = "Mensuel"
    case yearly = "Annuel"
    case none = "Aucune"
}

struct Invoice: Identifiable {
    let id: UUID
    let client: Client
    let items: [InvoiceItem]
    let date: Date
    let dueDate: Date
    var status: InvoiceStatus
    var nextInvoiceDate: Date?
    var frequency: InvoiceFrequency
    
    var totalAmount: Double {
        return items.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity) * (1 + $1.taxRate / 100)) }
    }
} 