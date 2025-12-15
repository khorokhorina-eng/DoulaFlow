import SwiftUI

struct ProfileScreen: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var isPresentingExporter = false
    @State private var isShowingPreview = false
    @State private var isPresentingPublicLinkShare = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Full Name", text: $viewModel.profile.fullName)
                    TextField("Title", text: $viewModel.profile.professionalTitle)
                    TextField("Experience", text: $viewModel.profile.experienceSummary)
                }

                Section("Bio") {
                    TextEditor(text: $viewModel.profile.bio)
                        .frame(minHeight: 120)
                }

                Section("Contact") {
                    TextField("Email", text: $viewModel.profile.contactEmail)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $viewModel.profile.phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Website", text: Binding(
                        get: { viewModel.profile.website?.absoluteString ?? "" },
                        set: { viewModel.profile.website = URL(string: $0) }
                    ))
                }

                Section("Certifications") {
                    ForEach(Array(viewModel.profile.certifications.enumerated()), id: \.offset) { index, cert in
                        TextField("Certification", text: Binding(
                            get: { cert },
                            set: { viewModel.profile.certifications[index] = $0 }
                        ))
                    }
                    Button("Add Certification") {
                        viewModel.profile.certifications.append("")
                    }
                }

                Section("Sharing") {
                    if let url = viewModel.publicLinkURL {
                        Text(url.absoluteString)
                            .textSelection(.enabled)
                            .font(.footnote)
                        Button("Share public link") {
                            isPresentingPublicLinkShare = true
                        }
                    }
                    Button("Generate public profile link") {
                        Task {
                            await viewModel.generatePublicLink()
                            isPresentingPublicLinkShare = viewModel.publicLinkURL != nil
                        }
                    }
                }
            }
            .navigationTitle("Doula Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Preview") { isShowingPreview = true }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    }
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                    Button {
                        Task {
                            await viewModel.exportPDF()
                            isPresentingExporter = viewModel.exportURL != nil
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $isPresentingExporter) {
                if let url = viewModel.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $isPresentingPublicLinkShare) {
                if let url = viewModel.publicLinkURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $isShowingPreview) {
                NavigationStack {
                    ProfilePreviewScreen(profile: viewModel.profile)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            ), actions: {}) {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
