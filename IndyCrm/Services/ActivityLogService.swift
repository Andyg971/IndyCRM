import Foundation

@MainActor
public class ActivityLogService: ObservableObject {
    @Published public private(set) var logs: [ActivityLog] = []
    private let saveKey = "SavedActivityLogs"
    
    public init() {
        loadLogsSync()
    }
    
    private var saveURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("\(saveKey).json")
    }
    
    private func loadLogsSync() {
        do {
            let data = try Data(contentsOf: saveURL)
            logs = try JSONDecoder().decode([ActivityLog].self, from: data)
        } catch {
            logs = []
            print("Erreur de chargement des logs: \(error)")
        }
    }
    
    private func saveLogs() {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Erreur de sauvegarde des logs: \(error)")
        }
    }
    
    public func addLog(_ log: ActivityLog) {
        logs.append(log)
        saveLogs()
    }
    
    public func logsForEntity(type: ActivityLog.EntityType, id: UUID) -> [ActivityLog] {
        logs.filter { $0.entityType == type && $0.entityId == id }
            .sorted { $0.date > $1.date }
    }
} 