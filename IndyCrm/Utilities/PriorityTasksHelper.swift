import Foundation
import SwiftUI

/// Utilitaire pour ajouter des tâches à haute priorité prédéfinies aux projets
struct PriorityTasksHelper {
    
    /// Ajoute toutes les tâches à haute priorité au projet spécifié
    /// - Parameters:
    ///   - project: Le projet auquel ajouter les tâches
    ///   - projectManager: Le gestionnaire de projets pour mettre à jour le projet
    @MainActor
    static func addHighPriorityTasks(to project: Project, projectManager: ProjectManager) {
        var updatedProject = project
        
        // Création des tâches de haute priorité
        let highPriorityTasks = createHighPriorityTasks()
        
        // Ajout des tâches au projet
        updatedProject.tasks.append(contentsOf: highPriorityTasks)
        
        // Mise à jour du projet
        Task {
            await projectManager.updateProject(updatedProject)
        }
    }
    
    /// Crée une liste de tâches à haute priorité prédéfinies
    /// - Returns: Un tableau de tâches de haute priorité
    static func createHighPriorityTasks() -> [ProjectTask] {
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        
        return [
            ProjectTask(
                title: "Compléter l'authentification avec Sign in with Apple",
                description: "Intégrer la fonctionnalité Sign in with Apple pour permettre aux utilisateurs de se connecter facilement avec leur identifiant Apple. Cela inclut la configuration de l'app dans App Store Connect, l'implémentation du flux d'authentification, et la gestion des tokens.",
                status: .todo,
                priority: .high,
                dueDate: twoWeeksFromNow,
                estimatedHours: 16
            ),
            
            ProjectTask(
                title: "Implémenter la persistance des données",
                description: "Mettre en place un système robuste de persistance des données pour sauvegarder toutes les informations localement. Utiliser CoreData ou une autre solution adaptée, et s'assurer que les données sont correctement sauvegardées et récupérées à chaque lancement de l'application.",
                status: .todo,
                priority: .high,
                dueDate: twoWeeksFromNow,
                estimatedHours: 24
            ),
            
            ProjectTask(
                title: "Ajouter le chiffrement des données sensibles",
                description: "Mettre en œuvre un système de chiffrement pour protéger les données sensibles des clients et des projets. Utiliser des algorithmes de chiffrement modernes et s'assurer que les clés sont correctement gérées et protégées.",
                status: .todo,
                priority: .high,
                dueDate: twoWeeksFromNow,
                estimatedHours: 20
            ),
            
            ProjectTask(
                title: "Créer une politique de confidentialité",
                description: "Rédiger une politique de confidentialité complète expliquant comment les données des utilisateurs sont collectées, utilisées et protégées. S'assurer qu'elle soit conforme aux réglementations comme le RGPD et inclure les informations relatives au chiffrement des données.",
                status: .todo,
                priority: .high,
                dueDate: twoWeeksFromNow,
                estimatedHours: 8
            )
        ]
    }
    
    /// Ajoute une tâche spécifique à haute priorité à un projet
    /// - Parameters:
    ///   - taskIndex: L'index de la tâche dans la liste des tâches à haute priorité (0-3)
    ///   - project: Le projet auquel ajouter la tâche
    ///   - projectManager: Le gestionnaire de projets pour mettre à jour le projet
    @MainActor
    static func addSpecificHighPriorityTask(taskIndex: Int, to project: Project, projectManager: ProjectManager) {
        guard taskIndex >= 0 && taskIndex < 4 else { return }
        
        var updatedProject = project
        let highPriorityTasks = createHighPriorityTasks()
        
        if taskIndex < highPriorityTasks.count {
            updatedProject.tasks.append(highPriorityTasks[taskIndex])
            Task {
                await projectManager.updateProject(updatedProject)
            }
        }
    }
} 