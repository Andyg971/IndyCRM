import SwiftUI
import Foundation

struct ProjectRow: View {
    let project: Project
    @ObservedObject private var timeManager = TimeTrackingManager.shared
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @ObservedObject var collaborationService: CollaborationService
    
    var body: some View {
        HStack {
            // Partie cliquable pour la navigation
            NavigationLink(destination: ProjectDetailView(
                project: project,
                projectManager: projectManager,
                contactsManager: contactsManager,
                collaborationService: collaborationService
            )) {
                projectInfoView
            }
            
            // Partie non cliquable pour le suivi du temps
            timeTrackingView
        }
    }
    
    private var projectInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                Text(project.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text(project.notes)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text("\(project.startDate.formatted(date: .abbreviated, time: .omitted)) - \(project.deadline?.formatted(date: .abbreviated, time: .omitted) ?? "Pas de date limite")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                ProgressView(value: project.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                Text("\(Int(project.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeTrackingView: some View {
        VStack {
            Text(formatTime(timeManager.getTrackedTime(for: project.id)))
                .font(.caption)
                .foregroundColor(timeManager.isProjectTracking(projectId: project.id) ? .blue : .gray)
            
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
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct ProjectsView: View {
    @State private var projects: [Project] = []
    @State private var showingAddProject = false
    @StateObject private var projectManager = ProjectManager()
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var collaborationService = CollaborationService()
    
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
                ForEach(projects) { project in
                    ProjectRow(project: project, projectManager: projectManager, contactsManager: contactsManager, collaborationService: collaborationService)
                }
                .onDelete(perform: deleteProjects)
            }
        }
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
    }
}

struct ProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectsView()
    }
} 