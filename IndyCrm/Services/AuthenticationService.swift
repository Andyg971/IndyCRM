import Foundation
import SwiftUI
import AuthenticationServices

/// Service gérant l'authentification des utilisateurs
@MainActor
public class AuthenticationService: ObservableObject {
    // MARK: - Published Properties
    @Published public var isAuthenticated = false
    @Published public var currentUser: User?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // Service Apple Auth
    private lazy var appleAuthService = AppleAuthenticationService(authService: self)
    
    // MARK: - Initialization
    public init() {
        print("🔐 Initialisation du service d'authentification")
        restoreSession()
    }
    
    // MARK: - Models
    public struct User: Codable {
        public let id: String
        public let name: String?
        public let email: String?
        public let authProvider: AuthProvider
        public let profileImageURL: URL?
        
        public init(id: String, name: String?, email: String?, authProvider: AuthProvider, profileImageURL: URL?) {
            self.id = id
            self.name = name
            self.email = email
            self.authProvider = authProvider
            self.profileImageURL = profileImageURL
        }
    }
    
    public enum AuthProvider: String, Codable {
        case email
        case apple
        case anonymous
    }
    
    // MARK: - Authentication Methods
    
    /// Authentification par email
    /// - Parameters:
    ///   - email: L'adresse email de l'utilisateur
    ///   - password: Le mot de passe de l'utilisateur
    public func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Validation de l'email
        guard !email.isEmpty else {
            errorMessage = "Veuillez saisir une adresse email"
            isLoading = false
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Format d'email invalide"
            isLoading = false
            return
        }
        
        // Validation du mot de passe
        guard !password.isEmpty else {
            errorMessage = "Veuillez saisir un mot de passe"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères"
            isLoading = false
            return
        }
        
        do {
            // Simuler un délai réseau
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let user = User(
                id: UUID().uuidString,
                name: email.components(separatedBy: "@").first,
                email: email,
                authProvider: .email,
                profileImageURL: nil
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.saveUser(user)
            
        } catch {
            errorMessage = "Erreur de connexion: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Authentification avec Apple
    public func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        // Déléguer l'authentification au service Apple
        appleAuthService.signInWithApple()
    }
    
    /// Prépare une demande d'authentification Apple et configure le nonce
    public func prepareAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        appleAuthService.configureRequest(request)
    }
    
    /// Traite le résultat de l'authentification Apple
    public func processAppleSignIn(credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        errorMessage = nil
        
        // Déléguer le traitement au service Apple
        appleAuthService.processCredential(credential)
    }
    
    /// Définir l'utilisateur authentifié (appelé par AppleAuthenticationService)
    public func setAuthenticatedUser(id: String?, name: String?, email: String?) {
        guard let id = id else {
            errorMessage = "ID utilisateur manquant"
            isLoading = false
            return
        }
        
        let user = User(
            id: id,
            name: name,
            email: email,
            authProvider: .apple,
            profileImageURL: nil
        )
        
        self.currentUser = user
        self.isAuthenticated = true
        self.saveUser(user)
        isLoading = false
    }
    
    /// Déconnexion de l'utilisateur
    public func signOut() {
        // Si l'utilisateur est connecté avec Apple, déconnecter également le service Apple
        if currentUser?.authProvider == .apple {
            appleAuthService.signOut()
        }
        
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    /// Connexion anonyme
    public func signInAnonymously() {
        isLoading = true
        
        let user = User(
            id: UUID().uuidString,
            name: "Utilisateur Anonyme",
            email: nil,
            authProvider: .anonymous,
            profileImageURL: nil
        )
        
        self.currentUser = user
        self.isAuthenticated = true
        self.saveUser(user)
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    /// Sauvegarde les données de l'utilisateur
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    /// Restaure la session précédente
    private func restoreSession() {
        // Vérifier d'abord si l'utilisateur avait une session Apple
        appleAuthService.loadSavedSession()
        
        // Si pas de session Apple, vérifier les autres méthodes
        if !isAuthenticated {
            if let userData = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }
    
    /// Réessaie la dernière opération
    public func retryLastOperation() async {
        // Pour une future implémentation de réessai
    }
} 