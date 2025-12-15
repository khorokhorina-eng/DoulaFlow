import Foundation

// MARK: - Shared JSON coding

private extension JSONEncoder {
    static let postgrest: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
}

private extension JSONDecoder {
    static let postgrest: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
}

// MARK: - DTOs (snake_case)

private struct DBDoulaProfile: Codable {
    let id: UUID
    var name: String
    var title: String
    var experience: String
    var bio: String
    var photo_url: String?
    var contact_email: String
    var phone: String
    var website: String?
    var certifications: [String]
}

private struct DBClient: Codable {
    let id: UUID
    let doula_id: UUID
    var name: String
    var contact: String
    var edd: Date
    var pregnancy_week: Int
    var status: String
    var notes: String
    var medical_notes: String?
}

private struct DBBirthPlan: Codable {
    let id: UUID
    let client_id: UUID
    var content: [BirthPlanSection]
    var updated_at: Date
    var pdf_url: String?
}

private struct DBRecommendation: Codable {
    let id: UUID
    let client_id: UUID
    var title: String
    var content: String
    var attachments: [RecommendationAttachment]
    var updated_at: Date
}

private struct DBPublicLink: Codable {
    let id: UUID
    let client_id: UUID
    var token: String
    var created_at: Date
    var expires_at: Date?
    var disabled: Bool
}

// MARK: - Mapping

private extension DoulaProfile {
    init(db: DBDoulaProfile) {
        id = db.id
        fullName = db.name
        professionalTitle = db.title
        experienceSummary = db.experience
        bio = db.bio
        photoURL = db.photo_url.flatMap(URL.init(string:))
        contactEmail = db.contact_email
        phoneNumber = db.phone
        website = db.website.flatMap(URL.init(string:))
        certifications = db.certifications
    }

    func toDB(userId: UUID) -> DBDoulaProfile {
        DBDoulaProfile(
            id: userId,
            name: fullName,
            title: professionalTitle,
            experience: experienceSummary,
            bio: bio,
            photo_url: photoURL?.absoluteString,
            contact_email: contactEmail,
            phone: phoneNumber,
            website: website?.absoluteString,
            certifications: certifications
        )
    }
}

private extension Client {
    init(db: DBClient) throws {
        id = db.id
        doulaId = db.doula_id
        name = db.name
        contactDetails = db.contact
        estimatedDueDate = db.edd
        pregnancyWeek = db.pregnancy_week
        status = try Status.fromDB(db.status)
        notes = db.notes
        medicalNotes = db.medical_notes
    }

    func toDB() -> DBClient {
        DBClient(
            id: id,
            doula_id: doulaId,
            name: name,
            contact: contactDetails,
            edd: estimatedDueDate,
            pregnancy_week: pregnancyWeek,
            status: status.rawValue,
            notes: notes,
            medical_notes: medicalNotes
        )
    }
}

private extension Client.Status {
    static func fromDB(_ raw: String) throws -> Client.Status {
        guard let parsed = Client.Status(rawValue: raw) else {
            throw RepositoryError(message: "Unknown client status: \(raw)")
        }
        return parsed
    }
}

private extension BirthPlan {
    init(db: DBBirthPlan) {
        id = db.id
        clientId = db.client_id
        sections = db.content
        updatedAt = db.updated_at
    }

    func toDB() -> DBBirthPlan {
        DBBirthPlan(id: id, client_id: clientId, content: sections, updated_at: updatedAt, pdf_url: nil)
    }
}

private extension Recommendation {
    init(db: DBRecommendation) {
        id = db.id
        clientId = db.client_id
        title = db.title
        content = db.content
        attachments = db.attachments
        updatedAt = db.updated_at
    }

    func toDB() -> DBRecommendation {
        DBRecommendation(id: id, client_id: clientId, title: title, content: content, attachments: attachments, updated_at: updatedAt)
    }
}

private extension PublicLink {
    init(db: DBPublicLink) {
        id = db.id
        clientId = db.client_id
        token = db.token
        createdAt = db.created_at
        expiresAt = db.expires_at
        disabled = db.disabled
    }
}

// MARK: - Repositories

final class SupabaseProfileRepository: ProfileRepository {
    private let http: SupabaseHTTPClient
    private let storage: SupabaseStorageClient
    private let config: SupabaseConfig
    private let sessionProvider: () -> SupabaseSession?
    private let keychainService = "BirthPrepPro.Supabase"
    private let keychainAccount = "public_profile_token"

