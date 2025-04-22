import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var languageService = LanguageService.shared
    @State private var showingRestartInfo = false
    
    var body: some View {
        VStack {
            List {
                ForEach(languageService.availableLanguages, id: \.code) { language in
                    Button(action: {
                        if languageService.currentLanguage != language.code {
                            languageService.currentLanguage = language.code
                            showingRestartInfo = true
                        }
                    }) {
                        HStack {
                            Text(language.name)
                            Spacer()
                            if languageService.currentLanguage == language.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            
            if showingRestartInfo {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("La langue a été changée et appliquée à l'application. Si certains éléments n'apparaissent pas dans la nouvelle langue, veuillez rafraîchir la vue ou redémarrer l'application.")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Compris") {
                        showingRestartInfo = false
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showingRestartInfo)
            }
        }
        .navigationTitle("settings.language".localized)
        .id(languageService.refreshID) // Force le rechargement de la vue quand la langue change
    }
}

#Preview {
    NavigationView {
        LanguageSettingsView()
    }
} 