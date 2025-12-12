import ArgumentParser
import Foundation
import Darwin

@main
struct Airis: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "airis",
        abstract: "The AI-Native Messenger for Image Operations",
        discussion: """
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

    @OptionGroup var globalOptions: GlobalOptions

    mutating func validate() throws {
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
        let devNull = open("/dev/null", O_WRONLY)
        guard devNull != -1 else { return }
        dup2(devNull, STDOUT_FILENO)
        close(devNull)
    }
}

/// 全局选项（所有子命令共享）
struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: ArgumentHelp(
        "Output language",
        discussion: "Specify en or cn. Defaults to system language.",
        valueName: "lang"
    ))
    var lang: Language?

    @Flag(name: [.short, .long], help: "Enable verbose output")
    var verbose: Bool = false

    @Flag(name: .long, help: "Suppress all output except errors")
    var quiet: Bool = false
}
