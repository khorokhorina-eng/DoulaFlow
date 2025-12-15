import Foundation

enum MarkdownHTML {
    /// Very small Markdown subset for MVP mini-cabinet:
    /// - Headings: `##` and `###`
    /// - Bullets: `- `
    /// - Bold: `**text**`
    /// - Links: `[title](url)` and raw `https://...`
    static func toHTML(_ markdown: String) -> String {
        let lines = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        var html: [String] = []
        var inList = false

        func closeListIfNeeded() {
            if inList {
                html.append("</ul>")
                inList = false
            }
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                closeListIfNeeded()
                html.append("<div class=\"spacer\"></div>")
                continue
            }

            if line.hasPrefix("### ") {
                closeListIfNeeded()
                html.append("<h3>\(inline(line.dropFirst(4).string))</h3>")
                continue
            }
            if line.hasPrefix("## ") {
                closeListIfNeeded()
                html.append("<h2>\(inline(line.dropFirst(3).string))</h2>")
                continue
            }

            if line.hasPrefix("- ") {
                if !inList {
                    html.append("<ul>")
                    inList = true
                }
                html.append("<li>\(inline(line.dropFirst(2).string))</li>")
                continue
            }

            closeListIfNeeded()
            html.append("<p>\(inline(line))</p>")
        }

        closeListIfNeeded()
        return html.joined(separator: "\n")
    }

    private static func inline(_ text: String) -> String {
        var s = escape(text)
        s = replaceBold(s)
        s = replaceMarkdownLinks(s)
        s = linkifyURLs(s)
        return s
    }

    private static func escape(_ s: String) -> String {
        s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func replaceBold(_ s: String) -> String {
        // naive **bold** replacement
        var out = ""
        var i = s.startIndex
        var isBold = false
        while i < s.endIndex {
            if s[i...].hasPrefix("**") {
                out += isBold ? "</strong>" : "<strong>"
                isBold.toggle()
                i = s.index(i, offsetBy: 2)
            } else {
                out.append(s[i])
                i = s.index(after: i)
            }
        }
        if isBold { out += "</strong>" }
        return out
    }

    private static func replaceMarkdownLinks(_ s: String) -> String {
        // naive [title](url) replacement (no nesting)
        var result = s
        while let openBracket = result.firstIndex(of: "["),
              let closeBracket = result[openBracket...].firstIndex(of: "]"),
              closeBracket < result.endIndex,
              result[result.index(after: closeBracket)...].hasPrefix("("),
              let closeParen = result[result.index(after: closeBracket)...].firstIndex(of: ")") {
            let title = String(result[result.index(after: openBracket)..<closeBracket])
            let urlStart = result.index(closeBracket, offsetBy: 2)
            let url = String(result[urlStart..<closeParen])
            let replacement = "<a href=\"\(escape(url))\" target=\"_blank\" rel=\"noopener noreferrer\">\(escape(title))</a>"
            result.replaceSubrange(openBracket...closeParen, with: replacement)
        }
        return result
    }

    private static func linkifyURLs(_ s: String) -> String {
        // linkify raw https://... sequences separated by whitespace
        let parts = s.split(separator: " ", omittingEmptySubsequences: false)
        return parts.map { partSub in
            let part = String(partSub)
            if part.hasPrefix("https://") || part.hasPrefix("http://") {
                let url = part.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?)\"'"))
                return "<a href=\"\(escape(url))\" target=\"_blank\" rel=\"noopener noreferrer\">\(escape(url))</a>"
            }
            return part
        }.joined(separator: " ")
    }
}

private extension Substring {
    var string: String { String(self) }
}

