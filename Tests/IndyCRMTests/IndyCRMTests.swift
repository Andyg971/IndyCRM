import XCTest
@testable import IndyCRM

final class IndyCRMTests: XCTestCase {
    var dataController: DataController!
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        viewContext = dataController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        dataController = nil
        viewContext = nil
    }
    
    func testCreateClient() throws {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Test Client"
        client.email = "test@example.com"
        client.dateCreated = Date()
        
        XCTAssertNoThrow(try viewContext.save())
        
        let request = NSFetchRequest<Client>(entityName: "Client")
        let clients = try viewContext.fetch(request)
        
        XCTAssertEqual(clients.count, 1)
        XCTAssertEqual(clients.first?.name, "Test Client")
        XCTAssertEqual(clients.first?.email, "test@example.com")
    }
    
    func testCreateProject() throws {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Test Client"
        client.dateCreated = Date()
        
        let project = Project(context: viewContext)
        project.id = UUID()
        project.title = "Test Project"
        project.client = client
        project.dateCreated = Date()
        project.status = "En cours"
        
        XCTAssertNoThrow(try viewContext.save())
        
        let request = NSFetchRequest<Project>(entityName: "Project")
        let projects = try viewContext.fetch(request)
        
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects.first?.title, "Test Project")
        XCTAssertEqual(projects.first?.client?.name, "Test Client")
    }
    
    func testCreateInvoice() throws {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Test Client"
        client.dateCreated = Date()
        
        let invoice = Invoice(context: viewContext)
        invoice.id = UUID()
        invoice.invoiceNumber = "FACT-2024-001"
        invoice.client = client
        invoice.dateCreated = Date()
        invoice.dateDue = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        invoice.status = "En attente"
        invoice.totalAmount = 1500.0
        
        let item = InvoiceItem(context: viewContext)
        item.id = UUID()
        item.description = "Test Item"
        item.quantity = 1
        item.unitPrice = 1500.0
        item.amount = 1500.0
        item.invoice = invoice
        
        XCTAssertNoThrow(try viewContext.save())
        
        let request = NSFetchRequest<Invoice>(entityName: "Invoice")
        let invoices = try viewContext.fetch(request)
        
        XCTAssertEqual(invoices.count, 1)
        XCTAssertEqual(invoices.first?.invoiceNumber, "FACT-2024-001")
        XCTAssertEqual(invoices.first?.totalAmount, 1500.0)
        XCTAssertEqual(invoices.first?.items?.count, 1)
    }
    
    func testDeleteClient() throws {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Test Client"
        client.dateCreated = Date()
        
        try viewContext.save()
        
        viewContext.delete(client)
        try viewContext.save()
        
        let request = NSFetchRequest<Client>(entityName: "Client")
        let clients = try viewContext.fetch(request)
        
        XCTAssertEqual(clients.count, 0)
    }
    
    func testCascadeDeleteProject() throws {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "Test Client"
        client.dateCreated = Date()
        
        let project = Project(context: viewContext)
        project.id = UUID()
        project.title = "Test Project"
        project.client = client
        project.dateCreated = Date()
        project.status = "En cours"
        
        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = "Test Task"
        task.project = project
        task.dateCreated = Date()
        
        try viewContext.save()
        
        viewContext.delete(project)
        try viewContext.save()
        
        let taskRequest = NSFetchRequest<Task>(entityName: "Task")
        let tasks = try viewContext.fetch(taskRequest)
        
        XCTAssertEqual(tasks.count, 0)
    }
}
