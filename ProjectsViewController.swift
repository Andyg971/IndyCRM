import UIKit

class ProjectsViewController: UIViewController, LocalizableViewController {
    // Gardez vos outlets et propriétés existantes ici
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocalization() // Ajout de la configuration de la localisation
    }
    
    private func setupUI() {
        // Votre configuration UI existante
    }
    
    // Implémentation requise pour LocalizableViewController
    func updateLocalizedStrings() {
        // Mettez à jour tous vos textes ici
        title = "projects".localized
        // Mettez à jour les autres textes de votre interface
    }
    
    deinit {
        cleanupLocalization()
    }
} 