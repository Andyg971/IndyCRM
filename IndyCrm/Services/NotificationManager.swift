import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Erreur d'autorisation des notifications: \(error)")
            }
        }
    }
    
    func scheduleProjectDeadlineAlert(project: Project, daysBeforeDeadline: Int = 7) {
        guard let deadline = project.deadline else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Date limite approche"
        content.body = "Le projet '\(project.name)' se termine dans \(daysBeforeDeadline) jours"
        content.sound = .default
        
        let alertDate = deadline.addingTimeInterval(-Double(daysBeforeDeadline * 86400))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "project-deadline-\(project.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleInvoiceReminder(invoice: Invoice, daysBeforeDue: Int = 3) {
        let content = UNMutableNotificationContent()
        content.title = "Facture à échéance"
        content.body = "La facture \(invoice.number) arrive à échéance dans \(daysBeforeDue) jours"
        content.sound = .default
        
        let alertDate = invoice.dueDate.addingTimeInterval(-Double(daysBeforeDue * 86400))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "invoice-due-\(invoice.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 