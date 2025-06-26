import Foundation

class InvoiceNumberManager {
    private static let userDefaults = UserDefaults.standard
    private static let lastInvoiceNumberKey = "lastInvoiceNumber"
    private static let invoicePrefix = "INDY-"
    private static let yearFormat = "yyyy"
    
    static func generateNextInvoiceNumber() -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearPrefix = "\(currentYear)-"
        
        // Récupérer le dernier numéro de facture
        let lastNumber = userDefaults.integer(forKey: lastInvoiceNumberKey)
        let nextNumber = lastNumber + 1
        
        // Sauvegarder le nouveau numéro
        userDefaults.set(nextNumber, forKey: lastInvoiceNumberKey)
        
        // Format: INDY-2024-0001
        let numberString = String(format: "%04d", nextNumber)
        return "\(invoicePrefix)\(yearPrefix)\(numberString)"
    }
    
    static func resetNumberingForNewYear() {
        userDefaults.set(0, forKey: lastInvoiceNumberKey)
    }
    
    static func getCurrentSequence() -> Int {
        return userDefaults.integer(forKey: lastInvoiceNumberKey)
    }
    
    // Vérifier si nous devons réinitialiser la numérotation pour la nouvelle année
    static func checkAndResetForNewYear() {
        let lastResetDateKey = "lastInvoiceNumberResetDate"
        let currentDate = Date()
        
        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            let lastResetYear = Calendar.current.component(.year, from: lastResetDate)
            let currentYear = Calendar.current.component(.year, from: currentDate)
            
            if currentYear > lastResetYear {
                resetNumberingForNewYear()
                userDefaults.set(currentDate, forKey: lastResetDateKey)
            }
        } else {
            userDefaults.set(currentDate, forKey: lastResetDateKey)
        }
    }
} 