    init(http: SupabaseHTTPClient, storage: SupabaseStorageClient, config: SupabaseConfig, sessionProvider: @escaping () -> SupabaseSession?) {
        self.http = http
        self.storage = storage
        self.config = config
        self.sessionProvider = sessionProvider
    }

    func fetchProfile() async throws -> DoulaProfile {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let query = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "id", value: "eq.\(session.userId.uuidString)")
        ]
        let (data, _) = try await http.request(.get, path: "/rest/v1/doula_profile", query: query, accessToken: session.accessToken)
        let rows = try JSONDecoder.postgrest.decode([DBDoulaProfile].self, from: data)
        if let row = rows.first {
            return DoulaProfile(db: row)
        }
        // If profile doesn't exist yet, return an empty draft using the authenticated id.
        return DoulaProfile(
            id: session.userId,
            fullName: "",
            professionalTitle: "",
            experienceSummary: "",
            bio: "",
            photoURL: nil,
            contactEmail: "",
            phoneNumber: "",
            website: nil,
            certifications: []
        )
    }

    func saveProfile(_ profile: DoulaProfile) async throws -> DoulaProfile {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let db = profile.toDB(userId: session.userId)
        let body = try JSONEncoder.postgrest.encode(db)
        let headers = [
            "Prefer": "resolution=merge-duplicates,return=representation"
        ]
        let query = [URLQueryItem(name: "on_conflict", value: "id")]
        let (data, _) = try await http.request(.post, path: "/rest/v1/doula_profile", query: query, accessToken: session.accessToken, headers: headers, body: body)
        let rows = try JSONDecoder.postgrest.decode([DBDoulaProfile].self, from: data)
        guard let row = rows.first else { throw RepositoryError(message: "Failed to save profile") }
        return DoulaProfile(db: row)
    }

    func exportProfilePDF(from profile: DoulaProfile) async throws -> URL {
        try PDFGenerator.makeProfilePDF(profile: profile)
    }

    func generatePublicProfileLink(from profile: DoulaProfile) async throws -> URL {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }

        let token = try loadOrCreateProfileToken()
        let html = ProfilePublicHTMLBuilder.build(profile: profile)
        let path = "\(config.publicProfilesPrefix)/\(token)/index.html"
        try await storage.upload(
            bucket: config.publicProfilesBucket,
            path: path,
            data: Data(html.utf8),
            contentType: "text/html; charset=utf-8",
            accessToken: session.accessToken,
            upsert: true
        )
        return storage.publicObjectURL(bucket: config.publicProfilesBucket, path: path)
    }

    private func loadOrCreateProfileToken() throws -> String {
        if let data = try KeychainStore.get(service: keychainService, account: keychainAccount),
           let token = String(data: data, encoding: .utf8),
           !token.isEmpty {
            return token
        }
        let token = randomToken()
        guard let data = token.data(using: .utf8) else {
            throw RepositoryError(message: "Failed to encode token")
        }
        try KeychainStore.set(data, service: keychainService, account: keychainAccount)
        return token
    }
}

final class SupabaseClientsRepository: ClientsRepository {
    private let http: SupabaseHTTPClient
    private let sessionProvider: () -> SupabaseSession?

    init(http: SupabaseHTTPClient, sessionProvider: @escaping () -> SupabaseSession?) {
        self.http = http
        self.sessionProvider = sessionProvider
    }

    func fetchClients() async throws -> [Client] {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let query = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "doula_id", value: "eq.\(session.userId.uuidString)"),
            URLQueryItem(name: "order", value: "edd.asc")
        ]
        let (data, _) = try await http.request(.get, path: "/rest/v1/clients", query: query, accessToken: session.accessToken)
        let rows = try JSONDecoder.postgrest.decode([DBClient].self, from: data)
        return try rows.map { try Client(db: $0) }
    }

    func upsertClient(_ client: Client) async throws -> Client {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let body = try JSONEncoder.postgrest.encode(client.toDB())
        let headers = [
            "Prefer": "resolution=merge-duplicates,return=representation"
        ]
        let query = [URLQueryItem(name: "on_conflict", value: "id")]
        let (data, _) = try await http.request(.post, path: "/rest/v1/clients", query: query, accessToken: session.accessToken, headers: headers, body: body)
        let rows = try JSONDecoder.postgrest.decode([DBClient].self, from: data)
        guard let row = rows.first else { throw RepositoryError(message: "Failed to save client") }
        return try Client(db: row)
    }

    func deleteClient(_ clientId: UUID) async throws {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let query = [
            URLQueryItem(name: "id", value: "eq.\(clientId.uuidString)")
        ]
        _ = try await http.request(.delete, path: "/rest/v1/clients", query: query, accessToken: session.accessToken)
    }

    func exportClientProfile(_ clientId: UUID) async throws -> URL {
        // Fetch client to render a complete PDF.
        let clients = try await fetchClients()
        guard let client = clients.first(where: { $0.id == clientId }) else {
            throw RepositoryError(message: "Client not found")
        }
        return try PDFGenerator.makeClientProfilePDF(client: client)
    }
}

