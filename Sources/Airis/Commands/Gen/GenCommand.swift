import ArgumentParser

struct GenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gen",
        abstract: "Generate images using AI providers",
        discussion: """
            Connect to AI image generation services like Gemini Image API.

            QUICK START (First Time Setup):
              1. Get API key from https://aistudio.google.com/apikey
              2. Configure: airis gen config set-key --provider gemini --key "YOUR_KEY"
              3. Generate: airis gen draw "a beautiful sunset"

            COMMANDS:
              draw    - Generate images from text prompts
              config  - Manage API keys and provider settings

            For detailed configuration options, run:
              airis gen config --help

            TROUBLESHOOTING:
              - "API key not found": Run 'airis gen config set-key --provider gemini --key "..."'
              - Check configuration: airis gen config show
            """,
        subcommands: [
            DrawCommand.self,
            ConfigCommand.self
        ]
    )
}
