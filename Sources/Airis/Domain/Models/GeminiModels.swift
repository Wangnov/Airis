import Foundation

// MARK: - Gemini API Models

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

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }
    }

    struct InlineData: Codable {
        let mimeType: String
        let data: String  // Base64 encoded

        enum CodingKeys: String, CodingKey {
            case mimeType = "mime_type"
            case data
        }
    }

    struct Tool: Codable {
        let googleSearch: GoogleSearch

        enum CodingKeys: String, CodingKey {
            case googleSearch = "google_search"
        }

        struct GoogleSearch: Codable {
            // 空对象即可
        }
    }

    struct GenerationConfig: Codable {
        let responseModalities: [String]
        let imageConfig: ImageConfig?

        enum CodingKeys: String, CodingKey {
            case responseModalities = "response_modalities"
            case imageConfig = "image_config"
        }
    }

    struct ImageConfig: Codable {
        let aspectRatio: String?
        let imageSize: String?

        enum CodingKeys: String, CodingKey {
            case aspectRatio = "aspect_ratio"
            case imageSize = "image_size"
        }
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

        // 注意：响应使用 camelCase
        enum CodingKeys: String, CodingKey {
            case text
            case inlineData  // 响应中是 camelCase，不是 snake_case
        }
    }

    struct InlineData: Codable {
        let mimeType: String
        let data: String  // Base64 encoded

        enum CodingKeys: String, CodingKey {
            case mimeType
            case data
        }
    }
}
