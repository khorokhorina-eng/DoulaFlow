import SwiftUI

struct ClientDetailScreen: View {
    let client: Client
    let services: AppServices

    @StateObject private var linkViewModel: PublicLinkViewModel
    @StateObject private var birthPlanViewModel: BirthPlanViewModel
    @StateObject private var recommendationsViewModel: RecommendationsViewModel

    init(client: Client, services: AppServices) {
        self.client = client
        self.services = services
        _linkViewModel = StateObject(wrappedValue: PublicLinkViewModel(repository: services.publicLinkRepository, clientId: client.id))
        _birthPlanViewModel = StateObject(wrappedValue: BirthPlanViewModel(repository: services.birthPlanRepository, clientId: client.id))
        _recommendationsViewModel = StateObject(wrappedValue: RecommendationsViewModel(repository: services.recommendationsRepository, clientId: client.id))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(client.name)
                                .font(.title2.bold())
                            Text(client.contactDetails)
                                .font(.subheadline)
                            Text("Status: \(client.status.displayName)")
                                .font(.subheadline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("EDD")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(client.estimatedDueDate, style: .date)
                                .font(.headline)
                            Text("Week \(client.pregnancyWeek)")
                                .font(.caption)
                        }
                    }
                }

                Section("Birth Plan") {
                    BirthPlanView(viewModel: birthPlanViewModel)
                }

                Section("Recommendations") {
                    RecommendationsView(viewModel: recommendationsViewModel)
                }

                Section("Public Link") {
                    PublicLinkView(viewModel: linkViewModel)
                }
            }
            .navigationTitle(client.name)
            .task {
                await birthPlanViewModel.load()
                await recommendationsViewModel.load()
            }
        }
    }
}
