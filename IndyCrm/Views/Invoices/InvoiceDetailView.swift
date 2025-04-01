import SwiftUI
import UserNotifications
import UniformTypeIdentifiers
import UIKit

// MARK: - Main View
struct InvoiceDetailView: View {
    let invoice: Invoice
    @ObservedObject var invoiceManager: InvoiceManager
    @ObservedObject var contactsManager: ContactsManager
    @State private var showingEditSheet = false
    @State private var showingExportSheet = false
    @State private var pdfURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var client: Contact? {
        contactsManager.contacts.first(where: { $0.id == invoice.clientId })
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // En-tête avec statut
                HStack {
                    VStack(alignment: .leading) {
                        Text("Facture \(invoice.number)")
                            .font(.title2.bold())
                        Text(invoice.date.formatted(date: .long, time: .omitted))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: invoice.status)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                // Informations client
                if let client = client {
                    ClientCard(client: client)
                        .padding(.horizontal)
                }
                
                // Articles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Articles")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 1) {
                        ForEach(invoice.items) { item in
                            InvoiceDetailItemRow(item: item)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                        }
                        
                        // Total
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(invoice.total.formatted(.currency(code: "EUR")))
                                .font(.title3.bold())
                        }
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Notes
                if !invoice.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(invoice.notes)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                InvoiceFormView(
                    invoiceManager: invoiceManager,
                    contactsManager: contactsManager,
                    editingInvoice: invoice
                )
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = pdfURL {
                InvoiceShareSheet(items: [url])
            }
        }
        .alert("Information", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Modifier") {
                    showingEditSheet = true
                }
                
                Button("Marquer comme payée") {
                    updateStatus(.paid)
                }
                .disabled(invoice.status == .paid)
                
                Button("Marquer comme envoyée") {
                    updateStatus(.sent)
                }
                .disabled(invoice.status == .sent || invoice.status == .paid)
                
                Button("Exporter en PDF") {
                    exportToPDF()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private func updateStatus(_ status: InvoiceStatus) {
        var updatedInvoice = invoice
        updatedInvoice.status = status
        invoiceManager.updateInvoice(updatedInvoice)
        
        // Afficher une confirmation
        alertMessage = "Facture marquée comme \(status.rawValue.lowercased())"
        showingAlert = true
        
        // Si la facture est marquée comme payée, programmer une notification de remerciement
        if status == .paid {
            let content = UNMutableNotificationContent()
            content.title = "Paiement reçu"
            content.body = "Le paiement de la facture \(invoice.number) a été reçu. Pensez à remercier votre client !"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // Rappel dans 1h
            let request = UNNotificationRequest(identifier: "payment-thanks-\(invoice.id)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func exportToPDF() {
        let clientName = client?.fullName ?? "Client inconnu"
        if let url = invoiceManager.exportInvoiceToPDF(invoice, clientName: clientName) {
            pdfURL = url
            showingExportSheet = true
        } else {
            alertMessage = "Erreur lors de l'export PDF"
            showingAlert = true
        }
    }
}

// MARK: - Composants
private struct ClientCard: View {
    let client: Contact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(client.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(client.initials)
                            .font(.headline)
                            .foregroundColor(client.type.color)
                    )
                
                VStack(alignment: .leading) {
                    Text(client.fullName)
                        .font(.headline)
                    Text(client.type.localizedName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if !client.organization.isEmpty {
                Text(client.organization)
                    .font(.subheadline)
            }
            
            HStack {
                Label(client.email, systemImage: "envelope")
                Spacer()
                Label(client.phone, systemImage: "phone")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Amélioration de InvoiceDetailItemRow
private struct InvoiceDetailItemRow: View {
    let item: InvoiceItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(item.description)
                    .font(.headline)
                Spacer()
                Text((item.quantity * item.unitPrice).formatted(.currency(code: "EUR")))
                    .font(.headline)
            }
            
            HStack {
                Text("\(item.quantity.formatted()) x \(item.unitPrice.formatted(.currency(code: "EUR")))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !item.notes.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - ShareSheet
struct InvoiceShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Prévisualisation
#Preview {
    NavigationView {
        InvoiceDetailView(
            invoice: Invoice(
                id: UUID(),
                number: "F-2025-001",
                clientId: UUID(),
                date: Date(),
                dueDate: Date().addingTimeInterval(86400 * 30),
                items: [],
                status: .draft,
                notes: ""
            ),
            invoiceManager: InvoiceManager(),
            contactsManager: ContactsManager()
        )
    }
} 
