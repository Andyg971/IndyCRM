// The Swift Programming Language
// https://docs.swift.org/swift-book

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

// Extension pour les notifications personnalisées
extension Notification.Name {
    static let createNewClient = Notification.Name("createNewClient")
    static let createNewInvoice = Notification.Name("createNewInvoice")
    static let createNewProject = Notification.Name("createNewProject")
}

// État global de l'application
class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    @Published var isShowingSettings = false
    @Published var currentTheme: AppTheme = .system
    @Published var alertMessage: AlertMessage?
    
    enum AppTab {
        case dashboard, clients, projects, invoices, reports
    }
    
    enum AppTheme {
        case light, dark, system
    }
    
    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let type: AlertType
        
        enum AlertType {
            case info, success, warning, error
        }
    }
}
