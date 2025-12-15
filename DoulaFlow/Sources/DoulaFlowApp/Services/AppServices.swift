import Foundation
import Combine

@MainActor
final class AppServices: ObservableObject {
    let supabaseConfig: SupabaseConfig?
    let authService: SupabaseAuthService?
    let profileRepository: ProfileRepository
    let clientsRepository: ClientsRepository
    let birthPlanRepository: BirthPlanRepository
    let recommendationsRepository: RecommendationsRepository
    let publicLinkRepository: PublicLinkRepository

    init(config: SupabaseConfig? = SupabaseConfig.loadFromBundle()) {
        self.supabaseConfig = config

        if let config {
            // Configure routing for client public links
            PublicLinkRouting.clientCabinetPublicBaseURL = config.clientCabinetPublicBaseURL

            let http = SupabaseHTTPClient(config: config)
            let storage = SupabaseStorageClient(config: config)
            let auth = SupabaseAuthService(http: http)
            self.authService = auth

            let sessionProvider: () -> SupabaseSession? = { auth.session }
            let profileRepo = SupabaseProfileRepository(http: http, storage: storage, config: config, sessionProvider: sessionProvider)
            let clientsRepo = SupabaseClientsRepository(http: http, sessionProvider: sessionProvider)
            let birthRepo = SupabaseBirthPlanRepository(http: http, sessionProvider: sessionProvider)
            let recRepo = SupabaseRecommendationsRepository(http: http, storage: storage, sessionProvider: sessionProvider)
            let linkRepo = SupabasePublicLinkRepository(
                http: http,
                storage: storage,
                clientsRepository: clientsRepo,
                birthPlanRepository: birthRepo,
                recommendationsRepository: recRepo,
                sessionProvider: sessionProvider,
                config: config
            )

            self.profileRepository = profileRepo
            self.clientsRepository = clientsRepo
            self.birthPlanRepository = birthRepo
            self.recommendationsRepository = recRepo
            self.publicLinkRepository = linkRepo
        } else {
            // Fallback: in-memory mock store (for dev / previews)
            self.authService = nil
            let mockStore = MockDataStore()
            self.profileRepository = mockStore
            self.clientsRepository = mockStore
            self.birthPlanRepository = mockStore
            self.recommendationsRepository = mockStore
            self.publicLinkRepository = mockStore
        }
    }
}
