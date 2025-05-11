import SwiftUI

struct ContactListView: View {
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var projectManager: ProjectManager
    @State private var showingAddContact = false
    @State private var showingDeleteAlert = false
    @State private var contactToDelete: Contact?
    @State private var searchText = ""
    
    var body: some View {
        List {
            ForEach(filteredContacts) { contact in
                NavigationLink(destination: ContactDetailView(
                    contact: contact,
                    contactsManager: contactsManager,
                    projectManager: projectManager
                )) {
                    ContactRowView(contact: contact)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        contactToDelete = contact
                        showingDeleteAlert = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        contactToDelete = contact
                        showingDeleteAlert = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher un contact")
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddContact = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            NavigationView {
                ContactFormView(
                    contactsManager: contactsManager,
                    projectManager: projectManager
                )
            }
        }
        .alert("Supprimer le contact ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                if let contact = contactToDelete {
                    if !contactsManager.canDeleteContact(contact, projectManager: projectManager) {
                        // Afficher une alerte d'erreur
                        showDeletionErrorAlert(for: contact)
                    } else {
                        Task {
                            DataController.shared.deleteClient(by: contact.id)
                        }
                    }
                }
            }
        } message: {
            if let contact = contactToDelete {
                Text("Voulez-vous vraiment supprimer \(contact.fullName) ? Cette action est irréversible.")
            }
        }
    }
    
    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contactsManager.contacts
        }
        return contactsManager.contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func showDeletionErrorAlert(for contact: Contact) {
        let alert = UIAlertController(
            title: "Impossible de supprimer",
            message: "Ce contact est utilisé dans un ou plusieurs projets actifs. Veuillez d'abord le retirer des projets.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
} 