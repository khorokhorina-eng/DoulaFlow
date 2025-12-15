import Foundation

struct DoulaProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var fullName: String
    var professionalTitle: String
    var experienceSummary: String
    var bio: String
    var photoURL: URL?
    var contactEmail: String
    var phoneNumber: String
    var website: URL?
    var certifications: [String]
}

struct Client: Identifiable, Codable, Equatable {
    enum Status: String, CaseIterable, Codable {
        case onboarding
        case preparing
        case approaching
        case postpartum

        var displayName: String {
            rawValue.capitalized
        }
    }

    var id: UUID = UUID()
    var doulaId: UUID
    var name: String
    var contactDetails: String
    var estimatedDueDate: Date
    var pregnancyWeek: Int
    var status: Status
    var notes: String
    var medicalNotes: String?
}

struct BirthPlanSection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
    }

    init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
    }
}

struct BirthPlan: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var clientId: UUID
    var sections: [BirthPlanSection]
    var updatedAt: Date
}

struct RecommendationAttachment: Identifiable, Codable, Equatable {
    enum AttachmentType: String, Codable {
        case pdf
        case image
        case docx
        case other
    }

    var id: UUID = UUID()
    var fileName: String
    var url: URL
    var type: AttachmentType

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case url
        case type
    }

    init(id: UUID = UUID(), fileName: String, url: URL, type: AttachmentType) {
        self.id = id
        self.fileName = fileName
        self.url = url
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        fileName = try container.decode(String.self, forKey: .fileName)
        url = try container.decode(URL.self, forKey: .url)
        type = try container.decode(AttachmentType.self, forKey: .type)
    }
}

struct Recommendation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var clientId: UUID
    var title: String
    var content: String
    var attachments: [RecommendationAttachment]
    var updatedAt: Date
}

struct PublicLink: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var clientId: UUID
    var token: String
    var createdAt: Date
    var expiresAt: Date?
    var disabled: Bool

    var shareURL: URL? {
        PublicLinkRouting.clientCabinetURL(token: token)
    }
}
