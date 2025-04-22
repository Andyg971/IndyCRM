import SwiftUI
import AuthenticationServices
import CryptoKit

class AppleAuthenticationService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userID: String?
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var errorMessage: String?
    
    // État pour le challenge de sécurité actuel
    private var currentNonce: String?
    
    // Référence à AuthenticationService pour la coordination
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
        super.init()
    }
    
    // MARK: - Sign in with Apple
    
    func signInWithApple() {
        // Générer un nonce aléatoire pour chaque tentative de connexion
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Créer une requête d'autorisation Apple
        let request = ASAuthorizationAppleIDProvider().createRequest()
        // Demander le nom et l'email de l'utilisateur
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // Créer un contrôleur d'autorisation
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // Configure une requête avec le nonce pour la sécurité
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    // Traite les informations d'identification après une authentification réussie
    func processCredential(_ credential: ASAuthorizationAppleIDCredential) {
        guard currentNonce != nil else {
            DispatchQueue.main.async {
                self.errorMessage = "Erreur de sécurité: nonce manquant"
                self.authService.errorMessage = "Erreur de sécurité lors de l'authentification Apple"
                self.authService.isLoading = false
            }
            return
        }
        
        // Vérification du nonce (dans une implémentation complète, vous vérifieriez aussi avec le backend)
        
        // Récupérer les informations d'identité
        let userID = credential.user
        var fullName: String?
        if let firstName = credential.fullName?.givenName,
           let lastName = credential.fullName?.familyName {
            fullName = "\(firstName) \(lastName)"
        }
        let email = credential.email
        
        // Sauvegarder la session utilisateur
        saveUserSession(userID: userID, fullName: fullName, email: email)
    }
    
    // MARK: - Gestion du token et persistence
    
    func saveUserSession(userID: String, fullName: String?, email: String?) {
        // Sauvegarder les informations d'utilisateur dans le keychain ou UserDefaults
        UserDefaults.standard.set(userID, forKey: "appleUserID")
        UserDefaults.standard.set(fullName, forKey: "appleUserName")
        UserDefaults.standard.set(email, forKey: "appleUserEmail")
        UserDefaults.standard.set(true, forKey: "isAppleAuthenticated")
        
        // Mettre à jour l'état
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.userID = userID
            self.userName = fullName
            self.userEmail = email
            
            // Informer le service d'authentification principal
            self.authService.setAuthenticatedUser(id: userID, name: fullName, email: email)
        }
    }
    
    func loadSavedSession() {
        // Vérifier si l'utilisateur a déjà une session
        if UserDefaults.standard.bool(forKey: "isAppleAuthenticated") {
            let userID = UserDefaults.standard.string(forKey: "appleUserID")
            let userName = UserDefaults.standard.string(forKey: "appleUserName")
            let userEmail = UserDefaults.standard.string(forKey: "appleUserEmail")
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.userID = userID
                self.userName = userName
                self.userEmail = userEmail
                
                // Informer le service d'authentification principal
                self.authService.setAuthenticatedUser(id: userID, name: userName, email: userEmail)
            }
        }
    }
    
    func signOut() {
        // Effacer les données de session
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.set(false, forKey: "isAppleAuthenticated")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userID = nil
            self.userName = nil
            self.userEmail = nil
            
            // Informer le service d'authentification principal
            self.authService.signOut()
        }
    }
    
    // MARK: - Fonctions utilitaires
    
    // Génère une chaîne aléatoire utilisée pour le nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Erreur lors de la génération du nonce aléatoire: \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // Convertit une chaîne en son hash SHA256 pour la sécurité
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Extensions pour l'implémentation de ASAuthorizationControllerDelegate

extension AppleAuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Gérer le succès de l'authentification
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            processCredential(appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Gérer les erreurs d'authentification
        let errorDescription: String
        
        switch (error as NSError).code {
        case ASAuthorizationError.canceled.rawValue:
            errorDescription = "L'autorisation a été annulée"
        case ASAuthorizationError.failed.rawValue:
            errorDescription = "L'autorisation a échoué"
        case ASAuthorizationError.invalidResponse.rawValue:
            errorDescription = "La réponse est invalide"
        case ASAuthorizationError.notHandled.rawValue:
            errorDescription = "La demande n'a pas été traitée"
        case ASAuthorizationError.unknown.rawValue:
            errorDescription = "Une erreur inconnue s'est produite"
        default:
            errorDescription = "Une erreur inconnue s'est produite: \(error.localizedDescription)"
        }
        
        DispatchQueue.main.async {
            self.errorMessage = errorDescription
        }
    }
}

// Extension pour fournir le contexte de présentation
extension AppleAuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // On doit fournir la fenêtre principale pour l'affichage
        // Dans une application SwiftUI moderne, on utilise UIApplication.shared.connectedScenes
        let windowScene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first
        
        return windowScene?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
} 
