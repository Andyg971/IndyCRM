import Foundation
import _Concurrency

@MainActor
public class ProjectManager: ObservableObject {
    @Published public private(set) var projects: [Project] = []
    private let saveKey = "SavedProjects"
    private let activityLogService: ActivityLogService
    private let alertService: AlertService
    
    public init(activityLogService: ActivityLogService? = nil, alertService: AlertService? = nil) {
        self.activityLogService = activityLogService ?? ActivityLogService()
        self.alertService = alertService ?? AlertService()
        loadProjectsSync()
        
        Task {
            await self.alertService.setup()
        }
    }
    
    private var saveURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("\(saveKey).json")
    }
    
    private func loadProjectsSync() {
        do {
            let data = try Data(contentsOf: saveURL)
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            projects = []
            print("Erreur de chargement des projets: \(error)")
        }
    }
    
    private func saveProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Erreur de sauvegarde des projets: \(error)")
        }
    }
    
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
        
        // Enregistrer l'activité
        let log = ActivityLog(
            id: UUID(),
            date: Date(),
            userId: UUID(), // À remplacer par l'ID de l'utilisateur actuel
            action: .created,
            entityType: .project,
            entityId: project.id,
            details: "Création du projet \(project.name)"
        )
        activityLogService.addLog(log)
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            let oldProject = projects[index]
            projects[index] = project
            saveProjects()
            
            // Enregistrer l'activité
            if oldProject.status != project.status {
                let log = ActivityLog(
                    id: UUID(),
                    date: Date(),
                    userId: UUID(),
                    action: .statusChanged,
                    entityType: .project,
                    entityId: project.id,
                    details: "Statut changé de \(oldProject.status.rawValue) à \(project.status.rawValue)"
                )
                activityLogService.addLog(log)
            } else {
                let log = ActivityLog(
                    id: UUID(),
                    date: Date(),
                    userId: UUID(),
                    action: .updated,
                    entityType: .project,
                    entityId: project.id,
                    details: "Mise à jour du projet \(project.name)"
                )
                activityLogService.addLog(log)
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveProjects()
    }
    
    func projectsForClient(_ clientId: UUID) -> [Project] {
        projects.filter { $0.clientId == clientId }
    }
    
    func checkDeadlinesAndTasks() {
        alertService.checkProjectDeadlines(projects)
        alertService.checkTaskStatus(projects)
    }
} 