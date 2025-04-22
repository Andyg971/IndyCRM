import Foundation
import SwiftUI // Using SwiftUI for ObservableObject and MainActor

@MainActor
class ProjectDetailViewModel: ObservableObject {
    // Published property to hold the project data.
    // Views observing this ViewModel will update when the project changes.
    @Published var project: Project

    // Reference to the ProjectManager to handle data persistence.
    // This assumes ProjectManager is available (e.g., passed via initializer or EnvironmentObject).
    private var projectManager: ProjectManager
    // You might need other managers like ContactsManager or AlertService depending on functionality.
    // private var alertService: AlertService // Example

    // Initializer to receive the project and necessary managers.
    init(project: Project, projectManager: ProjectManager /*, alertService: AlertService */ ) {
        self.project = project
        self.projectManager = projectManager
        // self.alertService = alertService // Example
    }

    // Function to update the project's status.
    func updateProjectStatus(_ status: ProjectStatus) {
        // Create a mutable copy to update.
        var updatedProject = project
        updatedProject.status = status
        updatedProject.updatedAt = Date() // Set the modification date.

        // Perform the update asynchronously within a Task.
        Task {
            // Call the manager to save the changes.
            await projectManager.updateProject(updatedProject)
            // Update the local published property upon success.
            // This ensures the UI reflects the change immediately
            // without waiting for a potential reload from the manager.
            self.project = updatedProject
        }
    }

    // Function to update the project's name.
    func updateProjectName(_ name: String) {
        // Create a mutable copy.
        var updatedProject = project
        updatedProject.name = name.trimmingCharacters(in: .whitespacesAndNewlines) // Trim whitespace
        updatedProject.updatedAt = Date() // Set modification date.

        // Prevent saving empty names
        guard !updatedProject.name.isEmpty else {
            print("Project name cannot be empty.")
            // Optionally show an alert to the user.
            // alertService.createAlert(type: .warning, title: "Invalid Name", message: "Project name cannot be empty.", severity: .medium)
            return
        }

        // Perform the update asynchronously.
        Task {
            // Call the manager to save the changes.
            await projectManager.updateProject(updatedProject)
            // Update local state upon success.
            self.project = updatedProject
        }
    }

    // --- Add other functions from the original ProjectDetailView that interact with managers ---
    // Example: Function to mark project as complete
    func markProjectAsComplete() {
        if project.status == .completed {
            // Si le projet est déjà terminé, le rouvrir
            updateProjectStatus(.inProgress)
        } else {
            // Sinon, le marquer comme terminé
            updateProjectStatus(.completed)
        }
    }
    
    // Fonction pour mettre en pause ou reprendre un projet
    func toggleProjectHold() {
        if project.status == .onHold {
            // Si le projet est en pause, le reprendre
            updateProjectStatus(.inProgress)
        } else {
            // Sinon, le mettre en pause
            updateProjectStatus(.onHold)
        }
    }
    
    // Fonction pour ajouter une nouvelle tâche au projet
    func addTask(_ task: ProjectTask) {
        var updatedProject = project
        updatedProject.tasks.append(task)
        updatedProject.updatedAt = Date()
        
        Task {
            await projectManager.updateProject(updatedProject)
            self.project = updatedProject
        }
    }
    
    // Fonction pour mettre à jour une tâche existante
    func updateTask(_ updatedTask: ProjectTask) {
        var updatedProject = project
        if let index = updatedProject.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            updatedProject.tasks[index] = updatedTask
            updatedProject.updatedAt = Date()
            
            Task {
                await projectManager.updateProject(updatedProject)
                self.project = updatedProject
            }
        }
    }
    
    // Fonction pour supprimer une tâche
    func deleteTask(_ taskId: UUID) {
        var updatedProject = project
        updatedProject.tasks.removeAll { $0.id == taskId }
        updatedProject.updatedAt = Date()
        
        Task {
            await projectManager.updateProject(updatedProject)
            self.project = updatedProject
        }
    }
    
    // Fonction pour mettre à jour le statut d'une tâche (terminée/non terminée)
    func updateTaskStatus(_ task: ProjectTask, isCompleted: Bool) {
        var updatedTask = task
        updatedTask.isCompleted = isCompleted
        
        // Mettre à jour également le statut de la tâche en fonction de isCompleted
        if isCompleted {
            updatedTask.status = .done
        } else if updatedTask.status == .done {
            updatedTask.status = .inProgress
        }
        
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    // Fonction pour mettre à jour les notes du projet
    func updateNotes(_ notes: String) {
        var updatedProject = project
        updatedProject.notes = notes
        updatedProject.updatedAt = Date()
        
        Task {
            await projectManager.updateProject(updatedProject)
            self.project = updatedProject
        }
    }
    
    // Fonction pour ajouter un jalon (milestone) au projet
    func addMilestone(_ milestone: Milestone) {
        var updatedProject = project
        updatedProject.milestones.append(milestone)
        updatedProject.updatedAt = Date()
        
        Task {
            await projectManager.updateProject(updatedProject)
            self.project = updatedProject
        }
    }
    
    // Fonction pour mettre à jour un jalon
    func updateMilestone(_ updatedMilestone: Milestone) {
        var updatedProject = project
        if let index = updatedProject.milestones.firstIndex(where: { $0.id == updatedMilestone.id }) {
            updatedProject.milestones[index] = updatedMilestone
            updatedProject.updatedAt = Date()
            
            Task {
                await projectManager.updateProject(updatedProject)
                self.project = updatedProject
            }
        }
    }
} 