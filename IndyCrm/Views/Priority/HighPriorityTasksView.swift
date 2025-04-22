import SwiftUI

struct HighPriorityTasksView: View {
    @ObservedObject var projectManager: ProjectManager
    @State private var selectedTaskType = 0
    @State private var showingAppleAuthInfo = false
    @State private var showingDataPersistenceInfo = false
    @State private var showingEncryptionInfo = false
    @State private var showingPrivacyPolicyInfo = false
    @State private var showingProjectSelector = false
    @State private var selectedTaskIndex = 0
    
    private let highPriorityTasks = PriorityTasksHelper.createHighPriorityTasks()
    
    var body: some View {
        List {
            Section {
                Picker("Catégorie", selection: $selectedTaskType) {
                    Text("Toutes").tag(0)
                    Text("À faire").tag(1)
                    Text("En cours").tag(2)
                    Text("Terminées").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Tâches prioritaires du système")) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ces tâches ont été identifiées comme hautement prioritaires pour assurer la sécurité et la conformité de votre application.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                
                highPriorityTaskCard(
                    title: "Authentification avec Apple",
                    description: "Intégrer la fonctionnalité Sign in with Apple",
                    icon: "apple.logo",
                    color: .blue,
                    showInfoAction: { showingAppleAuthInfo = true }
                )
                
                highPriorityTaskCard(
                    title: "Persistance des données",
                    description: "Implémenter la sauvegarde locale des données",
                    icon: "externaldrive.fill",
                    color: .purple,
                    showInfoAction: { showingDataPersistenceInfo = true }
                )
                
                highPriorityTaskCard(
                    title: "Chiffrement des données",
                    description: "Sécuriser les informations sensibles",
                    icon: "lock.shield.fill",
                    color: .green,
                    showInfoAction: { showingEncryptionInfo = true }
                )
                
                highPriorityTaskCard(
                    title: "Politique de confidentialité",
                    description: "Créer une politique conforme au RGPD",
                    icon: "doc.text.fill",
                    color: .orange,
                    showInfoAction: { showingPrivacyPolicyInfo = true }
                )
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Statut global des tâches prioritaires")
                        .font(.headline)
                    
                    ProgressView(value: getCompletionRatio())
                        .tint(.indigo)
                    
                    Text("\(getCompletedCount()) sur 4 tâches complétées")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Tâches prioritaires")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAppleAuthInfo) {
            taskDetailSheet(index: 0)
        }
        .sheet(isPresented: $showingDataPersistenceInfo) {
            taskDetailSheet(index: 1)
        }
        .sheet(isPresented: $showingEncryptionInfo) {
            taskDetailSheet(index: 2)
        }
        .sheet(isPresented: $showingPrivacyPolicyInfo) {
            taskDetailSheet(index: 3)
        }
    }
    
    @ViewBuilder
    private func highPriorityTaskCard(
        title: String,
        description: String,
        icon: String,
        color: Color,
        showInfoAction: @escaping () -> Void
    ) -> some View {
        VStack {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: showInfoAction) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.indigo)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            HStack {
                Text("Statut: \(getStatus(for: title))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if getStatus(for: title) == "Terminé" {
                    Label("Complété", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func taskDetailSheet(index: Int) -> some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(highPriorityTasks[index].title)
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            Label("Haute priorité", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                            
                            Spacer()
                            
                            Label("\(Int(highPriorityTasks[index].estimatedHours ?? 0))h estimées", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Text(highPriorityTasks[index].description)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pourquoi c'est important")
                            .font(.headline)
                        
                        Text(getImportanceText(for: index))
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment implémenter")
                            .font(.headline)
                        
                        Text(getImplementationText(for: index))
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Détails de la tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter à un projet") {
                        selectedTaskIndex = index
                        showingProjectSelector = true
                    }
                    .foregroundStyle(.indigo)
                }
            }
            .sheet(isPresented: $showingProjectSelector) {
                ProjectSelectorView(
                    projectManager: projectManager,
                    onSelect: { project in
                        PriorityTasksHelper.addSpecificHighPriorityTask(
                            taskIndex: selectedTaskIndex,
                            to: project,
                            projectManager: projectManager
                        )
                    }
                )
            }
        }
    }
    
    private func getStatus(for taskTitle: String) -> String {
        let allProjects = projectManager.projects
        
        switch taskTitle {
        case "Authentification avec Apple":
            if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("Sign in with Apple") && $0.isCompleted 
                })
            }) {
                return "Terminé"
            } else if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("Sign in with Apple") && !$0.isCompleted 
                })
            }) {
                return "En cours"
            }
            
        case "Persistance des données":
            if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("persistance") && $0.isCompleted 
                })
            }) {
                return "Terminé"
            } else if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("persistance") && !$0.isCompleted 
                })
            }) {
                return "En cours"
            }
            
        case "Chiffrement des données":
            if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("chiffrement") && $0.isCompleted 
                })
            }) {
                return "Terminé"
            } else if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("chiffrement") && !$0.isCompleted 
                })
            }) {
                return "En cours"
            }
            
        case "Politique de confidentialité":
            if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("politique") && $0.isCompleted 
                })
            }) {
                return "Terminé"
            } else if allProjects.contains(where: { project in
                project.tasks.contains(where: { 
                    $0.title.contains("politique") && !$0.isCompleted 
                })
            }) {
                return "En cours"
            }
            
        default:
            break
        }
        
        return "À faire"
    }
    
    private func getCompletedCount() -> Int {
        var count = 0
        
        if getStatus(for: "Authentification avec Apple") == "Terminé" { count += 1 }
        if getStatus(for: "Persistance des données") == "Terminé" { count += 1 }
        if getStatus(for: "Chiffrement des données") == "Terminé" { count += 1 }
        if getStatus(for: "Politique de confidentialité") == "Terminé" { count += 1 }
        
        return count
    }
    
    private func getCompletionRatio() -> Double {
        Double(getCompletedCount()) / 4.0
    }
    
    private func getImportanceText(for index: Int) -> String {
        switch index {
        case 0:
            return "L'authentification avec Apple offre une méthode sécurisée et simple pour vos utilisateurs de se connecter sans avoir à créer un compte spécifique. Cela améliore la sécurité, la confidentialité et l'expérience utilisateur, tout en étant conforme aux exigences d'Apple pour les applications utilisant des services d'authentification tiers."
            
        case 1:
            return "Une persistance des données robuste est essentielle pour garantir que les informations des utilisateurs sont sauvegardées correctement et peuvent être récupérées même après un redémarrage de l'application. Cela améliore l'expérience utilisateur et évite la perte de données importantes."
            
        case 2:
            return "Le chiffrement des données sensibles est crucial pour protéger les informations confidentielles des clients et des projets. C'est une exigence légale dans de nombreuses juridictions et une pratique essentielle pour maintenir la confiance des utilisateurs."
            
        case 3:
            return "Une politique de confidentialité claire et complète est légalement requise pour expliquer comment vous collectez, utilisez et protégez les données des utilisateurs. C'est obligatoire pour les applications sur l'App Store et essentiel pour la conformité aux réglementations comme le RGPD."
            
        default:
            return ""
        }
    }
    
    private func getImplementationText(for index: Int) -> String {
        switch index {
        case 0:
            return "1. Configurez votre application dans App Store Connect\n2. Ajoutez la capacité 'Sign in with Apple' dans votre projet Xcode\n3. Importez AuthenticationServices\n4. Implémentez ASAuthorizationControllerDelegate\n5. Créez un bouton Sign in with Apple\n6. Gérez les jetons d'authentification"
            
        case 1:
            return "1. Choisissez une solution de persistance (CoreData recommandé)\n2. Créez un modèle de données\n3. Implémentez des méthodes de sauvegarde dans les gestionnaires\n4. Ajoutez une gestion d'erreurs robuste\n5. Testez la récupération des données"
            
        case 2:
            return "1. Utilisez la Data Protection API d'iOS\n2. Chiffrez les données sensibles avec CryptoKit\n3. Stockez les clés de manière sécurisée dans le Keychain\n4. Appliquez des contraintes de sécurité aux fichiers\n5. Testez le chiffrement et le déchiffrement"
            
        case 3:
            return "1. Identifiez les données que vous collectez\n2. Expliquez comment vous les utilisez\n3. Détaillez les mesures de protection\n4. Informez sur les droits des utilisateurs\n5. Publiez la politique sur un site web accessible\n6. Ajoutez un lien vers la politique dans votre application"
            
        default:
            return ""
        }
    }
}

struct ProjectSelectorView: View {
    @ObservedObject var projectManager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    var onSelect: (Project) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projectManager.projects) { project in
                    Button(action: {
                        onSelect(project)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(project.name)
                                    .font(.headline)
                                
                                Text("Statut: \(project.status.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Sélectionner un projet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        HighPriorityTasksView(projectManager: ProjectManager())
    }
} 