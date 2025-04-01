import SwiftUI

struct InvoiceItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (InvoiceItem) -> Void
    
    @State private var description = ""
    @State private var quantity = 1.0
    @State private var unitPrice = 0.0
    @State private var notes = ""
    
    var body: some View {
        Form {
            Section(header: Text("Détails de l'article")) {
                TextField("Description", text: $description)
                
                HStack {
                    Text("Quantité")
                    Spacer()
                    TextField("Quantité", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Prix unitaire")
                    Spacer()
                    TextField("Prix", value: $unitPrice, format: .currency(code: "EUR"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
            
            Section(header: Text("Total")) {
                HStack {
                    Text("Total HT")
                    Spacer()
                    Text((quantity * unitPrice).formatted(.currency(code: "EUR")))
                        .fontWeight(.bold)
                }
            }
        }
        .navigationTitle("Nouvel article")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Ajouter") {
                    saveItem()
                }
                .disabled(!isValid)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
    }
    
    private var isValid: Bool {
        !description.isEmpty && quantity > 0 && unitPrice > 0
    }
    
    private func saveItem() {
        let item = InvoiceItem(
            id: UUID(),
            description: description,
            quantity: quantity,
            unitPrice: unitPrice,
            notes: notes
        )
        onSave(item)
        dismiss()
    }
} 