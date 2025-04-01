import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var invoiceManager: InvoiceManager
    
    var body: some View {
        List {
            Section(header: Text("Répartition des clients")) {
                Chart {
                    ForEach(EmploymentStatus.allCases, id: \.self) { status in
                        let count = contactsManager.contacts.filter { $0.employmentStatus == status }.count
                        SectorMark(
                            angle: .value("Count", count),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Status", status.rawValue))
                    }
                }
                .frame(height: 200)
            }
            
            Section(header: Text("Projets par statut")) {
                Chart {
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        let count = projectManager.projects.filter { $0.status == status }.count
                        BarMark(
                            x: .value("Status", status.rawValue),
                            y: .value("Count", count)
                        )
                    }
                }
                .frame(height: 200)
            }
            
            Section(header: Text("Chiffre d'affaires mensuel")) {
                Chart {
                    ForEach(lastSixMonths, id: \.self) { month in
                        let revenue = monthlyRevenue(for: month)
                        LineMark(
                            x: .value("Mois", month, unit: .month),
                            y: .value("Revenu", revenue)
                        )
                    }
                }
                .frame(height: 200)
            }
        }
        .navigationTitle("Analyses")
    }
    
    private var lastSixMonths: [Date] {
        // Calculer les 6 derniers mois
        (0..<6).map { months in
            Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        }.reversed()
    }
    
    private func monthlyRevenue(for date: Date) -> Double {
        // Calculer le revenu pour un mois donné
        invoiceManager.invoices
            .filter { $0.status == .paid && Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
            .reduce(0) { $0 + $1.total }
    }
} 