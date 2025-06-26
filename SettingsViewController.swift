import UIKit

class SettingsViewController: UIViewController, LocalizableViewController {
    
    private let languageSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["french".localized, "english".localized])
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let languageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocalization()
        
        // Sélectionner la langue actuelle
        languageSegmentedControl.selectedSegmentIndex = LanguageManager.shared.currentLanguage == .french ? 0 : 1
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(languageLabel)
        view.addSubview(languageSegmentedControl)
        
        NSLayoutConstraint.activate([
            languageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            languageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            languageSegmentedControl.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 10),
            languageSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            languageSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        languageSegmentedControl.addTarget(self, action: #selector(languageSelectionChanged(_:)), for: .valueChanged)
    }
    
    func updateLocalizedStrings() {
        title = "settings".localized
        languageLabel.text = "language".localized
        languageSegmentedControl.setTitle("french".localized, forSegmentAt: 0)
        languageSegmentedControl.setTitle("english".localized, forSegmentAt: 1)
    }
    
    @objc private func languageSelectionChanged(_ sender: UISegmentedControl) {
        let newLanguage: LanguageManager.Language = sender.selectedSegmentIndex == 0 ? .french : .english
        LanguageManager.shared.setLanguage(newLanguage)
    }
    
    deinit {
        cleanupLocalization()
    }
}