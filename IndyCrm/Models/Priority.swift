import SwiftUI

public enum Priority: String, CaseIterable, Codable, StatusDisplayable {
    case high = "Haute"
    case medium = "Moyenne"
    case low = "Basse"
    
    public var statusTitle: String {
        rawValue
    }
    
    public var statusColor: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    public var icon: String {
        switch self {
        case .high: return "flag.fill"
        case .medium: return "flag"
        case .low: return "flag.slash"
        }
    }
} 