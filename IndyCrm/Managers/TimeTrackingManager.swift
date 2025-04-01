import Foundation
import SwiftUI

class TimeTrackingManager: ObservableObject {
    static let shared = TimeTrackingManager()
    
    @Published var trackedTimes: [UUID: TimeInterval] = [:]
    @Published var isTracking: [UUID: Bool] = [:]
    private var timers: [UUID: Timer] = [:]
    
    private init() {}
    
    func toggleTracking(for projectId: UUID) {
        if isTracking[projectId] ?? false {
            // Arrêter le suivi
            timers[projectId]?.invalidate()
            timers[projectId] = nil
            isTracking[projectId] = false
        } else {
            // Démarrer le suivi
            isTracking[projectId] = true
            timers[projectId] = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.trackedTimes[projectId] = (self?.trackedTimes[projectId] ?? 0) + 1
            }
        }
    }
    
    func getTrackedTime(for projectId: UUID) -> TimeInterval {
        return trackedTimes[projectId] ?? 0
    }
    
    func isProjectTracking(projectId: UUID) -> Bool {
        return isTracking[projectId] ?? false
    }
} 