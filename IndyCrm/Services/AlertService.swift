import Foundation
import UserNotifications
import SwiftUI

@MainActor
public class AlertService: ObservableObject {
    @Published public private(set) var currentAlerts: [Alert] = []
    private let notificationCenter = UNUserNotificationCenter.current()
    
    public struct Alert: Identifiable {
        public let id = UUID()
        public let type: AlertType
        public let title: String
        public let message: String
        public let date: Date
        public let severity: Severity
        public var isRead = false
        
        public enum AlertType: StatusDisplayable {
            case success
            case error
            case warning
            case info
            
            public var statusTitle: String {
                switch self {
                case .success: return "Succès"
                case .error: return "Erreur"
                case .warning: return "Attention"
                case .info: return "Information"
                }
            }
            
            public var statusColor: Color {
                switch self {
                case .success: return .green
                case .error: return .red
                case .warning: return .orange
                case .info: return .blue
                }
            }
            
            public var icon: String {
                switch self {
                case .success: return "checkmark.circle"
                case .error: return "xmark.circle"
                case .warning: return "exclamationmark.triangle"
                case .info: return "info.circle"
                }
            }
        }
        
        public enum Severity {
            case low
            case medium
            case high
            
            var color: Color {
                switch self {
                case .low: return .blue
                case .medium: return .orange
                case .high: return .red
                }
            }
        }
    }
    
    public init() {}
    
    public func setup() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus != .authorized {
            do {
                try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                print("Erreur d'autorisation des notifications: \(error)")
            }
        }
    }
    
    public func checkProjectDeadlines(_ projects: [Project]) {
        let calendar = Calendar.current
        let now = Date()
        
        for project in projects {
            guard let deadline = project.deadline else { continue }
            
            let daysUntilDeadline = calendar.dateComponents([.day], from: now, to: deadline).day ?? 0
            
            if daysUntilDeadline <= 0 && project.status != .completed {
                createAlert(
                    type: .error,
                    title: "Date limite dépassée",
                    message: "Le projet '\(project.name)' a dépassé sa date limite.",
                    severity: .high
                )
            } else if daysUntilDeadline <= 7 {
                createAlert(
                    type: .warning,
                    title: "Date limite proche",
                    message: "Le projet '\(project.name)' doit être terminé dans \(daysUntilDeadline) jours.",
                    severity: .medium
                )
            }
        }
    }
    
    public func checkTaskStatus(_ projects: [Project]) {
        let now = Date()
        
        for project in projects {
            for task in project.tasks {
                if let dueDate = task.dueDate {
                    if dueDate < now && !task.isCompleted {
                        createAlert(
                            type: .warning,
                            title: "Tâche en retard",
                            message: "La tâche '\(task.title)' du projet '\(project.name)' est en retard.",
                            severity: .medium
                        )
                    }
                }
                
                if task.estimatedHours != nil && task.workedHours > (task.estimatedHours ?? 0) * 1.2 {
                    createAlert(
                        type: .warning,
                        title: "Dépassement de temps",
                        message: "La tâche '\(task.title)' a dépassé le temps estimé de 20%.",
                        severity: .medium
                    )
                }
            }
        }
    }
    
    public func createAlert(type: Alert.AlertType, title: String, message: String, severity: Alert.Severity) {
        let alert = Alert(
            type: type,
            title: title,
            message: message,
            date: Date(),
            severity: severity
        )
        
        currentAlerts.append(alert)
        scheduleNotification(for: alert)
    }
    
    private func scheduleNotification(for alert: Alert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    public func markAsRead(_ alertId: UUID) {
        if let index = currentAlerts.firstIndex(where: { $0.id == alertId }) {
            currentAlerts[index].isRead = true
        }
    }
    
    public func clearOldAlerts() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        currentAlerts.removeAll { $0.date < thirtyDaysAgo }
    }
} 