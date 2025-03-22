import SwiftUI

struct InvoicesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Invoice.dateCreated, ascending: false)],
                  animation: .default)
    private var invoices: FetchedResults<Invoice>
    
    @State private var searchText = ""
    @State private var showingAddInvoice = false
    @State private var selectedInvoice: Invoice?
    @State private var filterStatus = InvoiceStatus.all
    
    enum InvoiceStatus: String, CaseIterable {
        case all = "Toutes"
        case pending = "En attente"
        case paid = "Payées"
        case overdue = "En retard"
    }
    
    var body: some View {
        VStack {
            // Filtres
            Picker("Statut", selection: $filterStatus) {
                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Résumé financier
            FinancialSummary(invoices: Array(invoices))
            
            // Liste des factures
            List {
                ForEach(filteredInvoices) { invoice in
                    InvoiceRow(invoice: invoice)
                        .onTapGesture {
                            selectedInvoice = invoice
                        }
                }
                .onDelete(perform: deleteInvoices)
            }
            .searchable(text: $searchText, prompt: "Rechercher une facture")
        }
        .navigationTitle("Factures")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddInvoice = true }) {
                    Label("Ajouter", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddInvoice) {
            AddInvoiceView()
        }
        .sheet(item: $selectedInvoice) { invoice in
            InvoiceDetailView(invoice: invoice)
        }
    }
    
    private var filteredInvoices: [Invoice] {
        var result = invoices
        
        // Filtre par statut
        if filterStatus != .all {
            result = result.filter { invoice in
                switch filterStatus {
                case .pending:
                    return invoice.status == "En attente"
                case .paid:
                    return invoice.status == "Payée"
                case .overdue:
                    return invoice.status == "En retard"
                case .all:
                    return true
                }
            }
        }
        
        // Filtre par recherche
        if !searchText.isEmpty {
            result = result.filter { invoice in
                invoice.invoiceNumber?.localizedCaseInsensitiveContains(searchText) == true ||
                invoice.client?.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return Array(result)
    }
    
    private func deleteInvoices(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredInvoices[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Erreur lors de la suppression : \(error)")
            }
        }
    }
}

struct FinancialSummary: View {
    let invoices: [Invoice]
    
    var totalAmount: Double {
        invoices.reduce(0) { $0 + $1.totalAmount }
    }
    
    var paidAmount: Double {
        invoices.filter { $0.status == "Payée" }.reduce(0) { $0 + $1.totalAmount }
    }
    
    var pendingAmount: Double {
        invoices.filter { $0.status == "En attente" }.reduce(0) { $0 + $1.totalAmount }
    }
    
    var overdueAmount: Double {
        invoices.filter { $0.status == "En retard" }.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                FinancialCard(title: "Total", amount: totalAmount, color: .blue)
                FinancialCard(title: "Payé", amount: paidAmount, color: .green)
            }
            
            HStack(spacing: 20) {
                FinancialCard(title: "En attente", amount: pendingAmount, color: .orange)
                FinancialCard(title: "En retard", amount: overdueAmount, color: .red)
            }
        }
        .padding()
    }
}

struct FinancialCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.2f €", amount))
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    
    var statusColor: Color {
        switch invoice.status {
        case "Payée": return .green
        case "En attente": return .orange
        case "En retard": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(invoice.invoiceNumber ?? "")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f €", invoice.totalAmount))
                    .bold()
            }
            
            if let client = invoice.client {
                Text(client.name ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(invoice.dateCreated?.formatted(date: .abbreviated, time: .omitted) ?? "",
                      systemImage: "calendar")
                
                Spacer()
                
                Text(invoice.status ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddInvoiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedClient: Client?
    @State private var selectedProject: Project?
    @State private var dueDate = Date()
    @State private var items: [InvoiceItemData] = []
    
    struct InvoiceItemData: Identifiable {
        let id = UUID()
        var description: String
        var quantity: Double
        var unitPrice: Double
        
        var amount: Double {
            quantity * unitPrice
        }
    }
    
    var totalAmount: Double {
        items.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client et Projet")) {
                    ClientPicker(selectedClient: $selectedClient)
                    if let client = selectedClient {
                        ProjectPicker(client: client, selectedProject: $selectedProject)
                    }
                }
                
                Section(header: Text("Détails")) {
                    DatePicker("Date d'échéance",
                              selection: $dueDate,
                              displayedComponents: [.date])
                }
                
                Section(header: Text("Articles")) {
                    ForEach(items) { item in
                        InvoiceItemRow(item: item)
                    }
                    
                    Button(action: addItem) {
                        Label("Ajouter un article", systemImage: "plus")
                    }
                }
                
                Section {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f €", totalAmount))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Nouvelle facture")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        createInvoice()
                    }
                    .disabled(selectedClient == nil || items.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        items.append(InvoiceItemData(description: "", quantity: 1, unitPrice: 0))
    }
    
    private func createInvoice() {
        withAnimation {
            let newInvoice = Invoice(context: viewContext)
            newInvoice.id = UUID()
            newInvoice.client = selectedClient
            newInvoice.project = selectedProject
            newInvoice.dateCreated = Date()
            newInvoice.dateDue = dueDate
            newInvoice.status = "En attente"
            newInvoice.totalAmount = totalAmount
            
            // Générer le numéro de facture
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMM"
            let prefix = dateFormatter.string(from: Date())
            newInvoice.invoiceNumber = "FACT-\(prefix)-001" // À améliorer avec une séquence
            
            // Créer les articles
            for itemData in items {
                let item = InvoiceItem(context: viewContext)
                item.id = UUID()
                item.description = itemData.description
                item.quantity = itemData.quantity
                item.unitPrice = itemData.unitPrice
                item.amount = itemData.amount
                item.invoice = newInvoice
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Erreur lors de la création de la facture : \(error)")
            }
        }
    }
}

struct InvoiceItemRow: View {
    let item: AddInvoiceView.InvoiceItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.description)
                .font(.headline)
            
            HStack {
                Text("Quantité : \(String(format: "%.2f", item.quantity))")
                Spacer()
                Text("Prix unitaire : \(String(format: "%.2f €", item.unitPrice))")
            }
            .font(.caption)
            
            HStack {
                Spacer()
                Text("Total : \(String(format: "%.2f €", item.amount))")
                    .font(.subheadline)
                    .bold()
            }
        }
    }
}

struct ProjectPicker: View {
    let client: Client
    @Binding var selectedProject: Project?
    
    var body: some View {
        if let projects = client.projects?.allObjects as? [Project], !projects.isEmpty {
            Picker("Projet", selection: $selectedProject) {
                Text("Aucun projet").tag(Project?.none)
                ForEach(projects) { project in
                    Text(project.title ?? "").tag(Project?.some(project))
                }
            }
        }
    }
}
