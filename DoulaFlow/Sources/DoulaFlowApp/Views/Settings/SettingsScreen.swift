import SwiftUI

struct SettingsScreen: View {
    let services: AppServices

    var body: some View {
        NavigationStack {
            List {
                Section("Templates") {
                    NavigationLink {
                        TemplatesScreen()
                    } label: {
                        Label("Templates", systemImage: "list.bullet.rectangle")
                    }
                }

                Section("Account") {
                    if let auth = services.authService {
                        if let session = auth.session {
                            LabeledContent("User") {
                                Text(String(session.userId.uuidString.prefix(8)))
                                    .font(.body.monospaced())
                            }
                        } else {
                            Text("Not signed in.")
                                .foregroundStyle(.secondary)
                        }

                        Button("Sign Out", role: .destructive) {
                            Task { await auth.signOut() }
                        }
                        .disabled(auth.isBusy || auth.session == nil)
                    } else {
                        Text("Backend is not configured (using local mock data).")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

