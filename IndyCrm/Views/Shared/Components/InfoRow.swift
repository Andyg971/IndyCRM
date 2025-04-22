import SwiftUI

/// Composant partagé pour afficher une ligne d'information avec un titre et une valeur
public struct InfoRow: View {
    let title: String
    let value: String
    let fontStyle: FontStyle
    
    public enum FontStyle {
        case normal
        case subheadline
    }
    
    public init(
        title: String,
        value: String,
        fontStyle: FontStyle = .normal
    ) {
        self.title = title
        self.value = value
        self.fontStyle = fontStyle
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(fontStyle == .subheadline ? .subheadline : .body)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .font(fontStyle == .subheadline ? .subheadline : .body)
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        InfoRow(title: "Date de début", value: "01/01/2023")
        InfoRow(title: "Budget", value: "10 000 €", fontStyle: .subheadline)
        InfoRow(title: "Statut", value: "En cours")
    }
    .padding()
} 