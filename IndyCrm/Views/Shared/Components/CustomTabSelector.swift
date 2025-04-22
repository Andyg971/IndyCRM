import SwiftUI

public struct CustomTabSelector: View {
    @Binding var selectedTab: Int
    let titles: [String]
    
    public init(selectedTab: Binding<Int>, titles: [String]) {
        self._selectedTab = selectedTab
        self.titles = titles
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<titles.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    Text(titles[index])
                        .fontWeight(selectedTab == index ? .semibold : .regular)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(selectedTab == index ? .primary : .secondary)
                .background(
                    ZStack {
                        if selectedTab == index {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.1))
                        }
                    }
                )
                .accessibilityLabel("\(titles[index]) tab")
                .accessibilityAddTraits(selectedTab == index ? [.isSelected] : [])
            }
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CustomTabSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomTabSelector(
                selectedTab: .constant(0),
                titles: ["Premier", "Deuxième", "Troisième"]
            )
            
            CustomTabSelector(
                selectedTab: .constant(1),
                titles: ["Aperçu", "Tâches", "Notes", "Fichiers"]
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 