import Foundation
import PDFKit
import XLSXWriter

class ExportService: ObservableObject {
    enum ExportType: String {
        case contacts
        case projects
        case tasks
        case invoices
    }
    
    enum ExportFormat: String {
        case csv
        case excel
        case pdf
        case vcard
        case ical
    }
    
    private func createExportDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let exportPath = documentsPath.appendingPathComponent("Exports", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: exportPath, withIntermediateDirectories: true)
            return exportPath
        } catch {
            print("Erreur création dossier export: \(error)")
            return nil
        }
    }
    
    private func escapeCSV(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
    
    private func escapeVCard(_ value: String) -> String {
        var escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        if !escaped.canBeConverted(to: .ascii) {
            escaped = ";CHARSET=UTF-8:" + escaped
        }
        
        return escaped
    }
    
    func exportToCSV(_ type: ExportType, contacts: [Contact]? = nil, projects: [Project]? = nil, tasks: [ProjectTask]? = nil, invoices: [Invoice]? = nil) -> URL? {
        guard let exportDir = createExportDirectory() else { return nil }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "\(type.rawValue)_\(timestamp).csv"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        var csvContent = ""
        let bom = "\u{FEFF}" // UTF-8 BOM for Excel compatibility
        
        switch type {
        case .contacts:
            guard let contacts = contacts else { return nil }
            let headers = ["ID", "Prénom", "Nom", "Email", "Téléphone", "Type", "Statut", "Organisation", "Notes"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            
            for contact in contacts {
                let row = [
                    contact.id.uuidString,
                    contact.firstName,
                    contact.lastName,
                    contact.email ?? "",
                    contact.phone ?? "",
                    contact.type.rawValue,
                    contact.status.rawValue,
                    contact.organization ?? "",
                    contact.notes ?? ""
                ].map { escapeCSV($0) }.joined(separator: ",")
                csvContent += row + "\n"
            }
            
        case .projects:
            guard let projects = projects else { return nil }
            let headers = ["ID", "Nom", "Date début", "Date fin", "Statut", "Notes"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            
            for project in projects {
                let row = [
                    project.id.uuidString,
                    project.name,
                    DateFormatter.localizedString(from: project.startDate, dateStyle: .short, timeStyle: .none),
                    project.endDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "",
                    project.status.rawValue,
                    project.notes ?? ""
                ].map { escapeCSV($0) }.joined(separator: ",")
                csvContent += row + "\n"
            }
            
        case .tasks:
            guard let tasks = tasks else { return nil }
            let headers = ["ID", "Titre", "Description", "Complété", "Date limite", "Heures estimées", "Heures travaillées"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            
            for task in tasks {
                let row = [
                    task.id.uuidString,
                    task.title,
                    task.description ?? "",
                    task.isCompleted ? "Oui" : "Non",
                    task.dueDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "",
                    String(format: "%.1f", task.estimatedHours),
                    String(format: "%.1f", task.workedHours)
                ].map { escapeCSV($0) }.joined(separator: ",")
                csvContent += row + "\n"
            }
            
        case .invoices:
            guard let invoices = invoices else { return nil }
            let headers = ["Numéro", "Date", "Date d'échéance", "Montant", "Statut", "Notes"]
            csvContent = bom + headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            
            for invoice in invoices {
                let row = [
                    invoice.number,
                    DateFormatter.localizedString(from: invoice.date, dateStyle: .short, timeStyle: .none),
                    DateFormatter.localizedString(from: invoice.dueDate, dateStyle: .short, timeStyle: .none),
                    String(format: "%.2f €", invoice.amount),
                    invoice.status.rawValue,
                    invoice.notes ?? ""
                ].map { escapeCSV($0) }.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Erreur export CSV: \(error)")
            return nil
        }
    }
    
    func exportToExcel(_ type: ExportType, contacts: [Contact]? = nil, projects: [Project]? = nil, tasks: [ProjectTask]? = nil, invoices: [Invoice]? = nil) -> URL? {
        guard let exportDir = createExportDirectory() else { return nil }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "\(type.rawValue)_\(timestamp).xlsx"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        let workbook = XLSXWriter()
        
        // Styles
        let headerStyle = workbook.addFormat()
        headerStyle.bold = true
        headerStyle.backgroundColor = .gray
        headerStyle.fontColor = .white
        
        let dateStyle = workbook.addFormat()
        dateStyle.dateFormat = "dd/mm/yyyy"
        
        let currencyStyle = workbook.addFormat()
        currencyStyle.numberFormat = "#,##0.00 €"
        
        switch type {
        case .contacts:
            guard let contacts = contacts else { return nil }
            let worksheet = workbook.addWorksheet("Contacts")
            
            // Headers
            let headers = ["ID", "Prénom", "Nom", "Email", "Téléphone", "Type", "Statut", "Organisation", "Notes"]
            worksheet.write(row: 0, headers: headers, format: headerStyle)
            
            // Data
            for (index, contact) in contacts.enumerated() {
                let row = [
                    contact.id.uuidString,
                    contact.firstName,
                    contact.lastName,
                    contact.email ?? "",
                    contact.phone ?? "",
                    contact.type.rawValue,
                    contact.status.rawValue,
                    contact.organization ?? "",
                    contact.notes ?? ""
                ]
                worksheet.write(row: index + 1, values: row)
            }
            
            worksheet.autofit()
            
        case .projects:
            guard let projects = projects else { return nil }
            let worksheet = workbook.addWorksheet("Projets")
            
            // Headers
            let headers = ["ID", "Nom", "Date début", "Date fin", "Statut", "Notes"]
            worksheet.write(row: 0, headers: headers, format: headerStyle)
            
            // Data
            for (index, project) in projects.enumerated() {
                worksheet.write(row: index + 1, values: [
                    project.id.uuidString,
                    project.name,
                    project.startDate,
                    project.endDate as Any,
                    project.status.rawValue,
                    project.notes ?? ""
                ], formats: [nil, nil, dateStyle, dateStyle])
            }
            
            worksheet.autofit()
            
        case .tasks:
            guard let tasks = tasks else { return nil }
            let worksheet = workbook.addWorksheet("Tâches")
            
            // Headers
            let headers = ["ID", "Titre", "Description", "Complété", "Date limite", "Heures estimées", "Heures travaillées"]
            worksheet.write(row: 0, headers: headers, format: headerStyle)
            
            // Data
            for (index, task) in tasks.enumerated() {
                worksheet.write(row: index + 1, values: [
                    task.id.uuidString,
                    task.title,
                    task.description ?? "",
                    task.isCompleted ? "Oui" : "Non",
                    task.dueDate as Any,
                    task.estimatedHours,
                    task.workedHours
                ], formats: [nil, nil, nil, nil, dateStyle])
            }
            
            worksheet.autofit()
            
        case .invoices:
            guard let invoices = invoices else { return nil }
            let worksheet = workbook.addWorksheet("Factures")
            
            // Headers
            let headers = ["Numéro", "Date", "Date d'échéance", "Montant", "Statut", "Notes"]
            worksheet.write(row: 0, headers: headers, format: headerStyle)
            
            // Data
            for (index, invoice) in invoices.enumerated() {
                worksheet.write(row: index + 1, values: [
                    invoice.number,
                    invoice.date,
                    invoice.dueDate,
                    invoice.amount,
                    invoice.status.rawValue,
                    invoice.notes ?? ""
                ], formats: [nil, dateStyle, dateStyle, currencyStyle])
            }
            
            worksheet.autofit()
        }
        
        do {
            try workbook.save(to: fileURL)
            return fileURL
        } catch {
            print("Erreur export Excel: \(error)")
            return nil
        }
    }
    
    func exportToPDF(_ type: ExportType, contacts: [Contact]? = nil, projects: [Project]? = nil, tasks: [ProjectTask]? = nil, invoices: [Invoice]? = nil) -> URL? {
        guard let exportDir = createExportDirectory() else { return nil }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "\(type.rawValue)_\(timestamp).pdf"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        // Création du document PDF
        let pdfMetaData = [
            kCGPDFContextCreator: "IndyCRM",
            kCGPDFContextAuthor: "Exporté par IndyCRM",
            kCGPDFContextTitle: "Export \(type.rawValue)"
        ]
        
        guard let pdfContext = CGContext(fileURL as CFURL, mediaBox: nil, pdfMetaData as CFDictionary) else {
            return nil
        }
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let bodyFont = UIFont.systemFont(ofSize: 11)
        
        // Fonction helper pour dessiner du texte
        func drawText(_ text: String, rect: CGRect, font: UIFont, alignment: NSTextAlignment = .left) {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(in: rect, withAttributes: attributes)
        }
        
        // Début de la page
        pdfContext.beginPage(mediaBox: pageRect)
        
        let title: String
        var currentY: CGFloat = 50
        
        switch type {
        case .contacts:
            guard let contacts = contacts else { return nil }
            title = "Liste des Contacts"
            drawText(title, rect: CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 30), font: titleFont, alignment: .center)
            currentY += 50
            
            // En-têtes
            let headers = ["Nom", "Email", "Téléphone", "Type", "Organisation"]
            var x: CGFloat = 50
            for header in headers {
                drawText(header, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: headerFont)
                x += 110
            }
            currentY += 30
            
            // Données
            for contact in contacts {
                if currentY > pageRect.height - 100 {
                    pdfContext.endPage()
                    pdfContext.beginPage(mediaBox: pageRect)
                    currentY = 50
                }
                
                x = 50
                let fullName = "\(contact.firstName) \(contact.lastName)"
                drawText(fullName, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(contact.email ?? "-", rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(contact.phone ?? "-", rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(contact.type.rawValue, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(contact.organization ?? "-", rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                
                currentY += 25
            }
            
        case .projects:
            guard let projects = projects else { return nil }
            title = "Liste des Projets"
            drawText(title, rect: CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 30), font: titleFont, alignment: .center)
            currentY += 50
            
            // En-têtes
            let headers = ["Nom", "Date début", "Date fin", "Statut"]
            var x: CGFloat = 50
            for header in headers {
                drawText(header, rect: CGRect(x: x, y: currentY, width: 120, height: 20), font: headerFont)
                x += 130
            }
            currentY += 30
            
            // Données
            for project in projects {
                if currentY > pageRect.height - 100 {
                    pdfContext.endPage()
                    pdfContext.beginPage(mediaBox: pageRect)
                    currentY = 50
                }
                
                x = 50
                drawText(project.name, rect: CGRect(x: x, y: currentY, width: 120, height: 20), font: bodyFont)
                x += 130
                
                let startDate = DateFormatter.localizedString(from: project.startDate, dateStyle: .short, timeStyle: .none)
                drawText(startDate, rect: CGRect(x: x, y: currentY, width: 120, height: 20), font: bodyFont)
                x += 130
                
                let endDate = project.endDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "-"
                drawText(endDate, rect: CGRect(x: x, y: currentY, width: 120, height: 20), font: bodyFont)
                x += 130
                
                drawText(project.status.rawValue, rect: CGRect(x: x, y: currentY, width: 120, height: 20), font: bodyFont)
                
                currentY += 25
            }
            
        case .tasks:
            guard let tasks = tasks else { return nil }
            title = "Liste des Tâches"
            drawText(title, rect: CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 30), font: titleFont, alignment: .center)
            currentY += 50
            
            // En-têtes
            let headers = ["Titre", "Description", "Date limite", "Heures est.", "Complété"]
            var x: CGFloat = 50
            for header in headers {
                drawText(header, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: headerFont)
                x += 110
            }
            currentY += 30
            
            // Données
            for task in tasks {
                if currentY > pageRect.height - 100 {
                    pdfContext.endPage()
                    pdfContext.beginPage(mediaBox: pageRect)
                    currentY = 50
                }
                
                x = 50
                drawText(task.title, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(task.description ?? "-", rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                let dueDate = task.dueDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "-"
                drawText(dueDate, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(String(format: "%.1f h", task.estimatedHours), rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(task.isCompleted ? "Oui" : "Non", rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                
                currentY += 25
            }
            
        case .invoices:
            guard let invoices = invoices else { return nil }
            title = "Liste des Factures"
            drawText(title, rect: CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 30), font: titleFont, alignment: .center)
            currentY += 50
            
            // En-têtes
            let headers = ["Numéro", "Date", "Échéance", "Montant", "Statut"]
            var x: CGFloat = 50
            for header in headers {
                drawText(header, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: headerFont)
                x += 110
            }
            currentY += 30
            
            // Données
            for invoice in invoices {
                if currentY > pageRect.height - 100 {
                    pdfContext.endPage()
                    pdfContext.beginPage(mediaBox: pageRect)
                    currentY = 50
                }
                
                x = 50
                drawText(invoice.number, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                let date = DateFormatter.localizedString(from: invoice.date, dateStyle: .short, timeStyle: .none)
                drawText(date, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                let dueDate = DateFormatter.localizedString(from: invoice.dueDate, dateStyle: .short, timeStyle: .none)
                drawText(dueDate, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(String(format: "%.2f €", invoice.amount), rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                x += 110
                
                drawText(invoice.status.rawValue, rect: CGRect(x: x, y: currentY, width: 100, height: 20), font: bodyFont)
                
                currentY += 25
            }
        }
        
        // Pied de page
        let footerText = "Exporté le \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))"
        drawText(footerText, rect: CGRect(x: 50, y: pageRect.height - 50, width: pageRect.width - 100, height: 20), font: bodyFont, alignment: .center)
        
        pdfContext.endPage()
        pdfContext.closePDF()
        
        return fileURL
    }
    
    func exportToVCard(contacts: [Contact]) -> URL? {
        guard let exportDir = createExportDirectory() else { return nil }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "contacts_\(timestamp).vcf"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        var vCardContent = ""
        
        for contact in contacts {
            vCardContent += "BEGIN:VCARD\n"
            vCardContent += "VERSION:3.0\n"
            vCardContent += "N:\(escapeVCard(contact.lastName));\(escapeVCard(contact.firstName));;;\n"
            vCardContent += "FN:\(escapeVCard("\(contact.firstName) \(contact.lastName)"))\n"
            
            if let email = contact.email {
                vCardContent += "EMAIL;TYPE=INTERNET:\(escapeVCard(email))\n"
            }
            
            if let phone = contact.phone {
                vCardContent += "TEL;TYPE=CELL:\(escapeVCard(phone))\n"
            }
            
            if let org = contact.organization {
                vCardContent += "ORG:\(escapeVCard(org))\n"
            }
            
            vCardContent += "TITLE:\(escapeVCard(contact.type.rawValue))\n"
            
            if let notes = contact.notes {
                vCardContent += "NOTE:\(escapeVCard(notes))\n"
            }
            
            vCardContent += "END:VCARD\n"
        }
        
        do {
            try vCardContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Erreur export vCard: \(error)")
            return nil
        }
    }
    
    func exportToICalendar(projects: [Project]) -> URL? {
        guard let exportDir = createExportDirectory() else { return nil }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "projects_\(timestamp).ics"
        let fileURL = exportDir.appendingPathComponent(fileName)
        
        var iCalContent = "BEGIN:VCALENDAR\n"
        iCalContent += "VERSION:2.0\n"
        iCalContent += "PRODID:-//IndyCRM//FR\n"
        iCalContent += "CALSCALE:GREGORIAN\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        for project in projects {
            iCalContent += "BEGIN:VEVENT\n"
            iCalContent += "UID:\(project.id.uuidString)\n"
            iCalContent += "DTSTAMP:\(dateFormatter.string(from: Date()))\n"
            iCalContent += "DTSTART:\(dateFormatter.string(from: project.startDate))\n"
            
            if let endDate = project.endDate {
                iCalContent += "DTEND:\(dateFormatter.string(from: endDate))\n"
            }
            
            iCalContent += "SUMMARY:\(project.name)\n"
            
            if let notes = project.notes {
                iCalContent += "DESCRIPTION:\(notes.replacingOccurrences(of: "\n", with: "\\n"))\n"
            }
            
            iCalContent += "STATUS:\(project.status.rawValue.uppercased())\n"
            iCalContent += "END:VEVENT\n"
        }
        
        iCalContent += "END:VCALENDAR\n"
        
        do {
            try iCalContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Erreur export iCalendar: \(error)")
            return nil
        }
    }
}