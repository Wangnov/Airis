import ArgumentParser
import Darwin
import Foundation

public struct AirisCommand: AsyncParsableCommand {
    public static var configuration: CommandConfiguration {
        // 让 --help 也能受 --lang / AIRIS_LANG 影响。
        Language.current = Language.resolve(explicit: ArgumentPreparser.parseLang(from: CommandLine.arguments))

        return CommandConfiguration(
            commandName: "airis",
            abstract: HelpTextFactory.text(
                en: "The AI-Native Messenger for Image Operations",
                cn: "AI 驱动的图像处理 CLI 工具"
            ),
            discussion: helpDiscussion(
                en: """
                Airis combines Vision framework, CoreImage, and AI generation to
                provide comprehensive image processing capabilities.

                QUICK START:
                  # 1. Generate an image with AI
                  airis gen draw "cyberpunk cat"

                  # 2. Analyze image content
                  airis analyze tag image.jpg

                  # 3. Detect faces in image
                  airis detect face photo.jpg

                  # 4. Edit and transform
                  airis edit resize image.jpg --width 1920

                COMMAND GROUPS:
                  gen      - AI image generation (Gemini API)
                             Configure: airis gen config --help
                             Generate: airis gen draw "prompt"

                  analyze  - Image analysis and recognition
                             • Basic info, tags, OCR, aesthetic scoring
                             • Color palette, similarity, metadata
                             • All analysis runs locally (Vision + CoreImage)

                  detect   - Object and feature detection
                             • Barcodes, faces, animals
                             • Human poses (2D/3D), hand gestures
                             • Pet body pose detection

                  vision   - Advanced vision operations
                             • Optical flow, image alignment
                             • Saliency detection, person segmentation

                  edit     - Image editing and transformation
                             • Background removal, resize, crop, enhance
                             • Artistic filters, color adjustments
                             • Format conversion, thumbnails

                GLOBAL OPTIONS:
                  --lang en|cn     Output language (default: system language)
                  --verbose        Show detailed processing information
                  --quiet          Only show errors

                COMMON WORKFLOWS:
                  # Generate → Analyze → Edit pipeline
                  airis gen draw "landscape" -o scene.png
                  airis analyze tag scene.png
                  airis edit enhance scene.png -o final.png

                  # Batch detection
                  for img in *.jpg; do
                    airis detect face "$img" --json > "$img.json"
                  done

                  # Multi-provider generation
                  airis gen draw "cat" --provider gemini
                  airis gen draw "cat" --provider duckcoding

                CONFIGURATION:
                  API Keys: macOS Keychain (secure storage)
                  Settings: ~/.config/airis/config.json
                  Software link: ~/.local/bin/airis

                TROUBLESHOOTING:
                  • First time setup: airis gen config --help
                  • Check version: airis --version
                  • Get detailed help: airis <command> --help
                  • Report issues: github.com/airis/issues

                For more information, visit each command's help page.
                """,
                cn: """
                Airis 结合 Vision 框架、Core Image 与 AI 生成能力，
                提供一站式的图像分析、检测、编辑与生成工具。

                QUICK START:
                  # 1. 用 AI 生成图片
                  airis gen draw "赛博朋克猫"

                  # 2. 分析图片内容
                  airis analyze tag image.jpg

                  # 3. 检测图片中的人脸
                  airis detect face photo.jpg

                  # 4. 编辑与变换
                  airis edit resize image.jpg --width 1920

                命令分组：
                  gen      - AI 图像生成（Gemini API）
                             配置：airis gen config --help
                             生成：airis gen draw "prompt"

                  analyze  - 图像分析与识别（本地运行）
                             • 基础信息、标签、OCR、美学评分
                             • 调色板、相似度、元数据

                  detect   - 目标/特征检测（Vision）
                             • 条码、人脸、动物
                             • 人体姿态（2D/3D）、手势
                             • 宠物姿态

                  vision   - 高级视觉能力
                             • 光流、图像对齐
                             • 显著性检测、人物分割

                  edit     - 图像编辑与转换
                             • 背景移除、缩放、裁剪、增强
                             • 艺术滤镜、色彩调整
                             • 格式转换、缩略图

                全局选项：
                  --lang en|cn     输出语言（默认：系统语言）
                  --verbose        输出更详细的处理信息
                  --quiet          静默模式：仅输出错误

                常用工作流：
                  # 生成 → 分析 → 编辑
                  airis gen draw "landscape" -o scene.png
                  airis analyze tag scene.png
                  airis edit enhance scene.png -o final.png

                  # 批量检测
                  for img in *.jpg; do
                    airis detect face "$img" --json > "$img.json"
                  done

                配置位置：
                  API Key：macOS 钥匙串（安全存储）
                  配置文件：~/.config/airis/config.json
                  安装链接：~/.local/bin/airis

                排障：
                  • 首次配置：airis gen config --help
                  • 查看版本：airis --version
                  • 查看子命令帮助：airis <command> --help

                进一步信息请查看各子命令的帮助页。
                """
            ),
            version: "1.0.0",
            subcommands: [
                // 顶级命令组
                GenCommand.self,
                AnalyzeCommand.self,
                DetectCommand.self,
                VisionCommand.self,
                EditCommand.self,
            ]
        )
    }

    @OptionGroup public var globalOptions: GlobalOptions

    public init() {}

    public mutating func validate() throws {
        // 设置全局语言
        Language.current = Language.resolve(explicit: globalOptions.lang)

        // 解析全局 verbose/quiet
        AirisRuntime.isVerbose = globalOptions.verbose
        AirisRuntime.isQuiet = globalOptions.quiet

        if globalOptions.quiet {
            redirectStdoutToDevNull()
        }
    }

    // quiet 模式：重定向 stdout 到 /dev/null，只保留 stderr（错误）。
    private func redirectStdoutToDevNull() {
        #if DEBUG
            let forceFail = ProcessInfo.processInfo.environment["AIRIS_FORCE_QUIET_REDIRECT_FAIL"] == "1"
            let devNull = forceFail ? -1 : open("/dev/null", O_WRONLY)
        #else
            let devNull = open("/dev/null", O_WRONLY)
        #endif
        guard devNull != -1 else { return }
        dup2(devNull, STDOUT_FILENO)
        close(devNull)
    }
}

/// 全局选项（所有子命令共享）
public struct GlobalOptions: ParsableArguments {
    public init() {}

    @Option(name: .long, help: ArgumentHelp(
        HelpTextFactory.text(en: "Output language", cn: "输出语言"),
        discussion: HelpTextFactory.text(
            en: "Specify en or cn. Defaults to system language.",
            cn: "指定 en 或 cn。默认使用系统语言。"
        ),
        valueName: "lang"
    ))
    var lang: Language?

    @Flag(name: [.short, .long], help: HelpTextFactory.help(en: "Enable verbose output", cn: "开启 verbose 详细输出"))
    var verbose: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Suppress all output except errors", cn: "静默模式：仅输出错误信息"))
    var quiet: Bool = false
}
