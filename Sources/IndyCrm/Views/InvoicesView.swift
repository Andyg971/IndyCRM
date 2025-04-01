import SwiftUI

struct InvoicesView: View {
    @StateObject private var autoInvoiceManager = AutoInvoiceManager(
        dataManager: DataManager(),
        notificationManager: NotificationManager(),
        pdfGenerator: PDFInvoiceGenerator(),
        emailService: EmailService()
    )
    
    @State private var showingAddInvoice = false
    
    var body: some View {
        VStack {
            List(autoInvoiceManager.invoices) { invoice in
                InvoiceRow(invoice: invoice)
            }
            
            Button(action: {
                Task {
                    await autoInvoiceManager.processPendingInvoices()
                }
            }) {
                HStack {
                    Image(systemName: "envelope.badge")
                    Text("Envoyer les factures en attente")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(autoInvoiceManager.isProcessing)
            
            if autoInvoiceManager.isProcessing {
                ProgressView()
                    .padding()
            }
        }
        .navigationTitle("Factures")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddInvoice = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddInvoice) {
            AddInvoiceView(dataManager: autoInvoiceManager.dataManager)
        }
        .onChange(of: showingAddInvoice) { isShowing in
            if !isShowing {
                autoInvoiceManager.refreshInvoices()
            }
        }
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(invoice.client.name)
                .font(.headline)
            
            HStack {
                Text("Montant: \(invoice.totalAmount, specifier: "%.2f")€")
                Spacer()
                StatusBadge(status: invoice.status)
            }
            
            Text("Échéance: \(invoice.dueDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: InvoiceStatus
    
    var backgroundColor: Color {
        switch status {
        case .pending: return .blue
        case .paid: return .green
        case .overdue: return .red
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct InvoicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InvoicesView()
        }
    }
} 