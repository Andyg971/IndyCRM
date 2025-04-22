import Foundation
import Compression
import os.log
import CryptoKit
import UIKit // Ajouter l'import pour UIDevice
import CommonCrypto

/// Service gérant les sauvegardes automatiques de l'application
class BackupService {
    static let shared: BackupService = {
        do {
            return try BackupService()
        } catch {
            fatalError("Impossible de créer le dossier de sauvegarde : \(error.localizedDescription)")
        }
    }()
    
    /// Nombre maximum de sauvegardes à conserver
    private var maxBackups: Int // Rendre var pour pouvoir la modifier
    private let fileManager = FileManager.default
    private let backupDirectory: URL
    private let temporaryBackupDirectory: URL // Déclarer ici
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.indycrm", category: "Backup")
    
    // URLs pour les fichiers de données principaux (utilisées pour la sauvegarde temporaire)
    // Assurez-vous que ces noms correspondent à ceux utilisés dans les managers
    private let contactsDataURL: URL
    private let projectsDataURL: URL
    private let invoicesDataURL: URL
    
    private let dateFormatter: DateFormatter
    
    // Taille maximale des données pour un traitement direct
    private let maxDirectDataSize = 1024 * 1024 // 1MB
    
    // Taille maximale d'un chunk
    private let maxChunkSize = 500 * 1024 // 500KB
    
    private init() throws {
        logger.info("Initialisation du service de sauvegarde")
        // Configuration par défaut
        self.maxBackups = UserDefaults.standard.integer(forKey: "MaxBackups") > 0 
            ? UserDefaults.standard.integer(forKey: "MaxBackups") 
            : 5
        
        // Chemins
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.backupDirectory = documentsPath.appendingPathComponent("Backups")
        // Placer le dossier temporaire à côté du dossier Backups
        self.temporaryBackupDirectory = documentsPath.appendingPathComponent("TemporaryBackup_IndyCRM") 
        
        // Définir les URLs des fichiers de données principaux
        // Assurez-vous que ces noms correspondent aux 'saveKey' des managers
        self.contactsDataURL = documentsPath.appendingPathComponent("SavedContacts.json") // Nom supposé pour les contacts
        self.projectsDataURL = documentsPath.appendingPathComponent("SavedProjects.json")
        self.invoicesDataURL = documentsPath.appendingPathComponent("SavedInvoices.json")
        
        // Création des dossiers si nécessaire
        try fileManager.createDirectory(at: self.backupDirectory, withIntermediateDirectories: true, attributes: nil)
        // Nettoyer et créer le dossier temporaire au démarrage
        try? fileManager.removeItem(at: self.temporaryBackupDirectory)
        try fileManager.createDirectory(at: self.temporaryBackupDirectory, withIntermediateDirectories: true, attributes: nil)
        
        logger.info("Dossier de sauvegarde : \(self.backupDirectory.path)")
        logger.info("Dossier de sauvegarde temporaire : \(self.temporaryBackupDirectory.path)")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    }
    
    /// Configure le nombre maximum de sauvegardes à conserver
    func setMaxBackups(_ count: Int) {
        guard count > 0 else {
            logger.error("Le nombre maximum de sauvegardes doit être supérieur à 0")
            return
        }
        UserDefaults.standard.set(count, forKey: "MaxBackups")
        logger.info("Nombre maximum de sauvegardes configuré à : \(count)")
    }
    
