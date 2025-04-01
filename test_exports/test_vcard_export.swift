import Foundation
import Contacts

// Définition des types nécessaires
public enum ContactType: String, Codable, CaseIterable {
    case client
    case prospect
    case supplier
    case partner
}

public enum EmploymentStatus: String, CaseIterable, Codable {
    case freelance = "Freelance"
    case independent = "Indépendant"
    case permanent = "Salarié Permanent"
}

public struct Rate: Identifiable, Codable {
    public let id: UUID
    public let description: String
    public let amount: Double
    public let unit: RateUnit
    public let isDefault: Bool
    
    public init(id: UUID = UUID(), description: String, amount: Double, unit: RateUnit, isDefault: Bool = false) {
        self.id = id
        self.description = description
        self.amount = amount
        self.unit = unit
        self.isDefault = isDefault
    }
}

public enum RateUnit: String, Codable, CaseIterable {
    case hourly = "Par heure"
    case daily = "Par jour"
    case fixed = "Forfait"
}

public struct Contact: Identifiable, Codable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let email: String
    public let phone: String
    public let type: ContactType
    public let employmentStatus: EmploymentStatus
    public let notes: String
    public let rates: [Rate]
    public let organization: String
    
    public var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    public init(id: UUID = UUID(), firstName: String, lastName: String, email: String, phone: String, type: ContactType, employmentStatus: EmploymentStatus, notes: String, rates: [Rate], organization: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.type = type
        self.employmentStatus = employmentStatus
        self.notes = notes
        self.rates = rates
        self.organization = organization
    }
}

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
    
    func exportToVCard(contacts: [Contact]) -> URL? {
        let tempDir = fileManager.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("exports", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            // Générer le nom du fichier avec la date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "contacts_\(timestamp).vcf"
            let fileURL = exportDir.appendingPathComponent(fileName)
            
            // Créer le contenu vCard
            var vCardString = ""
            
            for contact in contacts {
                // Créer un CNMutableContact pour chaque contact
                let cnContact = CNMutableContact()
                
                // Nom et prénom
                cnContact.givenName = contact.firstName
                cnContact.familyName = contact.lastName
                
                // Email
                if !contact.email.isEmpty {
                    let emailAddress = CNLabeledValue(
                        label: CNLabelWork,
                        value: contact.email as NSString
                    )
                    cnContact.emailAddresses = [emailAddress]
                }
                
                // Téléphone
                if !contact.phone.isEmpty {
                    let phoneNumber = CNLabeledValue(
                        label: CNLabelPhoneNumberMain,
                        value: CNPhoneNumber(stringValue: contact.phone)
                    )
                    cnContact.phoneNumbers = [phoneNumber]
                }
                
                // Organisation
                if !contact.organization.isEmpty {
                    cnContact.organizationName = contact.organization
                }
                
                // Notes
                if !contact.notes.isEmpty {
                    cnContact.note = contact.notes
                }
                
                // Convertir en vCard
                do {
                    let vCardData = try CNContactVCardSerialization.data(with: [cnContact])
                    if let vCard = String(data: vCardData, encoding: .utf8) {
                        vCardString += vCard
                    }
                } catch {
                    print("Erreur de conversion en vCard pour \(contact.fullName): \(error)")
                }
            }
            
            // Écrire le fichier
            try vCardString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
            
        } catch {
            print("Erreur d'export vCard: \(error)")
            return nil
        }
    }
}

// Créer des contacts de test
let contacts = [
    Contact(
        firstName: "Jean",
        lastName: "Dupont",
        email: "jean.dupont@example.com",
        phone: "+33 6 12 34 56 78",
        type: .client,
        employmentStatus: .permanent,
        notes: "Client principal",
        rates: [],
        organization: "Dupont SA"
    ),
    Contact(
        firstName: "Marie",
        lastName: "Martin",
        email: "marie.martin@example.com",
        phone: "+33 6 98 76 54 32",
        type: .prospect,
        employmentStatus: .freelance,
        notes: "Prospect intéressé par nos services",
        rates: [],
        organization: "Martin Design"
    ),
    Contact(
        firstName: "Pierre",
        lastName: "Bernard",
        email: "p.bernard@example.com",
        phone: "+33 1 23 45 67 89",
        type: .supplier,
        employmentStatus: .independent,
        notes: "Fournisseur matériel informatique",
        rates: [],
        organization: "Tech Solutions"
    )
]

// Créer une instance de ExportService
let exportService = ExportService()

// Exporter les contacts
if let exportURL = await exportService.exportToVCard(contacts: contacts) {
    print("Export vCard réussi : \(exportURL.path)")
    
    // Lire le fichier exporté
    do {
        let vCardContent = try String(contentsOf: exportURL, encoding: .utf8)
        print("\nContenu du fichier vCard :")
        print(vCardContent)
        
        // Tester l'importation avec CNContactVCardSerialization
        let vCardData = try Data(contentsOf: exportURL)
        let importedContacts = try CNContactVCardSerialization.contacts(with: vCardData)
        
        print("\nNombre de contacts importés : \(importedContacts.count)")
        for contact in importedContacts {
            print("- \(contact.givenName) \(contact.familyName)")
        }
    } catch {
        print("Erreur lors de la lecture/validation du fichier : \(error)")
    }
} else {
    print("Erreur lors de l'export vCard")
} 