import ArgumentParser
import Foundation

@main
struct Airis: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "airis",
        abstract: "The AI-Native Messenger for Image Operations",
        discussion: """
            Airis combines Vision framework, CoreImage, and AI generation \
            to provide comprehensive image processing capabilities.

            Use --lang to specify output language (en/cn).
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
