import Foundation
import SwiftUI

enum AlertType {
    case deadline
    case task
    case project
    case system
}

enum AlertSeverity {
    case info
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
} 