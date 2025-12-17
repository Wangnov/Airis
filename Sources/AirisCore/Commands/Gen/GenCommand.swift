import ArgumentParser

struct GenCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "gen",
            abstract: HelpTextFactory.text(
                en: "Generate images using AI providers",
                cn: "使用 AI 服务生成图像"
            ),
            discussion: helpDiscussion(
                en: """
                    Connect to AI image generation services like Gemini Image API.

                    QUICK START (First Time Setup):
                      1. Get API key from https://aistudio.google.com/apikey
                      2. Configure: airis gen config set-key --provider gemini --key "YOUR_KEY"
                      3. Generate: airis gen draw "a beautiful sunset"

                    AVAILABLE MODELS:
                      • gemini-2.5-flash-image (Nano Banana)
                        - Fast and efficient for high-volume tasks
                        - 1024px resolution, low latency
                        - Best for: Quick iterations, batch generation

                      • gemini-3-pro-image-preview (Nano Banana Pro) [DEFAULT]
                        - Professional asset production
                        - 1K/2K/4K resolution support
                        - Advanced text rendering, Google Search grounding
                        - Up to 14 reference images
                        - Thinking mode for complex prompts
                        - Best for: High-quality output, complex edits

                    SUPPORTED ASPECT RATIOS:
                      1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9

                    SUPPORTED RESOLUTIONS (gemini-3-pro only):
                      1K: 1024px level  (e.g., 1:1 = 1024x1024, 16:9 = 1376x768)
                      2K: 2048px level  (e.g., 1:1 = 2048x2048, 16:9 = 2752x1536)
                      4K: 4096px level  (e.g., 1:1 = 4096x4096, 16:9 = 5504x3072)

                    USE CASES:
                      • Text-to-image: Generate from text descriptions
                      • Image editing: Add/remove/modify elements with text
                      • Style transfer: Apply artistic styles to photos
                      • Multi-image composition: Combine up to 14 images
                      • Character consistency: Generate 360° views
                      • Real-time grounding: Use Google Search for current data

                    COMMANDS:
                      draw    - Generate images from text prompts
                      config  - Manage API keys and provider settings

                    For detailed configuration options, run:
                      airis gen config --help

                    TROUBLESHOOTING:
                      - "API key not found": Run 'airis gen config set-key --provider gemini --key "..."'
                      - Check configuration: airis gen config show
                      - Model selection: Use --model flag to override default
                    """,
                cn: """
                    连接并调用 AI 图像生成服务（如 Gemini Image API）。

                    QUICK START（首次配置）：
                      1. 获取 API Key：https://aistudio.google.com/apikey
                      2. 配置 Key：airis gen config set-key --provider gemini --key "YOUR_KEY"
                      3. 生成图片：airis gen draw "a beautiful sunset"

                    子命令：
                      draw    - 文本生成图片（可选参考图）
                      config  - 管理 API Key 与服务商配置

                    提示：
                      - 查看配置帮助：airis gen config --help
                      - 需要更详细输出：加 --verbose
                      - 仅输出错误：加 --quiet
                    """
            ),
            subcommands: [
                DrawCommand.self,
                ConfigCommand.self
            ],
            aliases: ["g"]
        )
    }
}
