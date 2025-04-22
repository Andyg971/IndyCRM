import SwiftUI
import UniformTypeIdentifiers
import MessageUI

struct ExportColumn: Identifiable {
    let id = UUID()
    let title: String
    let key: String
    var isSelected: Bool
}

struct ContactsListView: View {
    @EnvironmentObject var contactsManager: ContactsManager
    @EnvironmentObject var projectManager: ProjectManager
    @State private var searchText = ""
    @State private var selectedType: ContactType?
    @State private var showingNewContact = false
    @StateObject private var exportService = ExportService()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                FilterBarView(searchText: $searchText, selectedType: $selectedType)
                
                List {
                    ForEach(filteredContacts) { contact in
                        NavigationLink(destination: ContactDetailView(
                            contact: contact,
                            contactsManager: contactsManager,
                            projectManager: projectManager
                        )) {
                            ContactRow(contact: contact)
                        }
                    }
                    .onDelete(perform: deleteContacts)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingNewContact = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.indigo)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: exportToCSV) {
                        Label("Exporter en CSV", systemImage: "doc.text")
                    }
                    
                    Button(action: exportToVCard) {
                        Label("Exporter en vCard", systemImage: "person.crop.rectangle")
                    }
                    
                    Button(action: exportToExcel) {
                        Label("Exporter en Excel", systemImage: "tablecells")
                    }
                    
                    Button(action: { showingNewContact = true }) {
                        Label("Ajouter un contact", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .accentColor(.indigo)
        .sheet(isPresented: $showingNewContact) {
            NavigationView {
                ContactFormView(contactsManager: contactsManager, projectManager: projectManager)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                SystemShareSheet(items: [url])
            }
        }
    }
    
    private var filteredContacts: [Contact] {
        var contacts = contactsManager.contacts
        
        if let selectedType = selectedType {
            contacts = contacts.filter { $0.type == selectedType }
        }
        
        if !searchText.isEmpty {
            contacts = contacts.filter {
                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return contacts.sorted { $0.lastName < $1.lastName }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        let contactsToDelete = offsets.map { filteredContacts[$0] }
        Task {
            for contact in contactsToDelete {
                // Vérifier ici aussi si la suppression est possible avant d'appeler deleteContact
                // Ou laisser la vue de détail gérer les dépendances complexes
                await contactsManager.deleteContact(contact)
            }
        }
    }
    
    private func exportToCSV() {
        if let url = exportService.exportToCSV(.contacts, contacts: contactsManager.contacts) {
            exportURL = url
            showingShareSheet = true
        }
    }
    
    private func exportToVCard() {
        if let url = exportService.exportToVCard(contacts: contactsManager.contacts) {
            exportURL = url
            showingShareSheet = true
        }
    }
    
    private func exportToExcel() {
        if let url = exportService.exportToExcel(.contacts, contacts: contactsManager.contacts) {
            exportURL = url
            showingShareSheet = true
        }
    }
}

// MARK: - Sous-composants
private struct FilterBarView: View {
    @Binding var searchText: String
    @Binding var selectedType: ContactType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(title: NSLocalizedString("contacts.all", comment: "All contacts filter"), type: nil, selectedType: $selectedType)
                
                ForEach(ContactType.allCases, id: \.self) { type in
                    FilterButton(title: type.localizedName, type: type, selectedType: $selectedType)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
    }
}

private struct FilterButton: View {
    let title: String
    let type: ContactType?
    @Binding var selectedType: ContactType?
    
    var body: some View {
        Button {
            withAnimation {
                selectedType = type
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(type == selectedType ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(type == selectedType ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(contact.type.color.opacity(0.2))
                .overlay(
                    Text(contact.initials)
                        .font(.headline)
                        .foregroundColor(contact.type.color)
                )
                .frame(width: 45, height: 45)
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName) \(contact.lastName)")
                    .font(.headline)
                
                HStack {
                    Image(systemName: contact.type.icon)
                        .foregroundColor(contact.type.color)
                    Text(contact.type.localizedName)
                        .font(.caption)
                    
                    if let rate = contact.rates.first(where: { $0.isDefault }) {
                        Spacer()
                        Text(rate.formattedAmount)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Extensions pour les propriétés visuelles
extension Contact {
    var initials: String {
        let firstInitial = firstName.prefix(1)
        let lastInitial = lastName.prefix(1)
        return (firstInitial + lastInitial).uppercased()
    }
}

extension ContactType {
    var icon: String {
        switch self {
        case .client: return "person.fill"
        case .prospect: return "person.fill.questionmark"
        case .supplier: return "shippingbox.fill"
        case .partner: return "person.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .client: return .blue
        case .prospect: return .orange
        case .supplier: return .green
        case .partner: return .purple
        }
    }
}

#Preview {
    NavigationView {
        ContactsListView()
            .environmentObject(ContactsManager())
            .environmentObject(ProjectManager(activityLogService: ActivityLogService()))
    }
} 