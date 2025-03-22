import SwiftUI

struct ClientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
                  animation: .default)
    private var clients: FetchedResults<Client>
    
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var showingClientDetails = false
    
    var body: some View {
        List {
            ForEach(filteredClients) { client in
                ClientRow(client: client)
                    .onTapGesture {
                        selectedClient = client
                        showingClientDetails = true
                    }
            }
            .onDelete(perform: deleteClients)
        }
        .searchable(text: $searchText, prompt: "Rechercher un client")
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddClient = true }) {
                    Label("Ajouter", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
        }
        .sheet(item: $selectedClient) { client in
            ClientDetailView(client: client)
        }
    }
    
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return Array(clients)
        } else {
            return clients.filter { client in
                client.name?.localizedCaseInsensitiveContains(searchText) == true ||
                client.email?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredClients[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Erreur lors de la suppression : \(error)")
            }
        }
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.name ?? "")
                .font(.headline)
            
            if let email = client.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let projectCount = client.projects?.count, projectCount > 0 {
                    Label("\(projectCount) projet(s)", systemImage: "folder")
                        .font(.caption)
                }
                
                if let invoiceCount = client.invoices?.count, invoiceCount > 0 {
                    Label("\(invoiceCount) facture(s)", systemImage: "doc.text")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var vatNumber = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations générales")) {
                    TextField("Nom", text: $name)
                    TextField("Email", text: $email)
                    TextField("Téléphone", text: $phone)
                }
                
                Section(header: Text("Adresse")) {
                    TextField("Adresse complète", text: $address)
                    TextField("Numéro TVA", text: $vatNumber)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Nouveau client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        addClient()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addClient() {
        withAnimation {
            let newClient = Client(context: viewContext)
            newClient.id = UUID()
            newClient.name = name
            newClient.email = email
            newClient.phone = phone
            newClient.address = address
            newClient.vatNumber = vatNumber
            newClient.notes = notes
            newClient.dateCreated = Date()
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Erreur lors de la création du client : \(error)")
            }
        }
    }
}

struct ClientDetailView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Informations générales")) {
                    DetailRow(title: "Nom", value: client.name ?? "")
                    DetailRow(title: "Email", value: client.email ?? "")
                    DetailRow(title: "Téléphone", value: client.phone ?? "")
                }
                
                Section(header: Text("Adresse")) {
                    DetailRow(title: "Adresse", value: client.address ?? "")
                    DetailRow(title: "Numéro TVA", value: client.vatNumber ?? "")
                }
                
                if let notes = client.notes, !notes.isEmpty {
                    Section(header: Text("Notes")) {
                        Text(notes)
                    }
                }
                
                Section(header: Text("Projets")) {
                    if let projects = client.projects?.allObjects as? [Project], !projects.isEmpty {
                        ForEach(projects) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectRow(project: project)
                            }
                        }
                    } else {
                        Text("Aucun projet")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Factures")) {
                    if let invoices = client.invoices?.allObjects as? [Invoice], !invoices.isEmpty {
                        ForEach(invoices) { invoice in
                            NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                InvoiceRow(invoice: invoice)
                            }
                        }
                    } else {
                        Text("Aucune facture")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(client.name ?? "Client")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Modifier") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditClientView(client: client)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
