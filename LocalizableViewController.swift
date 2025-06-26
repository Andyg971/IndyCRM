import UIKit

// Protocole que tous les view controllers qui ont besoin de localisation doivent implémenter
protocol LocalizableViewController: UIViewController {
    func updateLocalizedStrings()
}

// Extension par défaut pour tous les view controllers localisables
extension LocalizableViewController {
    func setupLocalization() {
        // S'abonner aux changements de langue
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: Notification.Name("LanguageChanged"),
            object: nil
        )
        
        // Mettre à jour les textes initialement
        updateLocalizedStrings()
    }
    
    @objc private func languageDidChange() {
        // Mettre à jour les textes quand la langue change
        updateLocalizedStrings()
    }
}

// Extension pour nettoyer les observers
extension LocalizableViewController {
    func cleanupLocalization() {
        NotificationCenter.default.removeObserver(self)
    }
} 