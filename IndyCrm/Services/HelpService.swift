import Foundation
import SwiftUI

@MainActor
public class HelpService: ObservableObject {
    @Published public private(set) var helpMessages: [HelpMessage] = []
    @Published public var showingHelp = false
    
    public struct HelpMessage: Identifiable {
        public let id = UUID()
        public let title: String
        public let message: String
        public let type: MessageType
        public let date = Date()
        
        public enum MessageType {
            case warning
            case info
            case tip
            
            public var icon: String {
                switch self {
                case .warning: return "exclamationmark.triangle"
                case .info: return "info.circle"
                case .tip: return "lightbulb"
                }
            }
            
            public var color: Color {
                switch self {
                case .warning: return .orange
                case .info: return .blue
                case .tip: return .green
                }
            }
        }
    }
    
    public init() {}
    
    public func checkContact(_ contact: Contact) {
        var messages: [HelpMessage] = []
        
        if contact.notes.isEmpty {
            messages.append(HelpMessage(
                title: "Notes manquantes",
                message: "Le contact \(contact.fullName) n'a pas de notes. Ajoutez des informations pour un meilleur suivi.",
                type: .warning
            ))
        }
        
        if contact.type == .client && contact.organization.isEmpty {
            messages.append(HelpMessage(
                title: "Organisation manquante",
                message: "Le client \(contact.fullName) n'a pas d'organisation associée.",
                type: .warning
            ))
        }
        
        helpMessages.append(contentsOf: messages)
        if !messages.isEmpty {
            showingHelp = true
        }
    }
    
    public func checkProject(_ project: Project) {
        var messages: [HelpMessage] = []
        
        if project.notes.isEmpty {
            messages.append(HelpMessage(
                title: "Description manquante",
                message: "Le projet \(project.name) n'a pas de description.",
                type: .warning
            ))
        }
        
        if project.tasks.isEmpty {
            messages.append(HelpMessage(
                title: "Tâches manquantes",
                message: "Le projet \(project.name) n'a aucune tâche. Ajoutez des tâches pour suivre la progression.",
                type: .warning
            ))
        }
        
        if project.deadline == nil {
            messages.append(HelpMessage(
                title: "Date limite manquante",
                message: "Le projet \(project.name) n'a pas de date limite définie.",
                type: .info
            ))
        }
        
        helpMessages.append(contentsOf: messages)
        if !messages.isEmpty {
            showingHelp = true
        }
    }
    
    public func addTip(_ message: String) {
        helpMessages.append(HelpMessage(
            title: "Conseil",
            message: message,
            type: .tip
        ))
    }
    
    public func clearMessages() {
        helpMessages.removeAll()
    }
} 