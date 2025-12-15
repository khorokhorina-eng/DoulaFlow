import SwiftUI

struct ClientsScreen: View {
    @ObservedObject var viewModel: ClientsViewModel
    let services: AppServices

    @State private var isPresentingForm = false
    @State private var selectedClient: Client?

    var body: some View {
        NavigationStack {
            List(viewModel.clients) { client in
                Button {
                    selectedClient = client
                } label: {
                    ClientRow(client: client)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.delete(clientId: client.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .overlay {
                if viewModel.clients.isEmpty {
                    PlaceholderView(title: "No Clients", systemImage: "person.badge.plus", description: "Add your first client to get started.")
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedClient = nil
                        isPresentingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await viewModel.load() }
            .sheet(item: $selectedClient, onDismiss: {
                Task { await viewModel.load() }
            }) { client in
                ClientDetailScreen(client: client, services: services)
            }
            .sheet(isPresented: $isPresentingForm) {
                let doulaId = services.authService?.session?.userId ?? SampleData.doulaProfile.id
                ClientFormView(client: Client(
                    doulaId: doulaId,
                    name: "",
                    contactDetails: "",
                    estimatedDueDate: Date(),
                    pregnancyWeek: PregnancyWeekCalculator.week(edd: Date()),
                    status: .onboarding,
                    notes: "",
                    medicalNotes: nil
                )) { client in
                    Task { await viewModel.upsert(client: client) }
                }
            }
        }
    }
}

struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(client.name)
                    .font(.headline)
                Text(client.status.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("EDD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(client.estimatedDueDate, style: .date)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}
