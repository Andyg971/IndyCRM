////
//  IndyCrmApp.swift
//  IndyCrm
//
//  Created by Grava Andy on 17/02/2025.
//

import SwiftUI
import Contacts
import ContactsUI
import UniformTypeIdentifiers

@main
struct IndyCrmApp: App {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var contactsManager = ContactsManager()
    @StateObject private var projectManager = ProjectManager(activityLogService: ActivityLogService())
    @StateObject private var invoiceManager = InvoiceManager()
    @StateObject private var alertService = AlertService()
    @StateObject private var helpService = HelpService()
    @StateObject private var messagingService = MessagingService()
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(contactsManager)
                    .environmentObject(projectManager)
                    .environmentObject(invoiceManager)
                    .environmentObject(alertService)
                    .environmentObject(helpService)
                    .environmentObject(messagingService)
            } else {
                WelcomeView(authService: authService)
                    .environmentObject(helpService)
            }
        }
    }
}

struct ContactExporterView: View {
    var body: some View {
        Text("Contact Exporter View")
    }
}

struct ContactPicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, CNContactPickerDelegate {
        var parent: ContactPicker

        init(parent: ContactPicker) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.didSelectContacts(contacts)
        }
    }

    var didSelectContacts: ([CNContact]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
