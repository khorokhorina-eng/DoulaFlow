import Foundation

@MainActor
final class ClientsViewModel: ObservableObject {
    @Published private(set) var clients: [Client] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedClient: Client?

    private let repository: ClientsRepository

    init(repository: ClientsRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            clients = try await repository.fetchClients()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func upsert(client: Client) async {
        do {
            _ = try await repository.upsertClient(client)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(clientId: UUID) async {
        do {
            try await repository.deleteClient(clientId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func export(clientId: UUID) async -> URL? {
        do {
            return try await repository.exportClientProfile(clientId)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
