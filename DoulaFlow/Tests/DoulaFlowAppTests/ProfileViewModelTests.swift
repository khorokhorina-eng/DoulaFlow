import XCTest
@testable import DoulaFlowApp

final class ProfileViewModelTests: XCTestCase {
    @MainActor
    func testLoadProfile() async throws {
        let repository = MockDataStore()
        let viewModel = ProfileViewModel(repository: repository)
        await viewModel.load()
        XCTAssertFalse(viewModel.profile.fullName.isEmpty)
    }
}
