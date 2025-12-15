import Foundation

@MainActor
final class SupabaseAuthService: ObservableObject {
    @Published private(set) var session: SupabaseSession?
    @Published var errorMessage: String?
    @Published var isBusy: Bool = false

    private let http: SupabaseHTTPClient
    private let keychainService = "BirthPrepPro.Supabase"
    private let keychainAccount = "session"

    init(http: SupabaseHTTPClient) {
        self.http = http
        self.session = try? loadSession()
    }

    func signIn(email: String, password: String) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let body = try JSONEncoder.supabase.encode(["email": email, "password": password])
            let (data, _) = try await http.request(
                .post,
                path: "/auth/v1/token",
                query: [URLQueryItem(name: "grant_type", value: "password")],
                accessToken: nil,
                headers: ["Content-Type": "application/json"],
                body: body
            )
            let token = try JSONDecoder.supabase.decode(AuthTokenResponse.self, from: data)
            guard let userId = UUID(uuidString: token.user.id) else {
                throw RepositoryError(message: "Invalid user id")
            }
            let expiresAt = Date().addingTimeInterval(TimeInterval(token.expires_in))
            let newSession = SupabaseSession(
                accessToken: token.access_token,
                refreshToken: token.refresh_token,
                userId: userId,
                expiresAt: expiresAt
            )
            try saveSession(newSession)
            session = newSession
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        isBusy = true
        defer { isBusy = false }
        do {
            if let token = session?.accessToken {
                _ = try await http.request(.post, path: "/auth/v1/logout", accessToken: token, headers: ["Content-Type": "application/json"], body: Data())
            }
        } catch {
            // best-effort logout; still clear local session
            errorMessage = error.localizedDescription
        }
        do { try clearSession() } catch { /* ignore */ }
        session = nil
    }

    private func saveSession(_ session: SupabaseSession) throws {
        let data = try JSONEncoder.supabase.encode(session)
        try KeychainStore.set(data, service: keychainService, account: keychainAccount)
    }

    private func loadSession() throws -> SupabaseSession? {
        guard let data = try KeychainStore.get(service: keychainService, account: keychainAccount) else { return nil }
        return try JSONDecoder.supabase.decode(SupabaseSession.self, from: data)
    }

    private func clearSession() throws {
        try KeychainStore.delete(service: keychainService, account: keychainAccount)
    }
}

private struct AuthTokenResponse: Codable {
    struct User: Codable { let id: String }
    let access_token: String
    let refresh_token: String
    let expires_in: Int
    let user: User
}

private extension JSONEncoder {
    static let supabase: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
}

private extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
}

