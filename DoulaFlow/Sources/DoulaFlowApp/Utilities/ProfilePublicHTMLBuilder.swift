import Foundation

enum ProfilePublicHTMLBuilder {
    static func build(profile: DoulaProfile) -> String {
        let name = escape(profile.fullName.isEmpty ? "Doula" : profile.fullName)
        let title = escape(profile.professionalTitle)
        let exp = escape(profile.experienceSummary)
        let bio = MarkdownHTML.toHTML(profile.bio)
        let email = escape(profile.contactEmail)
        let phone = escape(profile.phoneNumber)
        let website = profile.website?.absoluteString ?? ""

        let certs = profile.certifications
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { "<li>\(escape($0))</li>" }
            .joined(separator: "\n")

        let websiteHTML = website.isEmpty ? "" : "<p><strong>Website:</strong> <a href=\"\(escape(website))\">\(escape(website))</a></p>"
        let certHTML = certs.isEmpty ? "" : "<h2>Certifications</h2><ul>\(certs)</ul>"

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="robots" content="noindex,nofollow,noarchive" />
          <title>\(name) • BirthPrep Pro</title>
          <style>
            :root { color-scheme: light dark; }
            body { margin: 0; font-family: -apple-system, system-ui, Segoe UI, Roboto, Helvetica, Arial, sans-serif; background: #f6f6f8; color: #111; }
            .wrap { max-width: 760px; margin: 0 auto; padding: 20px 16px 40px; }
            header { background: #fff; border: 1px solid #e5e5ea; border-radius: 12px; padding: 14px 16px; }
            .brand { font-size: 12px; letter-spacing: 0.08em; text-transform: uppercase; color: #666; }
            h1 { margin: 6px 0 2px; font-size: 24px; }
            .subtitle { color: #666; font-size: 14px; margin: 0; }
            h2 { margin: 18px 0 8px; font-size: 16px; }
            p { margin: 0 0 10px; line-height: 1.4; }
            .card { background: #fff; border: 1px solid #e5e5ea; border-radius: 12px; padding: 14px 16px; margin-top: 12px; }
            a { color: #0a66c2; text-decoration: none; }
            a:hover { text-decoration: underline; }
            @media (prefers-color-scheme: dark) {
              body { background: #0b0b0d; color: #f3f3f5; }
              header, .card { background: #121216; border-color: #2a2a30; }
              .brand, .subtitle { color: #a7a7ad; }
              a { color: #6fb3ff; }
            }
          </style>
        </head>
        <body>
          <div class="wrap">
            <header>
              <div class="brand">BirthPrep Pro</div>
              <h1>\(name)</h1>
              <p class="subtitle">\(title)</p>
              <p class="subtitle">\(exp)</p>
            </header>

            <div class="card">
              <h2>Bio</h2>
              <div>\(bio)</div>
            </div>

            <div class="card">
              <h2>Contact</h2>
              <p><strong>Email:</strong> <a href="mailto:\(email)">\(email)</a></p>
              <p><strong>Phone:</strong> \(phone)</p>
              \(websiteHTML)
            </div>

            <div class="card">
              \(certHTML)
            </div>
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

