import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @ObservedObject var authService: AuthenticationService
    @EnvironmentObject var helpService: HelpService
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            // Arrière-plan avec dégradé
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.1),
                    Color.white,
                    Color.indigo.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Contenu principal
            ScrollView {
                VStack(spacing: 25) {
                    // Logo et titre
                    VStack(spacing: 25) {
                        // Logo animé
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .indigo.opacity(0.3), radius: 10, y: 5)
                            .rotation3DEffect(.degrees(authService.isLoading ? 360 : 0),
                                           axis: (x: 0, y: 1, z: 0))
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false),
                                     value: authService.isLoading)
                        
                        Text("IndyCRM")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    // Sous-titre
                    Text("Gérez vos contacts et projets\nen toute simplicité")
                        .font(.title2.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    // Formulaire de connexion
                    VStack(spacing: 20) {
                        // Email
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.indigo)
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        
                        // Mot de passe
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.indigo)
                            if isPasswordVisible {
                                TextField("Mot de passe", text: $password)
                            } else {
                                SecureField("Mot de passe", text: $password)
                            }
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        
                        // Bouton de connexion
                        Button {
                            Task {
                                await authService.signInWithEmail(email: email, password: password)
                            }
                        } label: {
                            HStack {
                                Text("Se connecter")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.indigo, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .indigo.opacity(0.3), radius: 5, y: 2)
                        }
                        
                        // Séparateur
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("ou")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Bouton sans inscription
                    Button {
                        authService.signInAnonymously()
                    } label: {
                        Text("Continuer sans inscription")
                            .font(.headline)
                            .padding()
                            .foregroundStyle(.indigo)
                            .background(
                                Capsule()
                                    .stroke(Color.indigo, lineWidth: 2)
                            )
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal)
            }
            
            // Overlay de chargement
            if authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    )
            }
        }
        .alert("Erreur de connexion", isPresented: .init(
            get: { authService.errorMessage != nil },
            set: { if !$0 { authService.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = authService.errorMessage {
                Text(error)
            }
        }
    }
}

// Pour la prévisualisation
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(authService: AuthenticationService())
    }
} 