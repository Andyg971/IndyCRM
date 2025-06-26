import CoreData

// Cette classe est utilisée pour générer le modèle Core Data
// Vous devrez créer un fichier .xcdatamodeld dans Xcode avec ces entités

/*
Entity: StoredInvoice
Attributes:
- invoiceNumber: String
- dateIssued: Date
- dueDate: Date
- clientName: String
- clientAddress: String
- total: Double
- taxAmount: Double
- pdfData: Binary Data (optional)
- csvData: Binary Data (optional)
- status: String
Relationships:
- items: StoredInvoiceItem (to-many)

Entity: StoredInvoiceItem
Attributes:
- description: String
- quantity: Integer 32
- unitPrice: Double
- vatRate: Double
Relationships:
- invoice: StoredInvoice (to-one)
*/

// Note: Ce fichier sert de documentation pour la structure de la base de données
// Vous devez créer le modèle de données dans Xcode : 
// File > New > File > Core Data > Data Model 