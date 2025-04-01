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
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var projectManager: ProjectManager
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var selectedType: ContactType?
    @State private var showingExportOptions = false
    
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
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingAddContact) {
            NavigationView {
                ContactFormView(contactsManager: contactsManager, projectManager: projectManager)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportView(
                projectManager: projectManager,
                contactsManager: contactsManager,
                invoiceManager: InvoiceManager()
            )
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showingAddContact = true
                } label: {
                    Label("Nouveau contact", systemImage: "person.badge.plus")
                }
                
                Button {
                    showingExportOptions = true
                } label: {
                    Label("Exporter", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
            }
        }
    }
    
    private var filteredContacts: [Contact] {
        var contacts = contactsManager.contacts
        
        if !searchText.isEmpty {
            contacts = contacts.filter {
                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let type = selectedType {
            contacts = contacts.filter { $0.type == type }
        }
        
        return contacts.sorted { $0.lastName < $1.lastName }
    }
}

// MARK: - Sous-vues
private struct FilterBarView: View {
    @Binding var selectedType: ContactType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "Tous",
                    icon: "person.3.fill",
                    isSelected: selectedType == nil
                ) {
                    withAnimation { selectedType = nil }
                }
                
                ForEach(ContactType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.localizedName,
                        icon: type.icon,
                        isSelected: selectedType == type
                    ) {
                        withAnimation { selectedType = type }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

private struct ContactListContent: View {
    let contacts: [Contact]
    let contactsManager: ContactsManager
    
    private var groupedContacts: [String: [Contact]] {
        Dictionary(grouping: contacts) { contact in
            String(contact.lastName.prefix(1).uppercased())
        }
    }
    
    var body: some View {
        List {
            ForEach(groupedContacts.keys.sorted(), id: \.self) { letter in
                Section(header: 
                    Text(letter)
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                        .textCase(nil)
                ) {
                    ForEach(groupedContacts[letter] ?? [], id: \.id) { contact in
                        NavigationLink(destination: ContactDetailView(
                            contact: contact,
                            contactsManager: contactsManager,
                            projectManager: ProjectManager(activityLogService: ActivityLogService())
                        )) {
                            ContactRow(contact: contact)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
    
    var localizedName: String {
        switch self {
        case .client: return "Client"
        case .prospect: return "Prospect"
        case .supplier: return "Fournisseur"
        case .partner: return "Partenaire"
        }
    }
}

#Preview {
    NavigationView {
        ContactsListView(
            contactsManager: ContactsManager(),
            projectManager: ProjectManager(activityLogService: ActivityLogService())
        )
    }
} 