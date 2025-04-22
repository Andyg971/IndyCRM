import Foundation
import CryptoKit
import Security

/// Service de chiffrement pour protéger les données sensibles
class EncryptionService {
    
    // MARK: - Constantes et identifiants
    private let keychainServiceID = "com.indycrm.encryption"
    private let masterKeyID = "masterEncryptionKey"
    private let saltID = "encryptionSalt"
    
    // MARK: - Initialisation
    
    /// Initialise le service et génère les clés si nécessaire
    init() {
        // Générer ou récupérer la clé maître
        if !doesMasterKeyExist() {
            do {
                try generateAndStoreNewMasterKey()
                print("🔐 Nouvelle clé de chiffrement générée et stockée")
            } catch {
                print("❌ Erreur lors de la génération de la clé: \(error.localizedDescription)")
            }
        } else {
            print("🔐 Clé de chiffrement existante chargée")
        }
    }
    
    // MARK: - API Public
    
    /// Chiffre des données sensibles
    /// - Parameter data: Données à chiffrer
    /// - Returns: Données chiffrées encodées en base64
    func encrypt(_ data: Data) throws -> String {
        guard let masterKey = retrieveMasterKey() else {
            throw EncryptionError.keyNotFound
        }
        
        let salt = try generateOrRetrieveSalt()
        
        // Dériver une clé symétrique à partir de la clé principale
        let symmetricKey = deriveSymmetricKey(from: masterKey, salt: salt)
        
        // Chiffrer les données avec la clé symétrique
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        
        // Convertir en chaîne base64 pour le stockage
        guard let encrypted = sealedBox.combined?.base64EncodedString() else {
            throw EncryptionError.encryptionFailed
        }
        
        return encrypted
    }
    
    /// Déchiffre des données chiffrées
    /// - Parameter encryptedBase64: Données chiffrées encodées en base64
    /// - Returns: Données déchiffrées
    func decrypt(_ encryptedBase64: String) throws -> Data {
        guard let masterKey = retrieveMasterKey() else {
            throw EncryptionError.keyNotFound
        }
        
        let salt = try generateOrRetrieveSalt()
        
        // Dériver la même clé symétrique pour le déchiffrement
        let symmetricKey = deriveSymmetricKey(from: masterKey, salt: salt)
        
        // Décoder la chaîne base64 en données
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else {
            throw EncryptionError.invalidData
        }
        
        // Reconstituer le sealedBox
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        
        // Déchiffrer les données
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        return decryptedData
    }
    
    /// Chiffre une chaîne de caractères
    /// - Parameter string: Chaîne à chiffrer
    /// - Returns: Chaîne chiffrée
    func encrypt(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try encrypt(data)
    }
    
    /// Déchiffre une chaîne chiffrée
    /// - Parameter encryptedString: Chaîne chiffrée
    /// - Returns: Chaîne déchiffrée
    func decrypt(_ encryptedString: String) throws -> String {
        let decryptedData = try decrypt(encryptedString) as Data
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        return string
    }
    
    // MARK: - Gestion des clés
    
    /// Vérifie si la clé maître existe déjà dans le keychain
    private func doesMasterKeyExist() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceID,
            kSecAttrAccount as String: masterKeyID,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Génère et stocke une nouvelle clé maître
    private func generateAndStoreNewMasterKey() throws {
        // Générer une nouvelle clé
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Stocker dans le keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceID,
            kSecAttrAccount as String: masterKeyID,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            throw EncryptionError.keyStorageFailed
        }
        
        // Générer un nouveau sel et le stocker
        try storeSalt(generateSalt())
    }
    
    /// Récupère la clé maître depuis le keychain
    private func retrieveMasterKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceID,
            kSecAttrAccount as String: masterKeyID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let keyData = item as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Génère un sel cryptographique
    private func generateSalt() -> Data {
        var salt = Data(count: 16) // 16 octets = 128 bits
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        return salt
    }
    
    /// Stocke le sel dans le keychain
    private func storeSalt(_ salt: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceID,
            kSecAttrAccount as String: saltID,
            kSecValueData as String: salt,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        // Vérifier si le sel existe déjà
        let checkQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceID,
            kSecAttrAccount as String: saltID,
            kSecReturnData as String: false
        ]
        
        let checkStatus = SecItemCopyMatching(checkQuery as CFDictionary, nil)
        
        if checkStatus == errSecItemNotFound {
            // Le sel n'existe pas, on l'ajoute
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw EncryptionError.saltStorageFailed
            }
        } else if checkStatus == errSecSuccess {
            // Le sel existe, on le met à jour
            let updateQuery: [String: Any] = [
                kSecValueData as String: salt
            ]
            let updateStatus = SecItemUpdate(checkQuery as CFDictionary, updateQuery as CFDictionary)
            if updateStatus != errSecSuccess {
                throw EncryptionError.saltStorageFailed
            }
        } else {
            throw EncryptionError.saltStorageFailed
        }
    }
    
    /// Récupère le sel du keychain ou en génère un nouveau
    private func generateOrRetrieveSalt() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceID,
            kSecAttrAccount as String: saltID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let saltData = item as? Data {
            return saltData
        } else {
            // Pas de sel trouvé, en générer un nouveau
            let newSalt = generateSalt()
            try storeSalt(newSalt)
            return newSalt
        }
    }
    
    /// Dérive une clé symétrique à partir de la clé maître et du sel
    private func deriveSymmetricKey(from masterKey: SymmetricKey, salt: Data) -> SymmetricKey {
        // Utiliser HKDF pour dériver une clé
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: Data("IndyCRM_Encryption".utf8),
            outputByteCount: 32 // 256 bits
        )
        
        return derivedKey
    }
    
    // MARK: - Erreurs
    
    enum EncryptionError: Error {
        case keyNotFound
        case keyStorageFailed
        case saltStorageFailed
        case encryptionFailed
        case decryptionFailed
        case invalidData
    }
}

// MARK: - Extensions utilitaires pour faciliter l'utilisation

extension String {
    /// Chiffre une chaîne de caractères avec le service de chiffrement partagé
    func encrypted() throws -> String {
        return try EncryptionService.shared.encrypt(self)
    }
    
    /// Déchiffre une chaîne de caractères avec le service de chiffrement partagé
    func decrypted() throws -> String {
        return try EncryptionService.shared.decrypt(self)
    }
}

// MARK: - Instance singleton pour un accès facile

extension EncryptionService {
    /// Instance partagée pour un accès facile depuis n'importe où dans l'application
    static let shared = EncryptionService()
} 