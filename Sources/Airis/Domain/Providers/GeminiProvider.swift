import Foundation

/// Gemini 图像生成 Provider
final class GeminiProvider {
    private let httpClient: HTTPClient
    private let keychainManager: KeychainManager
    private let configManager: ConfigManager

    static let providerName = "gemini"
    static let defaultModel = "gemini-3-pro-image-preview"

    init(
        httpClient: HTTPClient = HTTPClient(),
        keychainManager: KeychainManager = KeychainManager(),
        configManager: ConfigManager = ConfigManager()
    ) {
        self.httpClient = httpClient
        self.keychainManager = keychainManager
        self.configManager = configManager
    }

    /// 生成图像
    func generateImage(
        prompt: String,
        references: [URL] = [],
        model: String? = nil,
        aspectRatio: String = "1:1",
        imageSize: String = "2K",
        outputPath: String? = nil,
        enableSearch: Bool = false
    ) async throws -> URL {
        // 获取 API Key
        let apiKey = try keychainManager.getAPIKey(for: Self.providerName)

        // 获取配置
        let providerConfig = try configManager.getProviderConfig(for: Self.providerName)

        // 确定模型（参数 > 配置 > 默认）
        let actualModel = model ?? providerConfig.model ?? Self.defaultModel

        // 构建 API 端点（v1beta 固定在代码中）
        let baseURL = providerConfig.baseURL ?? "https://generativelanguage.googleapis.com"
        let endpoint = "\(baseURL)/v1beta/models/\(actualModel):generateContent"

        guard let url = URL(string: endpoint) else {
            throw AirisError.invalidPath(endpoint)
        }

        // 打印进度
        print(Strings.get("gen.connecting"))
        print(Strings.get("gen.model", actualModel))
        print(Strings.get("gen.prompt", prompt))

        // 构建请求体
        var parts: [GeminiGenerateRequest.Part] = [
            GeminiGenerateRequest.Part(text: prompt, inlineData: nil)
        ]

        // 添加参考图片
        if !references.isEmpty {
            print(Strings.get("gen.references", references.count))

            for refURL in references {
                let (base64Data, mimeType) = try ImageUtils.encodeImageToBase64(at: refURL)
                let inlineData = GeminiGenerateRequest.InlineData(
                    mimeType: mimeType,
                    data: base64Data
                )
                parts.append(GeminiGenerateRequest.Part(text: nil, inlineData: inlineData))
            }
        }

        // 构建完整请求
        let tools: [GeminiGenerateRequest.Tool]? = enableSearch ? [
            GeminiGenerateRequest.Tool(
                googleSearch: GeminiGenerateRequest.Tool.GoogleSearch()
            )
        ] : nil

        let request = GeminiGenerateRequest(
            contents: [
                GeminiGenerateRequest.Content(parts: parts)
            ],
            generationConfig: GeminiGenerateRequest.GenerationConfig(
                responseModalities: ["TEXT", "IMAGE"],
                imageConfig: GeminiGenerateRequest.ImageConfig(
                    aspectRatio: aspectRatio,
                    imageSize: imageSize
                )
            ),
            tools: tools
        )

        // 发送请求
        print("")
        print(Strings.get("info.processing"))

        let headers = [
            "x-goog-api-key": apiKey
        ]

        let (responseData, _) = try await httpClient.postJSON(
            url: url,
            headers: headers,
            body: request
        )

        // 解析响应
        let decoder = JSONDecoder()
        let response = try decoder.decode(GeminiGenerateResponse.self, from: responseData)

        // 提取生成的图片（搜索所有 parts，因为使用 Google Search 时可能有多个 parts）
        guard let candidate = response.candidates.first else {
            throw AirisError.noResultsFound
        }

        // 查找包含图片的 part
        var imagePart: GeminiGenerateResponse.Part?
        for part in candidate.content.parts {
            if part.inlineData != nil {
                imagePart = part
                break
            }
        }

        guard let foundImagePart = imagePart,
              let inlineData = foundImagePart.inlineData else {
            throw AirisError.noResultsFound
        }

        // 生成输出路径
        let finalOutputPath = outputPath ?? FileUtils.generateOutputPath(
            from: "generated_\(Date().timeIntervalSince1970)",
            suffix: "",
            extension: "png"
        )

        // 解码并保存图片
        try ImageUtils.decodeAndSaveImage(
            base64String: inlineData.data,
            to: finalOutputPath,
            format: "png"
        )

        print("")
        print(Strings.get("info.saved_to", finalOutputPath))

        return URL(fileURLWithPath: finalOutputPath)
    }
}
