import Foundation

// MARK: - Gemini API Models

/// Gemini API 错误响应模型
struct GeminiErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let code: Int
        let message: String
        let status: String
    }
}

/// Gemini API 请求模型
struct GeminiGenerateRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig
    let tools: [Tool]?

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String?
        let inlineData: InlineData?
    }

    struct InlineData: Codable {
        let mimeType: String
        let data: String // Base64 encoded
    }

    struct Tool: Codable {
        let googleSearch: GoogleSearch

        struct GoogleSearch: Codable {
            // 空对象即可
        }
    }

    struct GenerationConfig: Codable {
        let responseModalities: [String]
        let imageConfig: ImageConfig?
    }

    struct ImageConfig: Codable {
        let aspectRatio: String?
        let imageSize: String?
    }
}

/// Gemini API 响应模型
struct GeminiGenerateResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String?
        let inlineData: InlineData?
        let thoughtSignature: String? // Gemini 3 Pro 的 Thinking 签名

        // 注意：响应使用 camelCase
        enum CodingKeys: String, CodingKey {
            case text
            case inlineData // 响应中是 camelCase，不是 snake_case
            case thoughtSignature
        }
    }

    struct InlineData: Codable {
        let mimeType: String
        let data: String // Base64 encoded

        enum CodingKeys: String, CodingKey {
            case mimeType
            case data
        }
    }
}
