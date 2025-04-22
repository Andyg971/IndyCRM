import SwiftUI

struct ContactDetailView: View {
    let contact: Contact
    let contactsManager: ContactsManager
    let projectManager: ProjectManager
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            Section(header: Text("Informations personnelles")) {
                LabeledContent("Nom", value: contact.lastName)
                LabeledContent("Prénom", value: contact.firstName)
                LabeledContent("Email", value: contact.email)
                LabeledContent("Téléphone", value: contact.phone)
            }
            
            Section(header: Text("Statut")) {
                LabeledContent("Type", value: contact.type.localizedName)
                LabeledContent("Statut professionnel", value: contact.employmentStatus.rawValue)
            }
            
            if !contact.rates.isEmpty {
                Section(header: Text("Tarifs")) {
                    ForEach(contact.rates) { rate in
                        VStack(alignment: .leading) {
                            Text(rate.description)
                                .font(.headline)
                            HStack {
                                Text(rate.amount.formatted(.currency(code: "EUR")))
                                Text("/ \(rate.unit.rawValue)")
                                    .foregroundColor(.secondary)
                                if rate.isDefault {
                                    Spacer()
                                    Text("Par défaut")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            
            if !contact.notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(contact.notes)
                }
            }
        }
        .navigationTitle(contact.fullName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ContactFormView(
                    contactsManager: contactsManager,
                    projectManager: projectManager,
                    editingContact: contact
                )) {
                    Text("Modifier")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ContactFormView(
                    contactsManager: contactsManager,
                    projectManager: projectManager,
                    editingContact: contact
                )
            }
        }
    }
} 