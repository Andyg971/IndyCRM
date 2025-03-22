import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyVAT") private var companyVAT = ""
    
    @AppStorage("invoicePrefix") private var invoicePrefix = "FACT"
    @AppStorage("defaultPaymentTerms") private var defaultPaymentTerms = 30
    @AppStorage("defaultVATRate") private var defaultVATRate = 20.0
    
    @AppStorage("useCloudSync") private var useCloudSync = false
    @AppStorage("autoBackup") private var autoBackup = true
    @AppStorage("backupFrequency") private var backupFrequency = 7
    
    var body: some View {
        NavigationView {
            Form {
                // Informations de l'entreprise
                Section(header: Text("Informations de l'entreprise")) {
                    TextField("Nom de l'entreprise", text: $companyName)
                    TextField("Adresse", text: $companyAddress)
                    TextField("Téléphone", text: $companyPhone)
                    TextField("Email", text: $companyEmail)
                    TextField("Numéro de TVA", text: $companyVAT)
                }
                
                // Paramètres de facturation
                Section(header: Text("Paramètres de facturation")) {
                    TextField("Préfixe des factures", text: $invoicePrefix)
                    
                    Stepper("Délai de paiement : \(defaultPaymentTerms) jours",
                            value: $defaultPaymentTerms,
                            in: 0...90)
                    
                    HStack {
                        Text("Taux de TVA par défaut")
                        Spacer()
                        TextField("TVA %", value: $defaultVATRate, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }
                }
                
                // Synchronisation et sauvegarde
                Section(header: Text("Synchronisation et sauvegarde")) {
                    Toggle("Synchronisation iCloud", isOn: $useCloudSync)
                    Toggle("Sauvegarde automatique", isOn: $autoBackup)
                    
                    if autoBackup {
                        Picker("Fréquence de sauvegarde", selection: $backupFrequency) {
                            Text("Tous les jours").tag(1)
                            Text("Toutes les semaines").tag(7)
                            Text("Tous les mois").tag(30)
                        }
                    }
                    
                    Button("Sauvegarder maintenant") {
                        performBackup()
                    }
                    
                    Button("Restaurer une sauvegarde") {
                        restoreBackup()
                    }
                }
                
                // Apparence
                Section(header: Text("Apparence")) {
                    Picker("Thème", selection: $appState.currentTheme) {
                        Text("Clair").tag(AppState.AppTheme.light)
                        Text("Sombre").tag(AppState.AppTheme.dark)
                        Text("Système").tag(AppState.AppTheme.system)
                    }
                }
                
                // À propos
                Section(header: Text("À propos")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Politique de confidentialité",
                         destination: URL(string: "https://www.example.com/privacy")!)
                    
                    Link("Conditions d'utilisation",
                         destination: URL(string: "https://www.example.com/terms")!)
                }
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performBackup() {
        // Implémenter la sauvegarde
    }
    
    private func restoreBackup() {
        // Implémenter la restauration
    }
}
