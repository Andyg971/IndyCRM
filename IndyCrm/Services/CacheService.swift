import Foundation

/// Service de mise en cache pour optimiser les performances de l'application
final class CacheService {
    static let shared = CacheService()
    private let cache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configuration du cache en mémoire
        cache.countLimit = 100 // Nombre maximum d'objets en cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB limite
        
        // Configuration du cache sur disque
        let documentsPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("IndyCRMCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Cache en mémoire
    
    /// Stocke un objet dans le cache mémoire
    func cache<T: AnyObject>(_ object: T, forKey key: String) {
        cache.setObject(object, forKey: key as NSString)
    }
    
    /// Récupère un objet du cache mémoire
    func object<T: AnyObject>(forKey key: String) -> T? {
        return cache.object(forKey: key as NSString) as? T
    }
    
    /// Supprime un objet du cache mémoire
    func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Vide le cache mémoire
    func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Cache sur disque
    
    /// Stocke des données sur le disque
    func saveToDisk(_ data: Data, forKey key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try data.write(to: fileURL)
        
        // Mise à jour du manifeste
        try updateManifest(addingKey: key)
    }
    
    /// Récupère des données du disque
    func dataFromDisk(forKey key: String) throws -> Data {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return try Data(contentsOf: fileURL)
    }
    
    /// Supprime des données du disque
    func removeFromDisk(forKey key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try fileManager.removeItem(at: fileURL)
        
        // Mise à jour du manifeste
        try updateManifest(removingKey: key)
    }
    
    /// Vide le cache disque
    func clearDiskCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for url in contents {
            try fileManager.removeItem(at: url)
        }
        try updateManifest(clear: true)
    }
    
    // MARK: - Gestion du cache
    
    /// Vérifie si une clé existe dans le cache (mémoire ou disque)
    func exists(forKey key: String) -> Bool {
        if cache.object(forKey: key as NSString) != nil {
            return true
        }
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Obtient la taille du cache disque
    func getDiskCacheSize() throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
        return try contents.reduce(0) { total, url in
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return total + (attributes[.size] as? Int64 ?? 0)
        }
    }
    
    /// Nettoie le cache si nécessaire (appelé périodiquement)
    func performMaintenance() throws {
        // Supprime les fichiers de plus d'une semaine
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        for url in contents {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let creationDate = attributes[.creationDate] as? Date,
               creationDate < oneWeekAgo {
                try fileManager.removeItem(at: url)
            }
        }
        
        // Vérifie la taille totale du cache
        let maxSize: Int64 = 100 * 1024 * 1024 // 100 MB
        if try getDiskCacheSize() > maxSize {
            try clearDiskCache()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateManifest(addingKey: String? = nil, removingKey: String? = nil, clear: Bool = false) throws {
        let manifestURL = cacheDirectory.appendingPathComponent("manifest.json")
        var manifest: [String: Date] = [:]
        
        if !clear, fileManager.fileExists(atPath: manifestURL.path) {
            let data = try Data(contentsOf: manifestURL)
            manifest = try JSONDecoder().decode([String: Date].self, from: data)
        }
        
        if let key = addingKey {
            manifest[key] = Date()
        }
        if let key = removingKey {
            manifest.removeValue(forKey: key)
        }
        
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: manifestURL)
    }
}

// MARK: - Extensions

extension CacheService {
    /// Stocke un objet Codable dans le cache
    func cache<T: Codable>(_ object: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(object)
        try saveToDisk(data, forKey: key)
        
        // Stocke aussi en mémoire si c'est un petit objet
        if data.count < 50 * 1024 { // < 50 KB
            cache.setObject(data as AnyObject, forKey: key as NSString)
        }
    }
    
    /// Récupère un objet Codable du cache
    func object<T: Codable>(forKey key: String) throws -> T {
        // Essaie d'abord le cache mémoire
        if let data = cache.object(forKey: key as NSString) as? Data {
            return try JSONDecoder().decode(T.self, from: data)
        }
        
        // Sinon, charge depuis le disque
        let data = try dataFromDisk(forKey: key)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Invalide complètement le cache pour une clé spécifique
    /// Cette méthode garantit que les données seront rechargées depuis leur source d'origine
    func invalidateCache(forKey key: String) {
        // Supprime du cache mémoire
        removeObject(forKey: key)
        
        // Supprime du cache disque si possible
        do {
            try removeFromDisk(forKey: key)
            print("🗑️ Cache invalidé pour la clé: \(key)")
        } catch {
            print("⚠️ Impossible d'invalider le cache disque pour la clé \(key): \(error.localizedDescription)")
        }
    }
    
    /// Invalide complètement tout le cache (mémoire et disque)
    func invalidateAllCaches() {
        // Vider le cache mémoire
        clearMemoryCache()
        
        // Vider le cache disque
        do {
            try clearDiskCache()
            print("🧹 Cache complètement vidé (mémoire et disque)")
        } catch {
            print("⚠️ Impossible de vider le cache disque: \(error.localizedDescription)")
        }
    }
} 