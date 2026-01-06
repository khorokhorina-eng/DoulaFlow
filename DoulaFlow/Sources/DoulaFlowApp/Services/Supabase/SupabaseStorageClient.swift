import Foundation

final class SupabaseStorageClient {
    let config: SupabaseConfig

    init(config: SupabaseConfig) {
        self.config = config
    }

    /// Upload raw bytes to storage at `bucket/path`.
    func upload(
        bucket: String,
        path: String,
        data: Data,
        contentType: String,
        accessToken: String,
        upsert: Bool = true
    ) async throws {
        let url = config.url
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = data
        req.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue(upsert ? "true" : "false", forHTTPHeaderField: "x-upsert")

        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw RepositoryError(message: "Invalid HTTP response")
        }
        if !(200...299).contains(http.statusCode) {
            let message = String(data: respData, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw RepositoryError(message: "Storage upload error \(http.statusCode): \(message)")
        }
    }

    func publicObjectURL(bucket: String, path: String) -> URL {
        config.url
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)
    }

    /// Delete an object at `bucket/path`.
    func delete(bucket: String, path: String, accessToken: String) async throws {
        let url = config.url
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)

        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw RepositoryError(message: "Invalid HTTP response")
        }
        if !(200...299).contains(http.statusCode) {
            let message = String(data: respData, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw RepositoryError(message: "Storage delete error \(http.statusCode): \(message)")
        }
    }

    /// Best-effort extraction of bucket-relative path from a public storage URL.
    func path(fromPublicObjectURL url: URL, bucket: String) -> String? {
        // Expected path: /storage/v1/object/public/<bucket>/<path...>
        let comps = url.pathComponents
        guard let bucketIndex = comps.firstIndex(of: bucket) else { return nil }
        let next = comps.index(after: bucketIndex)
        guard next < comps.endIndex else { return nil }
        return comps[next...].joined(separator: "/")
    }
}

