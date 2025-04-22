// The Swift Programming Language
// https://docs.swift.org/swift-book

/// IndyCRM - Application de gestion pour indépendants
///
/// Cette application permet aux indépendants de gérer :
/// - Leurs clients
/// - Leurs projets
/// - Leurs factures
/// - Leurs rapports d'activité
///
/// Développée avec SwiftUI et Core Data, elle offre :
/// - Une interface moderne et responsive
/// - La synchronisation via CloudKit
/// - Le support multi-plateformes (iOS et macOS)
/// - Une gestion complète des données métier

import SwiftUI

/// Point d'entrée principal de l'application IndyCRM
/// Gère la configuration initiale et la structure principale de l'interface
@main
struct IndyCRMApp: App {
    /// Contrôleur de données principal pour la persistance
    @StateObject private var dataController = DataController.shared
    
    /// Initialisation de l'application
    /// Configure les services essentiels au démarrage
    init() {
        LoggingService.info("Démarrage de l'application IndyCRM")
    }
    
    /// Configuration de la scène principale de l'application
    /// Définit la structure de navigation et les commandes disponibles
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environmentObject(AppState())
                .onAppear {
                    LoggingService.debug("Interface principale chargée")
                }
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Commandes de la barre latérale macOS
            SidebarCommands()
            
            // Menu personnalisé pour la création rapide
            CommandGroup(replacing: .newItem) {
                // Création rapide de client
                Button("Nouveau Client") {
                    LoggingService.debug("Commande : Création d'un nouveau client")
                    NotificationCenter.default.post(name: .createNewClient, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                // Création rapide de facture
                Button("Nouvelle Facture") {
                    LoggingService.debug("Commande : Création d'une nouvelle facture")
                    NotificationCenter.default.post(name: .createNewInvoice, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                // Création rapide de projet
                Button("Nouveau Projet") {
                    LoggingService.debug("Commande : Création d'un nouveau projet")
                    NotificationCenter.default.post(name: .createNewProject, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}

/// Extension définissant les notifications personnalisées de l'application
/// Ces notifications sont utilisées pour la communication entre les composants
extension Notification.Name {
    /// Notification émise pour créer un nouveau client
    static let createNewClient = Notification.Name("createNewClient")
    /// Notification émise pour créer une nouvelle facture
    static let createNewInvoice = Notification.Name("createNewInvoice")
    /// Notification émise pour créer un nouveau projet
    static let createNewProject = Notification.Name("createNewProject")
}

/// Gestion de l'état global de l'application
/// Cette classe maintient l'état partagé entre tous les composants
class AppState: ObservableObject {
    /// Onglet actuellement sélectionné dans la navigation principale
    @Published var selectedTab: AppTab = .dashboard {
        didSet {
            LoggingService.debug("Navigation vers l'onglet : \(selectedTab)")
        }
    }
    
    /// État d'affichage de la fenêtre des paramètres
    @Published var isShowingSettings = false {
        didSet {
            LoggingService.debug("Paramètres \(isShowingSettings ? "ouverts" : "fermés")")
        }
    }
    
    /// Thème actuel de l'application
    @Published var currentTheme: AppTheme = .system {
        didSet {
            LoggingService.info("Thème changé pour : \(currentTheme)")
        }
    }
    
    /// Message d'alerte actuellement affiché
    @Published var alertMessage: AlertMessage? {
        didSet {
            if let message = alertMessage {
                LoggingService.info("Nouvelle alerte affichée : \(message.title)")
            }
        }
    }
    
    /// Énumération des onglets disponibles dans l'application
    enum AppTab {
        /// Tableau de bord avec les indicateurs clés
        case dashboard
        /// Liste et gestion des clients
        case clients
        /// Liste et gestion des projets
        case projects
        /// Liste et gestion des factures
        case invoices
        /// Génération et consultation des rapports
        case reports
    }
    
    /// Énumération des thèmes disponibles
    enum AppTheme {
        /// Thème clair
        case light
        /// Thème sombre
        case dark
        /// Thème suivant les préférences système
        case system
    }
    
    /// Structure représentant un message d'alerte dans l'application
    struct AlertMessage: Identifiable {
        /// Identifiant unique du message
        let id = UUID()
        /// Titre du message
        let title: String
        /// Contenu détaillé du message
        let message: String
        /// Type d'alerte
        let type: AlertType
        
        /// Types d'alertes disponibles
        enum AlertType {
            /// Information simple
            case info
            /// Succès d'une opération
            case success
            /// Avertissement
            case warning
            /// Erreur
            case error
        }
    }
}
