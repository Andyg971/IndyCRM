import SwiftUI

public enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Brouillon"
    case sent = "Envoyée"
    case paid = "Payée"
    case overdue = "En retard"
    case cancelled = "Annulée"
}

extension InvoiceStatus: StatusDisplayable {
    public var statusTitle: String {
        rawValue
    }
    
    public var statusColor: Color {
        switch self {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .purple
        }
    }
    
    public var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .sent: return "paperplane"
        case .paid: return "checkmark.circle"
        case .overdue: return "exclamationmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
}
