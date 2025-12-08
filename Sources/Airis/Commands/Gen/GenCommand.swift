import ArgumentParser

struct GenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gen",
        abstract: "Generate images using AI providers",
        discussion: """
            Connect to AI image generation services like Gemini Image.
            Requires API key configuration.

            Subcommands:
            - draw: Generate images from text prompts
            - config: Manage API keys and settings
            """,
        subcommands: [
            // DrawCommand.self,      // Task 2.1 实现
            // ConfigCommand.self,    // Task 2.1 实现
        ]
    )
}
