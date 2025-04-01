import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject private var timeManager = TimeTrackingManager.shared
    @State private var projects: [Project] = []
    
    var body: some View {
        VStack {
            Text("Statistiques")
                .font(.title)
                .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Graphique des heures travaillées
                    VStack(alignment: .leading) {
                        Text("Heures travaillées par projet")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(projects) { project in
                                BarMark(
                                    x: .value("Projet", project.name),
                                    y: .value("Heures", timeManager.getTrackedTime(for: project.id) / 3600)
                                )
                                .foregroundStyle(project.status.statusColor)
                            }
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    
                    // Autres statistiques...
                }
            }
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
} 