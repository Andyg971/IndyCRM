import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("colorSchemePreference") private var colorSchemePreference: Int = 0
    @AppStorage("accentColorPreference") private var accentColorPreference: Int = 0
    
    private let availableColorSchemes = [
        ColorSchemeOption(id: 0, name: "system", title: "settings.theme.system".localized),
        ColorSchemeOption(id: 1, name: "light", title: "settings.theme.light".localized),
        ColorSchemeOption(id: 2, name: "dark", title: "settings.theme.dark".localized)
    ]
    
    // Collection complète des couleurs d'accentuation disponibles
    private let accentColors: [AccentColorOption] = [
        AccentColorOption(id: 0, name: "blue", title: "settings.theme.color.blue".localized, color: .blue),
        AccentColorOption(id: 1, name: "indigo", title: "settings.theme.color.indigo".localized, color: .indigo),
        AccentColorOption(id: 2, name: "purple", title: "settings.theme.color.purple".localized, color: .purple),
        AccentColorOption(id: 3, name: "pink", title: "settings.theme.color.pink".localized, color: .pink),
        AccentColorOption(id: 4, name: "red", title: "settings.theme.color.red".localized, color: .red),
        AccentColorOption(id: 5, name: "orange", title: "settings.theme.color.orange".localized, color: .orange),
        AccentColorOption(id: 6, name: "yellow", title: "settings.theme.color.yellow".localized, color: .yellow),
        AccentColorOption(id: 7, name: "green", title: "settings.theme.color.green".localized, color: .green),
        AccentColorOption(id: 8, name: "mint", title: "settings.theme.color.mint".localized, color: .mint),
        AccentColorOption(id: 9, name: "teal", title: "settings.theme.color.teal".localized, color: .teal),
        AccentColorOption(id: 10, name: "cyan", title: "settings.theme.color.cyan".localized, color: .cyan),
        AccentColorOption(id: 11, name: "brown", title: "settings.theme.color.brown".localized, color: .brown)
    ]
    
    var body: some View {
        Form {
            Section(header: Text("settings.theme.appearance".localized)) {
                ForEach(availableColorSchemes, id: \.id) { option in
                    Button(action: {
                        colorSchemePreference = option.id
                    }) {
                        HStack {
                            Text(option.title)
                            Spacer()
                            if colorSchemePreference == option.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("settings.theme.accent_color".localized)) {
                AccentColorSelector(selectedColor: $accentColorPreference, accentColors: accentColors)
            }
            
            Section(footer: Text("settings.theme.restart_needed".localized)) {
                Button(action: {
                    // Réinitialiser aux valeurs par défaut
                    colorSchemePreference = 0
                    accentColorPreference = 0
                    UserDefaults.standard.synchronize()
                }) {
                    Text("settings.theme.reset".localized)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("settings.theme.title".localized)
        .onAppear {
            UserDefaults.standard.synchronize()
        }
    }
}

struct AccentColorSelector: View {
    @Binding var selectedColor: Int
    let accentColors: [AccentColorOption]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.theme.accent_color".localized)
                .font(.headline)
                .padding(.top, 8)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(accentColors) { option in
                    Button(action: {
                        selectedColor = option.id
                    }) {
                        ZStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            if selectedColor == option.id {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(option.title)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// Modèle pour les options de schéma de couleurs
struct ColorSchemeOption: Identifiable {
    var id: Int
    var name: String
    var title: String
}

// Modèle pour les options de couleur d'accentuation
struct AccentColorOption: Identifiable {
    var id: Int
    var name: String
    var title: String
    var color: Color
}

#Preview {
    NavigationView {
        ThemeSettingsView()
    }
} 