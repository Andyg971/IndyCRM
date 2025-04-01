import Foundation
import CoreData
import SwiftUI

/// Contrôleur de données principal pour gérer le modèle Core Data
class DataController: ObservableObject {
    /// Instance partagée (singleton) pour accéder facilement au DataController
    static let shared = DataController()
    
    /// Container Core Data qui stocke le modèle de données
    let container: NSPersistentCloudKitContainer
    
    /// Initialisation du DataController
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "IndyCRMModel")
        
        // Pour les tests, utiliser un stockage en mémoire
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configuration pour CloudKit (synchronisation)
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        // Chargement des stores persistants
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Erreur lors du chargement de Core Data: \(error.localizedDescription)")
                fatalError("Impossible de charger Core Data: \(error.localizedDescription)")
            }
        }
        
        // Configuration pour tracker les changements CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Observer les changements externes
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(self.processRemoteChanges),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    /// Traitement des changements distants (CloudKit)
    @objc private func processRemoteChanges(_ notification: Notification) {
        // Mise à jour de l'interface utilisateur lorsque les données sont modifiées à distance
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Sauvegarde du contexte si des changements sont présents
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Erreur lors de la sauvegarde: \(error.localizedDescription)")
                // Dans une application réelle, nous voudrions gérer cette erreur plus gracieusement
            }
        }
    }
    
    /// Création d'un exemple de données pour les tests et démonstrations
    func createSampleData() {
        let viewContext = container.viewContext
        
        // Création d'un client exemple
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Entreprise Exemple"
        client.email = "contact@exemple.fr"
        client.phone = "01 23 45 67 89"
        client.address = "123 Rue de l'Exemple, 75000 Paris"
        client.notes = "Client fidèle depuis 2020"
        client.dateCreated = Date()
        
        // Création d'un projet exemple
        let project = Project(context: viewContext)
        project.id = UUID()
        project.title = "Refonte du site web"
        project.details = "Refonte complète du site web avec design responsive"
        project.client = client
        project.dateCreated = Date()
        project.deadline = Calendar.current.date(byAdding: .month, value: 2, to: Date())
        project.status = "En cours"
        
        // Création d'une facture exemple
        let invoice = Invoice(context: viewContext)
        invoice.id = UUID()
        invoice.invoiceNumber = "FACT-2023-001"
        invoice.client = client
        invoice.project = project
        invoice.dateCreated = Date()
        invoice.dateDue = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        invoice.status = "En attente"
        invoice.totalAmount = 1500.0
        
        // Création d'éléments de facture
        let invoiceItem = InvoiceItem(context: viewContext)
        invoiceItem.id = UUID()
        invoiceItem.invoice = invoice
        invoiceItem.description = "Développement Front-end"
        invoiceItem.quantity = 5
        invoiceItem.unitPrice = 300.0
        invoiceItem.amount = 1500.0
        
        save()
    }
    
    /// Suppression de toutes les données (utile pour les tests)
    func deleteAllData() {
        let entities = container.managedObjectModel.entities
        entities.forEach { entity in
            if let entityName = entity.name {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try container.viewContext.execute(deleteRequest)
                } catch {
                    print("Erreur lors de la suppression des données: \(error.localizedDescription)")
                }
            }
        }
    }
} 