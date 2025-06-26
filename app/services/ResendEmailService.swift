import Foundation

// MARK: - Modèle de contenu pour email
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

// MARK: - Service d'email avec Resend
class ResendEmailService {
    private let apiKey: String
    private let fromEmail: String
    private let fromName: String
    
    // Constructeur sécurisé (utilise les variables d'environnement)
    init(fromEmail: String, fromName: String) {
        guard let apiKey = ProcessInfo.processInfo.environment["RESEND_API_KEY"], !apiKey.isEmpty else {
            fatalError("🚨 ERREUR : La clé API RESEND est absente ! Ajoutez-la dans Xcode > Edit Scheme > Run > Arguments > Environment Variables.")
        }
        self.apiKey = apiKey
        self.fromEmail = fromEmail
        self.fromName = fromName
    }
    
    func sendEmail(content: EmailContent, completion: @escaping (Result<String, Error>) -> Void) {
        // URL de l'API Resend
        guard let url = URL(string: "https://api.resend.com/emails") else {
            completion(.failure(EmailError.invalidURL))
            return
        }
        
        // Création de la requête
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Construction du corps de la requête
        do {
            let body = try createRequestBody(content: content)
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        // Envoi de la requête
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
            
            // Vérification du code de statut
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let id = json["id"] as? String {
                        completion(.success(id))
                    } else {
                        completion(.failure(EmailError.invalidData))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                if let errorDetails = String(data: data, encoding: .utf8) {
                    completion(.failure(EmailError.apiError(statusCode: httpResponse.statusCode, message: errorDetails)))
                } else {
                    completion(.failure(EmailError.apiError(statusCode: httpResponse.statusCode, message: nil)))
                }
            }
        }
        
        task.resume()
    }
    
    private func createRequestBody(content: EmailContent) throws -> [String: Any] {
        var body: [String: Any] = [
            "from": "\(fromName) <\(fromEmail)>",
            "to": [content.recipient],
            "subject": content.subject,
            "html": content.body
        ]
        
        if let ccRecipients = content.ccRecipients, !ccRecipients.isEmpty {
            body["cc"] = ccRecipients
        }
        
        if let bccRecipients = content.bccRecipients, !bccRecipients.isEmpty {
            body["bcc"] = bccRecipients
        }
        
        if let replyTo = content.replyTo {
            body["reply_to"] = replyTo
        }
        
        if let attachments = content.attachments, !attachments.isEmpty {
            body["attachments"] = attachments.map { attachment -> [String: String] in
                let base64EncodedData = attachment.data.base64EncodedString()
                return [
                    "content": base64EncodedData,
                    "filename": attachment.filename
                ]
            }
        }
        
        return body
    }
}

// MARK: - Erreurs possibles
enum EmailError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case invalidData
    case apiError(statusCode: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de l'API invalide."
        case .invalidResponse:
            return "Réponse de l'API invalide."
        case .noData:
            return "Aucune donnée reçue."
        case .invalidData:
            return "Données reçues invalides."
        case .apiError(let statusCode, let message):
            return message != nil ? "Erreur API (\(statusCode)): \(message!)" : "Erreur API (code \(statusCode))"
        }
    }
}

// MARK: - Fonction de test pour Xcode
#if DEBUG
func testResendEmailService(to recipient: String, completion: @escaping (Result<String, Error>) -> Void) {
    let fromEmail = "votre-email@domaine.com" // À remplacer par votre email
    let fromName = "Votre Entreprise"
    
    let emailService = ResendEmailService(fromEmail: fromEmail, fromName: fromName)
    
    let content = EmailContent(
        recipient: recipient,
        subject: "Test de configuration Resend",
        body: """
        <!DOCTYPE html>
        <html>
        <body>
            <h2>Test de configuration Resend</h2>
            <p>Si vous recevez cet email, la configuration fonctionne correctement.</p>
        </body>
        </html>
        """,
        attachments: nil,
        ccRecipients: nil,
        bccRecipients: nil,
        replyTo: nil
    )
    
    emailService.sendEmail(content: content, completion: completion)
}
#endif 