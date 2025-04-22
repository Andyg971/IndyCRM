import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    var onRequest: () -> Void
    
    var body: some View {
        Button(action: onRequest) {
            HStack {
                Image(systemName: "apple.logo")
                    .font(.title3)
                Text("Se connecter avec Apple")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .cornerRadius(10)
        }
    }
}

// Version qui utilise le bouton Apple natif
struct NativeAppleSignInButton: UIViewRepresentable {
    var onRequest: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleRequest), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest)
    }
    
    class Coordinator: NSObject {
        var onRequest: () -> Void
        
        init(onRequest: @escaping () -> Void) {
            self.onRequest = onRequest
        }
        
        @objc func handleRequest() {
            onRequest()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppleSignInButton(onRequest: {})
            .padding()
        
        NativeAppleSignInButton(onRequest: {})
            .frame(height: 50)
            .padding()
    }
} 