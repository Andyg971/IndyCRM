import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var projectManager: ProjectManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sécurité et Conformité".localized)) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Politique de confidentialité".localized)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: LanguageSettingsView()) {
                        HStack {
                            Image(systemName: "globe")
                            Text("settings.language".localized)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: BackupView()) {
                        HStack {
                            Image(systemName: "arrow.clockwise.icloud")
                            Text("settings.backup".localized)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: ThemeSettingsView()) {
                        HStack {
                            Image(systemName: "paintbrush")
                            Text("settings.theme".localized)
                        }
                    }
                }
            }
            .navigationTitle("settings.title".localized)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProjectManager())
} 