import SwiftUI
import UniformTypeIdentifiers

struct RecommendationsView: View {
    @ObservedObject var viewModel: RecommendationsViewModel
    @State private var isPreviewing = false
    @State private var isPresentingLink = false
    @State private var linkTitle = ""
    @State private var linkURL = ""
    @State private var isPresentingFilePicker = false
    @State private var templates: [RecommendationTemplate] = TemplateProvider.loadRecommendationTemplates()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Mode", selection: $isPreviewing) {
                    Text("Edit").tag(false)
                    Text("Preview").tag(true)
                }
                .pickerStyle(.segmented)

                Menu("Template") {
                    ForEach(templates) { template in
                        Button(template.title) {
                            viewModel.applyTemplate(template)
                        }
                    }
                }
                Spacer()
                Button {
                    isPresentingLink = true
                } label: {
                    Image(systemName: "link")
                }
                Button {
                    isPresentingFilePicker = true
                } label: {
                    Image(systemName: "paperclip")
                }
            }

            Group {
                if isPreviewing {
                    MarkdownPreview(markdown: viewModel.recommendation?.content ?? "")
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .secondarySystemBackground)))
                } else {
                    TextEditor(text: Binding(
                        get: { viewModel.recommendation?.content ?? "" },
                        set: { viewModel.updateContent($0) }
                    ))
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .secondarySystemBackground)))
                }
            }

            if let attachments = viewModel.recommendation?.attachments, !attachments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attachments")
                        .font(.headline)
                    ForEach(attachments) { attachment in
                        HStack {
                            Link(attachment.fileName, destination: attachment.url)
                            Spacer()
                            Button(role: .destructive) {
                                Task { await viewModel.removeAttachment(attachment) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            HStack {
                if viewModel.isSaving {
                    ProgressView()
                }
                if viewModel.isUploadingAttachment {
                    ProgressView()
                }
                Spacer()
                Button("Save") {
                    Task { await viewModel.save() }
                }
            }
        }
        .fileImporter(
            isPresented: $isPresentingFilePicker,
            allowedContentTypes: allowedAttachmentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let didStart = url.startAccessingSecurityScopedResource()
                Task {
                    defer {
                        if didStart { url.stopAccessingSecurityScopedResource() }
                    }
                    await viewModel.addAttachment(from: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isPresentingLink) {
            NavigationStack {
                Form {
                    Section("Link") {
                        TextField("Title (optional)", text: $linkTitle)
                        TextField("URL", text: $linkURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .navigationTitle("Insert link")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) { isPresentingLink = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Insert") {
                            viewModel.insertLink(title: linkTitle, urlString: linkURL)
                            linkTitle = ""
                            linkURL = ""
                            isPresentingLink = false
                        }
                    }
                }
            }
        }
    }
}

private extension RecommendationsView {
    var allowedAttachmentTypes: [UTType] {
        var types: [UTType] = [.pdf, .image]
        if let docx = UTType(filenameExtension: "docx") {
            types.append(docx)
        }
        types.append(.data)
        return types
    }
}

private struct MarkdownPreview: View {
    let markdown: String

    var body: some View {
        ScrollView {
            Text(attributed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var attributed: AttributedString {
        (try? AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full))) ?? AttributedString(markdown)
    }
}
