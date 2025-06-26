import Foundation
import SwiftUI

struct TestEmailService {
    static func sendTestInvoice() async {
        print("🚀 Démarrage du test d'envoi de facture...")
        
        // Création d'une facture de test
        let invoiceItems = [
            InvoiceItem(
                id: UUID(),
                description: "Développement application",
                quantity: 1,
                unitPrice: 1500.0,
                notes: "Application mobile"
            )
        ]
        
        let invoice = Invoice(
            id: UUID(),
            number: "TEST-2024-001",
            clientId: UUID(),
            date: Date(),
            dueDate: Date().addingTimeInterval(30 * 24 * 3600),
            items: invoiceItems,
            status: .draft,
            notes: "Facture de test"
        )
        
        // Création d'un PDF simple pour le test
        let pdfData = """
        Facture TEST-2024-001
        
        Montant : 1500.00 €
        Date d'échéance : \(invoice.dueDate.formatted())
        """.data(using: .utf8)!
        
        // Configuration du service d'email
        let emailService = ResendEmailService(
            fromEmail: "contact@indycrm.fr",
            fromName: "IndyCRM"
        )
        
        // Création du contenu de l'email
        let content = EmailContent(
            recipient: "andy.grava@gmail.com", // Email de test
            subject: "Test - Facture TEST-2024-001",
            body: """
            <!DOCTYPE html>
            <html>
            <body>
                <h2>Test d'envoi de facture</h2>
                <p>Ceci est un test d'envoi de facture via Resend.</p>
                <p>Facture jointe : TEST-2024-001</p>
                <p>Montant : 1500.00 €</p>
                <br>
                <p>Cordialement,</p>
                <p>IndyCRM</p>
            </body>
            </html>
            """,
            attachments: [
                EmailAttachment(
                    data: pdfData,
                    filename: "facture_test.pdf",
                    mimeType: "application/pdf"
                )
            ],
            ccRecipients: nil,
            bccRecipients: nil,
            replyTo: nil
        )
        
        // Envoi de l'email
        print("📧 Envoi de l'email de test...")
        
        emailService.sendEmail(content: content) { result in
            switch result {
            case .success(let id):
                print("✅ Email envoyé avec succès !")
                print("📝 ID de l'email : \(id)")
            case .failure(let error):
                print("❌ Erreur lors de l'envoi de l'email :")
                print(error.localizedDescription)
            }
        }
    }
} 