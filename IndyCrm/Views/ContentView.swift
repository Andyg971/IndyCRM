import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var projectManager = ProjectManager(activityLogService: ActivityLogService())
    @StateObject private var invoiceManager = InvoiceManager()
    @StateObject private var helpService = HelpService()
    @StateObject private var alertService = AlertService()
    @StateObject private var collaborationService = CollaborationService()
    @StateObject private var languageService = LanguageService.shared
    @EnvironmentObject private var authService: AuthenticationService
    
    @AppStorage("colorSchemePreference") private var colorSchemePreference: Int = 0
    @AppStorage("accentColorPreference") private var accentColorPreference: Int = 0
    
    var accentColor: Color {
        switch accentColorPreference {
        case 1: return .indigo
        case 2: return .purple
        case 3: return .pink
        case 4: return .red
        case 5: return .orange
        case 6: return .yellow
        case 7: return .green
        case 8: return .teal
        default: return .blue
        }
    }
    
    init() {
        // Observer pour le changement de langue
        NotificationCenter.default.addObserver(forName: Notification.Name("LanguageChanged"), object: nil, queue: .main) { _ in
            // Invalider tous les caches pour forcer le rechargement des données avec les bonnes traductions
            CacheService.shared.invalidateAllCaches()
            print("🌐 Notification de changement de langue reçue, cache vidé")
        }
    }
    
    var body: some View {
        TabView {
            NavigationView {
                ContactsListView()
            }
            .tabItem {
                Label("nav.contacts".localized, systemImage: "person.2.fill")
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
                Label("nav.projects".localized, systemImage: "folder.fill")
            }
            
            NavigationView {
                InvoicesListView(
                    invoiceManager: invoiceManager,
                    contactsManager: contactsManager
                )
            }
            .tabItem {
                Label("nav.invoices".localized, systemImage: "doc.text.fill")
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
                Label("nav.dashboard".localized, systemImage: "chart.bar")
            }
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("nav.settings".localized, systemImage: "gear")
            }
            .environmentObject(helpService)
            .environmentObject(alertService)
            .environmentObject(projectManager)
        }
        .tint(accentColor)
        .preferredColorScheme(from: colorSchemePreference)
        .environmentObject(languageService)
        .id(languageService.refreshID)
    }
}

extension View {
    func navigationBarBackground() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
    
    @ViewBuilder
    func preferredColorScheme(from preference: Int) -> some View {
        switch preference {
        case 1:
            self.preferredColorScheme(.light)
        case 2:
            self.preferredColorScheme(.dark)
        default:
            self.preferredColorScheme(nil) // Utilise la préférence système
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
} 
