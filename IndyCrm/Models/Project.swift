import Foundation
import SwiftUI

public struct Project: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var clientId: UUID
    public var startDate: Date
    public var deadline: Date?
    public var status: ProjectStatus
    public var tasks: [ProjectTask]
    public var notes: String
    public var milestones: [Milestone]
    
    // Calculs dérivés
    public var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)
    }
    
    var totalEstimatedHours: Double {
        tasks.reduce(0) { $0 + ($1.estimatedHours ?? 0) }
    }
    
    var totalWorkedHours: Double {
        tasks.reduce(0) { $0 + $1.workedHours }
    }
    
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return Date() > deadline && status != .completed
    }
    
    public init(id: UUID = UUID(), name: String, clientId: UUID, startDate: Date, deadline: Date? = nil, status: ProjectStatus = .planning, tasks: [ProjectTask] = [], notes: String = "", milestones: [Milestone] = []) {
        self.id = id
        self.name = name
        self.clientId = clientId
        self.startDate = startDate
        self.deadline = deadline
        self.status = status
        self.tasks = tasks
        self.notes = notes
        self.milestones = milestones
    }
}

public struct Milestone: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let date: Date
    public let description: String
    public var isCompleted: Bool
    public var progress: Double
    public var dependencies: [String]?
    public var assignedToContactId: UUID?
    public var lastUpdate: Date?
    public var comments: [Comment]
    
    public init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        description: String,
        isCompleted: Bool = false,
        progress: Double = 0,
        dependencies: [String]? = nil,
        assignedToContactId: UUID? = nil,
        lastUpdate: Date? = nil,
        comments: [Comment] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.description = description
        self.isCompleted = isCompleted
        self.progress = progress
        self.dependencies = dependencies
        self.assignedToContactId = assignedToContactId
        self.lastUpdate = lastUpdate
        self.comments = comments
    }
}

extension Project {
    static let example = Project(
        id: UUID(),
        name: "Projet exemple",
        clientId: UUID(),
        startDate: Date(),
        deadline: Date().addingTimeInterval(86400 * 30),
        status: .inProgress,
        tasks: [],
        notes: "Notes d'exemple",
        milestones: []
    )
} 