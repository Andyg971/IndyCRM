import SwiftUI

struct ContactsListView: View {
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var projectManager: ProjectManager
    
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var selectedType: ContactType?
    @State private var showingExportOptions = false
    @State private var showingContactExporter = false
    
    var filteredContacts: [Contact] {
        var contacts = contactsManager.contacts
        
        // Filtre par type si sélectionné
        if let selectedType = selectedType {
            contacts = contacts.filter { $0.type == selectedType }
        }
        
        // Filtre par recherche
        if !searchText.isEmpty {
            contacts = contacts.filter {
                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return contacts
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FilterBarView(selectedType: $selectedType)
            ContactListContent(
                contacts: filteredContacts,
                contactsManager: contactsManager
            )
        }
        .searchable(text: $searchText, prompt: "Rechercher un contact")
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingContactExporter = true }) {
                        Label("Exporter", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { showingAddContact = true }) {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            NavigationView {
                ContactFormView(contactsManager: contactsManager, projectManager: projectManager)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingContactExporter) {
            NavigationView {
                ContactExporterView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct ContactsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactsListView(
                contactsManager: ContactsManager(),
                projectManager: ProjectManager(activityLogService: ActivityLogService())
            )
        }
    }
} 