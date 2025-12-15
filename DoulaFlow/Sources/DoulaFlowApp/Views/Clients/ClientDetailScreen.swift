import SwiftUI

struct ClientDetailScreen: View {
    @State private var client: Client
    let services: AppServices

    @StateObject private var linkViewModel: PublicLinkViewModel
    @StateObject private var birthPlanViewModel: BirthPlanViewModel
    @StateObject private var recommendationsViewModel: RecommendationsViewModel
    @State private var isPresentingEdit = false
    @State private var isPresentingExporter = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    init(client: Client, services: AppServices) {
        _client = State(initialValue: client)
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
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        isPresentingEdit = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    Button {
                        Task {
                            do {
                                exportURL = try await services.clientsRepository.exportClientProfile(client.id)
                                isPresentingExporter = exportURL != nil
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .task {
                await birthPlanViewModel.load()
                await recommendationsViewModel.load()
            }
            .sheet(isPresented: $isPresentingEdit) {
                ClientFormView(client: client) { updated in
                    client = updated
                    Task {
                        do {
                            var normalized = updated
                            normalized.pregnancyWeek = PregnancyWeekCalculator.week(edd: normalized.estimatedDueDate)
                            _ = try await services.clientsRepository.upsertClient(normalized)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .sheet(isPresented: $isPresentingExporter) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            ), actions: {}) {
                Text(errorMessage ?? "")
            }
        }
    }
}
