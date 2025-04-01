import SwiftUI

public enum ProjectStatus: String, Codable, CaseIterable {
    case planning = "Planification"
    case inProgress = "En cours"
    case onHold = "En pause"
    case completed = "Terminé"
    case cancelled = "Annulé"
}

extension ProjectStatus: StatusDisplayable {
    public var statusTitle: String {
        rawValue
    }
    
    public var statusColor: Color {
        switch self {
        case .planning: return .orange
        case .inProgress: return .blue
        case .onHold: return .yellow
        case .completed: return .green
        case .cancelled: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .planning: return "calendar"
        case .inProgress: return "arrow.right.circle"
        case .onHold: return "pause.circle"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
}
