import SwiftUI

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedReport: ReportType = .revenue
    
    enum TimePeriod: String, CaseIterable {
        case week = "Semaine"
        case month = "Mois"
        case quarter = "Trimestre"
        case year = "Année"
        case custom = "Personnalisé"
    }
    
    enum ReportType: String, CaseIterable {
        case revenue = "Chiffre d'affaires"
        case clients = "Clients"
        case projects = "Projets"
        case invoices = "Factures"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Sélecteurs de période et type de rapport
            HStack {
                Picker("Période", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                
                Picker("Type de rapport", selection: $selectedReport) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            // Contenu du rapport
            ScrollView {
                VStack(spacing: 20) {
                    // Carte résumé
                    ReportSummaryCard(type: selectedReport, period: selectedPeriod)
                    
                    // Graphique principal
                    ReportChart(type: selectedReport, period: selectedPeriod)
                        .frame(height: 300)
                    
                    // Détails du rapport
                    ReportDetails(type: selectedReport, period: selectedPeriod)
                }
                .padding()
            }
        }
        .navigationTitle("Rapports")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: exportReport) {
                    Label("Exporter", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func exportReport() {
        // Implémenter l'export du rapport (PDF, Excel, etc.)
    }
}

struct ReportSummaryCard: View {
    let type: ReportsView.ReportType
    let period: ReportsView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type.rawValue)
                .font(.headline)
            
            HStack(spacing: 40) {
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("12 500 €")
                        .font(.title2)
                        .bold()
                }
                
                VStack(alignment: .leading) {
                    Text("Variation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("+15%")
                        .font(.title2)
                        .foregroundColor(.green)
                        .bold()
                }
            }
            
            Text("Période : \(period.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct ReportChart: View {
    let type: ReportsView.ReportType
    let period: ReportsView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolution")
                .font(.headline)
            
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let points = [0.2, 0.4, 0.3, 0.8, 0.5, 0.7, 0.6]
                    
                    path.move(to: CGPoint(x: 0, y: height * (1 - points[0])))
                    
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(points.count - 1)
                        let y = height * (1 - point)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct ReportDetails: View {
    let type: ReportsView.ReportType
    let period: ReportsView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Détails")
                .font(.headline)
            
            // Tableau des données
            VStack(spacing: 8) {
                ForEach(1...5, id: \.self) { _ in
                    HStack {
                        Text("Janvier 2024")
                        Spacer()
                        Text("2 500 €")
                            .bold()
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
