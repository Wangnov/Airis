import ArgumentParser
import Foundation

struct DrawCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draw",
        abstract: "Generate images using AI",
        discussion: """
            Generate images from text prompts, with optional reference images.

            BASIC EXAMPLES:
              airis gen draw "cyberpunk cat"
              airis gen draw "sunset landscape" --aspect-ratio 16:9 --image-size 4K
              airis gen draw "portrait" -o output.png --open

            PROMPT STRATEGIES (from Gemini best practices):

            1. PHOTOREALISTIC SCENES (use photography terms):
               "A photorealistic close-up portrait of an elderly Japanese ceramicist
               with deep wrinkles and warm smile, inspecting a tea bowl in his
               rustic workshop. Soft golden hour light through window. 85mm lens,
               bokeh background."

            2. STYLIZED ILLUSTRATIONS (be explicit about style):
               "A kawaii-style sticker of a happy red panda wearing a bamboo hat,
               munching bamboo. Bold outlines, cel-shading, vibrant colors.
               Transparent background."

            3. ACCURATE TEXT RENDERING (Pro model recommended):
               "Create a modern logo for 'The Daily Grind' coffee shop. Clean,
               bold sans-serif font. Black and white. Circular design with
               clever coffee bean element."

            4. PRODUCT MOCKUPS (use lighting/camera details):
               "Studio-lit product photo of matte black ceramic mug on concrete.
               Three-point softbox setup, soft highlights. 45-degree elevated
               angle. Sharp focus on steam. Square format."

            REFERENCE IMAGES (up to 14 with gemini-3-pro):
              # Single reference (style transfer, editing)
              airis gen draw "make it more vibrant" --ref original.jpg

              # Multiple references (character/object consistency)
              airis gen draw "group photo of these people making funny faces" \\
                --ref person1.jpg --ref person2.jpg --ref person3.jpg \\
                --model gemini-3-pro-image-preview --aspect-ratio 5:4

              # Style + composition mixing
              airis gen draw "combine these styles into landscape" \\
                --ref style1.jpg --ref style2.jpg --ref composition.jpg

            MODEL SELECTION:
              • Use gemini-2.5-flash-image for:
                - Fast iterations and previews
                - High-volume batch generation
                - Simple text-to-image

              • Use gemini-3-pro-image-preview for:
                - Professional assets and high resolution (4K)
                - Complex multi-turn editing
                - Accurate text rendering (logos, infographics)
                - Real-time data (Google Search grounding)
                - Multiple reference images (up to 14)

            ASPECT RATIO GUIDE:
              1:1   - Social media, icons, avatars
              3:4   - Portraits, book covers
              4:3   - Standard photos
              16:9  - Desktop wallpapers, presentations, YouTube thumbnails
              9:16  - Mobile wallpapers, Stories, Reels
              21:9  - Ultrawide cinema, banners

            RESOLUTION GUIDE (gemini-3-pro only):
              1K - Quick previews, web thumbnails
              2K - Standard social media, presentations (DEFAULT)
              4K - Print quality, professional assets

              Note: Must use uppercase 'K' (1K, not 1k)

            ADVANCED WORKFLOWS:
              # Image editing with reference
              airis gen draw "add wizard hat to this cat" --ref cat.jpg

              # Style transfer
              airis gen draw "transform to Van Gogh Starry Night style" --ref city.jpg

              # Multi-image composition
              airis gen draw "woman wearing this dress" --ref dress.jpg --ref model.jpg

              # Real-time information with Google Search (Pro model only)
              airis gen draw "current weather forecast for next 5 days in San Francisco" \\
                --enable-search --aspect-ratio 16:9 --model gemini-3-pro-image-preview

              # Sports news with Search grounding
              airis gen draw "last night's Champions League match graphic" \\
                --enable-search --model gemini-3-pro-image-preview

            BEST PRACTICES:
              ✓ Describe scenes, don't just list keywords
              ✓ Use specific details (colors, lighting, textures)
              ✓ Mention camera/lens for photorealistic results
              ✓ Be explicit about style for illustrations
              ✓ Use step-by-step for complex compositions
              ✗ Avoid vague terms like "make it better"
              ✗ Don't use negative prompts ("no cars"), describe positively

            POST-GENERATION:
              --open    Auto-open with default image viewer
              --reveal  Show in Finder after generation
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

    @Flag(name: .long, help: "Enable Google Search for real-time information (gemini-3-pro only)")
    var enableSearch: Bool = false

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
                outputPath: output,
                enableSearch: enableSearch
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
