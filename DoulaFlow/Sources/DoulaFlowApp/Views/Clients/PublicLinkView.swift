import SwiftUI

struct PublicLinkView: View {
    @ObservedObject var viewModel: PublicLinkViewModel
    @State private var shareURL: URL?
    @State private var presentingShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let link = viewModel.activeLink, let url = link.shareURL {
                Text("Active link")
                    .font(.headline)
                Text(url.absoluteString)
                    .textSelection(.enabled)
                    .font(.subheadline)
                Text("Expires: \(link.expiresAt.map { DateFormatter.short.string(from: $0) } ?? "Never")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Share") {
                    shareURL = url
                    presentingShare = true
                }
                Button("Revoke", role: .destructive) {
                    Task { await viewModel.revoke() }
                }
            } else {
                Text("No public link yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Generate Link") {
                    Task { await viewModel.generate() }
                }
            }
            if viewModel.isProcessing {
                ProgressView()
            }
        }
        .task {
            if viewModel.activeLink == nil {
                await viewModel.generate()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        ), actions: {}) {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $presentingShare) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

private extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
