import SwiftUI
import Contacts
import ContactsUI
import UniformTypeIdentifiers

struct ContactExporterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contacts: [CNContact] = []
    @State private var showContactPicker = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var exportFormat: ExportFormat = .csv
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case vcard = "VCard"
        
        var icon: String {
            switch self {
            case .csv: return "doc.text"
            case .vcard: return "person.crop.rectangle"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .vcard: return "vcf"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Liste des contacts sélectionnés
                List(contacts, id: \.identifier) { contact in
                    VStack(alignment: .leading) {
                        Text("\(contact.givenName) \(contact.familyName)")
                            .font(.headline)
                        Text(contact.phoneNumbers.first?.value.stringValue ?? "Aucun numéro")
                            .foregroundColor(.gray)
                    }
                }
                
                // Sélection du format
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Label(format.rawValue, systemImage: format.icon)
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Boutons d'action
                VStack(spacing: 12) {
                    Button(action: {
                        showContactPicker.toggle()
                    }) {
                        Label("Sélectionner des contacts", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: exportContacts) {
                        Label("Exporter", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(contacts.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Exporter les contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker(selectedContacts: $contacts)
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportURL = exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func exportContacts() {
        switch exportFormat {
        case .csv:
            exportToCSV()
        case .vcard:
            exportToVCard()
        }
    }
    
    private func createExportDirectory() -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("exports", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            return exportDir
        } catch {
            errorMessage = "Erreur lors de la création du dossier d'export: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }
    
    private func exportToCSV() {
        guard let exportDir = createExportDirectory() else { return }
        
        let csvString = "Nom,Prénom,Email,Téléphone,Organisation\n" + contacts.map { contact in
            let name = contact.familyName
            let firstName = contact.givenName
            let email = contact.emailAddresses.first?.value as String? ?? ""
            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            let organization = contact.organizationName
            return "\"\(name)\",\"\(firstName)\",\"\(email)\",\"\(phone)\",\"\(organization)\""
        }.joined(separator: "\n")
        
        let fileName = "contacts.\(exportFormat.fileExtension)"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showShareSheet = true
        } catch {
            errorMessage = "Erreur lors de l'exportation CSV: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func exportToVCard() {
        guard let exportDir = createExportDirectory() else { return }
        
        var vcardString = ""
        
        for contact in contacts {
            vcardString += "BEGIN:VCARD\n"
            vcardString += "VERSION:3.0\n"
            vcardString += "N:\(contact.familyName);\(contact.givenName);;;\n"
            vcardString += "FN:\(contact.givenName) \(contact.familyName)\n"
            
            if !contact.organizationName.isEmpty {
                vcardString += "ORG:\(contact.organizationName)\n"
            }
            
            for phoneNumber in contact.phoneNumbers {
                let number = phoneNumber.value.stringValue
                vcardString += "TEL;TYPE=CELL:\(number)\n"
            }
            
            for email in contact.emailAddresses {
                vcardString += "EMAIL;TYPE=INTERNET:\(email.value as String)\n"
            }
            
            vcardString += "END:VCARD\n"
        }
        
        let fileName = "contacts.\(exportFormat.fileExtension)"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        do {
            try vcardString.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showShareSheet = true
        } catch {
            errorMessage = "Erreur lors de l'exportation VCard: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Contact Picker
struct ContactPicker: UIViewControllerRepresentable {
    @Binding var selectedContacts: [CNContact]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.selectedContacts = contacts
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews
struct ContactExporterView_Previews: PreviewProvider {
    static var previews: some View {
        ContactExporterView()
    }
} 