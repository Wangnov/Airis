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
        case .fileNotFound(let path):
            return Strings.get("error.file_not_found", path)
        case .invalidPath(let path):
            return Strings.get("error.invalid_path", path)
        case .unsupportedFormat(let format):
            return Strings.get("error.unsupported_format", format)
        case .fileReadError(let path, _):
            return Strings.get("error.file_read", path)
        case .fileWriteError(let path, _):
            return Strings.get("error.file_write", path)
        case .visionRequestFailed(let message):
            return Strings.get("error.vision_failed", message)
        case .noResultsFound:
            return Strings.get("error.no_results")
        case .apiKeyNotFound(let provider):
            return Strings.get("error.api_key_not_found", provider)
        case .networkError(let error):
            return Strings.get("error.network", error.localizedDescription)
        case .invalidResponse:
            return Strings.get("error.invalid_response")
        case .invalidImageDimension(let width, let height, let max):
            return Strings.get("error.invalid_dimension", width, height, max)
        case .imageDecodeFailed:
            return Strings.get("error.image_decode")
        case .imageEncodeFailed:
            return Strings.get("error.image_encode")
        case .keychainError(let status):
            return Strings.get("error.keychain", Int(status))
        }
    }

    /// 恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .apiKeyNotFound(let provider):
            return Strings.get("error.api_key_recovery", provider)
        default:
            return nil
        }
    }

    /// 底层错误（用于错误链）
    var underlyingError: Error? {
        switch self {
        case .fileReadError(_, let error),
             .fileWriteError(_, let error),
             .networkError(let error):
            return error
        default:
            return nil
        }
    }
}
