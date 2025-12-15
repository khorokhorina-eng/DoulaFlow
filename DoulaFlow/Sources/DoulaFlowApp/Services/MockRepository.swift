import Foundation

@MainActor
final class MockDataStore {
    private var profile: DoulaProfile
    private var clients: [Client]
    private var birthPlans: [UUID: BirthPlan]
    private var recommendations: [UUID: Recommendation]
    private var publicLinks: [UUID: PublicLink]

    init(profile: DoulaProfile = SampleData.doulaProfile, clients: [Client] = SampleData.clients) {
        self.profile = profile
        self.clients = clients
        self.birthPlans = Dictionary(uniqueKeysWithValues: clients.map { client in
            (client.id, SampleData.birthPlan(for: client))
        })
        self.recommendations = Dictionary(uniqueKeysWithValues: clients.map { client in
            (client.id, SampleData.recommendations(for: client))
        })
        self.publicLinks = [:]
    }

    func readProfile() -> DoulaProfile { profile }

    func updateProfile(_ newProfile: DoulaProfile) -> DoulaProfile {
        profile = newProfile
        return profile
    }

    func listClients() -> [Client] {
        clients.sorted { $0.estimatedDueDate < $1.estimatedDueDate }
    }

    func upsert(_ client: Client) -> Client {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        } else {
            clients.append(client)
        }
        return client
    }

    func delete(clientId: UUID) {
        clients.removeAll { $0.id == clientId }
        birthPlans.removeValue(forKey: clientId)
        recommendations.removeValue(forKey: clientId)
        publicLinks = publicLinks.filter { $0.value.clientId != clientId }
    }

    func upsertBirthPlan(_ plan: BirthPlan) -> BirthPlan {
        birthPlans[plan.clientId] = plan
        return plan
    }

    func birthPlan(for clientId: UUID) throws -> BirthPlan {
        guard let plan = birthPlans[clientId] else {
            throw RepositoryError(message: "Missing plan for client")
        }
        return plan
    }

    func upsertRecommendation(_ recommendation: Recommendation) -> Recommendation {
        recommendations[recommendation.clientId] = recommendation
        return recommendation
    }

    func recommendation(for clientId: UUID) throws -> Recommendation {
        guard let recommendation = recommendations[clientId] else {
            throw RepositoryError(message: "Missing recommendation for client")
        }
        return recommendation
    }

    func makeLink(for clientId: UUID) -> PublicLink {
        let link = PublicLink(clientId: clientId, token: UUID().uuidString.replacingOccurrences(of: "-", with: ""), createdAt: Date(), expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()), disabled: false)
        publicLinks[link.id] = link
        return link
    }

    func revokeLink(linkId: UUID) {
        publicLinks[linkId] = nil
    }
}

extension MockDataStore: ProfileRepository {
    func fetchProfile() async throws -> DoulaProfile { readProfile() }

    func saveProfile(_ profile: DoulaProfile) async throws -> DoulaProfile { updateProfile(profile) }

    func exportProfilePDF(from profile: DoulaProfile) async throws -> URL {
        URL(fileURLWithPath: "/tmp/profile.pdf")
    }
}

extension MockDataStore: ClientsRepository {
    func fetchClients() async throws -> [Client] { listClients() }

    func upsertClient(_ client: Client) async throws -> Client { upsert(client) }

    func deleteClient(_ clientId: UUID) async throws { delete(clientId: clientId) }

    func exportClientProfile(_ clientId: UUID) async throws -> URL { URL(fileURLWithPath: "/tmp/client-\(clientId).pdf") }
}

extension MockDataStore: BirthPlanRepository {
    func fetchBirthPlan(for clientId: UUID) async throws -> BirthPlan {
        try birthPlan(for: clientId)
    }

    func saveBirthPlan(_ plan: BirthPlan) async throws -> BirthPlan {
        upsertBirthPlan(plan)
    }

    func exportBirthPlanPDF(_ plan: BirthPlan) async throws -> URL {
        URL(fileURLWithPath: "/tmp/birthplan-\(plan.clientId).pdf")
    }
}

extension MockDataStore: RecommendationsRepository {
    func fetchRecommendations(for clientId: UUID) async throws -> Recommendation {
        try recommendation(for: clientId)
    }

    func saveRecommendation(_ recommendation: Recommendation) async throws -> Recommendation {
        upsertRecommendation(recommendation)
    }
}

extension MockDataStore: PublicLinkRepository {
    func generateLink(for clientId: UUID) async throws -> PublicLink {
        makeLink(for: clientId)
    }

    func revokeLink(_ linkId: UUID) async throws {
        revokeLink(linkId: linkId)
    }
}
