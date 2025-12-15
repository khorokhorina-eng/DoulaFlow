import Foundation

enum SampleData {
    static let doulaProfile = DoulaProfile(
        fullName: "Avery Thompson",
        professionalTitle: "Certified Birth Doula",
        experienceSummary: "8 years supporting holistic births",
        bio: "Dedicated doula providing evidence-based guidance and emotional support before, during, and after labor.",
        photoURL: nil,
        contactEmail: "avery@doulaflow.app",
        phoneNumber: "+1 (555) 010-8899",
        website: URL(string: "https://averydoula.example.com"),
        certifications: ["DONA International", "CPR/AED", "Childbirth Educator"]
    )

    static let clients: [Client] = {
        let doulaId = doulaProfile.id
        return [
            Client(
                doulaId: doulaId,
                name: "Harper Lee",
                contactDetails: "harper@example.com / +1 (555) 010-1001",
                estimatedDueDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                pregnancyWeek: 32,
                status: .preparing,
                notes: "Prefers water birth, low-light environment.",
                medicalNotes: "Gestational diabetes diet controlled."
            ),
            Client(
                doulaId: doulaId,
                name: "Quinn Parker",
                contactDetails: "quinn@example.com / +1 (555) 010-4545",
                estimatedDueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                pregnancyWeek: 38,
                status: .approaching,
                notes: "Partner Alex will attend. Requests hypnobirthing cues.",
                medicalNotes: nil
            )
        ]
    }()

    static func birthPlan(for client: Client) -> BirthPlan {
        BirthPlan(
            clientId: client.id,
            sections: [
                BirthPlanSection(title: "Birth Environment", body: "Dim lights, calming music playlist, access to birthing ball."),
                BirthPlanSection(title: "Pain Management", body: "Hydrotherapy, hypnobirthing affirmations, nitrous optional."),
                BirthPlanSection(title: "Baby Care", body: "Immediate skin-to-skin, delayed cord clamping, breastfeeding within 1 hour.")
            ],
            updatedAt: Date()
        )
    }

    static func recommendations(for client: Client) -> Recommendation {
        Recommendation(
            clientId: client.id,
            title: "Weekly Prep",
            content: "## Movement\n- Daily walks\n- Prenatal yoga video: https://youtu.be/example\n\n### Nutrition\n- Iron-rich foods\n- Hydration goal: 3L/day",
            attachments: [
                RecommendationAttachment(fileName: "HospitalBag.pdf", url: URL(string: "https://example.com/HospitalBag.pdf")!, type: .pdf)
            ],
            updatedAt: Date()
        )
    }
}
