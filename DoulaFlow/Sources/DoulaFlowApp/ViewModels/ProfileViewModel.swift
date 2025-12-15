import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: DoulaProfile = SampleData.doulaProfile
    @Published var isSaving = false
    @Published var exportURL: URL?
    @Published var errorMessage: String?

    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func load() async {
        do {
            profile = try await repository.fetchProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            profile = try await repository.saveProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportPDF() async {
        do {
            exportURL = try await repository.exportProfilePDF(from: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
