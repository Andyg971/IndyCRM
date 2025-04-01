import Foundation

// MARK: - Services Protocols
protocol PDFGeneratorProtocol {
    func generatePDF(for invoice: Invoice) throws -> URL
}

protocol EmailServiceProtocol {
    func sendEmail(to recipient: String, subject: String, body: String, attachment: URL?) async throws
}

protocol DataManagerProtocol {
    func fetchPendingInvoices() -> [Invoice]
    func fetchAllInvoices() -> [Invoice]
    func saveInvoice(_ invoice: Invoice)
}

protocol NotificationManagerProtocol {
    func sendNotification(message: String)
}

// MARK: - Services Implementations
class PDFInvoiceGenerator: PDFGeneratorProtocol {
    func generatePDF(for invoice: Invoice) throws -> URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("invoice.pdf") else {
            throw NSError(domain: "PDFError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible de générer le PDF"])
        }
        return url
    }
}

class EmailService: EmailServiceProtocol {
    func sendEmail(to recipient: String, subject: String, body: String, attachment: URL?) async throws {
        // Simule l'envoi d'un e-mail de manière asynchrone
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simule un délai de 2 secondes
        print("E-mail envoyé à \(recipient) avec la pièce jointe: \(attachment?.absoluteString ?? "Aucune")")
    }
}

class DataManager: DataManagerProtocol {
    private var invoices: [Invoice] = []
    
    func fetchPendingInvoices() -> [Invoice] {
        return invoices.filter { $0.status == .pending }
    }
    
    func fetchAllInvoices() -> [Invoice] {
        return invoices
    }
    
    func saveInvoice(_ invoice: Invoice) {
        invoices.append(invoice)
    }
}

class NotificationManager: NotificationManagerProtocol {
    func sendNotification(message: String) {
        print("Notification: \(message)")
    }
}

// MARK: - AutoInvoiceManager
@MainActor
class AutoInvoiceManager: ObservableObject {
    let dataManager: DataManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    private let pdfGenerator: PDFGeneratorProtocol
    private let emailService: EmailServiceProtocol
    
    @Published var isProcessing = false
    @Published var invoices: [Invoice] = []
    
    init(dataManager: DataManagerProtocol, notificationManager: NotificationManagerProtocol, pdfGenerator: PDFGeneratorProtocol, emailService: EmailServiceProtocol) {
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        self.pdfGenerator = pdfGenerator
        self.emailService = emailService
        self.invoices = dataManager.fetchAllInvoices()
    }
    
    func refreshInvoices() {
        invoices = dataManager.fetchAllInvoices()
    }
    
    func processPendingInvoices() async {
        isProcessing = true
        defer { isProcessing = false }
        
        let pendingInvoices = dataManager.fetchPendingInvoices()
        for invoice in pendingInvoices {
            do {
                let pdfURL = try pdfGenerator.generatePDF(for: invoice)
                try await emailService.sendEmail(
                    to: invoice.client.email,
                    subject: "Votre facture",
                    body: "Veuillez trouver votre facture ci-jointe.",
                    attachment: pdfURL
                )
                notificationManager.sendNotification(message: "Facture envoyée avec succès à \(invoice.client.name)")
            } catch {
                print("Erreur: \(error.localizedDescription)")
            }
        }
        
        refreshInvoices()
    }
} 