import Foundation

extension String {
    var localized: String {
        // Utiliser le LanguageService pour obtenir la traduction avec le bon bundle
        if let path = Bundle.main.path(forResource: LanguageService.shared.currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: self, table: nil)
        }
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        let localizedFormat = self.localized
        return String(format: localizedFormat, arguments: arguments)
    }
}

// Usage example in views:
// Text("app.welcome".localized)
// Text("hello.name".localized(with: userName)) 