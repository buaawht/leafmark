import Foundation

public struct DocumentFileService {
    public enum FileError: LocalizedError, Equatable {
        case unsupportedExtension(String)
        case unreadableTextEncoding

        public var errorDescription: String? {
            switch self {
            case .unsupportedExtension(let ext):
                return "Unsupported file extension: \(ext)"
            case .unreadableTextEncoding:
                return "Could not read the file as UTF-8 text."
            }
        }
    }

    public init() {}

    public static func isSupportedDocument(_ url: URL) -> Bool {
        ["md", "markdown", "txt"].contains(url.pathExtension.lowercased())
    }

    public func read(from url: URL) throws -> String {
        guard Self.isSupportedDocument(url) else {
            throw FileError.unsupportedExtension(url.pathExtension)
        }

        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw FileError.unreadableTextEncoding
        }
        return text
    }

    public func write(_ text: String, to url: URL) throws {
        guard Self.isSupportedDocument(url) else {
            throw FileError.unsupportedExtension(url.pathExtension)
        }

        guard let data = text.data(using: .utf8) else {
            throw FileError.unreadableTextEncoding
        }

        try data.write(to: url, options: .atomic)
    }
}
