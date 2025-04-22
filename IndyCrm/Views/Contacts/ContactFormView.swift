import SwiftUI

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    let contactsManager: ContactsManager
    let projectManager: ProjectManager
    var editingContact: Contact?
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var type: ContactType = .client
    @State private var employmentStatus: EmploymentStatus = .freelance
    @State private var notes = ""
    @State private var rates: [Rate] = []
    @State private var organization = ""
    @State private var showingAddRate = false
    @State private var showingDeleteAlert = false
    @State private var showingCancelAlert = false
    @State private var hasChanges = false
    @State private var emailError: String?
    @State private var phoneError: String?
    @FocusState private var focusedField: Field?
    
    private var isEditing: Bool { editingContact != nil }
    
    enum Field {
        case firstName, lastName, email, phone, organization, notes
    }
    
    var body: some View {
        Form {
            Section(header: Text("Informations personnelles")) {
                TextField("Prénom", text: $firstName)
                    .focused($focusedField, equals: .firstName)
                    .textContentType(.givenName)
                    .onChange(of: firstName, initial: false) { oldValue, newValue in 
                        hasChanges = true 
                    }
                
                TextField("Nom", text: $lastName)
                    .focused($focusedField, equals: .lastName)
                    .textContentType(.familyName)
                    .onChange(of: lastName, initial: false) { oldValue, newValue in 
                        hasChanges = true 
                    }
                
                TextField("Email", text: $email)
                    .focused($focusedField, equals: .email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .onChange(of: email, initial: false) { oldValue, newValue in 
                        hasChanges = true
                        if !newValue.isEmpty && !newValue.isValidEmail {
                            emailError = "Format d'email invalide"
                        } else {
                            emailError = nil
                        }
                    }
                    .overlay(
                        Group {
                            if let error = emailError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 30)
                            }
                        }
                    )
                
                TextField("Téléphone", text: $phone)
                    .focused($focusedField, equals: .phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .onChange(of: phone, initial: false) { oldValue, newValue in
                        hasChanges = true
                        if !newValue.isEmpty && !newValue.isValidPhoneNumber {
                            phoneError = "Format de téléphone invalide"
                        } else {
                            phoneError = nil
                        }
                    }
                    .overlay(
                        Group {
                            if let error = phoneError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 30)
                            }
                        }
                    )
                
                TextField("Organisation", text: $organization)
                    .focused($focusedField, equals: .organization)
                    .textContentType(.organizationName)
                    .onChange(of: organization, initial: false) { oldValue, newValue in 
                        hasChanges = true 
                    }
            }
            
            Section(header: Text("Statut")) {
                Picker("Type de contact", selection: $type) {
                    ForEach(ContactType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                .onChange(of: type, initial: false) { oldValue, newValue in 
                    hasChanges = true 
                }
                
                Picker("Statut professionnel", selection: $employmentStatus) {
                    ForEach(EmploymentStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .onChange(of: employmentStatus, initial: false) { oldValue, newValue in 
                    hasChanges = true 
                }
            }
            
            Section(header: HStack {
                Text("Tarifs")
                Spacer()
                Button(action: { showingAddRate = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }) {
                if rates.isEmpty {
                    Text("Aucun tarif")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(rates) { rate in
                        RateRow(rate: rate)
                    }
                    .onDelete { indexSet in
                        rates.remove(atOffsets: indexSet)
                        hasChanges = true
                    }
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .focused($focusedField, equals: .notes)
                    .frame(minHeight: 100)
                    .onChange(of: notes, initial: false) { oldValue, newValue in 
                        hasChanges = true 
                    }
            }
            
            if isEditing {
                Section {
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.3)) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .symbolEffect(.bounce, value: showingDeleteAlert)
                            Text("Supprimer le contact")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Modifier le contact" : "Nouveau contact")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Enregistrer" : "Créer") {
                    saveContact()
                }
                .disabled(!isValid || !hasChanges)
                .fontWeight(.bold)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    if hasChanges {
                        showingCancelAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button(action: focusPreviousField) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!hasPreviousField)
                    
                    Button(action: focusNextField) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(!hasNextField)
                    
                    Spacer()
                    
                    Button("Terminé") {
                        focusedField = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRate) {
            NavigationView {
                RateFormView { rate in
                    rates.append(rate)
                    hasChanges = true
                }
            }
        }
        .onAppear {
            setupInitialValues()
            // Focus sur le premier champ si nouveau contact
            if !isEditing {
                focusedField = .firstName
            }
        }
        .alert("Supprimer le contact ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                deleteContact()
            }
        } message: {
            if let contact = editingContact {
                Text("Voulez-vous vraiment supprimer \(contact.fullName) ? Cette action est irréversible.")
            }
        }
        .alert("Annuler les modifications ?", isPresented: $showingCancelAlert) {
            Button("Continuer l'édition", role: .cancel) {}
            Button("Annuler les modifications", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Toutes les modifications non enregistrées seront perdues.")
        }
    }
    
    private func setupInitialValues() {
        if let contact = editingContact {
            firstName = contact.firstName
            lastName = contact.lastName
            email = contact.email
            phone = contact.phone
            type = contact.type
            employmentStatus = contact.employmentStatus
            notes = contact.notes
            rates = contact.rates
            organization = contact.organization
        }
    }
    
    private var isValid: Bool {
        !firstName.trim().isEmpty && 
        !lastName.trim().isEmpty && 
        (email.isEmpty || (email.isValidEmail && emailError == nil)) &&
        (phone.isEmpty || (phone.isValidPhoneNumber && phoneError == nil))
    }
    
    private var hasPreviousField: Bool {
        guard let current = focusedField else { return false }
        let fields: [Field] = [.firstName, .lastName, .email, .phone, .organization, .notes]
        return fields.firstIndex(of: current)! > 0
    }
    
    private var hasNextField: Bool {
        guard let current = focusedField else { return false }
        let fields: [Field] = [.firstName, .lastName, .email, .phone, .organization, .notes]
        return fields.firstIndex(of: current)! < fields.count - 1
    }
    
    private func focusPreviousField() {
        guard let current = focusedField else { return }
        let fields: [Field] = [.firstName, .lastName, .email, .phone, .organization, .notes]
        if let currentIndex = fields.firstIndex(of: current), currentIndex > 0 {
            focusedField = fields[currentIndex - 1]
        }
    }
    
    private func focusNextField() {
        guard let current = focusedField else { return }
        let fields: [Field] = [.firstName, .lastName, .email, .phone, .organization, .notes]
        if let currentIndex = fields.firstIndex(of: current), currentIndex < fields.count - 1 {
            focusedField = fields[currentIndex + 1]
        }
    }
    
    private func saveContact() {
        let contact = Contact(
            id: editingContact?.id ?? UUID(),
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email.trim(),
            phone: phone.trim(),
            type: type,
            employmentStatus: employmentStatus,
            notes: notes.trim(),
            rates: rates,
            organization: organization.trim()
        )
        
        Task {
            if isEditing {
                await contactsManager.updateContact(contact)
            } else {
                await contactsManager.addContact(contact)
            }
        }
        
        dismiss()
    }
    
    private func deleteContact() {
        if let contact = editingContact {
            // Vérifier si le contact est lié à des projets
            let linkedProjects = projectManager.projects.filter { $0.clientId == contact.id }
            
            if !linkedProjects.isEmpty {
                // TODO: Gérer le cas où le contact est lié à des projets
                print("⚠️ Le contact ne peut pas être supprimé car il est lié à \(linkedProjects.count) projet(s)")
                return
            }
            
            Task {
                await contactsManager.deleteContact(contact)
                // Revenir sur le fil principal pour les mises à jour de l'interface utilisateur
                await MainActor.run {
                    // Appliquer l'animation après la suppression réussie
                    withAnimation {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private struct Dependency {
        let type: String
        let name: String
    }
    
    private func checkDependencies(for contact: Contact) -> [Dependency] {
        var dependencies: [Dependency] = []
        
        for project in projectManager.projects {
            if project.clientId == contact.id {
                dependencies.append(Dependency(type: "Client", name: project.name))
            }
            
            for task in project.tasks where task.assignedTo == contact.id {
                dependencies.append(Dependency(type: "Tâche", name: task.title))
            }
            
            for milestone in project.milestones where milestone.assignedToContactId == contact.id {
                dependencies.append(Dependency(type: "Jalon", name: milestone.title))
            }
        }
        
        return dependencies
    }
    
    private func showDependenciesAlert(dependencies: [Dependency]) {
        var message = "Ce contact ne peut pas être supprimé car il est utilisé dans :\n\n"
        for dependency in dependencies {
            message += "- \(dependency.type): \(dependency.name)\n"
        }
        message += "\nVoulez-vous forcer la suppression ? Cette action est irréversible et peut causer des problèmes dans les projets associés."
        
        let alert = UIAlertController(
            title: "Contact utilisé",
            message: message,
            preferredStyle: .alert
        )
        
        // Bouton Annuler
        alert.addAction(UIAlertAction(
            title: "Annuler",
            style: .cancel
        ))
        
        // Bouton de suppression forcée
        alert.addAction(UIAlertAction(
            title: "Forcer la suppression",
            style: .destructive
        ) { _ in
            Task {
                guard let contact = editingContact else { return }
                await contactsManager.deleteContact(contact)
                // Dismiss on main thread AFTER successful deletion
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        dismiss()
                    }
                }
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Cette fonction n'est pas utilisée et fait référence à un type non défini
    // Commenter ou supprimer si elle n'est plus nécessaire
    /*
    private func priorityColor(_ priority: Priority) -> Color {
        priority.statusColor
    }
    */
}

struct RateRow: View {
    let rate: Rate
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(rate.description)
                .font(.headline)
            HStack {
                Text(rate.amount.formatted(.currency(code: "EUR")))
                Text("/ \(rate.unit.rawValue)")
                    .foregroundColor(.secondary)
                if rate.isDefault {
                    Spacer()
                    Text("Par défaut")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }
}

struct RateFormView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Rate) -> Void
    
    @State private var description = ""
    @State private var amount = 0.0
    @State private var unit: RateUnit = .hourly
    @State private var isDefault = false
    
    var body: some View {
        Form {
            Section(header: Text("Détails du tarif")) {
                TextField("Description", text: $description)
                
                HStack {
                    Text("Montant")
                    Spacer()
                    TextField("Montant", value: $amount, format: .currency(code: "EUR"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                Picker("Unité", selection: $unit) {
                    ForEach(RateUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                
                Toggle("Tarif par défaut", isOn: $isDefault)
            }
        }
        .navigationTitle("Nouveau tarif")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Ajouter") {
                    saveRate()
                }
                .disabled(!isValid)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
    }
    
    private var isValid: Bool {
        !description.isEmpty && amount > 0
    }
    
    private func saveRate() {
        let rate = Rate(
            id: UUID(),
            description: description,
            amount: amount,
            unit: unit,
            isDefault: isDefault
        )
        onSave(rate)
        dismiss()
    }
}

private extension String {
    func trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPhoneNumber: Bool {
        let phoneRegex = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s.]?[0-9]{1,3}[-\\s.]?[0-9]{4,6}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
} 