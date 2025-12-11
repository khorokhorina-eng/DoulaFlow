import SwiftUI

struct BirthPlanView: View {
    @ObservedObject var viewModel: BirthPlanViewModel
    @State private var presentingShare = false
    @State private var exportURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let plan = viewModel.plan {
                ForEach(plan.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)
                        TextEditor(text: Binding(
                            get: { section.body },
                            set: { newValue in viewModel.update(section: section, body: newValue) }
                        ))
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .secondarySystemBackground)))
                    }
                }
            } else {
                PlaceholderView(title: "No Birth Plan", systemImage: "doc.text", description: "Tap add section to get started.")
            }

            HStack {
                Button("Add Section", action: viewModel.addSection)
                Spacer()
                Button("Save") {
                    Task { await viewModel.save() }
                }
                Button("Export") {
                    Task {
                        exportURL = await viewModel.exportPDF()
                        presentingShare = exportURL != nil
                    }
                }
            }
        }
        .sheet(isPresented: $presentingShare) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}
