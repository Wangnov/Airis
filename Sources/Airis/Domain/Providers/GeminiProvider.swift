import Foundation

/// Gemini 兼容 API 图像生成 Provider（支持多个兼容端点）
final class GeminiProvider: Sendable {
    private let httpClient: HTTPClient
    private let keychainManager: KeychainManager
    private let configManager: ConfigManager
    private let providerName: String

    static let defaultModel = "gemini-3-pro-image-preview"

    init(
        providerName: String,
        httpClient: HTTPClient = HTTPClient(),
        keychainManager: KeychainManager = KeychainManager(),
        configManager: ConfigManager = ConfigManager()
    ) {
        self.providerName = providerName
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
        let apiKey = try keychainManager.getAPIKey(for: providerName)

        // 获取配置
        let providerConfig = try configManager.getProviderConfig(for: providerName)

        // 确定模型（参数 > 配置 > 默认）
        let actualModel = model ?? providerConfig.model ?? Self.defaultModel

        // 标准化 imageSize（支持 1k/2k/4k 等小写输入）
        let normalizedImageSize = imageSize.uppercased()

        // 构建 API 端点（v1beta 固定在代码中）
        let baseURL = providerConfig.baseURL ?? "https://generativelanguage.googleapis.com"
        let endpoint = "\(baseURL)/v1beta/models/\(actualModel):generateContent"

        guard let url = URL(string: endpoint) else {
            throw AirisError.invalidPath(endpoint)
        }

        // 打印进度和参数信息
        print(Strings.get("gen.connecting"))
        print("")
        print("🔑 模型: \(actualModel)")
        print("📝 提示词: \(prompt)")
        print("")
        print("📐 纵横比: \(aspectRatio)")

        if actualModel.contains("2.5-flash") {
            // Flash 模型固定 1024px
            let resolution = getResolutionForFlash(aspectRatio: aspectRatio)
            print("📏 分辨率: 1024px 级别 (\(resolution))")
        } else {
            // Pro 模型可变分辨率
            let resolution = getResolutionForPro(aspectRatio: aspectRatio, size: normalizedImageSize)
            print("📏 分辨率: \(normalizedImageSize) (\(resolution))")
        }

        if !references.isEmpty {
            print("🖼️  参考图片: \(references.count) 张")
            for (index, refURL) in references.enumerated() {
                print("   [\(index + 1)] \(refURL.lastPathComponent)")
            }
        }

        if let outputPath = outputPath {
            print("💾 输出路径: \(outputPath)")
        } else {
            print("💾 输出路径: 自动生成（当前目录）")
        }

        if enableSearch {
            print("🔍 Google Search: 已启用（实时信息）")
        }

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

        // gemini-2.5-flash-image 不支持 imageSize（固定 1024px）
        let imageConfig: GeminiGenerateRequest.ImageConfig?
        if actualModel.contains("2.5-flash") {
            // Flash 模型只支持 aspectRatio
            imageConfig = GeminiGenerateRequest.ImageConfig(
                aspectRatio: aspectRatio,
                imageSize: nil
            )
        } else {
            // Pro 模型支持 aspectRatio 和 imageSize（使用标准化后的值）
            imageConfig = GeminiGenerateRequest.ImageConfig(
                aspectRatio: aspectRatio,
                imageSize: normalizedImageSize
            )
        }

        let request = GeminiGenerateRequest(
            contents: [
                GeminiGenerateRequest.Content(parts: parts)
            ],
            generationConfig: GeminiGenerateRequest.GenerationConfig(
                responseModalities: ["TEXT", "IMAGE"],
                imageConfig: imageConfig
            ),
            tools: tools
        )

        // 发送请求
        print("")
        print("⏳ \(Strings.get("info.processing"))")

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

        // 查找包含图片的 part，同时收集文本响应
        var imagePart: GeminiGenerateResponse.Part?
        var textParts: [String] = []

        for part in candidate.content.parts where part.inlineData != nil {
            imagePart = part
            break
        }

        // 收集所有文本部分
        for part in candidate.content.parts {
            if let text = part.text, !text.isEmpty {
                textParts.append(text)
            }
        }

        guard let foundImagePart = imagePart,
              let inlineData = foundImagePart.inlineData else {
            // 如果有文本响应，将其作为错误信息提供给用户
            if !textParts.isEmpty {
                let reason = textParts.joined(separator: "\n")
                print("")
                print("⚠️ API 未返回图片，模型响应：")
                print("─────────────────────────────")
                print(reason)
                print("─────────────────────────────")
                print("")
                print("💡 建议：")
                print("   1. 尝试修改提示词")
                print("   2. 检查是否违反内容政策")
                print("   3. 使用 --model 切换模型")
                print("")
            }
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

    // MARK: - Resolution Helpers

    /// 获取 Flash 模型的实际分辨率
    private func getResolutionForFlash(aspectRatio: String) -> String {
        switch aspectRatio {
        case "1:1": return "1024×1024"
        case "2:3": return "832×1248"
        case "3:2": return "1248×832"
        case "3:4": return "864×1184"
        case "4:3": return "1184×864"
        case "4:5": return "896×1152"
        case "5:4": return "1152×896"
        case "9:16": return "768×1344"
        case "16:9": return "1344×768"
        case "21:9": return "1536×672"
        default: return "1024×1024"
        }
    }

    /// 获取 Pro 模型的实际分辨率
    private func getResolutionForPro(aspectRatio: String, size: String) -> String {
        // 容错处理：将 size 转为大写（支持 1k、2k、4k 等小写输入）
        let normalizedSize = size.uppercased()

        let resolutions: [String: [String: String]] = [
            "1K": [
                "1:1": "1024×1024",
                "2:3": "848×1264",
                "3:2": "1264×848",
                "3:4": "896×1200",
                "4:3": "1200×896",
                "4:5": "928×1152",
                "5:4": "1152×928",
                "9:16": "768×1376",
                "16:9": "1376×768",
                "21:9": "1584×672"
            ],
            "2K": [
                "1:1": "2048×2048",
                "2:3": "1696×2528",
                "3:2": "2528×1696",
                "3:4": "1792×2400",
                "4:3": "2400×1792",
                "4:5": "1856×2304",
                "5:4": "2304×1856",
                "9:16": "1536×2752",
                "16:9": "2752×1536",
                "21:9": "3168×1344"
            ],
            "4K": [
                "1:1": "4096×4096",
                "2:3": "3392×5056",
                "3:2": "5056×3392",
                "3:4": "3584×4800",
                "4:3": "4800×3584",
                "4:5": "3712×4608",
                "5:4": "4608×3712",
                "9:16": "3072×5504",
                "16:9": "5504×3072",
                "21:9": "6336×2688"
            ]
        ]

        return resolutions[normalizedSize]?[aspectRatio] ?? "Unknown"
    }
}
