import Foundation
import CoreData
import SwiftUI

/// Contrôleur principal de la persistance des données pour IndyCRM
///
/// Ce contrôleur gère toutes les opérations de persistance des données via Core Data et CloudKit.
/// Il implémente le pattern Singleton pour assurer une instance unique dans l'application.
///
/// Fonctionnalités principales :
/// - Gestion du stockage Core Data
/// - Synchronisation avec CloudKit
/// - Gestion des changements en temps réel
/// - Support du mode test (stockage en mémoire)
/// - Création de données d'exemple
///
/// Usage typique :
/// ```swift
/// let dataController = DataController.shared
/// let context = dataController.container.viewContext
/// // Utiliser le context pour les opérations Core Data
/// ```
class DataController: ObservableObject {
    /// Instance partagée unique du contrôleur (pattern Singleton)
    /// Utilisée pour accéder au contrôleur depuis n'importe où dans l'application
    static let shared = DataController()
    
    /// Container Core Data principal
    /// Gère le modèle de données et les stores persistants
    let container: NSPersistentCloudKitContainer
    
    /// Initialise le contrôleur de données
    /// - Parameter inMemory: Si true, utilise un stockage temporaire en mémoire (utile pour les tests)
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "IndyCRMModel")
        
        // Configuration du stockage
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            LoggingService.info("Initialisation du DataController en mode mémoire")
        } else {
            LoggingService.info("Initialisation du DataController avec stockage persistant")
        }
        
        // Configuration de CloudKit
        if let description = container.persistentStoreDescriptions.first {
            // Active la notification des changements distants
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // Active le suivi de l'historique pour la synchronisation
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            LoggingService.debug("Configuration CloudKit activée")
        }
        
        // Chargement des stores persistants
        container.loadPersistentStores { description, error in
            if let error = error {
                LoggingService.critical("Erreur fatale lors du chargement de Core Data: \(error.localizedDescription)")
                fatalError("Impossible de charger Core Data: \(error.localizedDescription)")
            }
            LoggingService.info("Stores persistants chargés avec succès")
        }
        
        // Configuration de la fusion automatique des changements
        container.viewContext.automaticallyMergesChangesFromParent = true
        // En cas de conflit, les données locales sont prioritaires
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configuration de l'observation des changements CloudKit
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(self.processRemoteChanges),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
        LoggingService.debug("Observateur de changements CloudKit configuré")
    }
    
    /// Traite les changements reçus de CloudKit
    /// Cette méthode est appelée automatiquement lorsque des modifications sont synchronisées depuis d'autres appareils
    @objc private func processRemoteChanges(_ notification: Notification) {
        LoggingService.info("Changements distants détectés via CloudKit")
        // Notifie l'interface utilisateur des changements
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Sauvegarde les modifications en attente dans le contexte
    /// Cette méthode doit être appelée après toute modification des données
    /// Elle ne fait rien si aucune modification n'est en attente
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                LoggingService.info("Données sauvegardées avec succès")
            } catch {
                LoggingService.error("Échec de la sauvegarde des données")
                error.log()
            }
        }
    }
    
    /// Crée un jeu de données d'exemple pour les tests et démonstrations
    /// Cette méthode génère :
    /// - Un client exemple
    /// - Un projet associé
    /// - Une facture avec un élément
    func createSampleData() {
        LoggingService.info("Création des données d'exemple")
        let viewContext = container.viewContext
        
        // Création d'un client exemple avec des informations de base
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Entreprise Exemple"
        client.email = "contact@exemple.fr"
        client.phone = "01 23 45 67 89"
        client.address = "123 Rue de l'Exemple, 75000 Paris"
        client.notes = "Client fidèle depuis 2020"
        client.dateCreated = Date()
        LoggingService.debug("Client exemple créé: \(client.name)")
        
        // Création d'un projet exemple lié au client
        let project = Project(context: viewContext)
        project.id = UUID()
        project.title = "Refonte du site web"
        project.details = "Refonte complète du site web avec design responsive"
        project.client = client
        project.dateCreated = Date()
        project.deadline = Calendar.current.date(byAdding: .month, value: 2, to: Date())
        project.status = "En cours"
        LoggingService.debug("Projet exemple créé: \(project.title)")
        
        // Création d'une facture exemple liée au client et au projet
        let invoice = Invoice(context: viewContext)
        invoice.id = UUID()
        invoice.invoiceNumber = "FACT-2023-001"
        invoice.client = client
        invoice.project = project
        invoice.dateCreated = Date()
        invoice.dateDue = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        invoice.status = "En attente"
        invoice.totalAmount = 1500.0
        LoggingService.debug("Facture exemple créée: \(invoice.invoiceNumber)")
        
        // Création d'un élément de facture exemple
        let invoiceItem = InvoiceItem(context: viewContext)
        invoiceItem.id = UUID()
        invoiceItem.invoice = invoice
        invoiceItem.description = "Développement Front-end"
        invoiceItem.quantity = 5
        invoiceItem.unitPrice = 300.0
        invoiceItem.amount = 1500.0
        
        // Sauvegarde de toutes les données créées
        save()
        LoggingService.info("Données d'exemple créées avec succès")
    }
    
    /// Supprime toutes les données de l'application
    /// ⚠️ ATTENTION : Cette opération est irréversible
    /// Utilisée principalement pour les tests ou la réinitialisation complète
    func deleteAllData() {
        LoggingService.warning("Suppression de toutes les données en cours")
        let entities = container.managedObjectModel.entities
        
        // Suppression de chaque entité une par une
        entities.forEach { entity in
            if let entityName = entity.name {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try container.viewContext.execute(deleteRequest)
                    LoggingService.debug("Entité \(entityName) supprimée")
                } catch {
                    LoggingService.error("Erreur lors de la suppression de l'entité \(entityName)")
                    error.log()
                }
            }
        }
        LoggingService.info("Suppression de toutes les données terminée")
    }
} 