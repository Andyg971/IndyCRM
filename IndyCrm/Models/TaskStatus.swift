import SwiftUI

public enum TaskStatus: String, CaseIterable, Codable, StatusDisplayable {
    case todo = "À faire"
    case inProgress = "En cours"
    case review = "En révision"
    case done = "Terminé"
    
    public var statusTitle: String {
        rawValue
    }
    
    public var statusColor: Color {
        switch self {
        case .todo: return .blue
        case .inProgress: return .orange
        case .review: return .purple
        case .done: return .green
        }
    }
    
    public var icon: String {
        switch self {
        case .todo: return "circle.dashed"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .review: return "eye"
        case .done: return "checkmark.circle"
        }
    }
} 