import SwiftUI
import Charts

struct ProjectStatsView: View {
    let project: Project
    @ObservedObject var contactsManager: ContactsManager
    
    private var daysLeft: Int {
        guard let deadline = project.deadline else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
    
    private var timeProgress: Double {
        let estimatedHours = project.totalEstimatedHours
        guard estimatedHours > 0 else { return 0 }
        return min(project.totalWorkedHours / estimatedHours, 1.0)
    }
    
    var body: some View {
        List {
            // Vue d'ensemble
            projectOverviewSection
            
            // Répartition des projets
            projectDistributionSection
            
            // Temps et progression
            timeProgressSection
            
            // Jalons
            milestonesSection
        }
        .navigationTitle("Statistiques")
    }
    
    private var projectOverviewSection: some View {
        Section("Vue d'ensemble") {
            VStack(alignment: .leading, spacing: 12) {
                // Progression globale
                progressView
                
                // Jours restants
                if project.deadline != nil {
                    deadlineView
                }
            }
        }
    }
    
    private var projectDistributionSection: some View {
        Section("Répartition des projets") {
            VStack(spacing: 16) {
                // Graphique en anneau
                Chart {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        let count = project.tasks.filter { $0.status == status }.count
                        if count > 0 {
                            SectorMark(
                                angle: .value("Nombre", count),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(status.statusColor)
                            .annotation(position: .overlay) {
                                VStack {
                                    Text("\(count)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(status.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .frame(height: 250)
                
                // Légende et statistiques détaillées
                VStack(spacing: 12) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        let count = project.tasks.filter { $0.status == status }.count
                        let total = project.tasks.count
                        let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0
                        
                        if count > 0 {
                            HStack {
                                // Indicateur de statut
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(status.statusColor)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(status.rawValue)
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                                
                                // Barre de progression
                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(status.statusColor.opacity(0.3))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(status.statusColor)
                                                .frame(width: geometry.size.width * CGFloat(percentage) / 100)
                                            , alignment: .leading
                                        )
                                }
                                .frame(width: 100, height: 8)
                                
                                // Statistiques
                                HStack(spacing: 4) {
                                    Text("\(count)")
                                        .font(.subheadline.bold())
                                    Text("(\(Int(percentage))%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Statistiques globales
                HStack(spacing: 20) {
                    StatCard(
                        title: "Total des tâches",
                        value: "\(project.tasks.count)",
                        icon: "list.bullet",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Taux de complétion",
                        value: "\(Int(project.progress * 100))%",
                        icon: "chart.pie.fill",
                        color: project.progress >= 0.7 ? .green : (project.progress >= 0.3 ? .orange : .red)
                    )
                }
            }
            .padding(.vertical)
        }
    }
    
    private var projectChart: some View {
        Chart {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                let count = project.tasks.filter { $0.status == status }.count
                if count > 0 {
                    SectorMark(
                        angle: .value("Nombre", count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(status.statusColor)
                    .annotation(position: .overlay) {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    private var projectLegend: some View {
        VStack(spacing: 8) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                let count = project.tasks.filter { $0.status == status }.count
                if count > 0 {
                    HStack {
                        Circle()
                            .fill(status.statusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(status.rawValue)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(count) tâche\(count > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var projectStats: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Taux de complétion",
                value: "\(Int(project.progress * 100))%",
                icon: "chart.pie.fill",
                color: .blue
            )
            
            StatCard(
                title: "Tâches terminées",
                value: "\(project.tasks.filter { $0.isCompleted }.count)/\(project.tasks.count)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }
    
    private var progressView: some View {
        HStack {
            Text("Progression globale")
            Spacer()
            Text("\(Int(project.progress * 100))%")
                .bold()
        }
    }
    
    private var deadlineView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Date limite")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(project.deadline?.formatted(date: .long, time: .omitted) ?? "")
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Jours restants")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(daysLeft)")
                    .font(.title2.bold())
                    .foregroundColor(daysLeft < 7 ? .red : (daysLeft < 14 ? .orange : .green))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var timeProgressSection: some View {
        Section("Temps et coûts") {
            VStack(spacing: 20) {
                // Graphique de progression du temps
                HStack(alignment: .bottom, spacing: 30) {
                    // Heures estimées
                    TimeBar(
                        value: project.totalEstimatedHours,
                        maxValue: max(project.totalEstimatedHours, project.totalWorkedHours),
                        color: .blue,
                        title: "Estimées",
                        unit: "h",
                        showValue: true
                    )
                    
                    // Heures réalisées
                    TimeBar(
                        value: project.totalWorkedHours,
                        maxValue: max(project.totalEstimatedHours, project.totalWorkedHours),
                        color: .green,
                        title: "Réalisées",
                        unit: "h",
                        showValue: true
                    )
                }
                .frame(height: 200)
                .padding(.vertical)
                
                // Barre de progression avec détails
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progression du temps")
                        .font(.headline)
                    
                    ModernProgressBar(
                        progress: timeProgress,
                        isPaused: project.status == .onHold,
                        height: 16
                    )
                    
                    // Détails sous la barre
                    HStack {
                        Text("\(Int(project.totalWorkedHours))h sur \(Int(project.totalEstimatedHours))h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(timeProgress * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(
                                timeProgress > 1 ? .red :
                                    (timeProgress > 0.9 ? .orange : .green)
                            )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Détails des heures
                VStack(spacing: 12) {
                    TimeDetailRow(
                        title: "Heures estimées",
                        value: project.totalEstimatedHours,
                        color: .blue,
                        icon: "clock"
                    )
                    
                    TimeDetailRow(
                        title: "Heures réalisées",
                        value: project.totalWorkedHours,
                        color: .green,
                        icon: "checkmark.circle"
                    )
                    
                    if project.totalEstimatedHours > 0 {
                        Divider()
                        
                        TimeDetailRow(
                            title: "Différence",
                            value: project.totalWorkedHours - project.totalEstimatedHours,
                            color: project.totalWorkedHours > project.totalEstimatedHours ? .red : .green,
                            icon: "arrow.up.arrow.down",
                            showSign: true
                        )
                        
                        // Temps restant estimé
                        let remainingHours = max(0, project.totalEstimatedHours - project.totalWorkedHours)
                        TimeDetailRow(
                            title: "Temps restant estimé",
                            value: remainingHours,
                            color: .orange,
                            icon: "hourglass",
                            showSign: false
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var milestonesSection: some View {
        Section("Jalons") {
            if project.milestones.isEmpty {
                Text("Aucun jalon défini")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 16) {
                    // Vue d'ensemble des jalons
                    MilestonesOverview(project: project)
                    
                    // Liste détaillée des jalons
                    ForEach(project.milestones.sorted(by: { $0.date < $1.date })) { milestone in
                        EnhancedMilestoneCard(
                            milestone: milestone,
                            project: project,
                            contactsManager: contactsManager
                        )
                    }
                }
            }
        }
    }
}

struct TimeBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let title: String
    let unit: String
    let showValue: Bool
    
    var height: Double {
        guard maxValue > 0 else { return 0 }
        return value / maxValue
    }
    
    var body: some View {
        VStack {
            if showValue {
                Text("\(Int(value))\(unit)")
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(height: geometry.size.height * height)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    )
                    .animation(.spring(response: 0.3), value: height)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TimeDetailRow: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    var showSign: Bool = false
    
    var formattedValue: String {
        let prefix = showSign && value > 0 ? "+" : ""
        return "\(prefix)\(Int(value))h"
    }
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.secondary)
            Spacer()
            Text(formattedValue)
                .foregroundColor(color)
                .bold()
        }
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    let projectStartDate: Date
    let isPaused: Bool
    
    private var progress: Double {
        let now = Date()
        let end = milestone.date
        
        guard end > projectStartDate else { return 1.0 }
        
        let totalDuration = end.timeIntervalSince(projectStartDate)
        let elapsed = now.timeIntervalSince(projectStartDate)
        
        return min(max(elapsed / totalDuration, 0), 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(milestone.isCompleted ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                
                Text(milestone.title)
                    .font(.headline)
                
                Spacer()
                
                Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !milestone.description.isEmpty {
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ModernProgressBar(
                progress: progress,
                isPaused: isPaused
            )
            .frame(height: 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// Nouveaux composants pour les jalons
struct MilestonesOverview: View {
    let project: Project
    
    private var completedMilestones: Int {
        project.milestones.filter { $0.isCompleted }.count
    }
    
    private var totalMilestones: Int {
        project.milestones.count
    }
    
    private var progress: Double {
        guard totalMilestones > 0 else { return 0 }
        return Double(completedMilestones) / Double(totalMilestones)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progression globale des jalons
            HStack {
                Text("Progression des jalons")
                    .font(.headline)
                Spacer()
                Text("\(completedMilestones)/\(totalMilestones)")
                    .font(.caption.bold())
            }
            
            ModernProgressBar(progress: progress)
                .frame(height: 8)
            
            // Statistiques des jalons
            HStack {
                MilestoneStatCard(
                    count: project.milestones.filter { $0.date > Date() }.count,
                    label: "À venir",
                    color: .blue
                )
                
                MilestoneStatCard(
                    count: project.milestones.filter { !$0.isCompleted && $0.date <= Date() }.count,
                    label: "En cours",
                    color: .orange
                )
                
                MilestoneStatCard(
                    count: completedMilestones,
                    label: "Terminés",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct EnhancedMilestoneCard: View {
    let milestone: Milestone
    let project: Project
    let contactsManager: ContactsManager
    
    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: milestone.date).day ?? 0
    }
    
    private var status: MilestoneStatus {
        if milestone.isCompleted {
            return .completed
        } else if milestone.date < Date() {
            return .late
        } else if daysUntil <= 7 {
            return .upcoming
        } else {
            return .planned
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête avec statut
            HStack {
                StatusIndicator(status: status)
                
                Text(milestone.title)
                    .font(.headline)
                
                Spacer()
                
                // Menu d'actions
                Menu {
                    Button("Marquer comme terminé") { }
                    Button("Modifier") { }
                    Button("Ajouter un commentaire") { }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            // Dates et échéances
            HStack {
                DateInfoView(
                    date: milestone.date,
                    label: "Échéance",
                    icon: "calendar"
                )
                
                Spacer()
                
                if daysUntil > 0 {
                    Text("\(daysUntil) jours restants")
                        .font(.caption)
                        .padding(6)
                        .background(status.color.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if !milestone.description.isEmpty {
                Text(milestone.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Dépendances et impact
            if let dependencies = milestone.dependencies {
                DependenciesView(dependencies: dependencies)
            }
            
            // Progression
            VStack(alignment: .leading, spacing: 4) {
                Text("Progression")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ModernProgressBar(
                    progress: milestone.progress,
                    isPaused: project.status == .onHold
                )
                .frame(height: 8)
            }
            
            // Dernière mise à jour et commentaires
            if let lastUpdate = milestone.lastUpdate {
                HStack {
                    Image(systemName: "clock")
                    Text("Dernière mise à jour: \(lastUpdate.formatted())")
                    Spacer()
                    Text("\(milestone.comments.count) commentaires")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

enum MilestoneStatus {
    case planned, upcoming, late, completed
    
    var color: Color {
        switch self {
        case .planned: return .blue
        case .upcoming: return .orange
        case .late: return .red
        case .completed: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .planned: return "calendar"
        case .upcoming: return "exclamationmark.circle"
        case .late: return "xmark.circle"
        case .completed: return "checkmark.circle"
        }
    }
    
    var description: String {
        switch self {
        case .planned: return "Planifié"
        case .upcoming: return "À venir"
        case .late: return "En retard"
        case .completed: return "Terminé"
        }
    }
}

struct StatusIndicator: View {
    let status: MilestoneStatus
    
    var body: some View {
        Label(
            title: { Text(status.description).font(.caption) },
            icon: { Image(systemName: status.icon) }
        )
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MilestoneStatCard: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DateInfoView: View {
    let date: Date
    let label: String
    let icon: String
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundColor(.secondary)
        }
    }
}

struct DependenciesView: View {
    let dependencies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dépendances")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(dependencies, id: \.self) { dependency in
                Label(dependency, systemImage: "link")
                    .font(.caption)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// Ajoutez cette structure pour les cartes de statistiques
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationView {
        ProjectStatsView(
            project: Project.example,
            contactsManager: ContactsManager()
        )
    }
} 