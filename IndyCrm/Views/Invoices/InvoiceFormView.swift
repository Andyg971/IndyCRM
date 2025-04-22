import SwiftUI

struct InvoiceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var invoiceManager: InvoiceManager
    @ObservedObject var contactsManager: ContactsManager
    
    var editingInvoice: Invoice?
    
    @State private var number: String = ""
    @State private var selectedClientId: UUID?
    @State private var date = Date()
    @State private var dueDate = Date()
    @State private var status: InvoiceStatus = .draft
    @State private var notes: String = ""
    @State private var items: [InvoiceItem] = []
    @State private var showingAddItem = false
    
    private var isEditing: Bool {
        editingInvoice != nil
    }
    
    var body: some View {
        Form {
            Section(header: Text("Informations")) {
                TextField("Numéro de facture", text: $number)
                
                Picker("Client", selection: $selectedClientId) {
                    Text("Sélectionner un client").tag(nil as UUID?)
                    ForEach(contactsManager.contacts.filter { $0.type == .client }) { contact in
                        Text(contact.fullName).tag(contact.id as UUID?)
                    }
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Date d'échéance", selection: $dueDate, displayedComponents: .date)
                
                Picker("Statut", selection: $status) {
                    ForEach(InvoiceStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }
            
            Section(header: Text("Articles")) {
                ForEach(items) { item in
                    InvoiceItemRow(item: item)
                }
                .onDelete { indexSet in
                    items.remove(atOffsets: indexSet)
                }
                
                Button("Ajouter un article") {
                    showingAddItem = true
                }
            }
            
            Section(header: Text("Total")) {
                HStack {
                    Text("Total HT")
                    Spacer()
                    Text(totalAmount.formatted(.currency(code: "EUR")))
                        .fontWeight(.bold)
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
        }
        .navigationTitle(isEditing ? "Modifier la facture" : "Nouvelle facture")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Enregistrer") {
                    saveInvoice()
                }
                .disabled(!isValid)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationView {
                InvoiceItemFormView { item in
                    items.append(item)
                }
            }
        }
        .onAppear {
            if let invoice = editingInvoice {
                number = invoice.number
                selectedClientId = invoice.clientId
                date = invoice.date
                dueDate = invoice.dueDate
                status = invoice.status
                notes = invoice.notes
                items = invoice.items
            }
        }
    }
    
    private var isValid: Bool {
        !number.isEmpty && selectedClientId != nil && !items.isEmpty
    }
    
    private var totalAmount: Double {
        items.reduce(0) { $0 + ($1.quantity * $1.unitPrice) }
    }
    
    private func saveInvoice() {
        guard let clientId = selectedClientId else { return }
        
        let invoice = Invoice(
            id: editingInvoice?.id ?? UUID(),
            number: number,
            clientId: clientId,
            date: date,
            dueDate: dueDate,
            items: items,
            status: status,
            notes: notes
        )
        
        Task {
            if isEditing {
                await invoiceManager.updateInvoice(invoice)
            } else {
                await invoiceManager.addInvoice(invoice)
            }
        }
        
        // Programmer les notifications pour l'échéance
        NotificationManager.shared.scheduleInvoiceReminder(invoice: invoice)
        
        dismiss()
    }
}

struct InvoiceItemRow: View {
    let item: InvoiceItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.description)
                .font(.headline)
            HStack {
                Text("\(item.quantity.formatted()) x \(item.unitPrice.formatted(.currency(code: "EUR")))")
                Spacer()
                Text((item.quantity * item.unitPrice).formatted(.currency(code: "EUR")))
                    .fontWeight(.semibold)
            }
        }
    }
} 