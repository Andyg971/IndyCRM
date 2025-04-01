import Foundation

public struct TimeEntry: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let hours: Double
    public let comment: String
    public let userId: UUID?
    
    public init(id: UUID = UUID(), date: Date = Date(), hours: Double, comment: String = "", userId: UUID? = nil) {
        self.id = id
        self.date = date
        self.hours = hours
        self.comment = comment
        self.userId = userId
    }
}

public struct ProjectTask: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public var status: TaskStatus
    public var priority: Priority
    public var dueDate: Date?
    public var assignedTo: UUID?
    public let estimatedHours: Double?
    public var workedHours: Double
    public var isCompleted: Bool
    public var comments: [Comment]
    public var timeEntries: [TimeEntry]
    
    public var progress: Double {
        if isCompleted { return 1.0 }
        guard let estimated = estimatedHours, estimated > 0 else { return 0 }
        return min(workedHours / estimated, 0.99)
    }
    
    public var timeByDay: [Date: Double] {
        Dictionary(grouping: timeEntries) { Calendar.current.startOfDay(for: $0.date) }
            .mapValues { entries in entries.reduce(0) { $0 + $1.hours } }
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        status: TaskStatus = .todo,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        assignedTo: UUID? = nil,
        estimatedHours: Double? = nil,
        workedHours: Double = 0,
        comments: [Comment] = [],
        timeEntries: [TimeEntry] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.assignedTo = assignedTo
        self.estimatedHours = estimatedHours
        self.workedHours = workedHours
        self.comments = comments
        self.timeEntries = timeEntries
    }
} 