import SwiftUI

struct PrivacyPolicyView: View {
    @State private var policyContent: String = ""
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ScrollView {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Text("Chargement de la politique...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(minHeight: 300)
            } else if let error = error {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Impossible de charger la politique de confidentialité")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: loadPolicy) {
                        Text("Réessayer")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding()
                .frame(minHeight: 300)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(policyContent)
                        .padding()
                }
            }
        }
        .navigationTitle("Politique de confidentialité")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPolicy)
    }
    
    private func loadPolicy() {
        isLoading = true
        error = nil
        
        // Essayer de charger le fichier markdown
        if let fileURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "md") {
            do {
                policyContent = try String(contentsOf: fileURL, encoding: .utf8)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        } else {
            // Utiliser une version intégrée de secours si le fichier n'est pas trouvé
            policyContent = """
            # Politique de Confidentialité - IndyCRM
            
            **Date d'entrée en vigueur :** 1er Juin 2023
            
            ## 1. Introduction
            
            Bienvenue dans IndyCRM. Nous nous engageons à protéger la confidentialité et la sécurité de vos informations personnelles. Cette politique de confidentialité explique comment nous collectons, utilisons, partageons et protégeons vos données lorsque vous utilisez notre application mobile IndyCRM.
            
            ## 2. Données que nous collectons
            
            ### 2.1 Données fournies par l'utilisateur
            
            - Informations de compte
            - Informations d'identification Apple
            - Données de contacts et de clients
            - Données de projets
            - Données de facturation
            
            ### 2.2 Données collectées automatiquement
            
            - Données d'utilisation
            - Données de l'appareil
            - Journaux d'erreurs
            
            ## 3. Protection de vos données
            
            Toutes les données sensibles sont chiffrées à l'aide d'algorithmes de chiffrement standard de l'industrie (AES-256).
            
            Pour une version complète de notre politique, veuillez consulter notre site web.
            """
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
} 