import Foundation
import SwiftUI

/// Service gérant l'authentification des utilisateurs
@MainActor
public class AuthenticationService: ObservableObject {
    // MARK: - Published Properties
    @Published public var isAuthenticated = false
    @Published public var currentUser: User?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
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
    
    /// Déconnexion de l'utilisateur
    public func signOut() {
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
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    /// Réessaie la dernière opération
    public func retryLastOperation() async {
        // Pour une future implémentation de réessai
    }
} 