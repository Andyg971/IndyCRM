import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSidebarItem: SidebarItem = .dashboard
    
    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "Tableau de bord"
        case clients = "Clients"
        case projects = "Projets"
        case invoices = "Factures"
        case reports = "Rapports"
        case settings = "Paramètres"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.xaxis"
            case .clients: return "person.2"
            case .projects: return "folder"
            case .invoices: return "doc.text"
            case .reports: return "chart.pie"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Barre latérale
            List(SidebarItem.allCases) { item in
                NavigationLink(
                    destination: destinationView(for: item),
                    tag: item,
                    selection: $selectedSidebarItem
                ) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            .navigationTitle("IndyCRM")
            
            // Vue par défaut
            Text("Sélectionnez un élément dans la barre latérale")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .sheet(isPresented: $appState.isShowingSettings) {
            SettingsView()
        }
    }
    
    @ViewBuilder
    private func destinationView(for item: SidebarItem) -> some View {
        switch item {
        case .dashboard:
            DashboardView()
        case .clients:
            ClientsView()
        case .projects:
            ProjectsView()
        case .invoices:
            InvoicesView()
        case .reports:
            ReportsView()
        case .settings:
            Button("Ouvrir les paramètres") {
                appState.isShowingSettings = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .environment(\.managedObjectContext, DataController.shared.container.viewContext)
            .environmentObject(DataController.shared)
    }
} 