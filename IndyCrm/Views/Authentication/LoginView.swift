import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Logo et titre
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.indigo)
                        .padding(.top, 50)
                    
                    Text("IndyCRM")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)
                    
                    Text("La gestion de clients pour les indépendants")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 30)
                    
                    // Formulaire de connexion
                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Mot de passe", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Button(action: {
                            Task {
                                await authService.signInWithEmail(email: email, password: password)
                            }
                        }) {
                            Text("Se connecter")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.indigo)
                                .cornerRadius(10)
                        }
                        .disabled(authService.isLoading)
                        
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Ou
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                        
                        Text("OU")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // Bouton Apple Sign In
                    VStack(spacing: 15) {
                        NativeAppleSignInButton(onRequest: {
                            authService.signInWithApple()
                        })
                        .frame(height: 50)
                        .padding(.horizontal)
                        
                        Button(action: {
                            authService.signInAnonymously()
                        }) {
                            Text("Continuer sans compte")
                                .foregroundColor(.indigo)
                                .font(.subheadline)
                                .underline()
                        }
                    }
                    
                    Spacer()
                    
                    // Notes de bas de page
                    VStack(spacing: 5) {
                        Text("En vous connectant, vous acceptez nos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 5) {
                            Button(action: {
                                showingAlert = true
                            }) {
                                Text("Conditions d'utilisation")
                                    .font(.caption)
                                    .foregroundColor(.indigo)
                                    .underline()
                            }
                            
                            Text("et")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingAlert = true
                            }) {
                                Text("Politique de confidentialité")
                                    .font(.caption)
                                    .foregroundColor(.indigo)
                                    .underline()
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Information"),
                    message: Text("Ces documents seront disponibles prochainement."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
} 