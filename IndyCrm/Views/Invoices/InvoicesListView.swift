import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct InvoicesListView: View {
    @ObservedObject var invoiceManager: InvoiceManager
    @ObservedObject var contactsManager: ContactsManager
    @State private var showingNewInvoice = false
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var exportURLs: [URL] = []
    @State private var exportFormat: ExportFormat = .csv
    
    enum ExportFormat {
        case csv, pdf
    }
    
    var filteredInvoices: [Invoice] {
        if searchText.isEmpty {
            return invoiceManager.invoices
        } else {
            return invoiceManager.invoices.filter { invoice in
                let clientName = contactsManager.contacts.first(where: { $0.id == invoice.clientId })?.fullName ?? ""
                return invoice.number.localizedCaseInsensitiveContains(searchText) ||
                       clientName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(filteredInvoices) { invoice in
                    NavigationLink(destination: InvoiceDetailView(invoice: invoice, invoiceManager: invoiceManager, contactsManager: contactsManager)) {
                        InvoiceRowView(invoice: invoice, contact: contactsManager.contacts.first(where: { $0.id == invoice.clientId }))
                    }
                    .contextMenu {
                        Button(action: {
                            exportSingleInvoice(invoice)
                        }) {
                            Label("Exporter en PDF", systemImage: "arrow.down.doc")
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        invoiceManager.deleteInvoice(filteredInvoices[index])
                    }
                }
            }
            
            // Bouton de traitement automatique
            if !invoiceManager.invoices.filter({ $0.status == .draft }).isEmpty {
                Button(action: {
                    Task {
                        await invoiceManager.processPendingInvoices()
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.badge")
                        Text("Traiter les factures en attente")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(invoiceManager.isProcessingInvoices)
                
                if invoiceManager.isProcessingInvoices {
                    ProgressView()
                        .padding(.bottom)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher une facture")
        .navigationTitle("Factures")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewInvoice = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Exporter en CSV") {
                        exportFormat = .csv
                        exportInvoices()
                    }
                    
                    Button("Exporter en PDF") {
                        exportFormat = .pdf
                        exportInvoices()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingNewInvoice) {
            NavigationView {
                InvoiceFormView(invoiceManager: invoiceManager, contactsManager: contactsManager)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if exportFormat == .csv, let url = exportURL {
                InvoicesListShareSheet(items: [url])
            } else if exportFormat == .pdf {
                InvoicesListShareSheet(items: exportURLs)
            }
        }
    }
    
    private func exportInvoices() {
        switch exportFormat {
        case .csv:
            if let url = invoiceManager.exportToCSV() {
                exportURL = url
                showingExportSheet = true
            }
        case .pdf:
            if let url = invoiceManager.exportToPDF(contacts: contactsManager.contacts) {
                exportURLs = [url]
                showingExportSheet = true
            }
        }
    }
    
    private func exportSingleInvoice(_ invoice: Invoice) {
        let clientName = contactsManager.contacts.first(where: { $0.id == invoice.clientId })?.fullName ?? "Client inconnu"
        if let url = invoiceManager.exportInvoiceToPDF(invoice, clientName: clientName) {
            exportURLs = [url]
            exportFormat = .pdf
            showingExportSheet = true
        }
    }
}

// MARK: - UIActivityShareSheet
struct InvoicesListShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct InvoiceRowView: View {
    let invoice: Invoice
    let contact: Contact?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(invoice.number)
                    .font(.headline)
                Spacer()
                Text(invoice.total.formatted(.currency(code: "EUR")))
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text(contact?.fullName ?? "Client inconnu")
                    .foregroundColor(.secondary)
                Spacer()
                Text(invoice.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
    
    var statusColor: Color {
        switch invoice.status {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .purple
        }
    }
}

#Preview {
    NavigationView {
        InvoicesListView(
            invoiceManager: InvoiceManager(),
            contactsManager: ContactsManager()
        )
    }
} 
