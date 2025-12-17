import Foundation

enum OutputFormat: String, Sendable {
    case table
    case json
    case text

    static func parse(_ value: String) -> OutputFormat {
        OutputFormat(rawValue: value.lowercased()) ?? .table
    }
}
