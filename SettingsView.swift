import SwiftUI

struct SettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Langue / Language")) {
                ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if language == languageManager.currentLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        languageManager.setLanguage(language)
                    }
                }
            }
            
            // Ajoutez d'autres sections de paramètres ici si nécessaire
        }
        .navigationTitle("Paramètres")
    }
} 