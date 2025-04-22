import SwiftUI

struct BackupView: View {
    // Injecter les managers requis par BackupService
    @EnvironmentObject private var contactsManager: ContactsManager
    @EnvironmentObject private var projectManager: ProjectManager
    @EnvironmentObject private var invoiceManager: InvoiceManager
    
    // Utiliser le service de sauvegarde partagé
    private let backupService = BackupService.shared
    
    @State private var backups: [BackupInfo] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingRestoreAlert = false
    @State private var selectedBackup: BackupInfo?
    @State private var showingDeleteBackupAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Actions")) {
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.blue)
                        Text("Créer une sauvegarde")
                    }
                }
                .disabled(isLoading)
            }
            
            Section(header: Text("Sauvegardes disponibles")) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if backups.isEmpty {
                    Text("Aucune sauvegarde disponible")
                        .foregroundColor(.gray)
                } else {
                    ForEach(backups, id: \.name) { backup in
                        BackupRow(
                            backup: backup,
                            onRestore: {
                                selectedBackup = backup
                                showingRestoreAlert = true
                            },
                            onDelete: {
                                selectedBackup = backup
                                showingDeleteBackupAlert = true
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Sauvegardes")
        .onAppear(perform: loadBackups)
        .alert("Erreur", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Restaurer la sauvegarde ?", isPresented: $showingRestoreAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Restaurer", role: .destructive) {
                if let backup = selectedBackup {
                    restoreBackup(backup)
                }
            }
        } message: {
            if let backup = selectedBackup {
                Text("Voulez-vous vraiment restaurer la sauvegarde du \(formatDate(backup.creationDate)) ? Cette action remplacera toutes vos données actuelles.")
            }
        }
        .alert("Supprimer la sauvegarde ?", isPresented: $showingDeleteBackupAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                if let backup = selectedBackup {
                    deleteBackup(backup)
                }
            }
        } message: {
            if let backup = selectedBackup {
                Text("Voulez-vous vraiment supprimer la sauvegarde du \(formatDate(backup.creationDate)) ? Cette action est irréversible.")
            }
        }
    }
    
    private func loadBackups() {
        isLoading = true
        do {
            backups = try backupService.listBackups()
        } catch {
            errorMessage = "Impossible de charger les sauvegardes : \(error.localizedDescription)"
            showingError = true
        }
        isLoading = false
    }
    
    private func createBackup() {
        isLoading = true
        Task {
            do {
                try await backupService.createBackup(
                    contactsManager: contactsManager,
                    projectManager: projectManager,
                    invoiceManager: invoiceManager
                )
                await MainActor.run {
                    loadBackups()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossible de créer la sauvegarde : \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func restoreBackup(_ backup: BackupInfo) {
        isLoading = true
        Task {
            do {
                try await backupService.restoreBackup(
                    named: backup.name,
                    contactsManager: contactsManager,
                    projectManager: projectManager,
                    invoiceManager: invoiceManager
                )
                await MainActor.run {
                    loadBackups()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossible de restaurer la sauvegarde : \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteBackup(_ backup: BackupInfo) {
        isLoading = true
        Task {
            do {
                try backupService.deleteBackup(named: backup.name)
                await MainActor.run {
                    loadBackups()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossible de supprimer la sauvegarde : \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)
    }
}

struct BackupRow: View {
    let backup: BackupInfo
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(backup.name)
                    .font(.headline)
                Text(DateFormatter.localizedString(from: backup.creationDate, dateStyle: .medium, timeStyle: .medium))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: onRestore) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        BackupView()
            .environmentObject(ContactsManager())
            .environmentObject(ProjectManager(activityLogService: ActivityLogService()))
            .environmentObject(InvoiceManager())
    }
} 