import SwiftUI
import Charts

struct TimeEntryInputSection: View {
    let task: ProjectTask
    @Binding var additionalHours: Double
    @Binding var comment: String
    
    var body: some View {
        Section(header: Text("Ajouter du temps")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Temps déjà travaillé : \(Int(task.workedHours))h")
                    .foregroundColor(.secondary)
                
                if let estimated = task.estimatedHours {
                    Text("Temps estimé : \(Int(estimated))h")
                        .foregroundColor(.secondary)
                }
                
                Stepper(
                    "Heures à ajouter : \(Int(additionalHours))h",
                    value: $additionalHours,
                    in: Double(-Int(task.workedHours))...24
                )
                
                TextField("Commentaire (optionnel)", text: $comment)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct TimeEntryHistorySection: View {
    let task: ProjectTask
    @Binding var selectedTimeEntry: TimeEntry?
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        Section(header: Text("Historique")) {
            ForEach(task.timeEntries.sorted(by: { $0.date > $1.date })) { entry in
                TimeEntryRow(entry: entry)
                    .contextMenu {
                        Button(role: .destructive) {
                            selectedTimeEntry = entry
                            showingDeleteAlert = true
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
            }
        }
        
        Section(header: Text("Statistiques")) {
            TimeStatsView(task: task)
        }
    }
}

struct TimeEntryRow: View {
    let entry: TimeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(Int(entry.hours))h")
                    .font(.headline)
                
                Spacer()
                
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !entry.comment.isEmpty {
                Text(entry.comment)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimeStatsView: View {
    let task: ProjectTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimeChartView(task: task)
            TimeStatsBoxes(task: task)
        }
    }
}

struct TimeChartView: View {
    let task: ProjectTask
    
    var body: some View {
        let sortedData = Array(task.timeByDay.sorted(by: { $0.key < $1.key }))
        
        Chart(sortedData, id: \.key) { day, hours in
            BarMark(
                x: .value("Date", day, unit: .day),
                y: .value("Heures", hours)
            )
        }
        .frame(height: 100)
    }
}

struct TimeStatsBoxes: View {
    let task: ProjectTask
    
    var body: some View {
        HStack {
            StatBox(
                title: "Total",
                value: "\(Int(task.workedHours))h"
            )
            
            if let estimated = task.estimatedHours {
                StatBox(
                    title: "Restant",
                    value: "\(max(0, Int(estimated - task.workedHours)))h"
                )
            }
            
            StatBox(
                title: "Entrées",
                value: "\(task.timeEntries.count)"
            )
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
} 