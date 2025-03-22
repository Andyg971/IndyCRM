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
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Erreur lors du chargement de Core Data: \(error.localizedDescription)")
                fatalError("Impossible de charger Core Data: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(self.processRemoteChanges),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func processRemoteChanges(_ notification: Notification) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Erreur lors de la sauvegarde: \(error.localizedDescription)")
            }
        }
    }
}