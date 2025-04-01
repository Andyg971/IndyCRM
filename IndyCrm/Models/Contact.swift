import Foundation

public enum EmploymentStatus: String, CaseIterable, Codable {
    case freelance = "Freelance"
    case independent = "Indépendant"
    case permanent = "Salarié Permanent"
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
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "fr_FR")
        
        let amount = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        switch unit {
        case .hourly: return "\(amount)/h"
        case .daily: return "\(amount)/j"
        case .fixed: return amount
        }
    }
}

public enum RateUnit: String, Codable, CaseIterable {
    case hourly = "Par heure"
    case daily = "Par jour"
    case fixed = "Forfait"
}

public enum ContactType: String, Codable, CaseIterable {
    case client
    case prospect
    case supplier
    case partner
} 