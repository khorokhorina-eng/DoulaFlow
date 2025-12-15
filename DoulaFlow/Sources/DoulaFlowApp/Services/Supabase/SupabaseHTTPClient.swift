import Foundation

final class SupabaseHTTPClient {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    let config: SupabaseConfig

    init(config: SupabaseConfig) {
        self.config = config
    }

    func request(
        _ method: Method,
        path: String,
        query: [URLQueryItem] = [],
        accessToken: String? = nil,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var url = config.url.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        if !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = query
            if let newURL = components?.url { url = newURL }
        }

        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.httpBody = body

        req.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        for (k, v) in headers {
            req.setValue(v, forHTTPHeaderField: k)
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw RepositoryError(message: "Invalid HTTP response")
        }
        if !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw RepositoryError(message: "Supabase error \(http.statusCode): \(message)")
        }
        return (data, http)
    }
}

