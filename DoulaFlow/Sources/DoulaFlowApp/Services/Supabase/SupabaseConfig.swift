import Foundation

struct SupabaseConfig: Equatable {
    let url: URL
    let anonKey: String

    /// Storage bucket name for public mini-cabinets.
    var publicCabinetsBucket: String = "public_cabinets"
    /// Storage prefix used for client cabinet objects.
    var clientCabinetsPrefix: String = "c"

    /// Storage bucket name for public doula profile pages.
    var publicProfilesBucket: String = "public_profiles"
    /// Storage prefix used for public profile objects.
    var publicProfilesPrefix: String = "p"

    /// Base URL that points to `.../storage/v1/object/public/<bucket>/<prefix>`
    var clientCabinetPublicBaseURL: URL {
        url
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("public")
            .appendingPathComponent(publicCabinetsBucket)
            .appendingPathComponent(clientCabinetsPrefix)
    }

    static func loadFromBundle() -> SupabaseConfig? {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !anonKey.isEmpty
        else { return nil }
        return SupabaseConfig(url: url, anonKey: anonKey)
    }
}

