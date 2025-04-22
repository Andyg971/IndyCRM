import Foundation

/// Propriété wrapper pour chiffrer/déchiffrer automatiquement une String
@propertyWrapper
struct SecureString: Codable {
    // La valeur chiffrée stockée
    private var encryptedValue: String?
    
    // La valeur en clair, temporairement en mémoire
    private var temporaryValue: String?
    
    // Initialisation avec une valeur qui sera chiffrée
    init(wrappedValue: String?) {
        if let value = wrappedValue, !value.isEmpty {
            do {
                self.encryptedValue = try EncryptionService.shared.encrypt(value)
            } catch {
                print("⚠️ Erreur de chiffrement: \(error.localizedDescription)")
                self.temporaryValue = value
            }
        }
    }
    
    // Propriété wrapped qui gère le chiffrement/déchiffrement à la volée
    var wrappedValue: String? {
        get {
            // Si nous avons une valeur temporaire en mémoire, la retourner
            if let temp = temporaryValue {
                return temp
            }
            
            // Sinon, essayer de déchiffrer la valeur stockée
            guard let encrypted = encryptedValue else { return nil }
            
            do {
                return try EncryptionService.shared.decrypt(encrypted)
            } catch {
                print("⚠️ Erreur de déchiffrement: \(error.localizedDescription)")
                return nil
            }
        }
        set {
            if let newValue = newValue, !newValue.isEmpty {
                do {
                    // Chiffrer la nouvelle valeur
                    self.encryptedValue = try EncryptionService.shared.encrypt(newValue)
                    self.temporaryValue = nil
                } catch {
                    print("⚠️ Erreur de chiffrement: \(error.localizedDescription)")
                    self.temporaryValue = newValue
                }
            } else {
                self.encryptedValue = nil
                self.temporaryValue = nil
            }
        }
    }
    
    // Implémentation de Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.encryptedValue = value
        } else {
            self.encryptedValue = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encryptedValue)
    }
}

/// Exemple d'utilisation dans un modèle
struct SensitiveContact: Codable {
    let id: UUID
    var name: String
    
    // Les données sensibles seront automatiquement chiffrées
    @SecureString var creditCardNumber: String?
    @SecureString var socialSecurityNumber: String?
    @SecureString var notes: String?
    
    init(id: UUID = UUID(), name: String, creditCardNumber: String? = nil, socialSecurityNumber: String? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self._creditCardNumber = SecureString(wrappedValue: creditCardNumber)
        self._socialSecurityNumber = SecureString(wrappedValue: socialSecurityNumber)
        self._notes = SecureString(wrappedValue: notes)
    }
}

/// Utilitaire pour sécuriser les données sensibles dans les modèles existants
class SecureDataHelper {
    /* 
    // Code commenté temporairement car il fait référence au modèle Contact
    // qui n'est pas correctement importé et qui sera implémenté séparément
    
    /// Chiffre les données sensibles d'un contact
    static func secureContactData(_ contact: inout Contact) {
        if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
            do {
                contact.phoneNumber = try EncryptionService.shared.encrypt(phoneNumber)
            } catch {
                print("⚠️ Erreur de chiffrement du téléphone: \(error.localizedDescription)")
            }
        }
        
        if let email = contact.email, !email.isEmpty {
            do {
                contact.email = try EncryptionService.shared.encrypt(email)
            } catch {
                print("⚠️ Erreur de chiffrement de l'email: \(error.localizedDescription)")
            }
        }
        
        if let address = contact.address, !address.isEmpty {
            do {
                contact.address = try EncryptionService.shared.encrypt(address)
            } catch {
                print("⚠️ Erreur de chiffrement de l'adresse: \(error.localizedDescription)")
            }
        }
    }
    
    /// Déchiffre les données sensibles d'un contact
    static func decryptContactData(_ contact: inout Contact) {
        if let encryptedPhone = contact.phoneNumber, !encryptedPhone.isEmpty {
            do {
                contact.phoneNumber = try EncryptionService.shared.decrypt(encryptedPhone)
            } catch {
                print("⚠️ Erreur de déchiffrement du téléphone: \(error.localizedDescription)")
            }
        }
        
        if let encryptedEmail = contact.email, !encryptedEmail.isEmpty {
            do {
                contact.email = try EncryptionService.shared.decrypt(encryptedEmail)
            } catch {
                print("⚠️ Erreur de déchiffrement de l'email: \(error.localizedDescription)")
            }
        }
        
        if let encryptedAddress = contact.address, !encryptedAddress.isEmpty {
            do {
                contact.address = try EncryptionService.shared.decrypt(encryptedAddress)
            } catch {
                print("⚠️ Erreur de déchiffrement de l'adresse: \(error.localizedDescription)")
            }
        }
    }
    */
    
    /// Détermine si une chaîne est probablement chiffrée
    static func isEncrypted(_ string: String) -> Bool {
        // Les chaînes chiffrées sont généralement en base64 et ont une structure particulière
        return string.count > 20 && string.contains("+") && string.contains("/") && string.contains("=")
    }
} 