import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

// MARK: - Task Time Tracker
@MainActor
class TaskTimeTracker: ObservableObject {
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var currentTaskId: UUID?
    @Published var hasNotificationPermission: Bool = false
    private var startTime: Date?
    
    // Stockage des temps de travail par tâche
    private var taskTimers: [UUID: Date] = [:]
    
    init() {
        checkNotificationPermission()
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                self.hasNotificationPermission = granted
                if let error = error {
                    print("Erreur d'autorisation de notification: \(error)")
                }
            }
        }
    }
    
    // Démarrer le suivi pour une tâche
    func startTracking(taskId: UUID) {
        stopCurrentTracking() // Arrêter le suivi en cours si nécessaire
        
        taskTimers[taskId] = Date()
        currentTaskId = taskId
        isTracking = true
        
        if hasNotificationPermission {
            scheduleTrackingReminder(for: taskId)
        }
    }
    
    // Arrêter le suivi pour une tâche
    func stopTracking(taskId: UUID) -> TimeInterval? {
        guard let startTime = taskTimers[taskId] else { return nil }
        
        let duration = Date().timeIntervalSince(startTime)
        taskTimers.removeValue(forKey: taskId)
        
        if taskId == currentTaskId {
            currentTaskId = nil
            isTracking = false
        }
        
        if hasNotificationPermission {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["tracking-reminder-\(taskId)"])
        }
        
        return duration
    }
    
    // Arrêter le suivi en cours
    private func stopCurrentTracking() {
        if let currentId = currentTaskId {
            _ = stopTracking(taskId: currentId)
        }
    }
    
    // Programmer un rappel
    private func scheduleTrackingReminder(for taskId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "Rappel de suivi du temps"
        content.body = "N'oubliez pas d'arrêter le chronomètre si vous avez terminé votre tâche"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 heure
        let request = UNNotificationRequest(
            identifier: "tracking-reminder-\(taskId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur de programmation de notification: \(error)")
            }
        }
    }
    
    // Vérifier si une tâche est en cours de suivi
    func isTrackingTask(_ taskId: UUID) -> Bool {
        return taskTimers[taskId] != nil
    }
    
    // Obtenir le temps écoulé pour une tâche en cours
    func getElapsedTime(for taskId: UUID) -> TimeInterval? {
        guard let startTime = taskTimers[taskId] else { return nil }
        return Date().timeIntervalSince(startTime)
    }
}

// MARK: - Task Board View
struct TaskBoardView: View {
    @ObservedObject var projectManager: ProjectManager
    @ObservedObject var contactsManager: ContactsManager
    @EnvironmentObject var alertService: AlertService
    @StateObject private var timeTracker = TaskTimeTracker()
    let project: Project
    
    @State private var showingNewTaskSheet = false
    @State private var draggedTask: ProjectTask?
    @State private var searchText = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var isRefreshing = false
    
    // Animation pour le rafraîchissement
    @State private var rotationDegrees = 0.0
    
