import Foundation

enum PublicLinkRouting {
    /// Base URL that points to the *directory* containing token folders (e.g. `.../public_cabinets/c`)
    static var clientCabinetPublicBaseURL: URL = URL(string: "https://doula.flow.link/c")!

    static func clientCabinetURL(token: String) -> URL? {
        guard !token.isEmpty else { return nil }
        return clientCabinetPublicBaseURL
            .appendingPathComponent(token)
            .appendingPathComponent("index.html")
    }
}

