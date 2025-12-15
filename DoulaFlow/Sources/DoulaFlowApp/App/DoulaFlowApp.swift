import SwiftUI

@main
struct DoulaFlowApp: App {
    @StateObject private var services: AppServices
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var clientsViewModel: ClientsViewModel

    init() {
        let services = AppServices()
        _services = StateObject(wrappedValue: services)
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(repository: services.profileRepository))
        _clientsViewModel = StateObject(wrappedValue: ClientsViewModel(repository: services.clientsRepository))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let auth = services.authService, auth.session == nil {
                    SignInScreen(auth: auth)
                } else {
                    RootTabView(services: services)
                        .environmentObject(profileViewModel)
                        .environmentObject(clientsViewModel)
                }
            }
            .task(id: services.authService?.session?.userId.uuidString ?? "mock") {
                await profileViewModel.load()
                await clientsViewModel.load()
            }
        }
    }
}
