import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var projectManager = ProjectManager(activityLogService: ActivityLogService())
    @StateObject private var invoiceManager = InvoiceManager()
    @StateObject private var helpService = HelpService()
    @StateObject private var alertService = AlertService()
    @StateObject private var collaborationService = CollaborationService()
    @EnvironmentObject private var authService: AuthenticationService
    
    var body: some View {
        TabView {
            NavigationView {
                ContactsListView()
            }
            .tabItem {
                Label("Contacts", systemImage: "person.2.fill")
            }
            .environmentObject(contactsManager)
            .environmentObject(projectManager)
            .environmentObject(helpService)
            .environmentObject(alertService)
            
            NavigationView {
                ProjectsListView(
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    collaborationService: collaborationService,
                    helpService: helpService,
                    alertService: alertService
                )
            }
            .tabItem {
                Label("Projets", systemImage: "folder.fill")
            }
            
            NavigationView {
                InvoicesListView(
                    invoiceManager: invoiceManager,
                    contactsManager: contactsManager
                )
            }
            .tabItem {
                Label("Factures", systemImage: "doc.text.fill")
            }
            .environmentObject(helpService)
            .environmentObject(alertService)
            
            NavigationView {
                DashboardView(
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    invoiceManager: invoiceManager
                )
            }
            .tabItem {
                Label("Tableau de bord", systemImage: "chart.bar")
            }
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Paramètres", systemImage: "gear")
            }
            .environmentObject(helpService)
            .environmentObject(alertService)
            .environmentObject(projectManager)
        }
        .tint(.indigo)
    }
} 