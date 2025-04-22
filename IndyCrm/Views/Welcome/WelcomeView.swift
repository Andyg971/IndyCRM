import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @ObservedObject var authService: AuthenticationService
    @EnvironmentObject var helpService: HelpService
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var animateLogo = false
    @State private var showForm = false
    
    var body: some View {
        ZStack {
            // Fond blanc simple
            Color.white.ignoresSafeArea()
            
            // Contenu principal
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 40)
                    
                    // Logo et titre
                    LogoView(animate: $animateLogo, isLoading: authService.isLoading)
                        .padding(.bottom, 20)
                    
                    // Sous-titre
                    SubtitleView()
                        .opacity(showForm ? 1 : 0)
                        .offset(y: showForm ? 0 : 20)
                    
                    // Formulaire de connexion
                    LoginFormView(
                        email: $email,
                        password: $password,
                        isPasswordVisible: $isPasswordVisible,
                        onLogin: {
                            Task {
                                await authService.signInWithEmail(email: email, password: password)
                            }
                        }
                    )
                    .environmentObject(authService)
                    .padding(.horizontal)
                    .opacity(showForm ? 1 : 0)
                    .offset(y: showForm ? 0 : 40)
                }
                .padding(.horizontal)
            }
            
            // Overlay de chargement
            if authService.isLoading {
                LoadingOverlayView()
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateLogo = true
            }
            
            withAnimation(.easeOut.delay(0.3)) {
                showForm = true
            }
        }
        .accessibilityIdentifier("welcomeView")
    }
}

// Composants modulaires simplifiés
struct BackgroundView: View {
    var body: some View {
        Color.white.ignoresSafeArea()
    }
}

struct LogoView: View {
    @Binding var animate: Bool
    var isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Logo simplifié
            Image("IndyLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .scaleEffect(animate ? 1 : 0.5)
            
            // Titre simplifié
            Text("IndyCRM")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .opacity(animate ? 1 : 0)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

struct SubtitleView: View {
    var body: some View {
        Text("La gestion de votre entreprise\nn'a jamais été aussi simple")
            .font(.title3.weight(.regular))
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .padding(.horizontal)
            .accessibilityIdentifier("subtitle")
    }
}

struct LoginFormView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isPasswordVisible: Bool
    var onLogin: () -> Void
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        VStack(spacing: 24) {
            // Champs de connexion
            VStack(spacing: 16) {
                // Email
                SimpleTextFieldWithIcon(
                    iconName: "envelope",
                    placeholder: "Email",
                    text: $email,
                    isFocused: $isEmailFocused
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                
                // Mot de passe
                SimplePasswordFieldWithIcon(
                    password: $password,
                    isVisible: $isPasswordVisible,
                    isFocused: $isPasswordFocused
                )
            }
            
            // Bouton de connexion
            Button(action: onLogin) {
                Text("Se connecter")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
            
            // Séparateur
            HStack {
                VStack { Divider() }
                Text("ou")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                VStack { Divider() }
            }
            .padding(.vertical, 8)
            
            // Bouton Apple
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                    // Permettre au service AppleAuthenticationService de configurer le nonce
                    authService.prepareAppleSignIn(request: request)
                },
                onCompletion: { result in
                    // Traiter directement le résultat d'authentification
                    switch result {
                    case .success(let authorization):
                        // Passer les informations d'identification au service
                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            authService.processAppleSignIn(credential: appleIDCredential)
                        }
                    case .failure(let error):
                        // Afficher l'erreur à l'utilisateur
                        authService.errorMessage = error.localizedDescription
                    }
                }
            )
            .frame(height: 50)
            .signInWithAppleButtonStyle(.black)
            .cornerRadius(8)
            .accessibilityIdentifier("appleSignInButton")
        }
        .accessibilityIdentifier("loginForm")
    }
}

struct SimpleTextFieldWithIcon: View {
    var iconName: String
    var placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray)
                .frame(width: 24)
                .padding(.leading, 8)
            
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                isFocused = editing
            })
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SimplePasswordFieldWithIcon: View {
    @Binding var password: String
    @Binding var isVisible: Bool
    @Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.gray)
                .frame(width: 24)
                .padding(.leading, 8)
            
            if isVisible {
                TextField("Mot de passe", text: $password, onEditingChanged: { editing in
                    isFocused = editing
                })
                .padding()
            } else {
                SecureField("Mot de passe", text: $password)
                    .padding()
                    .onChange(of: password) { oldValue, newValue in
                        isFocused = true
                    }
            }
            
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct LoadingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Connexion en cours...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
        }
        .transition(.opacity)
        .accessibilityIdentifier("loadingOverlay")
    }
}

// Style de bouton simple
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// Pour la prévisualisation
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(authService: AuthenticationService())
            .environmentObject(HelpService())
            .previewDisplayName("Welcome Screen")
    }
} 