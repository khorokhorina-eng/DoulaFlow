import Foundation
import UIKit

enum PDFGenerator {
    struct Layout {
        let pageRect: CGRect
        let margin: CGFloat

        var contentRect: CGRect {
            pageRect.insetBy(dx: margin, dy: margin)
        }

        static let a4: Layout = Layout(
            pageRect: CGRect(x: 0, y: 0, width: 595.2, height: 841.8), // A4 @ 72dpi
            margin: 48
        )
    }

    static func makeProfilePDF(profile: DoulaProfile, appName: String = "BirthPrep Pro") throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("birthprep-profile-\(safeFileComponent(profile.fullName)).pdf")
        try render(to: fileURL, layout: .a4) { context, layout in
            let styles = Styles()
            var cursor = Cursor(layout: layout)

            drawHeader(appName: appName, title: "Doula Profile", context: context, styles: styles, cursor: &cursor)

            cursor.writeTitle(profile.fullName, styles: styles)
            cursor.writeSubtitle(profile.professionalTitle, styles: styles)
            cursor.writeKeyValue("Experience", profile.experienceSummary, styles: styles)
            cursor.writeParagraph(profile.bio, styles: styles)

            cursor.writeSectionTitle("Contact", styles: styles)
            cursor.writeLinkLine(label: "Email", text: profile.contactEmail, url: URL(string: "mailto:\(profile.contactEmail)"), context: context, styles: styles)
            cursor.writeTextLine(label: "Phone", value: profile.phoneNumber, styles: styles)
            if let website = profile.website {
                cursor.writeLinkLine(label: "Website", text: website.absoluteString, url: website, context: context, styles: styles)
            }

            if !profile.certifications.isEmpty {
                cursor.writeSectionTitle("Certifications", styles: styles)
                cursor.writeBullets(profile.certifications, styles: styles)
            }
        }
        return fileURL
    }

    static func makeClientProfilePDF(client: Client, appName: String = "BirthPrep Pro") throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("birthprep-client-\(safeFileComponent(client.name)).pdf")
        try render(to: fileURL, layout: .a4) { context, layout in
            let styles = Styles()
            var cursor = Cursor(layout: layout)

            drawHeader(appName: appName, title: "Client Profile", context: context, styles: styles, cursor: &cursor)

            cursor.writeTitle(client.name, styles: styles)
            cursor.writeKeyValue("Status", client.status.displayName, styles: styles)
            cursor.writeKeyValue("Contact", client.contactDetails, styles: styles)
            cursor.writeKeyValue("Estimated Due Date (EDD)", DateFormatter.pdfDate.string(from: client.estimatedDueDate), styles: styles)
            cursor.writeKeyValue("Pregnancy week", "Week \(client.pregnancyWeek)", styles: styles)

            cursor.writeSectionTitle("Notes", styles: styles)
            cursor.writeParagraph(client.notes, styles: styles)

            if let medical = client.medicalNotes, !medical.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cursor.writeSectionTitle("Medical Notes", styles: styles)
                cursor.writeParagraph(medical, styles: styles)
            }
        }
        return fileURL
    }

    static func makeBirthPlanPDF(plan: BirthPlan, appName: String = "BirthPrep Pro") throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("birthprep-birthplan-\(plan.clientId.uuidString).pdf")
        try render(to: fileURL, layout: .a4) { context, layout in
            let styles = Styles()
            var cursor = Cursor(layout: layout)

            drawHeader(appName: appName, title: "Birth Plan", context: context, styles: styles, cursor: &cursor)
            cursor.writeKeyValue("Updated", DateFormatter.pdfDateTime.string(from: plan.updatedAt), styles: styles)

            for section in plan.sections {
                cursor.ensureSpace(minHeight: 90, context: context, styles: styles)
                cursor.writeSectionTitle(section.title, styles: styles)
                cursor.writeParagraph(section.body, styles: styles)
            }
        }
        return fileURL
    }
}

// MARK: - Rendering primitives

