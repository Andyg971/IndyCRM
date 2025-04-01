import Foundation
import SwiftUI

@MainActor
public class InvoiceManager: ObservableObject {
    @Published public private(set) var invoices: [Invoice] = []
    private let saveKey = "SavedInvoices"
    private let exportService = ExportService()
    private let fileManager = FileManager.default
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let savedInvoicesURL: URL
    
    @Published var isProcessingInvoices = false
    
    public init() {
        savedInvoicesURL = documentsPath.appendingPathComponent("\(saveKey).json")
        createInitialFileIfNeeded()
        loadInvoices()
    }
    
    private func createInitialFileIfNeeded() {
        if !fileManager.fileExists(atPath: savedInvoicesURL.path) {
            do {
                let emptyInvoices: [Invoice] = []
                let data = try JSONEncoder().encode(emptyInvoices)
                try data.write(to: savedInvoicesURL)
            } catch {
                print("Erreur lors de la création du fichier initial SavedInvoices.json: \(error)")
            }
        }
    }
    
    private var saveURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("\(saveKey).json")
    }
    
    func loadInvoices() {
        do {
            let data = try Data(contentsOf: saveURL)
            invoices = try JSONDecoder().decode([Invoice].self, from: data)
        } catch {
            invoices = []
            print("Erreur de chargement des factures: \(error)")
        }
    }
    
    private func saveInvoices() {
        do {
            let data = try JSONEncoder().encode(invoices)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Erreur de sauvegarde des factures: \(error)")
        }
    }
    
    func addInvoice(_ invoice: Invoice) {
        invoices.append(invoice)
        saveInvoices()
    }
    
    func updateInvoice(_ invoice: Invoice) {
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            invoices[index] = invoice
            saveInvoices()
        }
    }
    
    func deleteInvoice(_ invoice: Invoice) {
        invoices.removeAll { $0.id == invoice.id }
        saveInvoices()
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
                if exportInvoiceToPDF(invoice, clientName: "Client") != nil {
                    // Simuler l'envoi d'email (à remplacer par un vrai service d'email)
                    print("Envoi de la facture \(invoice.number) au client...")
                    try await Task.sleep(nanoseconds: 1_000_000_000) // Simulation d'un délai d'envoi
                    
                    // Mettre à jour le statut
                    invoice.status = .sent
                    updateInvoice(invoice)
                    
                    // Programmer une notification de rappel
                    NotificationManager.shared.scheduleInvoiceReminder(invoice: invoice)
                    
                    print("✅ Facture \(invoice.number) traitée avec succès")
                }
            } catch {
                print("❌ Erreur lors du traitement de la facture \(invoice.number): \(error.localizedDescription)")
            }
        }
        
        // Sauvegarder les modifications
        saveInvoices()
    }
} 
