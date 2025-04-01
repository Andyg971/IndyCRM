import SwiftUI

struct ContactRowView: View {
    let contact: Contact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(contact.fullName)
                    .font(.headline)
                Spacer()
                Text(contact.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !contact.organization.isEmpty {
                Text(contact.organization)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.secondary)
                Text(contact.email)
                    .font(.caption)
            }
            
            if !contact.phone.isEmpty {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.secondary)
                    Text(contact.phone)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactRowView(contact: Contact(
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        phone: "+33 6 12 34 56 78",
        type: .client,
        employmentStatus: .freelance,
        notes: "",
        rates: [],
        organization: "ACME Corp"
    ))
    .padding()
} 