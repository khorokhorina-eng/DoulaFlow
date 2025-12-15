import SwiftUI

struct SignInScreen: View {
    @ObservedObject var auth: SupabaseAuthService
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("BirthPrep Pro")
                        .font(.title.bold())
                    Text("Sign in to sync your clients and share public links.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                Form {
                    Section("Account") {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Password", text: $password)
                    }

                    Section {
                        Button {
                            Task { await auth.signIn(email: email, password: password) }
                        } label: {
                            HStack {
                                Spacer()
                                if auth.isBusy { ProgressView() }
                                Text("Sign In")
                                Spacer()
                            }
                        }
                        .disabled(auth.isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { auth.errorMessage != nil },
                set: { _ in auth.errorMessage = nil }
            ), actions: {}) {
                Text(auth.errorMessage ?? "")
            }
        }
    }
}