final class SupabaseBirthPlanRepository: BirthPlanRepository {
    private let http: SupabaseHTTPClient
    private let sessionProvider: () -> SupabaseSession?

    init(http: SupabaseHTTPClient, sessionProvider: @escaping () -> SupabaseSession?) {
        self.http = http
        self.sessionProvider = sessionProvider
    }

    func fetchBirthPlan(for clientId: UUID) async throws -> BirthPlan {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let query = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientId.uuidString)")
        ]
        let (data, _) = try await http.request(.get, path: "/rest/v1/birth_plans", query: query, accessToken: session.accessToken)
        let rows = try JSONDecoder.postgrest.decode([DBBirthPlan].self, from: data)
        if let row = rows.first {
            return BirthPlan(db: row)
        }
        return BirthPlan(clientId: clientId, sections: [], updatedAt: Date())
    }

    func saveBirthPlan(_ plan: BirthPlan) async throws -> BirthPlan {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let body = try JSONEncoder.postgrest.encode(plan.toDB())
        let headers = [
            "Prefer": "resolution=merge-duplicates,return=representation"
        ]
        let query = [URLQueryItem(name: "on_conflict", value: "id")]
        let (data, _) = try await http.request(.post, path: "/rest/v1/birth_plans", query: query, accessToken: session.accessToken, headers: headers, body: body)
        let rows = try JSONDecoder.postgrest.decode([DBBirthPlan].self, from: data)
        guard let row = rows.first else { throw RepositoryError(message: "Failed to save birth plan") }
        return BirthPlan(db: row)
    }

    func exportBirthPlanPDF(_ plan: BirthPlan) async throws -> URL {
        try PDFGenerator.makeBirthPlanPDF(plan: plan)
    }
}

final class SupabaseRecommendationsRepository: RecommendationsRepository {
    private let http: SupabaseHTTPClient
    private let storage: SupabaseStorageClient
    private let sessionProvider: () -> SupabaseSession?

    /// Storage bucket used for recommendation attachments (make it public or provide signed URLs server-side).
    private let attachmentsBucket = "client_files"

    init(http: SupabaseHTTPClient, storage: SupabaseStorageClient, sessionProvider: @escaping () -> SupabaseSession?) {
        self.http = http
        self.storage = storage
        self.sessionProvider = sessionProvider
    }

    func fetchRecommendations(for clientId: UUID) async throws -> Recommendation {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let query = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientId.uuidString)")
        ]
        let (data, _) = try await http.request(.get, path: "/rest/v1/recommendations", query: query, accessToken: session.accessToken)
        let rows = try JSONDecoder.postgrest.decode([DBRecommendation].self, from: data)
        if let row = rows.first {
            return Recommendation(db: row)
        }
        return Recommendation(clientId: clientId, title: "New Recommendation", content: "", attachments: [], updatedAt: Date())
    }

    func saveRecommendation(_ recommendation: Recommendation) async throws -> Recommendation {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let body = try JSONEncoder.postgrest.encode(recommendation.toDB())
        let headers = [
            "Prefer": "resolution=merge-duplicates,return=representation"
        ]
        let query = [URLQueryItem(name: "on_conflict", value: "id")]
        let (data, _) = try await http.request(.post, path: "/rest/v1/recommendations", query: query, accessToken: session.accessToken, headers: headers, body: body)
        let rows = try JSONDecoder.postgrest.decode([DBRecommendation].self, from: data)
        guard let row = rows.first else { throw RepositoryError(message: "Failed to save recommendations") }
        return Recommendation(db: row)
    }

    func uploadAttachment(clientId: UUID, fileURL: URL) async throws -> RecommendationAttachment {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let data = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent.isEmpty ? "attachment" : fileURL.lastPathComponent
        let attachmentId = UUID()
        let path = "clients/\(clientId.uuidString)/\(attachmentId.uuidString)-\(fileName)"
        let contentType = mimeType(for: fileURL)
        try await storage.upload(bucket: attachmentsBucket, path: path, data: data, contentType: contentType, accessToken: session.accessToken, upsert: true)
        let url = storage.publicObjectURL(bucket: attachmentsBucket, path: path)
        return RecommendationAttachment(id: attachmentId, fileName: fileName, url: url, type: attachmentType(for: fileURL))
    }

    func deleteAttachment(clientId: UUID, attachmentId: UUID) async throws {
        // Optional for MVP: implement Storage delete.
        // We still remove it from the recommendation payload.
    }

    private func attachmentType(for url: URL) -> RecommendationAttachment.AttachmentType {
        switch url.pathExtension.lowercased() {
        case "pdf": return .pdf
        case "png", "jpg", "jpeg", "heic", "gif", "webp": return .image
        case "docx": return .docx
        default: return .other
        }
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default: return "application/octet-stream"
        }
    }
}

