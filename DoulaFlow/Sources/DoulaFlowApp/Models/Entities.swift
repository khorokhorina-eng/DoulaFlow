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
        guard !token.isEmpty else { return nil }
        return URL(string: "https://doula.flow.link/c/\(token)")
    }
}
