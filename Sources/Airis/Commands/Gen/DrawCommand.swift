import ArgumentParser
import Foundation

struct DrawCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draw",
        abstract: "Generate images using AI",
        discussion: """
            Generate images from text prompts, with optional reference images.

            Examples:
              airis gen draw "cyberpunk cat"
              airis gen draw "realistic photo" --ref sketch.jpg --aspect-ratio 16:9
              airis gen draw "portrait" --aspect-ratio 3:4 --image-size 4K
              airis gen draw "mix styles" --ref style1.jpg --ref style2.jpg -o output.png
            """
    )

    @Argument(help: "Text description for image generation")
    var prompt: String

    @Option(name: .long, help: "Reference image path (can be used multiple times)")
    var ref: [String] = []

    @Option(name: .long, help: "Model version ID (overrides config)")
    var model: String?

    @Option(name: .long, help: "AI provider (default: gemini)")
    var provider: String = "gemini"

    @Option(name: [.short, .long], help: "Output file path")
    var output: String?

    @Option(name: .long, help: "Aspect ratio (1:1, 16:9, 3:4, etc.)")
    var aspectRatio: String = "1:1"

    @Option(name: .long, help: "Image size (1K, 2K, 4K)")
    var imageSize: String = "2K"

    func run() async throws {
        // 验证参考图片
        let refURLs = try ref.map { path in
            try FileUtils.validateImageFile(at: path)
        }

        // 根据 provider 选择
        switch provider {
        case "gemini":
            let gemini = GeminiProvider()
            let outputURL = try await gemini.generateImage(
                prompt: prompt,
                references: refURLs,
                model: model,
                aspectRatio: aspectRatio,
                imageSize: imageSize,
                outputPath: output
            )

            // 显示输出位置（已在 Provider 中打印，这里无需重复）
            _ = outputURL

        default:
            throw AirisError.apiKeyNotFound(provider: provider)
        }
    }
}
