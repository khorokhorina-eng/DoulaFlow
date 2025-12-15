import SwiftUI

struct ProfilePreviewScreen: View {
    let profile: DoulaProfile

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.fullName.isEmpty ? "Your Name" : profile.fullName)
                        .font(.title2.bold())
                    if !profile.professionalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(profile.professionalTitle)
                            .foregroundStyle(.secondary)
                    }
                    if !profile.experienceSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(profile.experienceSummary)
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 6)
            }

            if !profile.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Bio") {
                    Text(profile.bio)
                }
            }

            Section("Contact") {
                if !profile.contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Email") {
                        Text(profile.contactEmail)
                    }
                }
                if !profile.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Phone") {
                        Text(profile.phoneNumber)
                    }
                }
                if let website = profile.website {
                    LabeledContent("Website") {
                        Text(website.absoluteString)
                    }
                }
            }

            if !profile.certifications.filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).isEmpty {
                Section("Certifications") {
                    ForEach(profile.certifications.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { cert in
                        Text(cert)
                    }
                }
            }
        }
        .navigationTitle("Preview")
    }
}

