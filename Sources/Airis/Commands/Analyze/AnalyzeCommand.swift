import ArgumentParser

struct AnalyzeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze image properties and content",        discussion: """
            Provides comprehensive image analysis including:
            - Basic info (dimensions, DPI, color space)
            - Content recognition (tags, objects)
            - Aesthetic scoring
            - Text extraction (OCR)
            - Color palette extraction
            - Image similarity comparison
            - EXIF metadata reading/writing

            All analysis is performed locally using Apple's Vision \
            and CoreImage frameworks.
            """,
        subcommands: [
            InfoCommand.self,
            TagCommand.self,
            ScoreCommand.self,
            OCRCommand.self,
            SafeCommand.self,
            PaletteCommand.self,
            SimilarCommand.self,
            MetaCommand.self,
        ],
        aliases: ["a"]
    )
}
