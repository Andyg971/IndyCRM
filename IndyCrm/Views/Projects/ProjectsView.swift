import SwiftUI
import Foundation

struct ProjectRow: View {
    let project: Project
    @ObservedObject private var timeManager = TimeTrackingManager.shared
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var collaborationService: CollaborationService
    @ObservedObject var helpService: HelpService
    @ObservedObject var alertService: AlertService
    
    var body: some View {
        HStack {
            // Partie cliquable pour la navigation
            NavigationLink(destination: ProjectDetailView(viewModel: ProjectDetailViewModel(project: project, projectManager: projectManager))) {
                projectInfoView
            }
            
            // Partie non cliquable pour le suivi du temps
            timeTrackingView
        }
    }
    
    private var projectInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête avec nom et statut
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                Text(project.status.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Description du projet
            if !project.notes.isEmpty {
                Text(project.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Dates du projet
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text("\(project.startDate.formatted(date: .abbreviated, time: .omitted)) - \(project.deadline?.formatted(date: .abbreviated, time: .omitted) ?? "Pas de date limite")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progression avec ModernProgressBar
            VStack(spacing: 4) {
                HStack {
                    Text("\(project.tasks.filter { $0.isCompleted }.count)/\(project.tasks.count) tâches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(project.progress * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(progressColor(for: project.progress))
                }
                
                ModernProgressBar(
                    progress: project.progress,
                    isPaused: project.status == .onHold
                )
                .frame(height: 12)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var timeTrackingView: some View {
        VStack {
            Text(formatTime(timeManager.getTrackedTime(for: project.id)))
                .font(.caption)
                .foregroundColor(timeManager.isProjectTracking(projectId: project.id) ? .indigo : .secondary)
            
            Button(action: {
                timeManager.toggleTracking(for: project.id)
            }) {
                Image(systemName: timeManager.isProjectTracking(projectId: project.id) ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(timeManager.isProjectTracking(projectId: project.id) ? .red : .green)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var statusColor: Color {
        project.status.statusColor
    }
    
    private func progressColor(for value: Double) -> Color {
        switch value {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        default: return .green
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct ProjectsView: View {
    @State private var showingAddProject = false
    @StateObject private var projectManager = ProjectManager()
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var collaborationService = CollaborationService()
    @StateObject private var helpService = HelpService()
    @StateObject private var alertService = AlertService()
    
    var body: some View {
        VStack {
            HStack {
                Text("Projets")
                    .font(.title)
                    .padding()
                Spacer()
                Button(action: {
                    showingAddProject = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding()
                }
            }
            
            List {
                ForEach(projectManager.projects) { project in
                    ProjectRow(
                        project: project,
                        projectManager: projectManager,
                        contactsManager: contactsManager,
                        collaborationService: collaborationService,
                        helpService: helpService,
                        alertService: alertService
                    )
                }
                .onDelete(perform: deleteProjects)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Projets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                // Add other toolbar items if needed (e.g., sorting, filtering)
            }
            .sheet(isPresented: $showingAddProject) {
                // Assuming ProjectFormView exists and takes necessary managers
                NavigationView {
                    ProjectFormView(
                        projectManager: projectManager,
                        contactsManager: contactsManager
                    )
                }
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        Task {
            let projectsToDelete = offsets.map { projectManager.projects[$0] }
            for project in projectsToDelete {
                await projectManager.deleteProject(project)
            }
        }
    }
}

// MARK: - Preview Provider
struct ProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        // Setup necessary environment objects for the preview
        let projectManager = ProjectManager()
        
        // Créer la prévisualisation avec un projet exemple préchargé
        return Group {
            ProjectsView()
                .environmentObject(projectManager)
                .environmentObject(AlertService()) // Assuming AlertService is used
                .environmentObject(ContactsManager()) // Assuming ContactsManager is used
                .onAppear {
                    // Utiliser Task pour appeler une méthode asynchrone dans onAppear
                    Task {
                        await projectManager.addProject(Project.example)
                    }
                }
        }
    }
}
 