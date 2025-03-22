import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var selectedPeriod: TimePeriod = .month
    
    enum TimePeriod: String, CaseIterable {
        case week = "Semaine"
        case month = "Mois"
        case quarter = "Trimestre"
        case year = "Année"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sélecteur de période
                Picker("Période", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Cartes de statistiques
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    StatCard(title: "Chiffre d'affaires", value: "12 500 €", trend: "+15%", icon: "chart.line.uptrend.xyaxis")
                    StatCard(title: "Clients actifs", value: "24", trend: "+3", icon: "person.2.fill")
                    StatCard(title: "Projets en cours", value: "8", trend: "-1", icon: "folder.fill")
                    StatCard(title: "Factures impayées", value: "3 200 €", trend: "-800 €", icon: "doc.text.fill")
                }
                .padding()
                
                // Graphique des revenus
                VStack(alignment: .leading) {
                    Text("Revenus")
                        .font(.headline)
                    RevenueChartView()
                        .frame(height: 200)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Liste des tâches urgentes
                VStack(alignment: .leading) {
                    Text("Tâches urgentes")
                        .font(.headline)
                    UrgentTasksList()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Activités récentes
                VStack(alignment: .leading) {
                    Text("Activités récentes")
                        .font(.headline)
                    RecentActivitiesList()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Tableau de bord")
    }
}

// Composant carte de statistique
struct StatCard: View {
    let title: String
    let value: String
    let trend: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(trend)
                .font(.caption)
                .foregroundColor(trend.hasPrefix("+") ? .green : .red)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Vue graphique des revenus
struct RevenueChartView: View {
    var body: some View {
        // Placeholder pour le graphique
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
}

// Liste des tâches urgentes
struct UrgentTasksList: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(1...3, id: \.self) { _ in
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Finaliser la proposition commerciale")
                    Spacer()
                    Text("Aujourd'hui")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Liste des activités récentes
struct RecentActivitiesList: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(1...5, id: \.self) { _ in
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption2)
                    Text("Nouvelle facture créée pour Client X")
                    Spacer()
                    Text("Il y a 2h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
