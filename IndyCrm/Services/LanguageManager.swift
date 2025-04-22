import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
        }
    }
    
    private init() {
        // Récupère la langue sauvegardée ou utilise la langue du système
        self.currentLanguage = UserDefaults.standard.string(forKey: "AppLanguage") 
            ?? Locale.current.language.languageCode?.identifier 
            ?? "en"
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
    }
    
    // Méthode pour traduire une chaîne
    func translate(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
} 