private extension PDFGenerator {
    static func render(to fileURL: URL, layout: Layout, draw: (UIGraphicsPDFRendererContext, Layout) -> Void) throws {
        let renderer = UIGraphicsPDFRenderer(bounds: layout.pageRect, format: UIGraphicsPDFRendererFormat())
        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            draw(context, layout)
        }
    }

    static func drawHeader(appName: String, title: String, context: UIGraphicsPDFRendererContext, styles: Styles, cursor: inout Cursor) {
        let headerLine = "\(appName) • \(title)"
        cursor.writeTopHeader(headerLine, styles: styles)
        cursor.writeDivider(styles: styles)
    }

    static func safeFileComponent(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "document" }
        return trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    struct Styles {
        let header: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let title: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let subtitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let sectionTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        let label: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let body: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.label
        ]
        let link: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.systemBlue
        ]
        let dividerColor: UIColor = UIColor.separator
    }

    struct Cursor {
        let layout: Layout
        var y: CGFloat

        init(layout: Layout) {
            self.layout = layout
            self.y = layout.contentRect.minY
        }

        mutating func writeTopHeader(_ text: String, styles: Styles) {
            let rect = CGRect(x: layout.contentRect.minX, y: y, width: layout.contentRect.width, height: 18)
            (text as NSString).draw(in: rect, withAttributes: styles.header)
            y = rect.maxY + 10
        }

        mutating func writeDivider(styles: Styles) {
            let x0 = layout.contentRect.minX
            let x1 = layout.contentRect.maxX
            let dividerY = y
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x0, y: dividerY))
            path.addLine(to: CGPoint(x: x1, y: dividerY))
            styles.dividerColor.setStroke()
            path.lineWidth = 1
            path.stroke()
            y = dividerY + 16
        }

        mutating func writeTitle(_ text: String, styles: Styles) {
            let rect = CGRect(x: layout.contentRect.minX, y: y, width: layout.contentRect.width, height: 30)
            (text as NSString).draw(in: rect, withAttributes: styles.title)
            y = rect.maxY + 8
        }

        mutating func writeSubtitle(_ text: String, styles: Styles) {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let rect = CGRect(x: layout.contentRect.minX, y: y, width: layout.contentRect.width, height: 18)
            (text as NSString).draw(in: rect, withAttributes: styles.subtitle)
            y = rect.maxY + 14
        }

        mutating func writeSectionTitle(_ text: String, styles: Styles) {
            let rect = CGRect(x: layout.contentRect.minX, y: y, width: layout.contentRect.width, height: 22)
            (text as NSString).draw(in: rect, withAttributes: styles.sectionTitle)
            y = rect.maxY + 8
        }

        mutating func writeKeyValue(_ label: String, _ value: String, styles: Styles) {
            writeTextLine(label: label, value: value, styles: styles)
            y += 6
        }

        mutating func writeTextLine(label: String, value: String, styles: Styles) {
            let labelText = "\(label): "
            let labelSize = (labelText as NSString).size(withAttributes: styles.label)
            let labelRect = CGRect(x: layout.contentRect.minX, y: y, width: min(labelSize.width, 180), height: 16)
            (labelText as NSString).draw(in: labelRect, withAttributes: styles.label)

            let valueRect = CGRect(x: labelRect.maxX, y: y, width: layout.contentRect.maxX - labelRect.maxX, height: 16)
            (value as NSString).draw(in: valueRect, withAttributes: styles.body)
            y = valueRect.maxY + 2
        }

        mutating func writeLinkLine(label: String, text: String, url: URL?, context: UIGraphicsPDFRendererContext, styles: Styles) {
            let labelText = "\(label): "
            let labelSize = (labelText as NSString).size(withAttributes: styles.label)
            let labelRect = CGRect(x: layout.contentRect.minX, y: y, width: min(labelSize.width, 180), height: 16)
            (labelText as NSString).draw(in: labelRect, withAttributes: styles.label)

            let linkRect = CGRect(x: labelRect.maxX, y: y, width: layout.contentRect.maxX - labelRect.maxX, height: 16)
            (text as NSString).draw(in: linkRect, withAttributes: styles.link)
            if let url {
                let linkTextSize = (text as NSString).size(withAttributes: styles.link)
                let tappableRect = CGRect(x: linkRect.minX, y: linkRect.minY, width: min(linkTextSize.width, linkRect.width), height: linkRect.height)
                context.setURL(url, for: tappableRect)
            }
            y = linkRect.maxY + 2
        }

        mutating func writeParagraph(_ text: String, styles: Styles) {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { return }
            let rect = CGRect(x: layout.contentRect.minX, y: y, width: layout.contentRect.width, height: layout.contentRect.maxY - y)
            let drawnHeight = (cleaned as NSString).boundingRect(
                with: rect.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: styles.body,
                context: nil
            ).height
            let drawRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: drawnHeight)
            (cleaned as NSString).draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: styles.body, context: nil)
            y = drawRect.maxY + 14
        }

        mutating func writeBullets(_ items: [String], styles: Styles) {
            for item in items {
                let bullet = "• \(item)"
                writeParagraph(bullet, styles: styles)
                y -= 8
            }
            y += 8
        }

        mutating func ensureSpace(minHeight: CGFloat, context: UIGraphicsPDFRendererContext, styles: Styles) {
            if y + minHeight > layout.contentRect.maxY {
                context.beginPage()
                y = layout.contentRect.minY
                writeTopHeader("BirthPrep Pro", styles: styles)
                writeDivider(styles: styles)
            }
        }
    }
}

private extension DateFormatter {
    static let pdfDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let pdfDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

