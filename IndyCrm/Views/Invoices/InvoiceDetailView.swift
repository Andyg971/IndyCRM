import SwiftUI
import UserNotifications
import UniformTypeIdentifiers
import UIKit

// MARK: - Main View
struct InvoiceDetailView: View {
    @State var invoice: Invoice
    @ObservedObject var invoiceManager: InvoiceManager
    @ObservedObject var contactsManager: ContactsManager
    @State private var showingEditSheet = false
    @State private var showingExportSheet = false
    @State private var pdfURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingStatusAlert = false
    @State private var selectedStatus: InvoiceStatus?
    
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
        .alert("Confirmer le changement de statut", isPresented: $showingStatusAlert) {
            Button(selectedStatus?.rawValue ?? "", role: .destructive) {
                updateStatus(selectedStatus ?? .draft)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Voulez-vous vraiment changer le statut de cette facture en \"\(selectedStatus?.rawValue ?? "")\" ?")
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Modifier") {
                    showingEditSheet = true
                }
                
                Button("Marquer comme payée") {
                    selectedStatus = .paid
                    showingStatusAlert = true
                }
                .disabled(invoice.status == .paid)
                
                Button("Marquer comme envoyée") {
                    selectedStatus = .sent
                    showingStatusAlert = true
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
    
    private func updateStatus(_ newStatus: InvoiceStatus) {
        var updatedInvoice = invoice
        updatedInvoice.status = newStatus
        updatedInvoice.updatedAt = Date() // Update the modification date
        // Wrap the asynchronous call in a Task
        Task {
            do {
                await invoiceManager.updateInvoice(updatedInvoice)
                print("Statut de la facture mis à jour avec succès.")
                self.invoice = updatedInvoice // Mettre à jour la vue locale
                alertMessage = NSLocalizedString("Facture marquée comme ", comment: "Alert message prefix") + newStatus.rawValue.lowercased()
                showingAlert = true
                
                // Si la facture est marquée comme payée, programmer une notification de remerciement
                if newStatus == .paid {
                    let content = UNMutableNotificationContent()
                    content.title = NSLocalizedString("Paiement reçu", comment: "Notification title")
                    content.body = String(format: NSLocalizedString("Le paiement de la facture %@ a été reçu. Pensez à remercier votre client !", comment: "Notification body"), invoice.number)
                    content.sound = .default
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // Rappel dans 1h
                    let request = UNNotificationRequest(identifier: "payment-thanks-\(invoice.id)", content: content, trigger: trigger)
                    
                    try await UNUserNotificationCenter.current().add(request)
                }
            } catch {
                print("Erreur lors de la mise à jour du statut de la facture: \(error.localizedDescription)")
                // Afficher une alerte à l'utilisateur
                alertMessage = NSLocalizedString("Erreur lors de la mise à jour : ", comment: "Alert message prefix for update error") + error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func exportToPDF() {
        let clientName = client?.fullName ?? "Client inconnu"
        if let url = invoiceManager.exportInvoiceToPDF(invoice, clientName: clientName) {
            pdfURL = url
            // Changer le statut à Envoyée si elle était en Brouillon
            if invoice.status == .draft {
                // Pas besoin d'alerte de confirmation ici, car l'export implique l'envoi
                updateStatus(.sent)
            }
            // Afficher la feuille de partage après la mise à jour éventuelle du statut
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
