import SwiftUI

struct ContentView: View {
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var projectManager = ProjectManager(activityLogService: ActivityLogService())
    @StateObject private var invoiceManager = InvoiceManager()
    @StateObject private var alertService = AlertService()
    @StateObject private var helpService = HelpService()
    @StateObject private var languageManager = LanguageManager.shared
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                WelcomeView(authService: authService)
            } else {
                TabView(selection: $selectedTab) {
                    NavigationView {
                        DashboardView(
                            projectManager: projectManager,
                            contactsManager: contactsManager,
                            invoiceManager: invoiceManager
                        )
                    }
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("nav.dashboard".localized)
                    }
                    .tag(0)
                    
                    NavigationView {
                        ContactsListView(
                            contactsManager: contactsManager,
                            projectManager: projectManager
                        )
                    }
                    .tabItem {
                        Image(systemName: "person.2")
                        Text("nav.contacts".localized)
                    }
                    .tag(1)
                    
                    NavigationView {
                        ProjectsListView(
                            projectManager: projectManager,
                            contactsManager: contactsManager
                        )
                    }
                    .tabItem {
                        Image(systemName: "folder")
                        Text("nav.projects".localized)
                    }
                    .tag(2)
                    
                    NavigationView {
                        InvoicesListView(
                            invoiceManager: invoiceManager,
                            contactsManager: contactsManager
                        )
                    }
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("nav.invoices".localized)
                    }
                    .tag(3)
                    
                    NavigationView {
                        SettingsView()
                    }
                    .tabItem {
                        Image(systemName: "gear")
                        Text("nav.settings".localized)
                    }
                    .tag(4)
                }
                .environmentObject(languageManager)
                .environmentObject(helpService)
                .tint(.indigo)
            }
        }
    }
} 