import Foundation

struct BirthPlanTemplate: Codable, Identifiable {
    let id: String
    let title: String
    let sections: [BirthPlanSection]
}

struct RecommendationTemplate: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
}

enum TemplateProvider {
    static func loadBirthPlanTemplates() -> [BirthPlanTemplate] {
        loadJSON(filename: "birth_plan_templates", as: [BirthPlanTemplate].self)
    }

    static func loadRecommendationTemplates() -> [RecommendationTemplate] {
        loadJSON(filename: "recommendation_templates", as: [RecommendationTemplate].self)
    }

    private static func loadJSON<T: Decodable>(filename: String, as type: T.Type) -> T {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json") else {
            return defaultValue(for: T.self)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to load template: \(error)")
            return defaultValue(for: T.self)
        }
    }

    private static func defaultValue<T>(for type: T.Type) -> T {
        if let emptyArray = [] as? T {
            return emptyArray
        }
        fatalError("Unsupported default value for type \(T.self)")
    }
}
