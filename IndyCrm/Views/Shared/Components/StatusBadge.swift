import SwiftUI

public struct StatusBadge<Status: StatusDisplayable>: View {
    let status: Status
    
    public init(status: Status) {
        self.status = status
    }
    
    public var body: some View {
        Text(status.statusTitle)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.statusColor.opacity(0.2))
            .foregroundColor(status.statusColor)
            .clipShape(Capsule())
    }
} 