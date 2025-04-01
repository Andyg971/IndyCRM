import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var invoiceManager: InvoiceManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Statistiques globales
                DashboardCard("Projets actifs", value: "\(activeProjects.count)")
                    .foregroundColor(.blue)
                
                DashboardCard("Chiffre d'affaires", value: totalRevenue.formatted(.currency(code: "EUR")))
                    .foregroundColor(.green)
                
                DashboardCard("Factures en attente", value: "\(unpaidInvoices.count)")
                    .foregroundColor(unpaidInvoices.isEmpty ? .green : .orange)
                
                DashboardCard("Taux de conversion", value: "\(Int(conversionRate * 100))%")
                    .foregroundColor(.blue)
            }
            .padding()
            
            // Répartition des projets par type de client
            ProjectDistributionChart(projects: projectManager.projects, contacts: contactsManager.contacts)
                .frame(height: 300)
                .padding()
            
            // Historique des transactions
            TransactionHistoryView(invoices: invoiceManager.invoices, contacts: contactsManager.contacts)
                .padding()
        }
        .navigationTitle("Tableau de bord")
    }
    
    private var activeProjects: [Project] {
        projectManager.projects.filter { $0.status == .inProgress }
    }
    
    private var unpaidInvoices: [Invoice] {
        invoiceManager.invoices.filter { $0.status != .paid }
    }
    
    private var totalRevenue: Double {
        invoiceManager.invoices
            .filter { $0.status == .paid }
            .reduce(0) { $0 + $1.total }
    }
    
    private var conversionRate: Double {
        let prospects = contactsManager.contacts.filter { $0.type == .prospect }.count
        let clients = contactsManager.contacts.filter { $0.type == .client }.count
        guard prospects > 0 else { return 0 }
        return Double(clients) / Double(prospects + clients)
    }
}

struct ProjectDistributionChart: View {
    let projects: [Project]
    let contacts: [Contact]
    
    var projectsByClientType: [(status: EmploymentStatus, count: Int)] {
        var distribution: [EmploymentStatus: Int] = [:]
        
        for project in projects {
            if let client = contacts.first(where: { $0.id == project.clientId }) {
                distribution[client.employmentStatus, default: 0] += 1
            }
        }
        
        return EmploymentStatus.allCases.map { status in
            (status: status, count: distribution[status] ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Répartition des projets")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart {
                ForEach(projectsByClientType, id: \.status) { item in
                    SectorMark(
                        angle: .value("Projets", item.count),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Type", item.status.rawValue))
                    .annotation(position: .overlay) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Légende
            VStack(alignment: .leading, spacing: 8) {
                ForEach(projectsByClientType, id: \.status) { item in
                    HStack {
                        Circle()
                            .fill(statusColor(for: item.status))
                            .frame(width: 10, height: 10)
                        Text(item.status.rawValue)
                        Spacer()
                        Text("\(item.count) projets")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func statusColor(for status: EmploymentStatus) -> Color {
        switch status {
        case .freelance: return .blue
        case .independent: return .green
        case .permanent: return .orange
        }
    }
}

struct TransactionHistoryView: View {
    let invoices: [Invoice]
    let contacts: [Contact]
    @State private var sortOrder: SortOrder = .date
    @State private var selectedPeriod: Period = .month
    
    enum SortOrder {
        case date, amount
    }
    
    enum Period {
        case week, month, quarter, year
    }
    
    var filteredInvoices: [Invoice] {
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = invoices.filter { invoice in
            switch selectedPeriod {
            case .week:
                return calendar.isDate(invoice.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(invoice.date, equalTo: now, toGranularity: .month)
            case .quarter:
                let quarterStart = calendar.date(byAdding: .month, value: -3, to: now)!
                return invoice.date >= quarterStart
            case .year:
                return calendar.isDate(invoice.date, equalTo: now, toGranularity: .year)
            }
        }
        
        return filtered.sorted { first, second in
            switch sortOrder {
            case .date:
                return first.date > second.date
            case .amount:
                return first.total > second.total
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historique des transactions")
                .font(.headline)
            
            HStack {
                Picker("Trier par", selection: $sortOrder) {
                    Text("Date").tag(SortOrder.date)
                    Text("Montant").tag(SortOrder.amount)
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                Picker("Période", selection: $selectedPeriod) {
                    Text("Semaine").tag(Period.week)
                    Text("Mois").tag(Period.month)
                    Text("Trimestre").tag(Period.quarter)
                    Text("Année").tag(Period.year)
                }
                .pickerStyle(.menu)
            }
            
            ForEach(filteredInvoices) { invoice in
                TransactionRow(invoice: invoice, contact: contacts.first { $0.id == invoice.clientId })
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TransactionRow: View {
    let invoice: Invoice
    let contact: Contact?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact?.fullName ?? "Client inconnu")
                    .font(.subheadline)
                Text(invoice.number)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(invoice.total.formatted(.currency(code: "EUR")))
                    .font(.subheadline)
                    .foregroundColor(invoice.status == .paid ? .green : .primary)
                Text(invoice.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    
    init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        DashboardView(
            projectManager: ProjectManager(activityLogService: ActivityLogService()),
            contactsManager: ContactsManager(),
            invoiceManager: InvoiceManager()
        )
    }
} 