    // Couleurs personnalisées
    private let backgroundColor = Color(UIColor.systemBackground)
    private let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)
    private let accentColor = Color.blue
    
    // Filtres disponibles
    enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "Toutes"
        case todo = "À faire"
        case inProgress = "En cours"
        case review = "En revue"
        case done = "Terminées"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .all: return "tray.full"
            case .todo: return "circle"
            case .inProgress: return "arrow.right.circle"
            case .review: return "eye.circle"
            case .done: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .todo: return .blue
            case .inProgress: return .orange
            case .review: return .purple
            case .done: return .green
            }
        }
    }
    
    // Tâches filtrées
    private var filteredTasks: [TaskStatus: [ProjectTask]] {
        let filtered = project.tasks.filter { task in
            if !searchText.isEmpty {
                return task.title.localizedCaseInsensitiveContains(searchText) ||
                       task.description.localizedCaseInsensitiveContains(searchText)
            }
            
            if selectedFilter == .all {
                return true
            }
            
            switch selectedFilter {
            case .todo: return task.status == .todo
            case .inProgress: return task.status == .inProgress
            case .review: return task.status == .review
            case .done: return task.status == .done
            case .all: return true
            }
        }
        
        return Dictionary(grouping: filtered) { $0.status }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête avec titre et boutons
            headerView
            
            // Barre de recherche et filtres
            searchAndFilterBar
            
            // Colonnes de tâches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    // Colonne "À faire"
                    taskColumn(
                        title: "À faire",
                        systemImage: "circle",
                        color: .blue,
                        tasks: filteredTasks[.todo] ?? []
                    )
                    
                    // Colonne "En cours"
                    taskColumn(
                        title: "En cours",
                        systemImage: "arrow.right.circle",
                        color: .orange,
                        tasks: filteredTasks[.inProgress] ?? []
                    )
                    
                    // Colonne "En revue"
                    taskColumn(
                        title: "En revue",
                        systemImage: "eye.circle",
                        color: .purple,
                        tasks: filteredTasks[.review] ?? []
                    )
                    
                    // Colonne "Terminé"
                    taskColumn(
                        title: "Terminé",
                        systemImage: "checkmark.circle",
                        color: .green,
                        tasks: filteredTasks[.done] ?? []
                    )
                }
                .padding()
            }
            .allowsHitTesting(true) // S'assurer que le scroll fonctionne
            .background(secondaryBackgroundColor.opacity(0.5))
        }
        .sheet(isPresented: $showingNewTaskSheet) {
            NavigationView {
                TaskFormView(
                    contactsManager: contactsManager,
                    onSave: { task in
                        var updatedProject = project
                        updatedProject.tasks.append(task)
                        projectManager.updateProject(updatedProject)
                        
                        alertService.createAlert(
                            type: .success,
                            title: "Tâche créée",
                            message: "La tâche \"\(task.title)\" a été créée avec succès.",
                            severity: .low
                        )
                    }
                )
            }
        }
        .onTapGesture { } // Bloque les taps généraux
        .background(
            // Utiliser la nouvelle API NavigationLink recommandée
            Group {
                if #available(iOS 16.0, *) {
                    // Ajouter un gestionnaire qui intercepte les taps pour éviter la navigation
                    EmptyView()
                        .simultaneousGesture(TapGesture().onEnded { _ in })
                } else {
                    // Fallback pour iOS 15 et moins avec un NavigationLink vide et désactivé
                    NavigationLink(destination: EmptyView(), isActive: .constant(false)) {
                        EmptyView()
                    }
                    .disabled(true) // Désactiver complètement le NavigationLink
                    .opacity(0) // Rendre invisible
                }
            }
        )
        .environment(\.isEnabled, true) // S'assurer que les interactions de l'utilisateur sont activées
    }
    
    // MARK: - Composants d'interface
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tableau des tâches")
                    .font(.title2.bold())
                
                Text("\(project.tasks.count) tâches au total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Bouton de rafraîchissement
            Button(action: refreshTasks) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                    .rotationEffect(.degrees(rotationDegrees))
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            
            // Bouton d'ajout
            Button(action: { showingNewTaskSheet = true }) {
                Label("Nouvelle tâche", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(backgroundColor)
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Rechercher une tâche...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(secondaryBackgroundColor)
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Filtres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TaskFilter.allCases) { filter in
                        filterButton(filter)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
        .background(backgroundColor)
    }
    
    private func filterButton(_ filter: TaskFilter) -> some View {
        Button(action: { selectedFilter = filter }) {
            HStack {
                Image(systemName: filter.systemImage)
                Text(filter.rawValue)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(selectedFilter == filter ? filter.color.opacity(0.2) : secondaryBackgroundColor)
            .foregroundColor(selectedFilter == filter ? filter.color : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selectedFilter == filter ? filter.color : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private func taskColumn(title: String, systemImage: String, color: Color, tasks: [ProjectTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête de colonne
            HStack {
                Label {
                    Text(title)
                        .font(.headline)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(color)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption.bold())
                    .padding(6)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
            
            // Liste des tâches
            if tasks.isEmpty {
                emptyColumnView(color: color)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasks) { task in
                            // Supprimer toute navigation associée à la carte
                            taskCardView(task: task)
                                .id(task.id)  // Force à recréer la vue si la tâche change
                                .buttonStyle(PlainButtonStyle()) // Éviter le comportement des boutons
                                .onTapGesture {} // Bloquer les taps sur la carte entière
                                .simultaneousGesture(TapGesture().onEnded { _ in }) // Double sécurité
                                .contentShape(Rectangle())
                                .onDrag {
                                    draggedTask = task
                                    return NSItemProvider(object: task.id.uuidString as NSString)
                                }
                        }
                    }
                }
            }
        }
        .frame(width: 280)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .onDrop(of: [UTType.text.identifier], delegate: TaskDropDelegate(
            destinationStatus: getTaskStatus(from: title),
            draggedTask: $draggedTask,
            tasks: project.tasks,
            onTaskMoved: updateTask
        ))
    }
    
    private func getTaskStatus(from title: String) -> TaskStatus {
        switch title {
        case "À faire": return .todo
        case "En cours": return .inProgress
        case "En revue": return .review
        case "Terminé": return .done
        default: return .todo
        }
    }
    
    private func taskCardView(task: ProjectTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête avec le titre
            HStack {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                
                // Boutons
                HStack(spacing: 12) {
                    // Bouton de suivi du temps (implémentation directe sans Button)
                    Image(systemName: timeTracker.isTrackingTask(task.id) ? "stop.circle.fill" : "play.circle.fill")
                        .foregroundColor(timeTracker.isTrackingTask(task.id) ? .red : .green)
                        .font(.title3)
                        .padding(8)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if timeTracker.isTrackingTask(task.id) {
                                if let duration = timeTracker.stopTracking(taskId: task.id) {
                                    let hours = duration / 3600
                                    var updatedTask = task
                                    updatedTask.workedHours += hours
                                    updateTask(updatedTask)
                                    
                                    alertService.createAlert(
                                        type: .success,
                                        title: "Temps ajouté",
                                        message: "Le temps de travail a été mis à jour (\(String(format: "%.1f", hours))h)",
                                        severity: .low
                                    )
                                }
                            } else {
                                timeTracker.startTracking(taskId: task.id)
                                alertService.createAlert(
                                    type: .info,
                                    title: "Suivi démarré",
                                    message: "Le suivi du temps a commencé pour la tâche \"\(task.title)\"",
                                    severity: .low
                                )
                            }
                        }
                        .preventNavigation()
                    
                    // Bouton de complétion (implémentation directe)
                    ZStack {
                        Circle()
                            .fill(task.isCompleted ? Color.green : Color.clear)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .strokeBorder(task.isCompleted ? Color.green : Color.gray, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        updateTaskStatus(task, isCompleted: !task.isCompleted)
                    }
                    .preventNavigation()
                }
            }
            
            // Contenu de la carte
            VStack(alignment: .leading, spacing: 8) {
                // Description
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Métadonnées
                HStack(spacing: 12) {
                    if let assignedContact = task.assignedTo.flatMap({ id in
                        contactsManager.contacts.first { $0.id == id }
                    }) {
                        Label(assignedContact.fullName, systemImage: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progression avec temps de travail en cours
                if let estimatedHours = task.estimatedHours {
                    VStack(spacing: 4) {
                        ProgressView(value: task.progress)
                            .tint(self.progressColor(for: task.progress))
                        
                        HStack {
                            HStack {
                                Image(systemName: "clock")
                                if timeTracker.isTrackingTask(task.id),
                                   let elapsedTime = timeTracker.getElapsedTime(for: task.id) {
                                    TimeDisplay(task: task, elapsedTime: elapsedTime, estimatedHours: estimatedHours)
                                } else {
                                    Text("\(Int(task.workedHours))h / \(Int(estimatedHours))h")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.caption)
                            
                            Spacer()
                            
                            Text("\(Int(task.progress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(self.progressColor(for: task.progress))
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .preventNavigation() // Prévenir toute navigation
        .onDrop(of: [UTType.text.identifier], delegate: TaskDropDelegate(
            destinationStatus: task.status,
            draggedTask: $draggedTask,
            tasks: project.tasks,
            onTaskMoved: updateTask
        ))
    }
    
    // Fonction pour déterminer la couleur de progression
    private func progressColor(for value: Double) -> Color {
        switch value {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
    
    // MARK: - Composants de la carte
    struct TimeTrackingButton: View {
        let task: ProjectTask
        @ObservedObject var timeTracker: TaskTimeTracker
        let onUpdate: (ProjectTask) -> Void
        let onTimeUpdate: (String, String, String) -> Void
        @EnvironmentObject var alertService: AlertService
        
        var body: some View {
            Image(systemName: timeTracker.isTrackingTask(task.id) ? "stop.circle.fill" : "play.circle.fill")
                .foregroundColor(timeTracker.isTrackingTask(task.id) ? .red : .green)
                .font(.title3)
                .onTapGesture {
                    if timeTracker.isTrackingTask(task.id) {
                        if let duration = timeTracker.stopTracking(taskId: task.id) {
                            let hours = duration / 3600
                            var updatedTask = task
                            updatedTask.workedHours += hours
                            onUpdate(updatedTask)
                            
                            onTimeUpdate(
                                "success",
                                "Temps ajouté",
                                "Le temps de travail a été mis à jour (\(String(format: "%.1f", hours))h)"
                            )
                        }
                    } else {
                        timeTracker.startTracking(taskId: task.id)
                        onTimeUpdate(
                            "info",
                            "Suivi démarré",
                            "Le suivi du temps a commencé pour la tâche \"\(task.title)\""
                        )
                    }
                }
                .contentShape(Rectangle())
        }
    }
    
    struct CompletionButton: View {
        let isCompleted: Bool
        let onToggle: () -> Void
        
        var body: some View {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .strokeBorder(isCompleted ? Color.green : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .contentShape(Rectangle())
        }
    }
    
    struct TaskCardContent: View {
        let task: ProjectTask
        let contactsManager: ContactsManager
        @ObservedObject var timeTracker: TaskTimeTracker
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Description
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Métadonnées
                HStack(spacing: 12) {
                    if let assignedContact = task.assignedTo.flatMap({ id in
                        contactsManager.contacts.first { $0.id == id }
                    }) {
                        Label(assignedContact.fullName, systemImage: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progression avec temps de travail en cours
                if let estimatedHours = task.estimatedHours {
                    VStack(spacing: 4) {
                        ProgressView(value: task.progress)
                            .tint(progressColor(for: task.progress))
                        
                        HStack {
                            HStack {
                                Image(systemName: "clock")
                                if timeTracker.isTrackingTask(task.id),
                                   let elapsedTime = timeTracker.getElapsedTime(for: task.id) {
                                    TimeDisplay(task: task, elapsedTime: elapsedTime, estimatedHours: estimatedHours)
                                } else {
                                    Text("\(Int(task.workedHours))h / \(Int(estimatedHours))h")
                                        .foregroundColor(.secondary)
                                        .onTapGesture {} // Empêche toute interaction
                                }
                            }
                            .font(.caption)
                            .onTapGesture {} // Empêche toute interaction
                            
                            Spacer()
                            
                            Text("\(Int(task.progress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(progressColor(for: task.progress))
                        }
                    }
                    .onTapGesture {} // Empêche toute interaction
                }
            }
            .onTapGesture {} // Empêche toute interaction
        }
        
        private func progressColor(for value: Double) -> Color {
            switch value {
            case 0..<0.3: return .red
            case 0.3..<0.7: return .orange
            case 0.7..<0.9: return .yellow
            default: return .green
            }
        }
    }
    
    private func emptyColumnView(color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(color.opacity(0.3))
            
            Text("Aucune tâche")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .background(secondaryBackgroundColor.opacity(0.3))
        .cornerRadius(8)
    }
    
    // MARK: - Fonctions utilitaires
    
    private func refreshTasks() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            rotationDegrees += 360
            isRefreshing = true
        }
        
        // Simuler un rafraîchissement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
    }
    
    // Remplacer la fonction showTimeSheet pour empêcher toute redirection
    private func showTimeSheet(for task: ProjectTask) {
        // Ne rien faire - cette fonction est délibérément vide pour empêcher la redirection
        print("Tentative de redirection bloquée")
    }
    
    private func updateTaskStatus(_ task: ProjectTask, isCompleted: Bool) {
        var updatedTask = task
        updatedTask.isCompleted = isCompleted
        if isCompleted {
            updatedTask.status = .done
        } else if updatedTask.status == .done {
            updatedTask.status = .inProgress
        }
        updateTask(updatedTask)
    }
    
    private func updateTask(_ task: ProjectTask) {
        var updatedProject = project
        if let index = updatedProject.tasks.firstIndex(where: { $0.id == task.id }) {
            updatedProject.tasks[index] = task
            projectManager.updateProject(updatedProject)
        }
    }
}

// MARK: - Délégué pour le glisser-déposer
struct TaskDropDelegate: DropDelegate {
    let destinationStatus: TaskStatus
    @Binding var draggedTask: ProjectTask?
    let tasks: [ProjectTask]
    let onTaskMoved: (ProjectTask) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = draggedTask else { return false }
        
        var updatedTask = draggedTask
        updatedTask.status = destinationStatus
        
        onTaskMoved(updatedTask)
        self.draggedTask = nil
        return true
    }
}

// Une vraie solution complète pour éviter toute redirection
extension View {
    func preventNavigation() -> some View {
        // Cette modification empêche la propagation des événements de tap
        self.simultaneousGesture(TapGesture().onEnded { _ in })
    }
}

// MARK: - Time Display View
private struct TimeDisplay: View {
    let task: ProjectTask
    let elapsedTime: TimeInterval
    let estimatedHours: Double
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text("\(Int(task.workedHours + (elapsedTime / 3600)))h / \(Int(estimatedHours))h")
            .foregroundColor(.orange)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
    }
}

struct TaskBoardView_Previews: PreviewProvider {
    static var previews: some View {
        let alertService = AlertService()
        let projectManager = ProjectManager()
        let contactsManager = ContactsManager()
        let project = Project.example
        
        NavigationView {
            TaskBoardView(
                projectManager: projectManager,
                contactsManager: contactsManager,
                project: project
            )
        }
        .environmentObject(alertService)
    }
} 
