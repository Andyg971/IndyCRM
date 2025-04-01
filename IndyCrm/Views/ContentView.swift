import SwiftUI

struct ContentView: View {
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var projectManager = ProjectManager(activityLogService: ActivityLogService())
    @StateObject private var invoiceManager = InvoiceManager()
    @StateObject private var alertService = AlertService()
    @StateObject private var helpService = HelpService()
    @EnvironmentObject var authService: AuthenticationService
    
    init() {
        let alertService = AlertService()
        _alertService = StateObject(wrappedValue: alertService)
        _projectManager = StateObject(wrappedValue: ProjectManager(alertService: alertService))
        
        Task {
            await alertService.setup()
            await alertService.setup()
        }
    }
    
    enum Tab {
        case contacts, invoices, projects, dashboard
    }
    
    @State private var selectedTab: Tab = .contacts
    @State private var showingAlerts = false
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                WelcomeView(authService: authService)
            } else {
                mainView
            }
        }
    }
    
    private var mainView: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ContactsListView(
                    contactsManager: contactsManager,
                    projectManager: projectManager
                )
            }
            .tabItem {
                Label("Contacts", systemImage: "person.2.fill")
            }
            .tag(Tab.contacts)
            
            NavigationView {
                ProjectsListView(
                    projectManager: projectManager,
                    contactsManager: contactsManager
                )
            }
            .tabItem {
                Label("Projets", systemImage: "folder.fill")
            }
            .tag(Tab.projects)
            
            NavigationView {
                InvoicesListView(
                    invoiceManager: invoiceManager,
                    contactsManager: contactsManager
                )
            }
            .tabItem {
                Label("Factures", systemImage: "doc.text.fill")
            }
            .tag(Tab.invoices)
            
            NavigationView {
                DashboardView(
                    projectManager: projectManager,
                    contactsManager: contactsManager,
                    invoiceManager: invoiceManager
                )
            }
            .tabItem {
                Label("Tableau de bord", systemImage: "chart.bar.fill")
            }
            .tag(Tab.dashboard)
        }
        .environmentObject(helpService)
        .tint(.indigo)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                VStack(spacing: 8) {
                    Button {
                        // Action pour le bouton +
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo.gradient)
                    }
                    
                    Menu {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                helpService.showingHelp = true
                            }
                        } label: {
                            Label("Aide", systemImage: "questionmark.circle.fill")
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingAlerts = true
                            }
                        } label: {
                            HStack {
                                Label("Notifications", systemImage: "bell.fill")
                                if !alertService.currentAlerts.isEmpty {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo.gradient)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { authService.signOut() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .sheet(isPresented: $showingAlerts) {
            AlertsView(alertService: alertService)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $helpService.showingHelp) {
            HelpView(helpService: helpService)
                .presentationBackground(.ultraThinMaterial)
        }
    }
}

extension View {
    func navigationBarBackground() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .environmentObject(ContactsManager())
        .environmentObject(ProjectManager(activityLogService: ActivityLogService()))
        .environmentObject(InvoiceManager())
        .environmentObject(MessagingService())
        .preferredColorScheme(.light)
} 