    /// Crée une sauvegarde complète des données en utilisant les managers fournis
    @MainActor
    func createBackup(
        contactsManager: ContactsManager,
        projectManager: ProjectManager,
        invoiceManager: InvoiceManager
    ) async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        let timestamp = dateFormatter.string(from: Date())
        let backupName = "backup_\(timestamp)".replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: "+", with: "Z")
        let backupURL = backupDirectory.appendingPathComponent(backupName)
        
        logger.info("Début de la création de la sauvegarde : \(backupName)")
        
        // Création du dossier de sauvegarde
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
        
        do {
            // Sauvegarde des contacts avec gestion des grandes données
            logger.debug("Sauvegarde des contacts...")
            let contactsData = try contactsManager.getContactsDataForBackup()
            
            // Utiliser la méthode de traitement par blocs pour les grands jeux de données
            if contactsData.count > 1 * 1024 * 1024 { // Si plus de 1MB
                try await saveDataInChunks(contactsData, fileName: "contacts", in: backupURL)
            } else {
                let contactsCompressedData = try compressData(contactsData)
                try writeData(contactsCompressedData, to: backupURL.appendingPathComponent("contacts.data"))
            }
            
            // Sauvegarde des projets avec gestion des grandes données
            logger.debug("Sauvegarde des projets...")
            let projectsData = try projectManager.getProjectsDataForBackup()
            
            if projectsData.count > 1 * 1024 * 1024 { // Si plus de 1MB
                try await saveDataInChunks(projectsData, fileName: "projects", in: backupURL)
            } else {
                let projectsCompressedData = try compressData(projectsData)
                try writeData(projectsCompressedData, to: backupURL.appendingPathComponent("projects.data"))
            }
            
            // Sauvegarde des factures avec gestion des grandes données
            logger.debug("Sauvegarde des factures...")
            let invoicesData = try invoiceManager.getInvoicesDataForBackup()
            
            if invoicesData.count > 1 * 1024 * 1024 { // Si plus de 1MB
                try await saveDataInChunks(invoicesData, fileName: "invoices", in: backupURL)
            } else {
                let invoicesCompressedData = try compressData(invoicesData)
                try writeData(invoicesCompressedData, to: backupURL.appendingPathComponent("invoices.data"))
            }
            
            // Création du fichier manifest
            logger.debug("Création du manifest...")
            try createManifest(at: backupURL, timestamp: timestamp)
            
            // Nettoyage des anciennes sauvegardes
            logger.debug("Nettoyage des anciennes sauvegardes...")
            try cleanupOldBackups()
            
            logger.info("Sauvegarde terminée avec succès : \(backupName)")
        } catch {
            logger.error("Erreur lors de la création de la sauvegarde : \(error.localizedDescription)")
            // Nettoyage en cas d'erreur
            try? fileManager.removeItem(at: backupURL)
            throw error
        }
    }
    
    /// Restaure une sauvegarde spécifique en utilisant les managers fournis
    @MainActor
    func restoreBackup(
        named backupName: String,
        contactsManager: ContactsManager,
        projectManager: ProjectManager,
        invoiceManager: InvoiceManager
    ) async throws {
        logger.info("Début de la restauration de la sauvegarde : \(backupName)")
        
        let backupURL = backupDirectory.appendingPathComponent(backupName)
        guard fileManager.fileExists(atPath: backupURL.path) else {
            logger.error("Sauvegarde non trouvée : \(backupName)")
            throw BackupError.backupNotFound
        }
        
        // Vérification du manifest
        let manifestURL = backupURL.appendingPathComponent("manifest.json")
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            let reason = "Fichier manifest.json manquant"
            logger.error("\(reason) dans la sauvegarde : \(backupName)")
            throw BackupError.invalidBackup(reason: reason)
        }
        
        do {
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(BackupManifest.self, from: manifestData)
            
            // Vérification de la version
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            guard manifest.appVersion == currentVersion else {
                logger.error("Version incompatible. Sauvegarde : \(manifest.appVersion), Application : \(currentVersion)")
                throw BackupError.incompatibleVersion
            }
            
            logger.debug("Création d'une sauvegarde temporaire...")
            try await createTemporaryBackup(
                contactsManager: contactsManager,
                projectManager: projectManager,
                invoiceManager: invoiceManager
            )
            
            do {
                // Restauration des données avec les nouvelles méthodes
                logger.debug("Restauration des contacts...")
                let contactsFileURL = backupURL.appendingPathComponent("contacts.data")
                logger.debug("Tentative de lecture du fichier contacts: \(contactsFileURL.path)")
                guard fileManager.fileExists(atPath: contactsFileURL.path) else {
                    logger.error("Fichier contacts.data non trouvé: \(contactsFileURL.path)")
                    throw BackupError.fileSystemError(reason: "Fichier contacts.data non trouvé")
                }
                
                let contactsCompressedData = try readData(from: contactsFileURL)
                logger.debug("Fichier contacts lu avec succès, taille: \(contactsCompressedData.count) octets")
                
                logger.debug("Tentative de décompression des données contacts")
                let contactsData = try decompressData(contactsCompressedData)
                logger.debug("Données contacts décompressées avec succès, taille: \(contactsData.count) octets")
                
                logger.debug("Tentative de restauration des contacts vers le gestionnaire")
                try await contactsManager.restoreContacts(from: contactsData)
                logger.debug("Contacts restaurés avec succès")
                
                logger.debug("Restauration des projets...")
                let projectsFileURL = backupURL.appendingPathComponent("projects.data")
                logger.debug("Tentative de lecture du fichier projets: \(projectsFileURL.path)")
                guard fileManager.fileExists(atPath: projectsFileURL.path) else {
                    logger.error("Fichier projects.data non trouvé: \(projectsFileURL.path)")
                    throw BackupError.fileSystemError(reason: "Fichier projects.data non trouvé")
                }
                
                let projectsCompressedData = try readData(from: projectsFileURL)
                logger.debug("Fichier projets lu avec succès, taille: \(projectsCompressedData.count) octets")
                
                logger.debug("Tentative de décompression des données projets")
                let projectsData = try decompressData(projectsCompressedData)
                logger.debug("Données projets décompressées avec succès, taille: \(projectsData.count) octets")
                
                logger.debug("Tentative de restauration des projets vers le gestionnaire")
                try await projectManager.restoreProjects(from: projectsData)
                logger.debug("Projets restaurés avec succès")
                
                logger.debug("Restauration des factures...")
                let invoicesFileURL = backupURL.appendingPathComponent("invoices.data")
                logger.debug("Tentative de lecture du fichier factures: \(invoicesFileURL.path)")
                guard fileManager.fileExists(atPath: invoicesFileURL.path) else {
                    logger.error("Fichier invoices.data non trouvé: \(invoicesFileURL.path)")
                    throw BackupError.fileSystemError(reason: "Fichier invoices.data non trouvé")
                }
                
                let invoicesCompressedData = try readData(from: invoicesFileURL)
                logger.debug("Fichier factures lu avec succès, taille: \(invoicesCompressedData.count) octets")
                
                logger.debug("Tentative de décompression des données factures")
                let invoicesData = try decompressData(invoicesCompressedData)
                logger.debug("Données factures décompressées avec succès, taille: \(invoicesData.count) octets")
                
                logger.debug("Tentative de restauration des factures vers le gestionnaire")
                try await invoiceManager.restoreInvoices(from: invoicesData)
                logger.debug("Factures restaurées avec succès")
                
                logger.debug("Suppression de la sauvegarde temporaire...")
                try deleteTemporaryBackup()
                
                logger.info("Restauration terminée avec succès : \(backupName)")
            } catch {
                // Ce bloc catch est celui qui doit gérer les erreurs de restauration
                logger.error("Erreur pendant la restauration: \(error.localizedDescription)")
                logger.error("Type d'erreur: \(type(of: error))")
                if let nsError = error as NSError? {
                    logger.error("Code: \(nsError.code), Domaine: \(nsError.domain)")
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                        logger.error("Erreur sous-jacente: \(underlyingError.localizedDescription)")
                    }
                }
                
                logger.error("Retour à la sauvegarde temporaire...")
                do {
                    try await restoreFromTemporaryBackup(
                        contactsManager: contactsManager,
                        projectManager: projectManager,
                        invoiceManager: invoiceManager
                    )
                    logger.debug("Retour à la sauvegarde temporaire réussi")
                } catch {
                    logger.error("Échec du retour à la sauvegarde temporaire: \(error.localizedDescription)")
                }
                
                // Propager l'erreur originale qui a causé l'échec de la restauration
                throw BackupError.restorationFailed(reason: error.localizedDescription, underlyingError: error)
            }
        } catch let error as BackupError {
             logger.error("Erreur de restauration (BackupError): \(error.localizedDescription)")
             throw error // Relancer les erreurs de type BackupError déjà connues
        } catch {
            logger.error("Erreur inattendue lors de la lecture du manifest ou autre : \(error.localizedDescription)")
            throw BackupError.unknownError(underlyingError: error) // Encapsuler les autres erreurs
        }
    }
    
    /// Liste toutes les sauvegardes disponibles
    func listBackups() throws -> [BackupInfo] {
        logger.debug("Listage des sauvegardes disponibles...")
        // S'assurer de ne lister que les dossiers et de récupérer les bonnes clés
        let contents = try fileManager.contentsOfDirectory(at: backupDirectory,
                                                           includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
                                                           options: .skipsHiddenFiles)

        let backups = try contents.compactMap { url -> BackupInfo? in
            let resourceValues = try url.resourceValues(forKeys: [.creationDateKey, .isDirectoryKey])
            // Ignorer les fichiers et ne garder que les dossiers
            guard resourceValues.isDirectory == true else { return nil }

            let creationDate = resourceValues.creationDate ?? Date()
            // Essayer de lire la date du manifest pour plus de précision
            let manifestURL = url.appendingPathComponent("manifest.json")
            var manifestDate = creationDate // Utiliser la date de création comme fallback
            if fileManager.fileExists(atPath: manifestURL.path) {
                 if let manifestData = try? Data(contentsOf: manifestURL),
                    let manifest = try? JSONDecoder().decode(BackupManifest.self, from: manifestData),
                    // Utiliser ISO8601DateFormatter pour parser la date du manifest
                    let dateFromManifest = ISO8601DateFormatter().date(from: manifest.creationDate) {
                     manifestDate = dateFromManifest
                 } else {
                     logger.warning("Impossible de lire la date depuis le manifest pour \(url.lastPathComponent)")
                 }
            }

            return BackupInfo(name: url.lastPathComponent, creationDate: manifestDate)
        }.sorted { $0.creationDate > $1.creationDate } // Trier par date (manifest ou création) la plus récente en premier

        logger.info("\(backups.count) sauvegarde(s) trouvée(s)")
        return backups
    }
    
    /// Supprime une sauvegarde spécifique
    func deleteBackup(named backupName: String) throws {
        logger.info("Suppression de la sauvegarde : \(backupName)")
        
        let backupURL = backupDirectory.appendingPathComponent(backupName)
        guard fileManager.fileExists(atPath: backupURL.path) else {
            logger.error("Sauvegarde non trouvée : \(backupName)")
            throw BackupError.backupNotFound
        }
        
        do {
            try fileManager.removeItem(at: backupURL)
            logger.info("Sauvegarde supprimée avec succès : \(backupName)")
        } catch {
            logger.error("Erreur lors de la suppression de la sauvegarde : \(error.localizedDescription)")
            throw BackupError.fileSystemError(reason: "Impossible de supprimer la sauvegarde : \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Compresse les données selon l'algorithme ZLIB
    private func compressData(_ data: Data) throws -> Data {
        logger.debug("Début de la compression des données (\(data.count) octets)")
        
        // Si les données sont trop petites, retourner les données non compressées
        if data.count < 100 {
            logger.debug("Données trop petites pour compression (\(data.count) octets), retour sans compression")
            return data
        }
        
        // Allocation d'un buffer beaucoup plus grand pour la compression
        // On utilise 4x plus grand pour s'assurer qu'il y a assez d'espace
        let bufferSize = max(data.count * 4, 1024 * 1024) // Au moins 1MB, 4x la taille source
        
        logger.debug("Allocation buffer de compression: \(bufferSize) octets")
        
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destinationBuffer.deallocate() }
        
        var sourceBuffer = Array<UInt8>(data)
        
        // Essayer la compression avec différents algorithmes si la première méthode échoue
        for compressionAlgorithm in [COMPRESSION_ZLIB, COMPRESSION_LZFSE, COMPRESSION_LZ4] {
            logger.debug("Tentative de compression avec algorithme: \(String(describing: compressionAlgorithm))")
            
            // Type explicite pour la fonction de compression
            let compressedSize: Int = Int(compression_encode_buffer(
                destinationBuffer,
                bufferSize,
                &sourceBuffer,
                sourceBuffer.count,
                nil,
                compressionAlgorithm
            ))
            
            if compressedSize > 0 {
                let compressedData: Data = Data(bytes: destinationBuffer, count: compressedSize)
                let compressionRatio: Double = (Double(compressedSize) / Double(data.count)) * 100.0
                logger.debug("Compression réussie avec algorithme \(String(describing: compressionAlgorithm)). Taille finale : \(compressedData.count) octets (ratio: \(String(format: "%.1f", compressionRatio))%)")
                return compressedData
            }
            
            logger.warning("Échec compression avec algorithme \(String(describing: compressionAlgorithm)), essai suivant")
        }
        
        // Si toutes les compressions ont échoué, essayer la méthode alternative
        logger.warning("Échec de toutes les méthodes de compression standard, tentative méthode alternative")
        return try alternativeCompression(data)
    }
    
    /// Méthode alternative de compression au cas où la méthode principale échoue
    private func alternativeCompression(_ data: Data) throws -> Data {
        logger.debug("Utilisation de la méthode alternative de compression")
        
        do {
            // Tentative avec la méthode Data.compressed si disponible
            if #available(iOS 13.0, *) {
                #if canImport(Compression)
                return try (data as NSData).compressed(using: .zlib) as Data
                #else
                return data
                #endif
            }
            
            // Tentative avec NSData en fallback
            if let compressedData = try? (data as NSData).compressed(using: .zlib) as Data {
                logger.debug("Compression NSData réussie. Taille finale : \(compressedData.count) octets")
                return compressedData
            }
            
            throw BackupError.compressionFailed(reason: "Toutes les méthodes de compression ont échoué")
        } catch {
            logger.error("Toutes les méthodes de compression ont échoué: \(error.localizedDescription)")
            
            // En dernier recours, retourner les données non compressées
            logger.warning("IMPORTANT: Retour des données non compressées comme dernier recours")
            return data
        }
    }
    
    /// Décompresse les données
    private func decompressData(_ data: Data) throws -> Data {
        logger.debug("Début de la décompression des données (\(data.count) octets)")
        
        // Essayer d'abord la décompression standard avec un buffer plus grand
        // Estimation de la taille décompressée (généralement 2-10 fois plus grande)
        let estimatedSize = data.count * 10
        
        // Vérifier que le buffer n'est pas trop grand
        guard estimatedSize > 0 && estimatedSize < 100 * 1024 * 1024 else { // Max 100MB 
            logger.error("Estimation de taille décompressée trop grande: \(estimatedSize) octets")
            // Essayer avec une taille plus raisonnable
            return try alternativeDecompression(data)
        }
        
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: estimatedSize)
        defer { destinationBuffer.deallocate() }
        
        var sourceBuffer = Array<UInt8>(data)
        
        // Type explicite pour la fonction de décompression
        let decompressedSize: Int = Int(compression_decode_buffer(
            destinationBuffer,
            estimatedSize,
            &sourceBuffer,
            sourceBuffer.count,
            nil,
            COMPRESSION_ZLIB
        ))
        
        if decompressedSize > 0 {
            let decompressedData: Data = Data(bytes: destinationBuffer, count: decompressedSize)
            logger.debug("Décompression terminée. Taille finale : \(decompressedData.count) octets")
            return decompressedData
        } else {
            logger.warning("Échec de la décompression standard, tentative de méthode alternative")
            return try alternativeDecompression(data)
        }
    }
    
    /// Méthode de décompression alternative
    private func alternativeDecompression(_ data: Data) throws -> Data {
        logger.debug("Tentative de décompression alternative")
        
        #if canImport(Compression)
        // Si disponible, essayer une autre méthode de décompression
        if #available(iOS 13.0, *) {
            do {
                return try (data as NSData).decompressed(using: .zlib) as Data
            } catch {
                logger.warning("Décompression alternative a échoué: \(error.localizedDescription)")
                // Si les données n'ont pas été compressées par notre méthode alternative,
                // renvoyons simplement les données telles quelles
                return data
            }
        }
        #endif
        
        // Si nous arrivons ici, supposons que les données n'ont pas été compressées
        // et retournons-les telles quelles
        logger.warning("Retour des données sans décompression comme solution de secours")
        return data
    }
    
    /// Vérifie l'existence d'un dossier et le crée si nécessaire
    private func ensureDirectoryExists(at url: URL) throws {
        logger.debug("Vérification du dossier : \(url.path)")
        var isDirectory: ObjCBool = false
        
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                logger.debug("Le dossier existe déjà")
                return
            }
            logger.error("Un fichier existe déjà à l'emplacement du dossier")
            throw BackupError.fileSystemError(reason: "Un fichier existe déjà à cet emplacement")
        }
        
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            logger.debug("Dossier créé avec succès")
        } catch {
            logger.error("Impossible de créer le dossier : \(error.localizedDescription)")
            throw BackupError.fileSystemError(reason: "Impossible de créer le dossier")
        }
    }
    
    /// Écrit des données dans un fichier
    private func writeData(_ data: Data, to url: URL) throws {
        logger.debug("Écriture des données vers : \(url.path)")
        
        // Calcul du hash avant l'écriture
        let hash = calculateHash(data)
        let hashURL = url.deletingPathExtension().appendingPathExtension("hash")
        
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            logger.debug("Fichier existant supprimé")
        }
        
        do {
            try data.write(to: url)
            try hash.write(to: hashURL, atomically: true, encoding: String.Encoding.utf8)
            logger.debug("Données écrites avec succès (\(data.count) octets)")
        } catch {
            logger.error("Impossible d'écrire les données : \(error.localizedDescription)")
            throw BackupError.fileSystemError(reason: "Impossible d'écrire les données")
        }
    }
    
    /// Lit des données depuis un fichier
    private func readData(from url: URL) throws -> Data {
        logger.debug("Lecture des données depuis : \(url.path)")
        
        guard fileManager.fileExists(atPath: url.path) else {
            logger.error("Fichier non trouvé : \(url.path)")
            throw BackupError.fileSystemError(reason: "Fichier non trouvé")
        }
        
        let hashURL = url.deletingPathExtension().appendingPathExtension("hash")
        
        do {
            let data = try Data(contentsOf: url)
            if let expectedHash = try? String(contentsOf: hashURL, encoding: .utf8) {
                guard verifyDataIntegrity(data, expectedHash: expectedHash) else {
                    logger.error("Vérification d'intégrité échouée pour : \(url.path)")
                    throw BackupError.fileSystemError(reason: "Intégrité des données compromise")
                }
            }
            logger.debug("Données lues avec succès (\(data.count) octets)")
            return data
        } catch {
            logger.error("Impossible de lire les données : \(error.localizedDescription)")
            throw BackupError.fileSystemError(reason: "Impossible de lire les données")
        }
    }
    
    // Les méthodes backupContacts, restoreContacts, backupProjects, restoreProjects, backupInvoices, restoreInvoices 
    // ont été remplacées par l'utilisation directe des méthodes des managers (getXxxDataForBackup, restoreXxx)
    
    // Utilisation de UIDevice nécessite UIKit/SwiftUI
    private func createManifest(at backupFolderURL: URL, timestamp: String) throws {
        let manifestURL = backupFolderURL.appendingPathComponent("manifest.json")
        let manifest = BackupManifest(
            creationDate: timestamp, // Utiliser le timestamp ISO8601 passé en paramètre
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            deviceModel: UIDevice.current.model, // Ajouter infos appareil
            systemVersion: UIDevice.current.systemVersion,
            contents: ["contacts", "projects", "invoices"] // Liste des données incluses
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)
        let compressedData = try compressData(data)
        try compressedData.write(to: manifestURL)
    }
    
    /// Nettoie les anciennes sauvegardes
    private func cleanupOldBackups() throws {
        logger.debug("Début du nettoyage des anciennes sauvegardes")
        
        let backups = try listBackups()
        guard backups.count > maxBackups else {
            logger.debug("Pas besoin de nettoyage (nombre de sauvegardes : \(backups.count))")
            return
        }
        
        let backupsToDelete = backups[maxBackups...]
        for backup in backupsToDelete {
            let backupURL = backupDirectory.appendingPathComponent(backup.name)
            do {
                try fileManager.removeItem(at: backupURL)
                logger.info("Sauvegarde supprimée : \(backup.name)")
            } catch {
                logger.error("Impossible de supprimer la sauvegarde \(backup.name) : \(error.localizedDescription)")
                throw BackupError.fileSystemError(reason: "Impossible de supprimer une ancienne sauvegarde")
            }
        }
        
        logger.debug("Nettoyage terminé. \(backupsToDelete.count) sauvegarde(s) supprimée(s)")
    }
    
    /// Crée une sauvegarde temporaire
    private func createTemporaryBackup(
        contactsManager: ContactsManager,
        projectManager: ProjectManager,
        invoiceManager: InvoiceManager
    ) async throws {
        logger.debug("Création d'une sauvegarde temporaire")
        let tempURL = backupDirectory.appendingPathComponent("temp_backup")
        
        do {
            if fileManager.fileExists(atPath: tempURL.path) {
                try fileManager.removeItem(at: tempURL)
                logger.debug("Ancienne sauvegarde temporaire supprimée")
            }
            
            try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
            
            // Sauvegarde des données avec les nouvelles méthodes
            // Contacts
            let contactsData = try await contactsManager.getContactsDataForBackup() // Ajouter await
            let contactsCompressedData = try compressData(contactsData)
            try writeData(contactsCompressedData, to: tempURL.appendingPathComponent("contacts.data"))
            
            // Projets
            let projectsData = try await projectManager.getProjectsDataForBackup() // Ajouter await
            let projectsCompressedData = try compressData(projectsData)
            try writeData(projectsCompressedData, to: tempURL.appendingPathComponent("projects.data"))
            
            // Factures
            let invoicesData = try await invoiceManager.getInvoicesDataForBackup() // Ajouter await
            let invoicesCompressedData = try compressData(invoicesData)
            try writeData(invoicesCompressedData, to: tempURL.appendingPathComponent("invoices.data"))
            
            logger.info("Sauvegarde temporaire créée avec succès")
        } catch {
            logger.error("Erreur lors de la création de la sauvegarde temporaire : \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Restaure depuis la sauvegarde temporaire
    private func restoreFromTemporaryBackup(
        contactsManager: ContactsManager,
        projectManager: ProjectManager,
        invoiceManager: InvoiceManager
    ) async throws {
        logger.debug("Début de la restauration depuis la sauvegarde temporaire")
        let tempURL = backupDirectory.appendingPathComponent("temp_backup")
        
        guard fileManager.fileExists(atPath: tempURL.path) else {
            logger.error("Sauvegarde temporaire non trouvée")
            throw BackupError.backupNotFound
        }
        
        do {
            // Restauration des données avec les nouvelles méthodes
            // Contacts
            let contactsFileURL = tempURL.appendingPathComponent("contacts.data")
            let contactsCompressedData = try readData(from: contactsFileURL)
            let contactsData = try decompressData(contactsCompressedData)
            try await contactsManager.restoreContacts(from: contactsData)
            
            // Projets
            let projectsFileURL = tempURL.appendingPathComponent("projects.data")
            let projectsCompressedData = try readData(from: projectsFileURL)
            let projectsData = try decompressData(projectsCompressedData)
            try await projectManager.restoreProjects(from: projectsData)
            
            // Factures
            let invoicesFileURL = tempURL.appendingPathComponent("invoices.data")
            let invoicesCompressedData = try readData(from: invoicesFileURL)
            let invoicesData = try decompressData(invoicesCompressedData)
            try await invoiceManager.restoreInvoices(from: invoicesData)
            
            try deleteTemporaryBackup()
            logger.info("Restauration depuis la sauvegarde temporaire terminée")
        } catch {
            logger.error("Erreur lors de la restauration depuis la sauvegarde temporaire : \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Supprime la sauvegarde temporaire
    private func deleteTemporaryBackup() throws {
        logger.debug("Suppression de la sauvegarde temporaire")
        let tempURL = backupDirectory.appendingPathComponent("temp_backup")
        
        if fileManager.fileExists(atPath: tempURL.path) {
            do {
                try fileManager.removeItem(at: tempURL)
                logger.debug("Sauvegarde temporaire supprimée")
            } catch {
                logger.error("Impossible de supprimer la sauvegarde temporaire : \(error.localizedDescription)")
                throw BackupError.fileSystemError(reason: "Impossible de supprimer la sauvegarde temporaire")
            }
        } else {
            logger.debug("Aucune sauvegarde temporaire à supprimer")
        }
    }
    
    /// Calcule le hash SHA-256 des données
    private func calculateHash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Vérifie l'intégrité des données
    private func verifyDataIntegrity(_ data: Data, expectedHash: String) -> Bool {
        let actualHash = calculateHash(data)
        return actualHash == expectedHash
    }
    
    /// Sauvegarde des données en les divisant en blocs plus petits
    private func saveDataInChunks(_ data: Data, fileName: String, in directory: URL) async throws {
        logger.debug("Sauvegarde des données en chunks pour \(fileName)")
        
        let originalDataHash = data.sha256Hash // Calcul du hash pour vérifier l'intégrité
        
        // Créer le dossier pour les chunks
        let chunksDirectory = directory.appendingPathComponent("\(fileName)_chunks")
        try fileManager.createDirectory(at: chunksDirectory, withIntermediateDirectories: true)
        
        // Diviser les données en chunks
        var chunks = [String]()
        var chunkIndex = 0
        var remainingData = data
        
        while !remainingData.isEmpty {
            let chunkSize = min(maxChunkSize, remainingData.count)
            let chunk = remainingData.prefix(chunkSize)
            let compressedChunk = try compressData(Data(chunk))
            
            // Générer un nom unique pour le chunk
            let chunkFileName = "\(fileName)_\(chunkIndex).chunk"
            let chunkURL = chunksDirectory.appendingPathComponent(chunkFileName)
            
            // Sauvegarder le chunk
            try compressedChunk.write(to: chunkURL)
            chunks.append(chunkFileName)
            
            // Avancer dans les données
            if chunkSize < remainingData.count {
                remainingData = remainingData.dropFirst(chunkSize)
            } else {
                remainingData = Data()
            }
            
            chunkIndex += 1
            
            // Laisser respirer le processus
            if chunkIndex % 10 == 0 {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        // Créer et sauvegarder le manifeste
        let manifest: [String: Any] = [
            "fileName": fileName,
            "originalSize": data.count,
            "chunks": chunks,
            "chunkCount": chunks.count,
            "originalHash": originalDataHash,
            "createdAt": Date().timeIntervalSince1970
        ]
        
        let manifestData = try JSONSerialization.data(withJSONObject: manifest)
        try manifestData.write(to: directory.appendingPathComponent("\(fileName)_manifest.json"))
        
        logger.debug("Sauvegarde en chunks terminée: \(chunks.count) chunks pour \(fileName)")
    }
    
    /// Récupère des données sauvegardées en blocs
    private func loadDataFromChunks(at url: URL) throws -> Data {
        let chunksDir = url.appendingPathExtension("chunks")
        let manifestURL = chunksDir.appendingPathComponent("manifest.json")
        let hashURL = url.appendingPathExtension("hash")
        
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw BackupError.fileSystemError(reason: "Fichier manifest.json des blocs non trouvé")
        }
        
        // Charger le manifeste
        let manifestData = try Data(contentsOf: manifestURL)
        let chunkManifest = try JSONDecoder().decode([String: Int].self, from: manifestData)
        
        // Préparer le buffer pour les données reconstruites
        var fullData = Data()
        
        // Charger et ajouter chaque bloc dans l'ordre
        for i in 0..<chunkManifest.count {
            let chunkFileName = "chunk_\(i)"
            let chunkURL = chunksDir.appendingPathComponent(chunkFileName)
            
            guard fileManager.fileExists(atPath: chunkURL.path) else {
                throw BackupError.fileSystemError(reason: "Bloc \(chunkFileName) manquant")
            }
            
            // Lire et décompresser le bloc
            let compressedChunkData = try Data(contentsOf: chunkURL)
            let chunkData = try decompressData(compressedChunkData)
            
            // Ajouter au buffer
            fullData.append(chunkData)
        }
        
        // Vérifier l'intégrité des données
        if let expectedHash = try? String(contentsOf: hashURL, encoding: .utf8) {
            let actualHash = calculateHash(fullData)
            guard actualHash == expectedHash else {
                throw BackupError.fileSystemError(reason: "Intégrité des données compromise après reconstitution des blocs")
            }
        }
        
        return fullData
    }
}

import SwiftUI // Importer pour UIDevice et potentiellement Identifiable

// MARK: - Models

struct BackupInfo: Identifiable { // Conformer à Identifiable
    let id = UUID() // Ajouter un ID unique
    let name: String
    let creationDate: Date
}

struct BackupManifest: Codable {
    let creationDate: String
    let appVersion: String
    let deviceModel: String // Ajouter champ
    let systemVersion: String // Ajouter champ
    let contents: [String]
    
    // Pas besoin de CodingKeys si les noms correspondent
}

enum BackupError: LocalizedError { // Conformer à LocalizedError pour une meilleure gestion
    case backupNotFound
    case invalidBackup(reason: String) // Ajouter une raison
    case restorationFailed(reason: String, underlyingError: Error?) // Ajouter raison et erreur sous-jacente
    case incompatibleVersion
    case missingFile(String)
    case compressionFailed(reason: String)
    case decompressionFailed(reason: String)
    case tempBackupNotFound
    case fileSystemError(reason: String)
    case fileNotFound(path: String) // Ajouter ce cas utilisé dans readData
    case unknownError(underlyingError: Error) // Ajouter ce cas pour les erreurs inattendues

    var errorDescription: String? { // Implémenter errorDescription requis par LocalizedError
        switch self {
        case .backupNotFound:
            return "La sauvegarde demandée n'a pas été trouvée."
        case .invalidBackup(let reason):
            return "Sauvegarde invalide : \(reason)."
        case .restorationFailed(let reason, _):
            return "La restauration a échoué : \(reason)."
        case .incompatibleVersion:
            return "La version de l'application de la sauvegarde est incompatible avec la version actuelle."
        case .missingFile(let name):
            return "Fichier manquant dans la sauvegarde : \(name)."
        case .compressionFailed(let reason):
            return "Échec de la compression : \(reason)."
        case .decompressionFailed(let reason):
            return "Échec de la décompression : \(reason)."
        case .tempBackupNotFound:
            return "La sauvegarde temporaire n'a pas été trouvée."
        case .fileSystemError(let reason):
            return "Erreur du système de fichiers : \(reason)."
        case .fileNotFound(let path):
             return "Fichier non trouvé : \(path)."
        case .unknownError(let underlyingError):
            return "Une erreur inconnue s'est produite : \(underlyingError.localizedDescription)."
        }
    }
    
    // Optionnel: Fournir plus de détails si nécessaire
    var failureReason: String? { 
        switch self {
        case .restorationFailed(_, let underlyingError):
            return underlyingError?.localizedDescription
        case .unknownError(let underlyingError):
            return underlyingError.localizedDescription
        default:
            return nil
        }
    }
}

// Extension pour le calcul du hash SHA-256
extension Data {
    var sha256Hash: String {
        let hash = withUnsafeBytes { bytes -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
} 