import Foundation
import CoreData

class InvoiceDatabase {
    static let shared = InvoiceDatabase()
    private let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "IndyCRM")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Erreur lors du chargement de la base de données: \(error)")
            }
        }
    }
    
    // MARK: - Core Data Model
    
    @objc(StoredInvoice)
    public class StoredInvoice: NSManagedObject {
        @NSManaged public var invoiceNumber: String
        @NSManaged public var dateIssued: Date
        @NSManaged public var dueDate: Date
        @NSManaged public var clientName: String
        @NSManaged public var clientAddress: String
        @NSManaged public var total: Double
        @NSManaged public var taxAmount: Double
        @NSManaged public var pdfData: Data?
        @NSManaged public var csvData: Data?
        @NSManaged public var status: String
        @NSManaged public var items: NSSet
    }
    
    @objc(StoredInvoiceItem)
    public class StoredInvoiceItem: NSManagedObject {
        @NSManaged public var description: String
        @NSManaged public var quantity: Int32
        @NSManaged public var unitPrice: Double
        @NSManaged public var vatRate: Double
        @NSManaged public var invoice: StoredInvoice
    }
    
    // MARK: - CRUD Operations
    
    func saveInvoice(_ invoice: Invoice, pdfData: Data?, csvData: Data?) throws {
        let context = container.viewContext
        
        let storedInvoice = StoredInvoice(context: context)
        storedInvoice.invoiceNumber = invoice.invoiceNumber
        storedInvoice.dateIssued = invoice.dateIssued
        storedInvoice.dueDate = invoice.dueDate
        storedInvoice.clientName = invoice.clientName
        storedInvoice.clientAddress = invoice.clientAddress
        storedInvoice.total = invoice.total
        storedInvoice.taxAmount = invoice.taxAmount
        storedInvoice.pdfData = pdfData
        storedInvoice.csvData = csvData
        storedInvoice.status = "émise"
        
        // Sauvegarder les articles
        for item in invoice.items {
            let storedItem = StoredInvoiceItem(context: context)
            storedItem.description = item.description
            storedItem.quantity = Int32(item.quantity)
            storedItem.unitPrice = item.unitPrice
            storedItem.vatRate = item.vatRate
            storedItem.invoice = storedInvoice
        }
        
        try context.save()
    }
    
    func fetchInvoices() throws -> [StoredInvoice] {
        let context = container.viewContext
        let request: NSFetchRequest<StoredInvoice> = StoredInvoice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateIssued", ascending: false)]
        
        return try context.fetch(request)
    }
    
    func fetchInvoice(withNumber number: String) throws -> StoredInvoice? {
        let context = container.viewContext
        let request: NSFetchRequest<StoredInvoice> = StoredInvoice.fetchRequest()
        request.predicate = NSPredicate(format: "invoiceNumber == %@", number)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    func updateInvoiceStatus(_ invoice: StoredInvoice, newStatus: String) throws {
        let context = container.viewContext
        invoice.status = newStatus
        try context.save()
    }
    
    func deleteInvoice(_ invoice: StoredInvoice) throws {
        let context = container.viewContext
        context.delete(invoice)
        try context.save()
    }
    
    // MARK: - Statistiques
    
    func getInvoiceStatistics() throws -> InvoiceStatistics {
        let context = container.viewContext
        let request: NSFetchRequest<StoredInvoice> = StoredInvoice.fetchRequest()
        
        let invoices = try context.fetch(request)
        
        let totalAmount = invoices.reduce(0) { $0 + $1.total }
        let totalTax = invoices.reduce(0) { $0 + $1.taxAmount }
        let averageAmount = invoices.isEmpty ? 0 : totalAmount / Double(invoices.count)
        
        return InvoiceStatistics(
            totalInvoices: invoices.count,
            totalAmount: totalAmount,
            totalTax: totalTax,
            averageAmount: averageAmount
        )
    }
}

// MARK: - Modèles de statistiques

struct InvoiceStatistics {
    let totalInvoices: Int
    let totalAmount: Double
    let totalTax: Double
    let averageAmount: Double
} 