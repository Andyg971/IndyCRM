import Foundation
import SwiftUI

// Cette classe gère le changement de langue dans l'application
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // Clé pour sauvegarder la langue choisie
    private let languageKey = "AppLanguage"
    
    // Les langues supportées
    enum Language: String, CaseIterable {
        case french = "fr"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .french: return "Français"
            case .english: return "English"
            }
        }
    }
    
    // Identifiant pour forcer le rechargement des vues
    @Published private(set) var refreshID = UUID()
    
    // Obtenir la langue actuelle
    @Published var currentLanguage: Language {
        didSet {
            if oldValue != currentLanguage {
                UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
                UserDefaults.standard.synchronize()
                
                // Force le rechargement des vues avec un léger délai pour assurer la synchronisation
                DispatchQueue.main.async {
                    withAnimation {
                        self.refreshID = UUID()
                    }
                }
                
                // Notification pour les observateurs externes
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
            }
        }
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .french
        }
    }
    
    // Changer la langue de l'application
    func setLanguage(_ language: Language) {
        self.currentLanguage = language
    }
    
    // Obtenir une chaîne localisée avec valeur par défaut
    func localizedString(for key: String) -> String {
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle = Bundle(path: path ?? "") ?? Bundle.main
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
}

// Extension pratique pour obtenir des chaînes localisées facilement
extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
}

// Extension pour créer une vue qui se recharge quand la langue change
extension View {
    func localized() -> some View {
        self.id(LanguageManager.shared.refreshID)
    }
} 