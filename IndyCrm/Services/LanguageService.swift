import Foundation
import SwiftUI

class LanguageService: ObservableObject {
    static let shared = LanguageService()
    
    @AppStorage("app_language") private var appLanguage: String = "fr"
    @Published var refreshID = UUID() // Identifiant pour forcer la mise à jour des vues
    
    private init() {}
    
    var currentLanguage: String {
        get { appLanguage }
        set {
            let oldValue = appLanguage
            appLanguage = newValue
            
            if oldValue != newValue {
                updateLanguage()
                
                // Forcer la mise à jour des vues
                DispatchQueue.main.async {
                    withAnimation {
                        self.refreshID = UUID()
                    }
                }
            }
        }
    }
    
    var availableLanguages: [(code: String, name: String)] {
        [
            ("en", "English"),
            ("fr", "Français"),
            ("es", "Español"),
            ("it", "Italiano"),
            ("de", "Deutsch")
        ]
    }
    
    private func updateLanguage() {
        // 1. Mettre à jour les préférences de langue du système
        UserDefaults.standard.set([appLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // 2. Notifier l'application du changement de langue
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
        
        print("🌐 Langue changée en: \(appLanguage)")
    }
    
    func languageName(for code: String) -> String {
        availableLanguages.first { $0.code == code }?.name ?? code
    }
} 