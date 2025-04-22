import SwiftUI
import UniformTypeIdentifiers
import UIKit

// Déplacé au niveau du module pour être accessible par toutes les vues
enum ExportFormat {
    case csv, pdf
}

struct InvoicesListView: View {
    @ObservedObject var invoiceManager: InvoiceManager
    @ObservedObject var contactsManager: ContactsManager
    @State private var searchText = ""
    @State private var selectedStatus: InvoiceStatus?
    @State private var showingNewInvoice = false
    @StateObject private var exportService = ExportService()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingDeleteAlert = false
    @State private var invoiceToDelete: Invoice?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                FilterBarView(searchText: $searchText, selectedStatus: $selectedStatus)
                
                List {
                    ForEach(filteredInvoices) { invoice in
                        NavigationLink(destination: InvoiceDetailView(
                            invoice: invoice,
                            invoiceManager: invoiceManager,
                            contactsManager: contactsManager
                        )) {
                            InvoiceRowView(
                                invoice: invoice,
                                contact: contactsManager.contacts.first(where: { $0.id == invoice.clientId })
                            )
                        }
                    }
                    .onDelete(perform: deleteInvoices)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingNewInvoice = true }) {
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
        .navigationTitle("Factures")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: exportToCSV) {
                        Label("Exporter en CSV", systemImage: "doc.text")
                    }
                    
                    Button(action: exportToExcel) {
                        Label("Exporter en Excel", systemImage: "tablecells")
                    }
                    
                    Button(action: { showingNewInvoice = true }) {
                        Label("Nouvelle facture", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .accentColor(.indigo)
        .sheet(isPresented: $showingNewInvoice) {
            NavigationView {
                InvoiceFormView(
                    invoiceManager: invoiceManager,
                    contactsManager: contactsManager
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                SystemShareSheet(items: [url])
            }
        }
        .alert("Confirmation", isPresented: $showingDeleteAlert) {
            Button("Supprimer", role: .destructive) {
                if let invoice = invoiceToDelete {
                    deleteInvoice(invoice)
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Voulez-vous vraiment supprimer cette facture ?")
        }
    }
    
    private var filteredInvoices: [Invoice] {
        var invoices = invoiceManager.invoices
        
        if let selectedStatus = selectedStatus {
            invoices = invoices.filter { $0.status == selectedStatus }
        }
        
        if !searchText.isEmpty {
            invoices = invoices.filter { invoice in
                let clientName = contactsManager.contacts.first(where: { $0.id == invoice.clientId })?.fullName ?? ""
                return invoice.number.localizedCaseInsensitiveContains(searchText) ||
                       clientName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return invoices.sorted { $0.date > $1.date }
    }
    
    private func deleteInvoices(at offsets: IndexSet) {
        for index in offsets {
            let invoice = filteredInvoices[index]
            invoiceToDelete = invoice
            showingDeleteAlert = true
        }
    }
    
    private func deleteInvoice(_ invoice: Invoice) {
        Task {
            await invoiceManager.deleteInvoice(invoice)
            invoiceToDelete = nil
        }
    }
    
    private func exportToCSV() {
        if let url = exportService.exportToCSV(.invoices, invoices: invoiceManager.invoices) {
            exportURL = url
            showingShareSheet = true
        }
    }
    
    private func exportToExcel() {
        if let url = exportService.exportToExcel(.invoices, invoices: invoiceManager.invoices) {
            exportURL = url
            showingShareSheet = true
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

// MARK: - Sous-composants
private struct InvoiceListContent: View {
    let filteredInvoices: [Invoice]
    let invoiceManager: InvoiceManager
    let contactsManager: ContactsManager
    @Binding var showingDeleteAlert: Bool
    @Binding var invoiceToDelete: Invoice?
    let exportSingleInvoice: (Invoice) -> Void
    
    var body: some View {
        List {
            if filteredInvoices.isEmpty {
                Text("invoices.empty".localized)
                    .foregroundColor(.secondary)
            } else {
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
                        invoiceToDelete = filteredInvoices[index]
                        showingDeleteAlert = true
                    }
                }
            }
        }
    }
}

private struct PendingInvoicesButton: View {
    @ObservedObject var invoiceManager: InvoiceManager
    
    var body: some View {
        if !invoiceManager.invoices.filter({ $0.status == .draft }).isEmpty {
            VStack {
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
    }
}

private struct ToolbarItems: ToolbarContent {
    @Binding var showingNewInvoice: Bool
    @Binding var exportFormat: ExportFormat
    let exportInvoices: () -> Void
    
    var body: some ToolbarContent {
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
}

private struct ExportSheet: View {
    let exportFormat: ExportFormat
    let exportURL: URL?
    let exportURLs: [URL]
    
    var body: some View {
        if exportFormat == .csv, let url = exportURL {
            InvoicesListShareSheet(items: [url])
        } else if exportFormat == .pdf {
            InvoicesListShareSheet(items: exportURLs)
        }
    }
}

private struct DeleteAlert: View {
    let invoiceToDelete: Invoice?
    let onDelete: (Invoice) -> Void
    
    var body: some View {
        Group {
            Button("action.delete".localized, role: .destructive) {
                if let invoice = invoiceToDelete {
                    onDelete(invoice)
                }
            }
            Button("action.cancel".localized, role: .cancel) {}
        }
    }
}

private struct StatusFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.indigo : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

private struct FilterBarView: View {
    @Binding var searchText: String
    @Binding var selectedStatus: InvoiceStatus?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(title: "Toutes", status: nil, selectedStatus: $selectedStatus)
                
                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                    FilterButton(
                        title: status.rawValue,
                        status: status,
                        selectedStatus: $selectedStatus
                    )
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
    let status: InvoiceStatus?
    @Binding var selectedStatus: InvoiceStatus?
    
    var body: some View {
        Button {
            withAnimation {
                selectedStatus = status
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(status == selectedStatus ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(status == selectedStatus ? .white : .primary)
                .cornerRadius(8)
        }
    }
} 
