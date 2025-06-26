import Foundation

// MARK: - Modèles
struct EmailContent {
    let recipient: String
    let subject: String
    let body: String
    let attachments: [EmailAttachment]?
    let ccRecipients: [String]?
    let bccRecipients: [String]?
    let replyTo: String?
}

struct EmailAttachment {
    let data: Data
    let filename: String
    let mimeType: String
}

enum EmailError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case invalidData
    case apiError(statusCode: Int, message: String?)
}

// MARK: - Service d'email
class ResendEmailService {
    private let apiKey: String
    private let fromEmail: String
    private let fromName: String
    
    init(fromEmail: String, fromName: String) {
        guard let apiKey = ProcessInfo.processInfo.environment["RESEND_API_KEY"] else {
            fatalError("🚨 RESEND_API_KEY non trouvée dans les variables d'environnement")
        }
        self.apiKey = apiKey
        self.fromEmail = fromEmail
        self.fromName = fromName
    }
    
    func sendEmail(content: EmailContent, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.resend.com/emails") else {
            completion(.failure(EmailError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let body: [String: Any] = [
                "from": "\(fromName) <\(fromEmail)>",
                "to": [content.recipient],
                "subject": content.subject,
                "html": content.body,
                "attachments": content.attachments?.map { [
                    "content": $0.data.base64EncodedString(),
                    "filename": $0.filename,
                    "content_type": $0.mimeType
                ] } as Any
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Debug : afficher le corps de la requête
            if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 Corps de la requête :")
                print(requestBody)
            }
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EmailError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(EmailError.noData))
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let id = json["id"] as? String {
                        completion(.success(id))
                    } else {
                        print("❌ Réponse invalide : \(String(data: data, encoding: .utf8) ?? "Aucune donnée")")
                        completion(.failure(EmailError.invalidData))
                    }
                } catch {
                    print("❌ Erreur de parsing JSON : \(error)")
                    completion(.failure(error))
                }
            } else {
                let errorMessage = String(data: data, encoding: .utf8)
                print("❌ Erreur HTTP \(httpResponse.statusCode) : \(errorMessage ?? "Pas de message d'erreur")")
                completion(.failure(EmailError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)))
            }
        }.resume()
    }
}

// MARK: - Test
print("🏃‍♂️ Démarrage du test d'envoi d'email...")

// Configuration du service
let emailService = ResendEmailService(
    fromEmail: "onboarding@resend.dev",
    fromName: "IndyCRM"
)

// Création d'un PDF simple pour le test
let pdfData = """
Facture TEST-2024-001

Montant : 1500.00 €
Date d'échéance : \(Date().addingTimeInterval(30 * 24 * 3600).formatted())
""".data(using: .utf8)!

// Création du contenu de l'email
let content = EmailContent(
    recipient: "asahi.zenji@gmail.com", // Email associé au compte Resend
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

let semaphore = DispatchSemaphore(value: 0)

emailService.sendEmail(content: content) { result in
    switch result {
    case .success(let id):
        print("✅ Email envoyé avec succès !")
        print("📝 ID de l'email : \(id)")
    case .failure(let error):
        print("❌ Erreur lors de l'envoi de l'email :")
        print(error.localizedDescription)
    }
    semaphore.signal()
}

_ = semaphore.wait(timeout: .now() + 10) 