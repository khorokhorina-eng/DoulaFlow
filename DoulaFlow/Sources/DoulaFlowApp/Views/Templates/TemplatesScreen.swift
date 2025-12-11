import SwiftUI

struct TemplatesScreen: View {
    @State private var birthPlanTemplates: [BirthPlanTemplate] = TemplateProvider.loadBirthPlanTemplates()
    @State private var recommendationTemplates: [RecommendationTemplate] = TemplateProvider.loadRecommendationTemplates()

    var body: some View {
        NavigationStack {
            List {
                Section("Birth Plan Templates") {
                    ForEach(birthPlanTemplates) { template in
                        VStack(alignment: .leading) {
                            Text(template.title).font(.headline)
                            Text("\(template.sections.count) sections").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Button("Add Birth Plan Template") {
                        birthPlanTemplates.append(BirthPlanTemplate(id: UUID().uuidString, title: "Untitled Template \(birthPlanTemplates.count + 1)", sections: []))
                    }
                }

                Section("Recommendation Templates") {
                    ForEach(recommendationTemplates) { template in
                        VStack(alignment: .leading) {
                            Text(template.title).font(.headline)
                            Text(template.content).lineLimit(2).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Button("Add Recommendation Template") {
                        recommendationTemplates.append(RecommendationTemplate(id: UUID().uuidString, title: "New Recommendation \(recommendationTemplates.count + 1)", content: "")) 
                    }
                }
            }
            .navigationTitle("Templates")
        }
    }
}
