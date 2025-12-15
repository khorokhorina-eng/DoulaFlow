import Foundation

@MainActor
final class RecommendationsViewModel: ObservableObject {
    @Published private(set) var recommendation: Recommendation?
    @Published var errorMessage: String?
    @Published var isSaving = false

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
