import Foundation
import _Concurrency

@MainActor
public class ProjectManager: ObservableObject {
    // Retirer static shared si l'init a des dépendances
    // public static let shared = ProjectManager()
    
    @Published public private(set) var projects: [Project] = []
    private let saveKey = "SavedProjects"
    private let activityLogService: ActivityLogService
    private let alertService: AlertService
    private let cacheService = CacheService.shared // Ajout du CacheService
    private let cacheKey = "CachedProjects"        // Clé pour le cache
    
    public init(activityLogService: ActivityLogService? = nil, alertService: AlertService? = nil) {
        self.activityLogService = activityLogService ?? ActivityLogService()
        self.alertService = alertService ?? AlertService()
        // loadProjectsSync() // Remplacé par chargement async
        
        Task {
            await self.alertService.setup()
            // Charger les projets au démarrage (avec cache)
            await loadProjects()
        }
    }
    
    private var saveURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("\(saveKey).json")
    }
    
    // Fonction asynchrone pour charger avec cache
    public func loadProjects() async {
        // 1. Essayer de charger depuis le cache
        do {
            let cachedProjects: [Project] = try cacheService.object(forKey: cacheKey)
            self.projects = cachedProjects
            print("📂 Projets chargés depuis le cache")
            checkDeadlinesAndTasks() // Vérifier après chargement
            return // Sortir si chargé depuis le cache
        } catch {
            print("📂 Cache des projets non trouvé ou expiré: \(error.localizedDescription)")
        }

        // 2. Charger depuis le fichier si le cache est vide ou invalide
        do {
            let data = try Data(contentsOf: saveURL)
            let loadedProjects = try JSONDecoder().decode([Project].self, from: data)
            self.projects = loadedProjects
            print("📂 Projets chargés depuis le fichier")

            // 3. Mettre les projets chargés dans le cache
            try cacheService.cache(loadedProjects, forKey: cacheKey)
            print("📂 Projets mis en cache")

        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            self.projects = []
            print("📂 Fichier \(saveKey).json non trouvé, initialisation à vide.")
        } catch {
            self.projects = [] // Initialiser à vide en cas d'autre erreur
            print("Erreur de chargement des projets depuis le fichier: \(error)")
        }
        
        // Vérifier les deadlines après le chargement initial depuis fichier
        checkDeadlinesAndTasks()
    }

    // Rendre la sauvegarde async
    private func saveProjects() async {
        do {
            // Sauvegarde sur disque
            let data = try JSONEncoder().encode(projects)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
            print("📂 Projets sauvegardés sur disque")

            // Mise à jour du cache
            try cacheService.cache(projects, forKey: cacheKey)
            print("📂 Cache des projets mis à jour")
        } catch {
            print("Erreur de sauvegarde des projets: \(error)")
        }
    }
    
    // Rendre async
    func addProject(_ project: Project) async {
        projects.append(project)
        await saveProjects()
        
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
    
    // Rendre async
    func updateProject(_ project: Project) async {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            let oldProject = projects[index]
            projects[index] = project
            await saveProjects()
            
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
    
    // Rendre async
    func deleteProject(_ project: Project) async {
        projects.removeAll { $0.id == project.id }
        await saveProjects()
        
        // Invalider explicitement le cache pour assurer que les données supprimées ne sont pas rechargées
        cacheService.invalidateCache(forKey: cacheKey)
        print("📂 Cache des projets invalidé après suppression")
        
        // Ajouter log de suppression
        let log = ActivityLog(
            id: UUID(),
            date: Date(),
            userId: UUID(),
            action: .deleted,
            entityType: .project,
            entityId: project.id,
            details: "Suppression du projet \(project.name)"
        )
        activityLogService.addLog(log)
    }
    
    func projectsForClient(_ clientId: UUID) -> [Project] {
        projects.filter { $0.clientId == clientId }
    }
    
    func checkDeadlinesAndTasks() {
        alertService.checkProjectDeadlines(projects)
        alertService.checkTaskStatus(projects)
    }
    
    // --- Ajout de méthodes pour l'intégration avec BackupService ---

    /// Retourne les données brutes des projets pour la sauvegarde
    func getProjectsDataForBackup() throws -> Data {
        // Assurer que Project est Codable
        return try JSONEncoder().encode(projects)
    }

    /// Remplace les projets actuels avec les données restaurées et met à jour le cache
    func restoreProjects(from data: Data) async throws {
        // Assurer que Project est Codable
        let restoredProjects = try JSONDecoder().decode([Project].self, from: data)
        self.projects = restoredProjects
        // Sauvegarder immédiatement les projets restaurés sur disque et dans le cache
        await saveProjects()
        print("📂 Projets restaurés depuis la sauvegarde")
        // Re-vérifier les deadlines après restauration
        checkDeadlinesAndTasks()
    }
} 