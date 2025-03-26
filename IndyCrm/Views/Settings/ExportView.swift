import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var invoiceManager: InvoiceManager
    @StateObject private var exportService = ExportService()
    @State private var selectedType: ExportService.ExportType = .contacts
    @State private var selectedFormat: ExportService.ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Type de données") {
                Picker("Type", selection: $selectedType) {
                    ForEach([
                        ExportService.ExportType.contacts,
                        .projects,
                        .tasks,
                        .invoices
                    ], id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }
            
            Section("Format") {
                Picker("Format", selection: $selectedFormat) {
                    Group {
                        Text("CSV").tag(ExportService.ExportFormat.csv)
                        Text("Excel").tag(ExportService.ExportFormat.excel)
                        Text("PDF").tag(ExportService.ExportFormat.pdf)
                        
                        if selectedType == .contacts {
                            Text("vCard").tag(ExportService.ExportFormat.vcard)
                        }
                        if selectedType == .projects || selectedType == .tasks {
                            Text("iCalendar").tag(ExportService.ExportFormat.ical)
                        }
                    }
                }
            }
            
            Section {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Exporter")
                    }
                }
            }
        }
        .navigationTitle("Export")
        .sheet(isPresented: $showingShareSheet, content: {
            if let url = exportURL {
                SystemShareSheet(items: [url])
            }
        })
        .alert("Export", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportData() {
        Task {
            var url: URL?
            
            let allTasks = projectManager.projects.flatMap { $0.tasks }
            
            switch (selectedType, selectedFormat) {
            case (.contacts, .csv):
                url = exportService.exportToCSV(.contacts, contacts: contactsManager.contacts)
            case (.projects, .csv):
                url = exportService.exportToCSV(.projects, projects: projectManager.projects)
            case (.tasks, .csv):
                url = exportService.exportToCSV(.tasks, tasks: allTasks)
            case (.invoices, .csv):
                url = exportService.exportToCSV(.invoices, invoices: invoiceManager.invoices)
            case (_, .excel):
                url = exportService.exportToExcel(selectedType, 
                                               contacts: contactsManager.contacts,
                                               projects: projectManager.projects,
                                               tasks: allTasks,
                                               invoices: invoiceManager.invoices)
            case (.projects, .ical):
                url = exportService.exportToICalendar(projects: projectManager.projects)
            case (.contacts, .vcard):
                url = exportService.exportToVCard(contacts: contactsManager.contacts)
            case (_, .pdf):
                url = exportService.exportToPDF(selectedType,
                                             contacts: contactsManager.contacts,
                                             projects: projectManager.projects,
                                             tasks: allTasks,
                                             invoices: invoiceManager.invoices)
            default:
                alertMessage = "Format non supporté"
                showingAlert = true
                return
            }
            
            if let url = url {
                exportURL = url
                showingShareSheet = true
            } else {
                alertMessage = "Erreur lors de l'export"
                showingAlert = true
            }
        }
    }
}

struct SystemShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        ExportView(
            projectManager: ProjectManager(activityLogService: ActivityLogService()),
            contactsManager: ContactsManager(),
            invoiceManager: InvoiceManager()
        )
    }
}