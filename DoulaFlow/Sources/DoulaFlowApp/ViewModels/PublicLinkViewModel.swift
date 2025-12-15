import Foundation

@MainActor
final class PublicLinkViewModel: ObservableObject {
    @Published var activeLink: PublicLink?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let repository: PublicLinkRepository
    private let clientId: UUID

    init(repository: PublicLinkRepository, clientId: UUID) {
        self.repository = repository
        self.clientId = clientId
    }

    func generate() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            activeLink = try await repository.generateLink(for: clientId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revoke() async {
        guard let link = activeLink else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await repository.revokeLink(link.id)
            activeLink = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
