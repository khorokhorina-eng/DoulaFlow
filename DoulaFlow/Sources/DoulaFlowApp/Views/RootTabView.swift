import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var clientsViewModel: ClientsViewModel

    let services: AppServices

    var body: some View {
        TabView {
            ProfileScreen(viewModel: profileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.text.rectangle")
                }

            ClientsScreen(viewModel: clientsViewModel, services: services)
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }

            TemplatesScreen()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet.rectangle")
                }
        }
    }
}
