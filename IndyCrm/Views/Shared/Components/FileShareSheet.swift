import SwiftUI
import UIKit

public struct FileShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    public init(items: [Any]) {
        self.items = items
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 