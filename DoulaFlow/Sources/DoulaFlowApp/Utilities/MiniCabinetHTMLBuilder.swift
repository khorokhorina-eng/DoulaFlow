import Foundation

enum MiniCabinetHTMLBuilder {
    static func build(client: Client, birthPlan: BirthPlan?, recommendation: Recommendation?) -> String {
        let title = escape(client.name.isEmpty ? "Client" : client.name)
        let edd = DateFormatter.miniCabinetDate.string(from: client.estimatedDueDate)

        let birthPlanHTML: String = {
            guard let birthPlan else { return "<p class=\"muted\">No birth plan yet.</p>" }
            let sections = birthPlan.sections.map { section in
                """
                <section class="card">
                  <h3>\(escape(section.title))</h3>
                  <div class="content">\(MarkdownHTML.toHTML(section.body))</div>
                </section>
                """
            }.joined(separator: "\n")
            return sections.isEmpty ? "<p class=\"muted\">No birth plan yet.</p>" : sections
        }()

        let recHTML: String = {
            guard let recommendation else { return "<p class=\"muted\">No recommendations yet.</p>" }
            let content = MarkdownHTML.toHTML(recommendation.content)
            let attachments: String = {
                guard !recommendation.attachments.isEmpty else { return "" }
                let items = recommendation.attachments.map { att in
                    "<li><a href=\"\(escape(att.url.absoluteString))\" target=\"_blank\" rel=\"noopener noreferrer\">\(escape(att.fileName))</a></li>"
                }.joined(separator: "\n")
                return """
                <section class="card">
                  <h3>Attachments</h3>
                  <ul>\(items)</ul>
                </section>
                """
            }()
            return """
            <section class="card">
              <h3>\(escape(recommendation.title))</h3>
              <div class="content">\(content)</div>
            </section>
            \(attachments)
            """
        }()

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="robots" content="noindex,nofollow,noarchive" />
          <title>\(title) • BirthPrep Pro</title>
          <style>
            :root { color-scheme: light dark; }
            body { margin: 0; font-family: -apple-system, system-ui, Segoe UI, Roboto, Helvetica, Arial, sans-serif; background: #f6f6f8; color: #111; }
            .wrap { max-width: 760px; margin: 0 auto; padding: 20px 16px 40px; }
            header { margin: 10px 0 18px; }
            .brand { font-size: 12px; letter-spacing: 0.08em; text-transform: uppercase; color: #666; }
            h1 { margin: 6px 0 4px; font-size: 24px; }
            .meta { color: #666; font-size: 13px; }
            .tabs { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 18px 0; }
            .tab { background: #fff; border-radius: 12px; padding: 12px 14px; border: 1px solid #e5e5ea; }
            .tab h2 { margin: 0; font-size: 15px; }
            .card { background: #fff; border-radius: 12px; padding: 12px 14px; border: 1px solid #e5e5ea; margin: 10px 0; }
            .card h3 { margin: 0 0 8px; font-size: 15px; }
            .content p { margin: 0 0 10px; line-height: 1.4; }
            .content h2, .content h3 { margin: 12px 0 6px; }
            .content ul { margin: 6px 0 10px 18px; }
            .spacer { height: 10px; }
            a { color: #0a66c2; text-decoration: none; }
            a:hover { text-decoration: underline; }
            .muted { color: #666; }
            @media (prefers-color-scheme: dark) {
              body { background: #0b0b0d; color: #f3f3f5; }
              .tab, .card { background: #121216; border-color: #2a2a30; }
              .brand, .meta, .muted { color: #a7a7ad; }
              a { color: #6fb3ff; }
            }
          </style>
        </head>
        <body>
          <div class="wrap">
            <header>
              <div class="brand">BirthPrep Pro</div>
              <h1>\(title)</h1>
              <div class="meta">EDD: \(escape(edd)) • Week \(client.pregnancyWeek)</div>
            </header>

            <div class="tabs">
              <div class="tab">
                <h2>Birth plan</h2>
              </div>
              <div class="tab">
                <h2>Recommendations</h2>
              </div>
            </div>

            <h2>Birth plan</h2>
            \(birthPlanHTML)

            <h2>Recommendations</h2>
            \(recHTML)
          </div>
        </body>
        </html>
        """
    }

    private static func escape(_ s: String) -> String {
        s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

private extension DateFormatter {
    static let miniCabinetDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}

