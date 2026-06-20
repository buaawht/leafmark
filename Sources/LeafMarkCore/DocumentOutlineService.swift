import Foundation

public struct DocumentOutlineNode: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let level: Int
    public let line: Int
    public let slug: String

    public init(title: String, level: Int, line: Int, slug: String) {
        self.id = "\(line)-\(slug)"
        self.title = title
        self.level = level
        self.line = line
        self.slug = slug
    }
}

public struct DocumentOutlineService {
    public init() {}

    public func parse(_ markdown: String) -> [DocumentOutlineNode] {
        var nodes: [DocumentOutlineNode] = []
        var slugger = DocumentHeadingSlugger()
        var inFence = false
        var fenceMarker: String?

        for (offset, rawLine) in markdown.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = String(rawLine)
            let trimmedLeading = line.drop { $0 == " " || $0 == "\t" }

            if isFenceBoundary(String(trimmedLeading), marker: &fenceMarker, inFence: &inFence) {
                continue
            }

            guard !inFence,
                  let heading = parseHeading(line)
            else {
                continue
            }

            nodes.append(
                DocumentOutlineNode(
                    title: heading.title,
                    level: heading.level,
                    line: offset + 1,
                    slug: slugger.slug(for: heading.title)
                )
            )
        }

        return nodes
    }

    private func parseHeading(_ line: String) -> (level: Int, title: String)? {
        let leadingSpaces = line.prefix { $0 == " " }.count
        guard leadingSpaces <= 3 else { return nil }

        let trimmed = line.dropFirst(leadingSpaces)
        let level = trimmed.prefix { $0 == "#" }.count
        guard (1...6).contains(level) else { return nil }

        let afterHashes = trimmed.dropFirst(level)
        guard afterHashes.first?.isWhitespace == true else { return nil }

        let title = afterHashes
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .trimmingCharacters(in: .whitespaces)

        guard !title.isEmpty else { return nil }
        return (level, title)
    }

    private func isFenceBoundary(
        _ line: String,
        marker: inout String?,
        inFence: inout Bool
    ) -> Bool {
        guard line.hasPrefix("```") || line.hasPrefix("~~~") else {
            return false
        }

        let prefix = String(line.prefix(3))
        if inFence, marker == prefix {
            inFence = false
            marker = nil
        } else if !inFence {
            inFence = true
            marker = prefix
        }
        return true
    }
}

struct DocumentHeadingSlugger {
    private var countsByBaseSlug: [String: Int] = [:]

    mutating func slug(for title: String) -> String {
        let base = Self.baseSlug(for: title)
        let count = countsByBaseSlug[base, default: 0]
        countsByBaseSlug[base] = count + 1
        return count == 0 ? base : "\(base)-\(count)"
    }

    private static func baseSlug(for title: String) -> String {
        let lowered = title.lowercased()
        var scalars: [UnicodeScalar] = []
        var previousWasDash = false

        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                scalars.append(scalar)
                previousWasDash = false
            } else if !previousWasDash {
                scalars.append("-")
                previousWasDash = true
            }
        }

        let slug = String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return slug.isEmpty ? "section" : slug
    }
}
