// IndyCRM - Gestion de clients, facturation et suivi de projets pour indépendants
// Développé avec SwiftUI et Core Data

import SwiftUI

@main
struct IndyCRMApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environmentObject(AppState())
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            SidebarCommands()
            
            CommandGroup(replacing: .newItem) {
                Button("Nouveau Client") {
                    NotificationCenter.default.post(name: .createNewClient, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Nouvelle Facture") {
                    NotificationCenter.default.post(name: .createNewInvoice, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Button("Nouveau Projet") {
                    NotificationCenter.default.post(name: .createNewProject, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}