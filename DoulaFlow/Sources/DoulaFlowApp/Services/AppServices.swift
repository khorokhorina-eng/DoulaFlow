import Foundation
import Combine
import Supabase

@MainActor
final class AppServices: ObservableObject {
    let supabaseClient: SupabaseClient
    let profileRepository: ProfileRepository
    let clientsRepository: ClientsRepository
    let birthPlanRepository: BirthPlanRepository
    let recommendationsRepository: RecommendationsRepository
    let publicLinkRepository: PublicLinkRepository

    init(supabaseURL: URL = URL(string: "https://example.supabase.co")!, supabaseAnonKey: String = "public-anon-key") {
        supabaseClient = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
        let mockStore = MockDataStore()
        self.profileRepository = mockStore
        self.clientsRepository = mockStore
        self.birthPlanRepository = mockStore
        self.recommendationsRepository = mockStore
        self.publicLinkRepository = mockStore
    }
}
