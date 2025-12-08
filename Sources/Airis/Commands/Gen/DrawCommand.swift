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
              airis gen draw "sunset" --open  # Auto-open after generation
              airis gen draw "landscape" --reveal  # Show in Finder after generation
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

    @Flag(name: .long, help: "Open image with default app after generation")
    var open: Bool = false

    @Flag(name: .long, help: "Reveal image in Finder after generation")
    var reveal: Bool = false

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

            // 打开图片或在 Finder 中显示
            if reveal {
                openInFinder(outputURL)
            } else if open {
                openWithDefaultApp(outputURL)
            }

        default:
            throw AirisError.apiKeyNotFound(provider: provider)
        }
    }

    /// 使用默认应用打开图片
    private func openWithDefaultApp(_ url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.path]

        do {
            try process.run()
        } catch {
            print("⚠️ Failed to open image: \(error.localizedDescription)")
        }
    }

    /// 在 Finder 中显示图片
    private func openInFinder(_ url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-R", url.path]

        do {
            try process.run()
        } catch {
            print("⚠️ Failed to reveal in Finder: \(error.localizedDescription)")
        }
    }
}
