import Foundation
import SwiftUI

@MainActor
public class InvoiceManager: ObservableObject {
    @Published public private(set) var invoices: [Invoice] = []
    private let saveKey = "SavedInvoices"
    private let exportService = ExportService()
    private let fileManager = FileManager.default
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    // private let savedInvoicesURL: URL // Remplacé par saveURL
    
    // Ajout du CacheService
    private let cacheService = CacheService.shared
    private let cacheKey = "CachedInvoices" // Clé pour le cache
    
    @Published var isProcessingInvoices = false
    
    public init() {
        // Remplacé par chargement async
        // savedInvoicesURL = documentsPath.appendingPathComponent("\(saveKey).json")
        // createInitialFileIfNeeded()
        // loadInvoices()
        
        // Charger les factures au démarrage (avec cache)
        Task {
            await loadInvoices()
        }
    }
    
    // Ne pas appeler createInitialFileIfNeeded ici, le chargement le gère

    private var saveURL: URL {
        documentsPath.appendingPathComponent("\(saveKey).json")
    }
    
    // Rendre async
    func loadInvoices() async {
        // 1. Essayer de charger depuis le cache
        do {
            let cachedInvoices: [Invoice] = try cacheService.object(forKey: cacheKey)
            self.invoices = cachedInvoices
            print("🧾 Factures chargées depuis le cache")
            return // Sortir si chargé depuis le cache
        } catch {
            print("🧾 Cache des factures non trouvé ou expiré: \(error.localizedDescription)")
        }

        // 2. Charger depuis le fichier si le cache est vide ou invalide
        do {
            let data = try Data(contentsOf: saveURL)
            let loadedInvoices = try JSONDecoder().decode([Invoice].self, from: data)
            self.invoices = loadedInvoices
            print("🧾 Factures chargées depuis le fichier")

            // 3. Mettre les factures chargées dans le cache
            try cacheService.cache(loadedInvoices, forKey: cacheKey)
            print("🧾 Factures mises en cache")

        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            self.invoices = []
            print("🧾 Fichier \(saveKey).json non trouvé, initialisation à vide.")
        } catch {
            self.invoices = []
            print("Erreur de chargement des factures depuis le fichier: \(error)")
        }
    }
    
    // Rendre async
    private func saveInvoices() async {
        do {
            let data = try JSONEncoder().encode(invoices)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
            print("🧾 Factures sauvegardées sur disque")

            // Mise à jour du cache
            try cacheService.cache(invoices, forKey: cacheKey)
            print("🧾 Cache des factures mis à jour")
        } catch {
            print("Erreur de sauvegarde des factures: \(error)")
        }
    }
    
    // Rendre async
    func addInvoice(_ invoice: Invoice) async {
        invoices.append(invoice)
        await saveInvoices()
    }
    
    // Rendre async
    func updateInvoice(_ invoice: Invoice) async {
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            invoices[index] = invoice
            await saveInvoices()
        }
    }
    
    // Rendre async
    func deleteInvoice(_ invoice: Invoice) async {
        invoices.removeAll { $0.id == invoice.id }
        await saveInvoices()
        
        // Invalider explicitement le cache pour assurer que les données supprimées ne sont pas rechargées
        cacheService.invalidateCache(forKey: cacheKey)
        print("🧾 Cache des factures invalidé après suppression")
    }
    
    // Export vers CSV
    func exportToCSV() -> URL? {
        return exportService.exportToCSV(.invoices, invoices: invoices)
    }
    
    // Export vers PDF
    func exportToPDF(contacts: [Contact]) -> URL? {
        return exportService.exportToPDF(.invoices, invoices: invoices)
    }
    
    // Export d'une facture spécifique en PDF
    func exportInvoiceToPDF(_ invoice: Invoice, clientName: String) -> URL? {
        return exportService.exportToPDF(.invoices, invoices: [invoice])
    }
    
    // Nouvelle fonction pour traiter les factures en attente
    func processPendingInvoices() async {
        isProcessingInvoices = true
        defer { isProcessingInvoices = false }
        
        let pendingInvoices = invoices.filter { $0.status == .draft }
        
        for var invoice in pendingInvoices {
            do {
                // Générer le PDF
                if exportInvoiceToPDF(invoice, clientName: "Client") != nil { // Assumer que clientName est obtenu correctement
                    // Simuler l'envoi d'email (à remplacer par un vrai service d'email)
                    print("Envoi de la facture \(invoice.number) au client...")
                    try await Task.sleep(nanoseconds: 1_000_000_000) // Simulation d'un délai d'envoi
                    
                    // Mettre à jour le statut
                    invoice.status = .sent
                    await updateInvoice(invoice) // Ajout de await ici
                    
                    // Programmer une notification de rappel
                    // Assurez-vous que NotificationManager est thread-safe ou appelé depuis le bon acteur si nécessaire
                    NotificationManager.shared.scheduleInvoiceReminder(invoice: invoice)
                    
                    print("✅ Facture \(invoice.number) traitée avec succès")
                } else {
                    print("❌ Échec de la génération du PDF pour la facture \(invoice.number)")
                }
            } catch {
                print("❌ Erreur lors du traitement de la facture \(invoice.number): \(error.localizedDescription)")
                // Envisager d'ajouter plus de détails ou de remonter l'erreur
            }
        }
        
        // Pas besoin de saveInvoices() ici car updateInvoice le fait déjà
        // await saveInvoices()
    }
    
    // --- Ajout de méthodes pour l'intégration avec BackupService ---

    /// Retourne les données brutes des factures pour la sauvegarde
    func getInvoicesDataForBackup() throws -> Data {
        // Assurer que Invoice est Codable
        return try JSONEncoder().encode(invoices)
    }

    /// Remplace les factures actuelles avec les données restaurées et met à jour le cache
    func restoreInvoices(from data: Data) async throws {
        // Assurer que Invoice est Codable
        let restoredInvoices = try JSONDecoder().decode([Invoice].self, from: data)
        self.invoices = restoredInvoices
        // Sauvegarder immédiatement les factures restaurées sur disque et dans le cache
        await saveInvoices()
        print("🧾 Factures restaurées depuis la sauvegarde")
    }
} 
