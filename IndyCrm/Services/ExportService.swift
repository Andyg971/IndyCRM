import Foundation
import UniformTypeIdentifiers
import EventKit
import PDFKit
import UIKit
import Contacts

@MainActor
class ExportService: ObservableObject {
    enum ExportFormat {
        case csv, excel, ical, vcard, pdf
    }
    
    enum ExportType: String {
        case contacts = "contacts"
        case projects = "projets"
        case tasks = "taches"
        case invoices = "factures"
        
        var filename: String {
            return self.rawValue
        }
    }
    
    private let fileManager = FileManager.default
    
    // Export vers CSV
    private func escapeCSV(_ value: String) -> String {
        let needsEscaping = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsEscaping {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
    
    func exportToCSV(_ type: ExportType, contacts: [Contact] = [], projects: [Project] = [], tasks: [ProjectTask] = [], invoices: [Invoice] = []) -> URL? {
        let tempDir = fileManager.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("exports", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "export_\(type.rawValue)_\(timestamp).csv"
            let fileURL = exportDir.appendingPathComponent(fileName)
            
            // Vérifier si les données sont vides selon le type
            switch type {
            case .contacts:
                if contacts.isEmpty {
                    print("Aucun contact à exporter")
                    return nil
                }
            case .projects:
                if projects.isEmpty {
                    print("Aucun projet à exporter")
                    return nil
                }
            case .tasks:
                if tasks.isEmpty {
                    print("Aucune tâche à exporter")
                    return nil
                }
            case .invoices:
                if invoices.isEmpty {
                    print("Aucune facture à exporter")
                    return nil
                }
            }
            
            var csvContent = ""
            
            // Ajouter le BOM UTF-8 pour Excel
            let bom = "\u{FEFF}"
            csvContent.append(bom)
            
            switch type {
            case .contacts:
                // En-têtes
                csvContent += "ID,Prénom,Nom,Email,Téléphone,Type,Statut,Organisation,Notes\n"
                
                // Données
                for contact in contacts {
                    let row = [
                        contact.id,
                        contact.firstName,
                        contact.lastName,
                        contact.email,
                        contact.phone,
                        contact.type.rawValue,
                        contact.employmentStatus.rawValue,
                        contact.organization,
                        contact.notes
                    ].map { escapeCSV(String(describing: $0)) }.joined(separator: ",")
                    csvContent += row + "\n"
                }
                
            case .projects:
                // En-têtes
                csvContent += "ID,Nom,Date début,Date fin,Statut,Notes\n"
                
                // Données
                for project in projects {
                    let row = [
                        project.id,
                        project.name,
                        formatDateISO8601(project.startDate),
                        project.deadline.map(formatDateISO8601) ?? "",
                        project.status.rawValue,
                        project.notes
                    ].map { escapeCSV(String(describing: $0)) }.joined(separator: ",")
                    csvContent += row + "\n"
                }
                
            case .tasks:
                // En-têtes
                csvContent += "ID,Titre,Description,Complété,Date limite,Heures estimées,Heures travaillées\n"
                
                // Données
                for task in tasks {
                    let row = [
                        task.id,
                        task.title,
                        task.description,
                        task.isCompleted ? "Oui" : "Non",
                        task.dueDate.map(formatDateISO8601) ?? "",
                        String(task.estimatedHours ?? 0),
                        String(task.workedHours)
                    ].map { escapeCSV(String(describing: $0)) }.joined(separator: ",")
                    csvContent += row + "\n"
                }
                
            case .invoices:
                // En-têtes
                csvContent += "Numéro,Date,Date d'échéance,Montant,Statut,Notes,Articles\n"
                
                // Données
                for invoice in invoices {
                    let itemsDetails = invoice.items.map { "\($0.description) (Qté: \($0.quantity), Prix: \($0.unitPrice)€)" }.joined(separator: "; ")
                    let row = [
                        invoice.number,
                        formatDateISO8601(invoice.date),
                        formatDateISO8601(invoice.dueDate),
                        String(format: "%.2f", invoice.total),
                        invoice.status.rawValue,
                        invoice.notes,
                        itemsDetails
                    ].map { escapeCSV(String(describing: $0)) }.joined(separator: ",")
                    csvContent += row + "\n"
                }
            }
            
            // Écrire le fichier avec l'encodage UTF-8
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Export CSV réussi: \(fileURL.path)")
            return fileURL
            
        } catch {
            print("Erreur d'export CSV pour \(type.rawValue): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Export vers Excel (XLSX)
    func exportToExcel(_ type: ExportType, contacts: [Contact]? = nil, projects: [Project]? = nil, tasks: [ProjectTask]? = nil, invoices: [Invoice]? = nil) -> URL? {
        guard let exportDir = createExportDirectory() else { return nil }
        
        // Vérifier qu'il y a des données à exporter selon le type
        switch type {
        case .contacts:
            guard let contactList = contacts, !contactList.isEmpty else { 
                print("Aucun contact à exporter")
                return nil 
            }
        case .projects:
            guard let projectList = projects, !projectList.isEmpty else { 
                print("Aucun projet à exporter")
                return nil 
            }
        case .tasks:
            guard let taskList = tasks, !taskList.isEmpty else { 
                print("Aucune tâche à exporter")
                return nil 
            }
        case .invoices:
            guard let invoiceList = invoices, !invoiceList.isEmpty else { 
                print("Aucune facture à exporter")
                return nil 
            }
        }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "\(type.rawValue)_\(timestamp).xlsx"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        var csvContent = ""
        let bom = "\u{FEFF}" // UTF-8 BOM pour Excel
        
        switch type {
        case .contacts:
            guard let contactsToExport = contacts else { return nil }
            let headers = ["ID", "Prénom", "Nom", "Email", "Téléphone", "Type", "Statut", "Organisation", "Notes"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: "\t") + "\n"
            
            for contact in contactsToExport {
                let row = [
                    contact.id.uuidString,
                    contact.firstName,
                    contact.lastName,
                    contact.email,
                    contact.phone,
                    contact.type.rawValue,
                    contact.employmentStatus.rawValue,
                    contact.organization,
                    contact.notes
                ].map { escapeCSV(String(describing: $0)) }.joined(separator: "\t")
                csvContent += row + "\n"
            }
            
        case .projects:
            guard let projectsToExport = projects else { return nil }
            let headers = ["ID", "Nom", "Date début", "Date fin", "Statut", "Notes"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: "\t") + "\n"
            
            for project in projectsToExport {
                let row = [
                    project.id.uuidString,
                    project.name,
                    DateFormatter.localizedString(from: project.startDate, dateStyle: .short, timeStyle: .none),
                    project.deadline.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "",
                    project.status.rawValue,
                    project.notes
                ].map { escapeCSV(String(describing: $0)) }.joined(separator: "\t")
                csvContent += row + "\n"
            }
            
        case .tasks:
            guard let tasksToExport = tasks else { return nil }
            let headers = ["ID", "Titre", "Description", "Complété", "Date limite", "Heures estimées", "Heures travaillées"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: "\t") + "\n"
            
            for task in tasksToExport {
                let row = [
                    task.id.uuidString,
                    task.title,
                    task.description,
                    task.isCompleted ? "Oui" : "Non",
                    task.dueDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "",
                    String(format: "%.1f", task.estimatedHours ?? 0.0),
                    String(format: "%.1f", task.workedHours)
                ].map { escapeCSV(String(describing: $0)) }.joined(separator: "\t")
                csvContent += row + "\n"
            }
            
        case .invoices:
            guard let invoicesToExport = invoices else { return nil }
            let headers = ["Numéro", "Date", "Date d'échéance", "Montant", "Statut", "Notes"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: "\t") + "\n"
            
            for invoice in invoicesToExport {
                let row = [
                    invoice.number,
                    DateFormatter.localizedString(from: invoice.date, dateStyle: .short, timeStyle: .none),
                    DateFormatter.localizedString(from: invoice.dueDate, dateStyle: .short, timeStyle: .none),
                    String(format: "%.2f €", invoice.total),
                    invoice.status.rawValue,
                    invoice.notes
                ].map { escapeCSV(String(describing: $0)) }.joined(separator: "\t")
                csvContent += row + "\n"
            }
        }
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Export Excel réussi: \(fileURL.path)")
            return fileURL
        } catch {
            print("Erreur d'export Excel pour \(type.rawValue): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Export vers iCalendar
    func exportToICalendar(projects: [Project]) -> URL? {
        var icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//IndyCRM//FR
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        """
        
        for project in projects {
            // Événement principal du projet
            icsContent += """
            
            BEGIN:VEVENT
            UID:\(project.id)
            DTSTAMP:\(formatDateICS(Date()))
            DTSTART:\(formatDateICS(project.startDate))
            """
            
            if let deadline = project.deadline {
                icsContent += "\nDTEND:\(formatDateICS(deadline))"
            }
            
            icsContent += """
            
            SUMMARY:\(project.name)
            DESCRIPTION:Statut: \(project.status.rawValue)\\nNotes: \(project.notes)
            CATEGORIES:PROJET
            STATUS:\(project.status == .completed ? "COMPLETED" : "CONFIRMED")
            END:VEVENT
            """
            
            // Ajouter les tâches comme événements
            for task in project.tasks {
                if let dueDate = task.dueDate {
                    icsContent += """
                    
                    BEGIN:VEVENT
                    UID:\(task.id)
                    DTSTAMP:\(formatDateICS(Date()))
                    DTSTART:\(formatDateICS(dueDate))
                    DTEND:\(formatDateICS(dueDate))
                    SUMMARY:\(task.title) [\(project.name)]
                    DESCRIPTION:Description: \(task.description)\\nHeures estimées: \(task.estimatedHours ?? 0)\\nHeures travaillées: \(task.workedHours)\\nStatut: \(task.isCompleted ? "Terminée" : "En cours")
                    CATEGORIES:TÂCHE
                    STATUS:\(task.isCompleted ? "COMPLETED" : "NEEDS-ACTION")
                    PRIORITY:\(task.priority.rawValue)
                    END:VEVENT
                    """
                }
            }
            
            // Ajouter les jalons (milestones) comme événements
            for milestone in project.milestones {
                icsContent += """
                
                BEGIN:VEVENT
                UID:\(milestone.id)
                DTSTAMP:\(formatDateICS(Date()))
                DTSTART:\(formatDateICS(milestone.date))
                DTEND:\(formatDateICS(milestone.date))
                SUMMARY:Jalon: \(milestone.title) [\(project.name)]
                DESCRIPTION:Description: \(milestone.description)\\nStatut: \(milestone.isCompleted ? "Terminé" : "En attente")
                CATEGORIES:JALON
                STATUS:\(milestone.isCompleted ? "COMPLETED" : "CONFIRMED")
                END:VEVENT
                """
            }
        }
        
        icsContent += "\nEND:VCALENDAR"
        return saveToFile(icsContent, type: .projects, fileExtension: "ics")
    }
    
    // Export vers PDF
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func exportToPDF(_ type: ExportType, contacts: [Contact] = [], projects: [Project] = [], tasks: [ProjectTask] = [], invoices: [Invoice] = []) -> URL? {
        // Vérifier si les données sont vides selon le type
        switch type {
        case .contacts:
            if contacts.isEmpty {
                print("Aucun contact à exporter en PDF")
                return nil
            }
        case .projects:
            if projects.isEmpty {
                print("Aucun projet à exporter en PDF")
                return nil
            }
        case .tasks:
            if tasks.isEmpty {
                print("Aucune tâche à exporter en PDF")
                return nil
            }
        case .invoices:
            if invoices.isEmpty {
                print("Aucune facture à exporter en PDF")
                return nil
            }
        }
        
        // Créer un nouveau document PDF
        let pdfDocument = PDFDocument()
        
        // Dimensions pour page A4
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 50
        
        // Fonction pour créer une page avec du contenu
        func createPage(withContent content: String, title: String, isCoverPage: Bool = false) -> PDFPage {
            // Utiliser UIGraphicsImageRenderer pour créer l'image de la page
            let renderer = UIGraphicsImageRenderer(bounds: pageRect)
            let image = renderer.image { context in
                let ctx = context.cgContext
                
                // Fond blanc
                UIColor.white.set()
                ctx.fill(pageRect)
                
                // Couleurs sobres et professionnelles
                let darkGray = UIColor(white: 0.3, alpha: 1.0)
                let mediumGray = UIColor(white: 0.5, alpha: 1.0)
                let lightGray = UIColor(white: 0.9, alpha: 1.0)
                
                // Dessiner un en-tête discret
                ctx.setStrokeColor(lightGray.cgColor)
                ctx.setLineWidth(1.0)
                ctx.move(to: CGPoint(x: margin, y: 60))
                ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: 60))
                ctx.strokePath()
                
                // Logo ou nom de l'application dans l'en-tête
                let logoText = "IndyCRM"
                let logoFont = UIFont.systemFont(ofSize: 16, weight: .medium)
                let logoAttributes: [NSAttributedString.Key: Any] = [
                    .font: logoFont,
                    .foregroundColor: darkGray
                ]
                let logoString = NSAttributedString(string: logoText, attributes: logoAttributes)
                logoString.draw(at: CGPoint(x: margin, y: 25))
                
                // Date d'export dans l'en-tête
                let dateText = "Export du \(formatDate(Date()))"
                let dateFont = UIFont.systemFont(ofSize: 9, weight: .regular)
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: dateFont,
                    .foregroundColor: mediumGray
                ]
                let dateString = NSAttributedString(string: dateText, attributes: dateAttributes)
                let dateWidth = dateString.size().width
                dateString.draw(at: CGPoint(x: pageRect.width - margin - dateWidth, y: 30))
                
                // Dessiner un pied de page discret
                ctx.setStrokeColor(lightGray.cgColor)
                ctx.setLineWidth(1.0)
                ctx.move(to: CGPoint(x: margin, y: pageRect.height - 40))
                ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: pageRect.height - 40))
                ctx.strokePath()
                
                // Texte du pied de page
                let footerText = "Page \(pdfDocument.pageCount + 1)"
                let footerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: footerFont,
                    .foregroundColor: mediumGray
                ]
                let footerString = NSAttributedString(string: footerText, attributes: footerAttributes)
                let footerWidth = footerString.size().width
                footerString.draw(at: CGPoint(x: (pageRect.width - footerWidth) / 2, y: pageRect.height - 25))
                
                // Configuration différente pour la page de couverture
                if isCoverPage {
                    // Grand titre
                    let coverTitleFont = UIFont.systemFont(ofSize: 26, weight: .semibold)
                    let coverTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: coverTitleFont,
                        .foregroundColor: darkGray
                    ]
                    let coverTitleString = NSAttributedString(string: title, attributes: coverTitleAttributes)
                    let coverTitleSize = coverTitleString.size()
                    coverTitleString.draw(at: CGPoint(x: (pageRect.width - coverTitleSize.width) / 2, y: 200))
                    
                    // Ligne séparatrice élégante sous le titre
                    ctx.setStrokeColor(mediumGray.cgColor)
                    ctx.setLineWidth(0.5)
                    ctx.move(to: CGPoint(x: pageRect.width / 3, y: 250))
                    ctx.addLine(to: CGPoint(x: pageRect.width * 2/3, y: 250))
                    ctx.strokePath()
                    
                    // Cadre d'information principal - bordure fine au lieu d'un fond coloré
                    let infoRect = CGRect(x: margin + 70, y: 300, width: pageRect.width - (margin + 70) * 2, height: 170)
                    ctx.setStrokeColor(lightGray.cgColor)
                    ctx.setLineWidth(0.5)
                    let cornerRadius: CGFloat = 4
                    let bezierPath = UIBezierPath(roundedRect: infoRect, cornerRadius: cornerRadius)
                    ctx.addPath(bezierPath.cgPath)
                    ctx.strokePath()
                    
                    // Contenu de la page de couverture
                    let contentFont = UIFont.systemFont(ofSize: 12)
                    let contentAttributes: [NSAttributedString.Key: Any] = [
                        .font: contentFont,
                        .foregroundColor: darkGray
                    ]
                    let contentString = NSAttributedString(string: content, attributes: contentAttributes)
                    contentString.draw(in: CGRect(x: infoRect.minX + 20, y: infoRect.minY + 20, 
                                                 width: infoRect.width - 40, height: infoRect.height - 40))
                    
                    // Logo discret en bas de page
                    let bottomLogoText = "DOCUMENT CONFIDENTIEL"
                    let bottomLogoFont = UIFont.systemFont(ofSize: 8, weight: .regular)
                    let bottomLogoAttributes: [NSAttributedString.Key: Any] = [
                        .font: bottomLogoFont,
                        .foregroundColor: UIColor(white: 0.7, alpha: 1.0)
                    ]
                    let bottomLogoString = NSAttributedString(string: bottomLogoText, attributes: bottomLogoAttributes)
                    let bottomLogoWidth = bottomLogoString.size().width
                    bottomLogoString.draw(at: CGPoint(x: (pageRect.width - bottomLogoWidth) / 2, y: pageRect.height - 60))
                } else {
                    // Sous-titre de la page discret
                    let titleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
                    let titleAttributes: [NSAttributedString.Key: Any] = [
                        .font: titleFont,
                        .foregroundColor: darkGray
                    ]
                    let titleString = NSAttributedString(string: title, attributes: titleAttributes)
                    titleString.draw(at: CGPoint(x: margin, y: 90))
                    
                    // Ligne séparatrice fine sous le titre
                    ctx.setStrokeColor(lightGray.cgColor)
                    ctx.setLineWidth(0.5)
                    ctx.move(to: CGPoint(x: margin, y: 115))
                    ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: 115))
                    ctx.strokePath()
                    
                    // Contenu principal
                    let contentRect = CGRect(x: margin + 10, y: 135, 
                                           width: pageRect.width - (margin + 10) * 2, 
                                           height: pageRect.height - 135 - 50)
                    
                    // Dessiner le contenu avec un style sobre
                    drawMinimalistContent(content, in: contentRect, ctx: ctx)
                }
            }
            
            // Créer la page PDF à partir de l'image
            return PDFPage(image: image)!
        }
        
        // Fonction pour dessiner du contenu avec un style minimaliste
        func drawMinimalistContent(_ content: String, in rect: CGRect, ctx: CGContext) {
            // Police et couleurs sobres pour le contenu
            let labelFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let valueFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let labelColor = UIColor(white: 0.3, alpha: 1.0)
            let valueColor = UIColor(white: 0.2, alpha: 1.0)
            let bulletColor = UIColor(white: 0.5, alpha: 1.0)
            
            // Parsons le contenu et formatons-le
            let lines = content.components(separatedBy: "\n")
            var yOffset: CGFloat = rect.minY
            let lineHeight: CGFloat = 18
            
            for line in lines {
                if line.isEmpty {
                    yOffset += lineHeight / 2
                    continue
                }
                
                if line.hasPrefix("-") {
                    // Élément de liste avec puce élégante
                    let bulletAttributes: [NSAttributedString.Key: Any] = [
                        .font: valueFont,
                        .foregroundColor: bulletColor
                    ]
                    let bulletString = NSAttributedString(string: "—", attributes: bulletAttributes)
                    bulletString.draw(at: CGPoint(x: rect.minX + 5, y: yOffset))
                    
                    let itemText = line.dropFirst()
                    let itemAttributes: [NSAttributedString.Key: Any] = [
                        .font: valueFont,
                        .foregroundColor: valueColor
                    ]
                    let itemString = NSAttributedString(string: String(itemText), attributes: itemAttributes)
                    itemString.draw(at: CGPoint(x: rect.minX + 20, y: yOffset))
                } else if line.contains(":") {
                    // Ligne clé-valeur avec style épuré
                    let components = line.components(separatedBy: ":")
                    if components.count >= 2 {
                        let label = components[0]
                        let value = components[1...].joined(separator: ":")
                        
                        let labelAttributes: [NSAttributedString.Key: Any] = [
                            .font: labelFont,
                            .foregroundColor: labelColor
                        ]
                        let labelString = NSAttributedString(string: label, attributes: labelAttributes)
                        labelString.draw(at: CGPoint(x: rect.minX, y: yOffset))
                        
                        let labelWidth = rect.width * 0.35  // Largeur fixe pour l'alignement
                        let valueAttributes: [NSAttributedString.Key: Any] = [
                            .font: valueFont,
                            .foregroundColor: valueColor
                        ]
                        let valueString = NSAttributedString(string: value, attributes: valueAttributes)
                        valueString.draw(at: CGPoint(x: rect.minX + labelWidth, y: yOffset))
                    }
                } else {
                    // Texte normal
                    let textAttributes: [NSAttributedString.Key: Any] = [
                        .font: valueFont,
                        .foregroundColor: valueColor
                    ]
                    let textString = NSAttributedString(string: line, attributes: textAttributes)
                    textString.draw(at: CGPoint(x: rect.minX, y: yOffset))
                }
                
                yOffset += lineHeight
            }
        }
        
        // Génération du contenu selon le type
        var allContent: [(title: String, content: String)] = []
        
        switch type {
        case .contacts:
            for (index, contact) in contacts.enumerated() {
                let title = "Contact \(index + 1): \(contact.firstName) \(contact.lastName)"
                let content = """
                Prénom: \(contact.firstName)
                Nom: \(contact.lastName)
                Email: \(contact.email)
                Téléphone: \(contact.phone)
                Type: \(contact.type.rawValue)
                Statut: \(contact.employmentStatus.rawValue)
                Organisation: \(contact.organization)
                Notes: \(contact.notes)
                """
                allContent.append((title: title, content: content))
            }
            
        case .projects:
            for (index, project) in projects.enumerated() {
                let title = "Projet \(index + 1): \(project.name)"
                let content = """
                Nom: \(project.name)
                Date début: \(formatDateISO8601(project.startDate))
                Date fin: \(project.deadline.map(formatDateISO8601) ?? "Non définie")
                Statut: \(project.status.rawValue)
                Notes: \(project.notes)
                """
                allContent.append((title: title, content: content))
            }
            
        case .tasks:
            for (index, task) in tasks.enumerated() {
                let title = "Tâche \(index + 1): \(task.title)"
                let content = """
                Titre: \(task.title)
                Description: \(task.description)
                Complété: \(task.isCompleted ? "Oui" : "Non")
                Date limite: \(task.dueDate.map(formatDateISO8601) ?? "Non définie")
                Heures estimées: \(String(format: "%.1f", task.estimatedHours ?? 0.0))
                Heures travaillées: \(String(format: "%.1f", task.workedHours))
                """
                allContent.append((title: title, content: content))
            }
            
        case .invoices:
            for (index, invoice) in invoices.enumerated() {
                let title = "Facture \(index + 1): \(invoice.number)"
                let itemsList = invoice.items.map {
                    "- \($0.description) (Qté: \($0.quantity), Prix: \($0.unitPrice)€)"
                }.joined(separator: "\n")
                
                let content = """
                Numéro: \(invoice.number)
                Date: \(formatDateISO8601(invoice.date))
                Date d'échéance: \(formatDateISO8601(invoice.dueDate))
                Montant: \(invoice.total.formatted(.currency(code: "EUR")))
                Statut: \(invoice.status.rawValue)
                Notes: \(invoice.notes)
                
                Articles:
                \(itemsList)
                """
                allContent.append((title: title, content: content))
            }
        }
        
        // Ajouter chaque page au document
        for (title, content) in allContent {
            let page = createPage(withContent: content, title: title)
            pdfDocument.insert(page, at: pdfDocument.pageCount)
        }
        
        // Ajouter une page de couverture
        let coverTitle = "Export \(type.rawValue.capitalized)"
        let coverContent = """
        Date d'export: \(formatDate(Date()))
        Nombre d'éléments: \(allContent.count)
        Type d'export: \(type.rawValue.capitalized)
        Format: PDF
        
        Ce document a été généré automatiquement par IndyCRM.
        Tous les éléments présentés dans ce document sont strictement confidentiels.
        """
        let coverPage = createPage(withContent: coverContent, title: coverTitle, isCoverPage: true)
        pdfDocument.insert(coverPage, at: 0)
        
        // Enregistrer le document PDF
        let tempDir = fileManager.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("exports", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            // Générer le nom du fichier avec la date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            
            let fileName = "export_\(type.rawValue)_\(timestamp).pdf"
            let fileURL = exportDir.appendingPathComponent(fileName)
            
            // Écrire le fichier PDF
            if pdfDocument.write(to: fileURL) {
                print("Export PDF réussi: \(fileURL.path)")
                return fileURL
            } else {
                print("Erreur lors de l'écriture du PDF")
                return nil
            }
        } catch {
            print("Erreur d'export PDF pour \(type.rawValue): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Export vers vCard
    private func escapeVCard(_ value: String) -> String {
        if value.isEmpty {
            return ""
        }
        
        // Échapper les caractères spéciaux selon la spec vCard
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        // Pour les caractères non-ASCII, on peut simplement utiliser UTF-8
        // La spec vCard 3.0 supporte UTF-8 nativement
        return escaped
    }
    
    func exportToVCard(contacts: [Contact]) -> URL? {
        let tempDir = fileManager.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("exports", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "contacts_\(timestamp).vcf"
            let fileURL = exportDir.appendingPathComponent(fileName)
            
            var vCardContent = ""
            
            for contact in contacts {
                vCardContent += """
                BEGIN:VCARD
                VERSION:3.0
                N:\(escapeVCard(contact.lastName));\(escapeVCard(contact.firstName));;;
                FN:\(escapeVCard(contact.firstName)) \(escapeVCard(contact.lastName))
                EMAIL;type=INTERNET;type=pref:\(escapeVCard(contact.email))
                TEL;type=CELL:\(escapeVCard(contact.phone))
                ORG:\(escapeVCard(contact.organization))
                TITLE:\(escapeVCard(contact.type.rawValue))
                ROLE:\(escapeVCard(contact.employmentStatus.rawValue))
                NOTE:\(escapeVCard(contact.notes))
                END:VCARD
                
                """
            }
            
            try vCardContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
            
        } catch {
            print("Erreur d'export vCard: \(error)")
            return nil
        }
    }
    
    // Fonctions utilitaires
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateICS(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    private func formatDateISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
    
    private func formatDateExcel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    private func saveToFile(_ content: String, type: ExportType, fileExtension: String) -> URL? {
        let tempDir = fileManager.temporaryDirectory
        let filename = "\(type.filename)_\(formatDateISO8601(Date())).\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Export \(fileExtension.uppercased()) réussi: \(fileURL.path)")
            return fileURL
        } catch {
            print("Erreur d'export \(fileExtension.uppercased()): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createExportDirectory() -> URL? {
        let tempDir = fileManager.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("exports", isDirectory: true)
        
        do {
            // Créer le répertoire si nécessaire
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: exportDir.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Le répertoire existe déjà
                    return exportDir
                } else {
                    // Un fichier existe avec ce nom, supprimer et recréer
                    try fileManager.removeItem(at: exportDir)
                }
            }
            
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true, attributes: nil)
            return exportDir
        } catch {
            print("Erreur de création du répertoire d'export: \(error)")
            return nil
        }
    }
} 
