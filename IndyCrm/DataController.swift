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
            print("Initialisation du DataController en mode mémoire")
        } else {
            print("Initialisation du DataController avec stockage persistant")
        }
        
        // Configuration de CloudKit
        if let description = container.persistentStoreDescriptions.first {
            // Active la notification des changements distants
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // Active le suivi de l'historique pour la synchronisation
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            print("Configuration CloudKit activée")
        }
        
        // Chargement des stores persistants
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Erreur fatale lors du chargement de Core Data: \(error.localizedDescription)")
                fatalError("Impossible de charger Core Data: \(error.localizedDescription)")
            }
            print("Stores persistants chargés avec succès")
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
        print("Observateur de changements CloudKit configuré")
    }
    
    /// Traite les changements reçus de CloudKit
    /// Cette méthode est appelée automatiquement lorsque des modifications sont synchronisées depuis d'autres appareils
    @objc private func processRemoteChanges(_ notification: Notification) {
        print("Changements distants détectés via CloudKit")
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
                print("Données sauvegardées avec succès")
            } catch {
                print("Échec de la sauvegarde des données")
                print(error)
            }
        }
    }
    
    /// Crée un jeu de données d'exemple pour les tests et démonstrations
    /// Cette méthode génère :
    /// - Un client exemple
    /// - Un projet associé
    /// - Une facture avec un élément
    func createSampleData() {
        print("Création des données d'exemple")
        // let viewContext = container.viewContext // Ligne supprimée car non utilisée
        // let viewContext = container.viewContext // Ligne supprimée car non utilisée
        // let viewContext = container.viewContext // Ligne supprimée car non utilisée

        // Les entités Client, Project, Invoice, InvoiceItem sont des struct Swift et non des NSManagedObject.
        // Il n'est pas possible de les instancier avec un contexte Core Data.
        // Si tu veux utiliser Core Data, il faut générer les entités dans Xcode (Editor > Create NSManagedObject Subclass...)
        // Exemple de code Core Data commenté :
        /*
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Entreprise Exemple"
        client.email = "contact@exemple.fr"
        client.phone = "01 23 45 67 89"
        client.address = "123 Rue de l'Exemple, 75000 Paris"
        client.notes = "Client fidèle depuis 2020"
        client.dateCreated = Date()
        print("Client exemple créé: \(client.name)")

        let project = Project(context: viewContext)
        project.id = UUID()
        project.title = "Refonte du site web"
        project.details = "Refonte complète du site web avec design responsive"
        project.client = client
        project.dateCreated = Date()
        project.deadline = Calendar.current.date(byAdding: .month, value: 2, to: Date())
        project.status = "En cours"
        print("Projet exemple créé: \(project.title)")

        let invoice = Invoice(context: viewContext)
        invoice.id = UUID()
        invoice.invoiceNumber = "FACT-2023-001"
        invoice.client = client
        invoice.project = project
        invoice.dateCreated = Date()
        invoice.dateDue = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        invoice.status = "En attente"
        invoice.totalAmount = 1500.0
        print("Facture exemple créée: \(invoice.invoiceNumber)")

        let invoiceItem = InvoiceItem(context: viewContext)
        invoiceItem.id = UUID()
        invoiceItem.invoice = invoice
        invoiceItem.description = "Développement Front-end"
        invoiceItem.quantity = 5
        invoiceItem.unitPrice = 300.0
        invoiceItem.amount = 1500.0
        */

        print("Impossible de créer des exemples : les entités ne sont pas des NSManagedObject.")
    }
    
    /// Supprime toutes les données de l'application
    /// ⚠️ ATTENTION : Cette opération est irréversible
    /// Utilisée principalement pour les tests ou la réinitialisation complète
    func deleteAllData() {
        print("Suppression de toutes les données en cours")
        let entities = container.managedObjectModel.entities
        
        // Suppression de chaque entité une par une
        entities.forEach { entity in
            if let entityName = entity.name {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try container.viewContext.execute(deleteRequest)
                    print("Entité \(entityName) supprimée")
                } catch {
                    print("Erreur lors de la suppression de l'entité \(entityName)")
                    print(error)
                }
            }
        }
        print("Suppression de toutes les données terminée")
    }
    
    /// Supprime un client (et toutes ses données associées) via Core Data
    /// - Parameter id: L'identifiant du client à supprimer
    func deleteClient(by id: UUID) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Client")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let client = try context.fetch(fetchRequest).first as? NSManagedObject {
                context.delete(client)
                save() // La suppression en cascade s'applique automatiquement
                print("Client supprimé avec succès (id: \(id))")
            } else {
                print("Aucun client trouvé avec l'id: \(id)")
            }
        } catch {
            print("Erreur lors de la suppression du client: \(error.localizedDescription)")
        }
    }

    /// Supprime une facture (et ses éléments associés) via Core Data
    /// - Parameter id: L'identifiant de la facture à supprimer
    func deleteInvoice(by id: UUID) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Invoice")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let invoice = try context.fetch(fetchRequest).first as? NSManagedObject {
                context.delete(invoice)
                save() // La suppression en cascade s'applique automatiquement
                print("Facture supprimée avec succès (id: \(id))")
            } else {
                print("Aucune facture trouvée avec l'id: \(id)")
            }
        } catch {
            print("Erreur lors de la suppression de la facture: \(error.localizedDescription)")
        }
    }
} 