final class SupabasePublicLinkRepository: PublicLinkRepository {
    private let http: SupabaseHTTPClient
    private let storage: SupabaseStorageClient
    private let clientsRepository: ClientsRepository
    private let birthPlanRepository: BirthPlanRepository
    private let recommendationsRepository: RecommendationsRepository
    private let sessionProvider: () -> SupabaseSession?
    private let config: SupabaseConfig

    init(
        http: SupabaseHTTPClient,
        storage: SupabaseStorageClient,
        clientsRepository: ClientsRepository,
        birthPlanRepository: BirthPlanRepository,
        recommendationsRepository: RecommendationsRepository,
        sessionProvider: @escaping () -> SupabaseSession?,
        config: SupabaseConfig
    ) {
        self.http = http
        self.storage = storage
        self.clientsRepository = clientsRepository
        self.birthPlanRepository = birthPlanRepository
        self.recommendationsRepository = recommendationsRepository
        self.sessionProvider = sessionProvider
        self.config = config
    }

    func generateLink(for clientId: UUID) async throws -> PublicLink {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }

        // Try to reuse an existing active link (avoid rotating token on every open).
        let existingQuery = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientId.uuidString)"),
            URLQueryItem(name: "disabled", value: "is.false"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let (existingData, _) = try await http.request(.get, path: "/rest/v1/public_links", query: existingQuery, accessToken: session.accessToken)
        let existingRows = try JSONDecoder.postgrest.decode([DBPublicLink].self, from: existingData)

        let row: DBPublicLink
        if let reused = existingRows.first {
            row = reused
        } else {
            // Create new token
            let token = randomToken()
            let linkId = UUID()
            let db = DBPublicLink(
                id: linkId,
                client_id: clientId,
                token: token,
                created_at: Date(),
                expires_at: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                disabled: false
            )
            let body = try JSONEncoder.postgrest.encode(db)
            let headers = [
                "Prefer": "resolution=merge-duplicates,return=representation"
            ]
            let query = [URLQueryItem(name: "on_conflict", value: "id")]
            let (data, _) = try await http.request(.post, path: "/rest/v1/public_links", query: query, accessToken: session.accessToken, headers: headers, body: body)
            let rows = try JSONDecoder.postgrest.decode([DBPublicLink].self, from: data)
            guard let created = rows.first else { throw RepositoryError(message: "Failed to create link") }
            row = created
        }

        // Build & upload mini-cabinet HTML (public bucket, tokenized path).
        let clients = try await clientsRepository.fetchClients()
        let client = clients.first(where: { $0.id == clientId })
        let birthPlan = try? await birthPlanRepository.fetchBirthPlan(for: clientId)
        let rec = try? await recommendationsRepository.fetchRecommendations(for: clientId)
        if let client {
            let html = MiniCabinetHTMLBuilder.build(client: client, birthPlan: birthPlan, recommendation: rec)
            let path = "\(config.clientCabinetsPrefix)/\(row.token)/index.html"
            try await storage.upload(bucket: config.publicCabinetsBucket, path: path, data: Data(html.utf8), contentType: "text/html; charset=utf-8", accessToken: session.accessToken, upsert: true)
        }

        // Ensure app routing points to the storage public base URL
        PublicLinkRouting.clientCabinetPublicBaseURL = config.clientCabinetPublicBaseURL
        return PublicLink(db: row)
    }

    func revokeLink(_ linkId: UUID) async throws {
        guard let session = sessionProvider() else { throw RepositoryError(message: "Not authenticated") }
        let patch = try JSONEncoder.postgrest.encode(["disabled": true])
        let query = [URLQueryItem(name: "id", value: "eq.\(linkId.uuidString)")]
        _ = try await http.request(.patch, path: "/rest/v1/public_links", query: query, accessToken: session.accessToken, headers: ["Prefer": "return=representation"], body: patch)
    }
}

private func randomToken() -> String {
    // 32 hex chars
    let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
    return bytes.map { String(format: "%02x", $0) }.joined()
}

