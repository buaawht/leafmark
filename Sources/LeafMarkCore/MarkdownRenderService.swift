import Foundation
import Markdown

public struct MarkdownRenderService {
    public init() {}

    public func render(_ markdown: String, baseFileURL: URL?) throws -> String {
        var renderer = HTMLRenderer(baseFileURL: baseFileURL)
        let body = renderer.render(Document(parsing: markdown))

        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        body { color: #1f2933; font: 16px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.6; margin: 2rem auto; max-width: 760px; padding: 0 1rem; }
        h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 1.5em 0 0.5em; }
        p { margin: 0 0 1em; }
        blockquote { border-left: 4px solid #d0d7de; color: #57606a; margin: 1em 0; padding: 0 1em; }
        code { background: #f6f8fa; border-radius: 4px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; padding: 0.15em 0.3em; }
        pre { background: #f6f8fa; border-radius: 6px; overflow-x: auto; padding: 1em; }
        pre code { background: transparent; padding: 0; }
        table { border-collapse: collapse; margin: 1em 0; width: 100%; }
        th, td { border: 1px solid #d0d7de; padding: 0.4em 0.6em; }
        img { height: auto; max-width: 100%; }
        a { color: #0969da; }
        hr { border: 0; border-top: 1px solid #d0d7de; margin: 2em 0; }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}

private struct HTMLRenderer: MarkupWalker {
    private(set) var result = ""
    private let baseDirectoryURL: URL?
    private var inTableHead = false
    private var tableColumnAlignments: [Table.ColumnAlignment?] = []
    private var currentTableColumn = 0
    private var headingSlugger = DocumentHeadingSlugger()

    init(baseFileURL: URL?) {
        self.baseDirectoryURL = baseFileURL?.deletingLastPathComponent()
    }

    mutating func render(_ markup: Markup) -> String {
        visit(markup)
        return result
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let languageAttribute = codeBlock.language.map { " class=\"language-\(escapeAttribute($0))\"" } ?? ""
        result += "<pre><code\(languageAttribute)>\(escapeHTML(codeBlock.code))</code></pre>\n"
    }

    mutating func visitHeading(_ heading: Heading) {
        let slug = headingSlugger.slug(for: heading.plainText)
        result += "<h\(heading.level) id=\"\(escapeAttribute(slug))\">"
        descendInto(heading)
        result += "</h\(heading.level)>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr />\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += escapeHTML(html.rawHTML)
    }

    mutating func visitListItem(_ listItem: ListItem) {
        result += "<li>"
        descendInto(listItem)
        result += "</li>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        let startAttribute = orderedList.startIndex == 1 ? "" : " start=\"\(orderedList.startIndex)\""
        result += "<ol\(startAttribute)>\n"
        descendInto(orderedList)
        result += "</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result += "<ul>\n"
        descendInto(unorderedList)
        result += "</ul>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        descendInto(paragraph)
        result += "</p>\n"
    }

    mutating func visitTable(_ table: Table) {
        result += "<table>\n"
        tableColumnAlignments = table.columnAlignments
        descendInto(table)
        tableColumnAlignments = []
        result += "</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) {
        result += "<thead>\n<tr>\n"
        inTableHead = true
        currentTableColumn = 0
        descendInto(tableHead)
        inTableHead = false
        result += "</tr>\n</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) {
        guard !tableBody.isEmpty else { return }
        result += "<tbody>\n"
        descendInto(tableBody)
        result += "</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Table.Row) {
        result += "<tr>\n"
        currentTableColumn = 0
        descendInto(tableRow)
        result += "</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) {
        guard tableCell.colspan > 0, tableCell.rowspan > 0 else { return }

        let tag = inTableHead ? "th" : "td"
        result += "<\(tag)\(alignmentAttributeForCurrentColumn())>"
        currentTableColumn += 1
        descendInto(tableCell)
        result += "</\(tag)>\n"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        descendInto(emphasis)
        result += "</em>"
    }

    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        descendInto(strong)
        result += "</strong>"
    }

    mutating func visitImage(_ image: Image) {
        let alt = image.children.compactMap { ($0 as? InlineMarkup)?.plainText }.joined()
        result += "<img alt=\"\(escapeAttribute(alt))\""
        if let source = image.source,
           let safeSource = safeImageSource(source) {
            result += " src=\"\(escapeAttribute(safeSource))\""
        }
        if let title = image.title, !title.isEmpty {
            result += " title=\"\(escapeAttribute(title))\""
        }
        result += " />"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        result += escapeHTML(inlineHTML.rawHTML)
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br />\n"
    }

    mutating func visitLink(_ link: Link) {
        guard let destination = link.destination,
              let safeDestination = safeLinkDestination(destination) else {
            descendInto(link)
            return
        }

        result += "<a href=\"\(escapeAttribute(safeDestination))\""
        if let title = link.title, !title.isEmpty {
            result += " title=\"\(escapeAttribute(title))\""
        }
        result += ">"
        descendInto(link)
        result += "</a>"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    mutating func visitText(_ text: Text) {
        result += escapeHTML(text.string)
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        descendInto(strikethrough)
        result += "</del>"
    }

    mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
        if let destination = symbolLink.destination {
            result += "<code>\(escapeHTML(destination))</code>"
        }
    }

    private mutating func alignmentAttributeForCurrentColumn() -> String {
        guard currentTableColumn < tableColumnAlignments.count,
              let alignment = tableColumnAlignments[currentTableColumn] else {
            return ""
        }

        switch alignment {
        case .left:
            return " style=\"text-align: left;\""
        case .center:
            return " style=\"text-align: center;\""
        case .right:
            return " style=\"text-align: right;\""
        }
    }

    private func safeLinkDestination(_ destination: String) -> String? {
        guard let normalizedDestination = normalizedURLString(destination),
              isSafeURL(normalizedDestination, allowedSchemes: ["http", "https", "mailto", "file"]) else {
            return nil
        }
        return normalizedDestination
    }

    private func safeImageSource(_ source: String) -> String? {
        guard let normalizedSource = normalizedURLString(source),
              isSafeURL(normalizedSource, allowedSchemes: ["http", "https", "file"]) else {
            return nil
        }

        guard isRelativeFilePath(normalizedSource), let baseDirectoryURL else {
            return normalizedSource
        }

        return baseDirectoryURL.appendingPathComponent(normalizedSource).standardizedFileURL.absoluteString
    }

    private func normalizedURLString(_ urlString: String) -> String? {
        let boundaryCharacters = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: " "))
        let normalized = urlString.trimmingCharacters(in: boundaryCharacters)

        guard !normalized.isEmpty,
              normalized.rangeOfCharacter(from: .controlCharacters) == nil else {
            return nil
        }

        return normalized
    }

    private func isSafeURL(_ urlString: String, allowedSchemes: Set<String>) -> Bool {
        guard !urlString.hasPrefix("//") else { return false }
        guard let scheme = URLComponents(string: urlString)?.scheme else { return true }
        return allowedSchemes.contains(scheme.lowercased())
    }

    private func isRelativeFilePath(_ source: String) -> Bool {
        guard !source.hasPrefix("/"),
              !source.hasPrefix("#"),
              !source.hasPrefix("//") else {
            return false
        }
        return URLComponents(string: source)?.scheme == nil
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(_ string: String) -> String {
        escapeHTML(string)
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
