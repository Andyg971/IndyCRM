import SwiftUI

public struct ModernProgressBar: View {
    let progress: Double
    let isPaused: Bool
    let height: CGFloat
    
    private var progressColor: LinearGradient {
        if isPaused {
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        let normalizedProgress = min(max(progress, 0), 1)
        switch normalizedProgress {
        case 0..<0.33:
            return LinearGradient(
                colors: [.red.opacity(0.8), .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 0.33..<0.66:
            return LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [.green.opacity(0.8), .green],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fond de la barre
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                
                // Barre de progression
                RoundedRectangle(cornerRadius: 12)
                    .fill(progressColor)
                    .frame(width: max(min(geometry.size.width * progress, geometry.size.width), 0))
                    .animation(.spring(response: 0.3), value: progress)
                    .overlay(
                        Group {
                            if isPaused {
                                StripedPattern()
                                    .mask(
                                        RoundedRectangle(cornerRadius: 12)
                                    )
                            }
                        }
                    )
                
                // Pourcentage
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    
                    if isPaused {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.none, value: progress)
            }
        }
        .frame(height: height)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
    }
    
    public init(progress: Double, isPaused: Bool = false, height: CGFloat = 8) {
        self.progress = min(max(progress, 0), 1)
        self.isPaused = isPaused
        self.height = height
    }
}

// Motif rayé pour l'état en pause
private struct StripedPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let stripeWidth: CGFloat = 10
                let spacing: CGFloat = 10
                let _: CGFloat = .pi / 4 // 45 degrés
                
                for x in stride(from: -geometry.size.width, through: geometry.size.width * 2, by: spacing + stripeWidth) {
                    let startPoint = CGPoint(x: x, y: -geometry.size.height)
                    let endPoint = CGPoint(x: x + geometry.size.height * 2, y: geometry.size.height * 2)
                    
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                    path.addLine(to: CGPoint(x: endPoint.x + stripeWidth, y: endPoint.y))
                    path.addLine(to: CGPoint(x: startPoint.x + stripeWidth, y: startPoint.y))
                    path.closeSubpath()
                }
            }
            .fill(Color.white.opacity(0.2))
            .rotationEffect(.radians(.pi / 4))
        }
    }
} 
