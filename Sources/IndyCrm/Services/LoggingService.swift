import Foundation
import OSLog

/// Service de logging centralisé pour IndyCRM
///
/// Ce service fournit une interface unifiée pour enregistrer les événements, erreurs et informations
/// de débogage dans l'application. Il utilise le système de logging natif d'Apple (OSLog) pour
/// une meilleure intégration avec les outils système.
///
/// Caractéristiques principales :
/// - Singleton accessible via `LoggingService.shared`
/// - 5 niveaux de log : debug, info, warning, error, critical
/// - Support du mode DEBUG avec affichage console
/// - Intégration avec OSLog pour les logs système
/// - Capture automatique du contexte (fichier, fonction, ligne)
class LoggingService {
    /// Instance partagée unique du service (pattern Singleton)
    static let shared = LoggingService()
    
    /// Logger système utilisé pour l'enregistrement permanent des logs
    private let logger: Logger
    
    /// Niveaux de log disponibles avec leurs emojis associés pour une meilleure visibilité
    ///
    /// - debug : Informations détaillées pour le développement
    /// - info : Événements normaux du cycle de vie de l'application
    /// - warning : Situations anormales mais non critiques
    /// - error : Erreurs récupérables
    /// - critical : Erreurs graves nécessitant une attention immédiate
    enum LogLevel: String {
        case debug = "🔍 DEBUG"    // Informations de débogage détaillées
        case info = "ℹ️ INFO"      // Informations générales sur le fonctionnement
        case warning = "⚠️ WARNING" // Avertissements non critiques
        case error = "❌ ERROR"     // Erreurs récupérables
        case critical = "🚨 CRITICAL" // Erreurs critiques système
    }
    
    /// Initialisation privée du service
    /// Configure le logger système avec l'identifiant du bundle de l'application
    private init() {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.indycrm",
            category: "IndyCRM"
        )
    }
    
    /// Fonction centrale de logging qui gère l'enregistrement des messages
    ///
    /// Cette fonction :
    /// 1. Formate le message avec le contexte (fichier, ligne, fonction)
    /// 2. Enregistre dans le logger système
    /// 3. Affiche dans la console en mode DEBUG
    ///
    /// - Parameters:
    ///   - message: Le message à logger
    ///   - level: Le niveau de gravité du log
    ///   - file: Le fichier source (automatique)
    ///   - function: La fonction appelante (automatique)
    ///   - line: La ligne de code (automatique)
    private func log(_ message: String, level: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        // Enregistrement dans le logger système avec le niveau approprié
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error, .critical:
            logger.error("\(logMessage)")
        }
        
        // Affichage console en mode DEBUG uniquement
        #if DEBUG
        print("\(level.rawValue) - \(logMessage)")
        #endif
    }
    
    // MARK: - Méthodes publiques de logging
    
    /// Enregistre un message de débogage
    /// Utilisé pour les informations détaillées utiles pendant le développement
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Enregistre une information générale
    /// Utilisé pour les événements normaux du cycle de vie de l'application
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Enregistre un avertissement
    /// Utilisé pour les situations anormales mais non critiques
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Enregistre une erreur
    /// Utilisé pour les erreurs récupérables
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Enregistre une erreur critique
    /// Utilisé pour les erreurs graves nécessitant une attention immédiate
    static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.log(message, level: .critical, file: file, function: function, line: line)
    }
}

/// Extension pour faciliter le logging des erreurs Swift
extension Error {
    /// Enregistre automatiquement l'erreur avec son message localisé
    /// Utilisation : `error.log()` au lieu de `LoggingService.error(error.localizedDescription)`
    func log(file: String = #file, function: String = #function, line: Int = #line) {
        LoggingService.error("\(self.localizedDescription)", file: file, function: function, line: line)
    }
} 