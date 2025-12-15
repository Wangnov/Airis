import ArgumentParser
import Foundation

struct DrawCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draw",
        abstract: HelpTextFactory.text(
            en: "Generate images using AI",
            cn: "使用 AI 生成图片"
        ),
        discussion: helpDiscussion(
            en: """
                Generate images from text prompts, with optional reference images.

                QUICK START:
                  airis gen draw "cyberpunk cat"

                EXAMPLES:
                  # Text-to-image
                  airis gen draw "sunset landscape" --aspect-ratio 16:9 --image-size 4K -o output.png

                  # Edit with reference image
                  airis gen draw "make it more vibrant" --ref original.jpg -o edited.png

                  # Multiple references (gemini-3-pro only)
                  airis gen draw "group photo of these people making funny faces" \\
                    --ref person1.jpg --ref person2.jpg --ref person3.jpg \\
                    --model gemini-3-pro-image-preview --aspect-ratio 5:4 -o group.png

                  # Real-time grounding with Google Search (gemini-3-pro only)
                  airis gen draw "weather forecast for next 5 days in San Francisco" \\
                    --enable-search --aspect-ratio 16:9 --model gemini-3-pro-image-preview -o weather.png

                OPTIONS:
                  --ref <path>            Reference image path (repeatable)
                  --aspect-ratio <ratio>  1:1, 3:4, 4:3, 16:9, 9:16, 21:9, ...
                  --image-size <size>     1K, 2K (default), 4K
                  --open                  Open result after generation
                  --reveal                Reveal result in Finder after generation
                  --enable-search         Enable Google Search grounding (pro only)

                TROUBLESHOOTING:
                  - Configure API key: airis gen config set-key --provider gemini --key "..."
                  - Check config: airis gen config show
                """,
            cn: """
                根据文本提示词生成图片，可选添加参考图（用于编辑/风格迁移/一致性）。

                QUICK START:
                  airis gen draw "赛博朋克猫"

                EXAMPLES:
                  # 文生图
                  airis gen draw "sunset landscape" --aspect-ratio 16:9 --image-size 4K -o output.png

                  # 参考图编辑
                  airis gen draw "make it more vibrant" --ref original.jpg -o edited.png

                  # 多参考图（gemini-3-pro）
                  airis gen draw "group photo of these people making funny faces" \\
                    --ref person1.jpg --ref person2.jpg --ref person3.jpg \\
                    --model gemini-3-pro-image-preview --aspect-ratio 5:4 -o group.png

                  # 开启 Google Search 实时信息（gemini-3-pro）
                  airis gen draw "未来 5 天旧金山天气预报" \\
                    --enable-search --aspect-ratio 16:9 --model gemini-3-pro-image-preview -o weather.png

                OPTIONS:
                  --ref <path>            参考图路径（可重复传多个）
                  --aspect-ratio <ratio>  1:1, 3:4, 4:3, 16:9, 9:16, 21:9, ...
                  --image-size <size>     1K, 2K（默认）, 4K
                  --open                  生成后自动打开
                  --reveal                生成后在 Finder 中显示
                  --enable-search         启用 Google Search grounding（pro 模型）

                排障：
                  - 配置 API key：airis gen config set-key --provider gemini --key \"...\"
                  - 查看配置：airis gen config show
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Text description for image generation", cn: "用于生成图片的文本提示词"))
    var prompt: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Reference image path (can be used multiple times)", cn: "参考图路径（可重复传多个）"))
    var ref: [String] = []

    @Option(name: .long, help: HelpTextFactory.help(en: "Model version ID (overrides config)", cn: "模型版本 ID（覆盖默认配置）"))
    var model: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "AI provider (default: from config or 'gemini')", cn: "AI Provider（默认：配置或 gemini）"))
    var provider: String?

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output file path", cn: "输出文件路径"))
    var output: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Aspect ratio (1:1, 16:9, 3:4, etc.)", cn: "画面比例（1:1、16:9、3:4 等）"))
    var aspectRatio: String = "1:1"

    @Option(name: .long, help: HelpTextFactory.help(en: "Image size (1K, 2K, 4K)", cn: "图片尺寸等级（1K / 2K / 4K）"))
    var imageSize: String = "2K"

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open image with default app after generation", cn: "生成后用默认应用打开"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Reveal image in Finder after generation", cn: "生成后在 Finder 中显示"))
    var reveal: Bool = false

    @Flag(
        name: .long,
        help: HelpTextFactory.help(
            en: "Enable Google Search for real-time information (gemini-3-pro only)",
            cn: "启用 Google Search 实时信息（gemini-3-pro）"
        )
    )
    var enableSearch: Bool = false

    func run() async throws {
        let isTestMode = ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1"
        // 确定使用的 provider
        let configManager = ConfigManager()
        let config = try configManager.loadConfig()
        let actualProvider = provider ?? config.defaultProvider ?? "gemini"

        // 验证参考图片
        let refURLs = try ref.map { path in
            try FileUtils.validateImageFile(at: path)
        }

        // 显示即将使用的参数（生成前总览）
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎨 图像生成参数")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🏢 Provider: \(actualProvider)")

        if let output = output {
            print("💾 输出: \(output)")
        }

        if open {
            print("👁️  完成后: 自动打开图片")
        } else if reveal {
            print("👁️  完成后: 在 Finder 中显示")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 使用通用的 Gemini 兼容 API
        let imageProvider = GeminiProvider(providerName: actualProvider)
        let outputURL = try await imageProvider.generateImage(
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
            print("")
            print("📂 正在 Finder 中显示...")
            openInFinder(outputURL, isTestMode: isTestMode)
        } else if open {
            print("")
            print("🖼️  正在打开图片...")
            openWithDefaultApp(outputURL, isTestMode: isTestMode)
        }
    }

    /// 使用默认应用打开图片
    private func openWithDefaultApp(_ url: URL, isTestMode: Bool) {
        let process = Process()
        #if DEBUG
        let forceFail = ProcessInfo.processInfo.environment["AIRIS_FORCE_DRAW_OPEN_FAIL"] == "1"
        var executable = forceFail ? "/nonexistent/open" : (isTestMode ? "/usr/bin/true" : "/usr/bin/open")
        if let override = ProcessInfo.processInfo.environment["AIRIS_DRAW_OPEN_EXECUTABLE_OVERRIDE"] {
            executable = override
        }
        #else
        let executable = isTestMode ? "/usr/bin/true" : "/usr/bin/open"
        #endif
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = isTestMode ? [] : [url.path]

        do {
            try process.run()
        } catch {
            print("⚠️ Failed to open image: \(error.localizedDescription)")
        }
    }

    /// 在 Finder 中显示图片
    private func openInFinder(_ url: URL, isTestMode: Bool) {
        let process = Process()
        #if DEBUG
        let forceFail = ProcessInfo.processInfo.environment["AIRIS_FORCE_DRAW_REVEAL_FAIL"] == "1"
        var executable = forceFail ? "/nonexistent/open" : (isTestMode ? "/usr/bin/true" : "/usr/bin/open")
        if let override = ProcessInfo.processInfo.environment["AIRIS_DRAW_REVEAL_EXECUTABLE_OVERRIDE"] {
            executable = override
        }
        #else
        let executable = isTestMode ? "/usr/bin/true" : "/usr/bin/open"
        #endif
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = isTestMode ? [] : ["-R", url.path]

        do {
            try process.run()
        } catch {
            print("⚠️ Failed to reveal in Finder: \(error.localizedDescription)")
        }
    }
}

#if DEBUG
extension DrawCommand {
    /// 测试辅助：暴露私有打开方法
    func testOpenWithDefaultApp(_ url: URL, isTestMode: Bool) {
        openWithDefaultApp(url, isTestMode: isTestMode)
    }

    func testOpenInFinder(_ url: URL, isTestMode: Bool) {
        openInFinder(url, isTestMode: isTestMode)
    }
}
#endif
