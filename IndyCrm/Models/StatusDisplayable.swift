import SwiftUI

public protocol StatusDisplayable {
    var statusTitle: String { get }
    var statusColor: Color { get }
    var icon: String { get }
} 