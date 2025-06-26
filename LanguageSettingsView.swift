import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("language".localized)) {
                Picker("", selection: $languageManager.currentLanguage) {
                    Text("french".localized)
                        .tag(LanguageManager.Language.french)
                    Text("english".localized)
                        .tag(LanguageManager.Language.english)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("settings".localized)
    }
} 