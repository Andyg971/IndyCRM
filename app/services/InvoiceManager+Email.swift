import Foundation
import SwiftUI

extension InvoiceManager {
    // Configuration de l'email
    private struct EmailConfig {
        static let fromEmail = "contact@indycrm.fr" // Email professionnel de IndyCRM
        static let fromName = "IndyCRM" // Nom de l'application
    }
    
    // Envoyer une facture par email
    @MainActor
    func sendInvoiceByEmail(invoice: Invoice, pdfData: Data) async throws {
        guard let client = contactsManager.contacts.first(where: { $0.id == invoice.clientId }) else {
            throw EmailError.invalidData
        }
        
        let emailService = ResendEmailService(
            fromEmail: EmailConfig.fromEmail,
            fromName: EmailConfig.fromName
        )
        
        // Création du contenu HTML de l'email
        let emailBody = """
        <!DOCTYPE html>
        <html>
        <body>
            <h2>Facture \(invoice.number)</h2>
            <p>Cher/Chère \(client.fullName),</p>
            <p>Veuillez trouver ci-joint votre facture \(invoice.number) d'un montant de \(formatCurrency(invoice.total)).</p>
            <p>Date d'échéance : \(formatDate(invoice.dueDate))</p>
            <br>
            <p>Cordialement,</p>
            <p>\(EmailConfig.fromName)</p>
        </body>
        </html>
        """
        
        let content = EmailContent(
            recipient: client.email,
            subject: "Facture \(invoice.number)",
            body: emailBody,
            attachments: [
                EmailAttachment(
                    data: pdfData,
                    filename: "Facture_\(invoice.number).pdf",
                    mimeType: "application/pdf"
                )
            ],
            ccRecipients: nil,
            bccRecipients: nil,
            replyTo: nil
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            emailService.sendEmail(content: content) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Traiter toutes les factures en attente
    @MainActor
    func processPendingInvoices() async {
        isProcessingInvoices = true
        defer { isProcessingInvoices = false }
        
        let pendingInvoices = invoices.filter { $0.status == .draft }
        
        for invoice in pendingInvoices {
            do {
                // Générer le PDF
                let pdfData = try generatePDFData(invoice: invoice)
                
                // Envoyer l'email
                try await sendInvoiceByEmail(invoice: invoice, pdfData: pdfData)
                
                // Mettre à jour le statut de la facture
                var updatedInvoice = invoice
                updatedInvoice.status = .sent
                updateInvoice(updatedInvoice)
                
            } catch {
                print("❌ Erreur lors du traitement de la facture \(invoice.number): \(error.localizedDescription)")
            }
        }
    }
    
    // Formater la devise
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) €"
    }
    
    // Formater la date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
} 