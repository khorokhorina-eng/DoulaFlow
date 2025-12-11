import Foundation

protocol ProfileRepository {
    func fetchProfile() async throws -> DoulaProfile
    func saveProfile(_ profile: DoulaProfile) async throws -> DoulaProfile
    func exportProfilePDF(from profile: DoulaProfile) async throws -> URL
}

protocol ClientsRepository {
    func fetchClients() async throws -> [Client]
    func upsertClient(_ client: Client) async throws -> Client
    func deleteClient(_ clientId: UUID) async throws
    func exportClientProfile(_ clientId: UUID) async throws -> URL
}

protocol BirthPlanRepository {
    func fetchBirthPlan(for clientId: UUID) async throws -> BirthPlan
    func saveBirthPlan(_ plan: BirthPlan) async throws -> BirthPlan
    func exportBirthPlanPDF(_ plan: BirthPlan) async throws -> URL
}

protocol RecommendationsRepository {
    func fetchRecommendations(for clientId: UUID) async throws -> Recommendation
    func saveRecommendation(_ recommendation: Recommendation) async throws -> Recommendation
}

protocol PublicLinkRepository {
    func generateLink(for clientId: UUID) async throws -> PublicLink
    func revokeLink(_ linkId: UUID) async throws
}

struct RepositoryError: Error, LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
