import SwiftUI

public struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    public init(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ActionButton(
                title: "Terminer",
                icon: "checkmark.circle",
                color: .green
            ) {
                print("Action terminée")
            }
            
            ActionButton(
                title: "Suspendre",
                icon: "pause.circle",
                color: .orange
            ) {
                print("Action suspendue")
            }
            
            ActionButton(
                title: "Supprimer",
                icon: "trash",
                color: .red
            ) {
                print("Action supprimée")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 