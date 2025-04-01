import SwiftUI

struct AddInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    let dataManager: DataManagerProtocol
    
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var dueDate = Date().addingTimeInterval(30 * 24 * 3600) // +30 jours par défaut
    @State private var items: [InvoiceItem] = []
    @State private var frequency: InvoiceFrequency = .none
    @State private var showingAddItem = false
    
    // États temporaires pour le nouvel item
    @State private var itemDescription = ""
    @State private var itemQuantity = ""
    @State private var itemUnitPrice = ""
    @State private var itemTaxRate = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations client")) {
                    TextField("Nom du client", text: $clientName)
                    TextField("Email du client", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                
                Section(header: Text("Détails de la facture")) {
                    DatePicker("Date d'échéance", selection: $dueDate, displayedComponents: .date)
                    
                    Picker("Fréquence", selection: $frequency) {
                        ForEach(InvoiceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("Articles")
                    Spacer()
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }) {
                    if items.isEmpty {
                        Text("Aucun article")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(items) { item in
                            VStack(alignment: .leading) {
                                Text(item.description)
                                    .font(.headline)
                                HStack {
                                    Text("\(item.quantity) × \(item.unitPrice, specifier: "%.2f")€")
                                    Spacer()
                                    Text("TVA: \(item.taxRate)%")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                if !items.isEmpty {
                    Section {
                        HStack {
                            Text("Total TTC")
                            Spacer()
                            Text("\(calculateTotal(), specifier: "%.2f")€")
                                .bold()
                        }
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
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                NavigationView {
                    Form {
                        TextField("Description", text: $itemDescription)
                        TextField("Quantité", text: $itemQuantity)
                            .keyboardType(.numberPad)
                        TextField("Prix unitaire", text: $itemUnitPrice)
                            .keyboardType(.decimalPad)
                        TextField("Taux de TVA (%)", text: $itemTaxRate)
                            .keyboardType(.decimalPad)
                    }
                    .navigationTitle("Nouvel article")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Annuler") {
                                showingAddItem = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Ajouter") {
                                addItem()
                            }
                            .disabled(!isItemValid)
                        }
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !clientName.isEmpty &&
        !clientEmail.isEmpty &&
        !items.isEmpty
    }
    
    private var isItemValid: Bool {
        !itemDescription.isEmpty &&
        !itemQuantity.isEmpty &&
        !itemUnitPrice.isEmpty &&
        !itemTaxRate.isEmpty &&
        (Int(itemQuantity) ?? 0) > 0 &&
        (Double(itemUnitPrice) ?? 0) > 0 &&
        (Double(itemTaxRate) ?? 0) >= 0
    }
    
    private func calculateTotal() -> Double {
        let invoice = Invoice(
            id: UUID(),
            client: Client(id: UUID(), name: "", email: ""),
            items: items,
            date: Date(),
            dueDate: dueDate,
            status: .pending,
            nextInvoiceDate: nil,
            frequency: frequency
        )
        return invoice.totalAmount
    }
    
    private func addItem() {
        guard let quantity = Int(itemQuantity),
              let unitPrice = Double(itemUnitPrice),
              let taxRate = Double(itemTaxRate) else {
            return
        }
        
        let item = InvoiceItem(
            description: itemDescription,
            quantity: quantity,
            unitPrice: unitPrice,
            taxRate: taxRate
        )
        
        items.append(item)
        
        // Réinitialiser les champs
        itemDescription = ""
        itemQuantity = ""
        itemUnitPrice = ""
        itemTaxRate = ""
        
        showingAddItem = false
    }
    
    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    private func createInvoice() {
        let client = Client(
            id: UUID(),
            name: clientName,
            email: clientEmail
        )
        
        let invoice = Invoice(
            id: UUID(),
            client: client,
            items: items,
            date: Date(),
            dueDate: dueDate,
            status: .pending,
            nextInvoiceDate: nil,
            frequency: frequency
        )
        
        dataManager.saveInvoice(invoice)
        dismiss()
    }
}

// Extension pour rendre InvoiceFrequency compatible avec Picker
extension InvoiceFrequency: CaseIterable { }

struct AddInvoiceView_Previews: PreviewProvider {
    static var previews: some View {
        AddInvoiceView(dataManager: DataManager())
    }
} 