import SwiftUI

struct RecommendationsView: View {
    @ObservedObject var viewModel: RecommendationsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: Binding(
                get: { viewModel.recommendation?.content ?? "" },
                set: { viewModel.updateContent($0) }
            ))
            .frame(minHeight: 180)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .secondarySystemBackground)))

            if let attachments = viewModel.recommendation?.attachments, !attachments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attachments")
                        .font(.headline)
                    ForEach(attachments) { attachment in
                        Link(attachment.fileName, destination: attachment.url)
                    }
                }
            }

            HStack {
                if viewModel.isSaving {
                    ProgressView()
                }
                Spacer()
                Button("Save") {
                    Task { await viewModel.save() }
                }
            }
        }
    }
}
