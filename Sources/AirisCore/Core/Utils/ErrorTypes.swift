import Foundation

/// Airis 统一错误类型
enum AirisError: LocalizedError {
    // ============ 文件系统错误 ============
    case fileNotFound(String)
    case invalidPath(String)
    case unsupportedFormat(String)
    case fileReadError(String, Error)
    case fileWriteError(String, Error)

    // ============ Vision 框架错误 ============
    case visionRequestFailed(String)
    case noResultsFound

    // ============ API 相关错误 ============
    case apiKeyNotFound(provider: String)
    case apiError(provider: String, message: String)
    case networkError(Error)
    case invalidResponse

    // ============ 图像处理错误 ============
    case invalidImageDimension(width: Int, height: Int, max: Int)
    case imageDecodeFailed
    case imageEncodeFailed

    // ============ Keychain 错误 ============
    case keychainError(OSStatus)

    /// 本地化错误描述
    var errorDescription: String? {
        switch self {
        case let .fileNotFound(path):
            Strings.get("error.file_not_found", path)
        case let .invalidPath(path):
            Strings.get("error.invalid_path", path)
        case let .unsupportedFormat(format):
            Strings.get("error.unsupported_format", format)
        case let .fileReadError(path, _):
            Strings.get("error.file_read", path)
        case let .fileWriteError(path, _):
            Strings.get("error.file_write", path)
        case let .visionRequestFailed(message):
            Strings.get("error.vision_failed", message)
        case .noResultsFound:
            Strings.get("error.no_results")
        case let .apiKeyNotFound(provider):
            Strings.get("error.api_key_not_found", provider)
        case let .apiError(provider, message):
            "[\(provider)] \(message)"
        case let .networkError(error):
            Strings.get("error.network", error.localizedDescription)
        case .invalidResponse:
            Strings.get("error.invalid_response")
        case let .invalidImageDimension(width, height, max):
            Strings.get("error.invalid_dimension", width, height, max)
        case .imageDecodeFailed:
            Strings.get("error.image_decode")
        case .imageEncodeFailed:
            Strings.get("error.image_encode")
        case let .keychainError(status):
            Strings.get("error.keychain", Int(status))
        }
    }

    /// 恢复建议
    var recoverySuggestion: String? {
        switch self {
        case let .apiKeyNotFound(provider):
            Strings.get("error.api_key_recovery", provider)
        default:
            nil
        }
    }

    /// 底层错误（用于错误链）
    var underlyingError: Error? {
        switch self {
        case let .fileReadError(_, error),
             let .fileWriteError(_, error),
             let .networkError(error):
            error
        default:
            nil
        }
    }
}
