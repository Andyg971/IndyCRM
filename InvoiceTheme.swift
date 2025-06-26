import UIKit

struct InvoiceTheme {
    // Couleurs
    static let primaryColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
    static let secondaryColor = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
    static let accentColor = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
    
    // Fonts
    static let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
    static let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    static let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let smallFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    
    // Mise en page
    struct Layout {
        static let pageMargin: CGFloat = 40.0
        static let headerHeight: CGFloat = 120.0
        static let footerHeight: CGFloat = 80.0
        static let lineSpacing: CGFloat = 8.0
        static let sectionSpacing: CGFloat = 20.0
    }
    
    // Style des éléments
    struct Style {
        static let cornerRadius: CGFloat = 8.0
        static let borderWidth: CGFloat = 1.0
        static let shadowOpacity: Float = 0.1
        static let shadowRadius: CGFloat = 4.0
    }
    
    // Images et logos
    struct Images {
        static let logoSize = CGSize(width: 120, height: 60)
        static let watermarkOpacity: CGFloat = 0.1
    }
} 