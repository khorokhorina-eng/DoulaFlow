import Foundation

@MainActor
final class RecommendationsViewModel: ObservableObject {
    @Published private(set) var recommendation: Recommendation?
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var isUploadingAttachment = false

    private let repository: RecommendationsRepository
    private let clientId: UUID

    init(repository: RecommendationsRepository, clientId: UUID) {
        self.repository = repository
        self.clientId = clientId
    }

    func load() async {
        do {
            recommendation = try await repository.fetchRecommendations(for: clientId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateContent(_ content: String) {
        if recommendation == nil {
            recommendation = Recommendation(clientId: clientId, title: "New Recommendation", content: content, attachments: [], updatedAt: Date())
        } else {
            recommendation?.content = content
        }
    }

    func insertLink(title: String?, urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let display = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let snippet: String
        if display.isEmpty {
            snippet = trimmed
        } else {
            snippet = "[\(display)](\(trimmed))"
        }
        let spacer = (recommendation?.content ?? "").isEmpty ? "" : "\n"
        updateContent((recommendation?.content ?? "") + spacer + snippet)
    }

    func applyTemplate(_ template: RecommendationTemplate) {
        updateContent(template.content)
        if recommendation?.title == "New Recommendation" || (recommendation?.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            recommendation?.title = template.title
        }
    }

    func addAttachment(from pickedFileURL: URL) async {
        isUploadingAttachment = true
        defer { isUploadingAttachment = false }
        do {
            let attachment = try await repository.uploadAttachment(clientId: clientId, fileURL: pickedFileURL)
            if recommendation == nil {
                recommendation = Recommendation(clientId: clientId, title: "New Recommendation", content: "", attachments: [attachment], updatedAt: Date())
            } else {
                recommendation?.attachments.append(attachment)
            }
            await save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAttachment(_ attachment: RecommendationAttachment) async {
        do {
            try await repository.deleteAttachment(clientId: clientId, attachmentId: attachment.id)
            recommendation?.attachments.removeAll { $0.id == attachment.id }
            await save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard var recommendation else { return }
        isSaving = true
        defer { isSaving = false }
        recommendation.updatedAt = Date()
        do {
            self.recommendation = try await repository.saveRecommendation(recommendation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
