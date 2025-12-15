import Foundation

@MainActor
final class BirthPlanViewModel: ObservableObject {
    @Published private(set) var plan: BirthPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: BirthPlanRepository
    private let clientId: UUID

    init(repository: BirthPlanRepository, clientId: UUID) {
        self.repository = repository
        self.clientId = clientId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plan = try await repository.fetchBirthPlan(for: clientId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(section: BirthPlanSection, body: String) {
        guard var plan else { return }
        if let index = plan.sections.firstIndex(where: { $0.id == section.id }) {
            plan.sections[index].body = body
        }
        self.plan = plan
    }

    func addSection() {
        guard var plan else {
            plan = BirthPlan(clientId: clientId, sections: [BirthPlanSection(title: "New Section", body: "")], updatedAt: Date())
            return
        }
        plan.sections.append(BirthPlanSection(title: "New Section", body: ""))
        self.plan = plan
    }

    func save() async {
        guard var plan else { return }
        plan.updatedAt = Date()
        do {
            self.plan = try await repository.saveBirthPlan(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportPDF() async -> URL? {
        guard let plan else { return nil }
        do {
            return try await repository.exportBirthPlanPDF(plan)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
