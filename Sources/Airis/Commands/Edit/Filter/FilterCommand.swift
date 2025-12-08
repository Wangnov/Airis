import ArgumentParser

struct FilterCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "filter",
        abstract: "Apply artistic filters and effects",
        discussion: """
            Apply various artistic filters:
            - Blur effects (gaussian, motion, zoom)
            - Sharpen and noise reduction
            - Pixelation effects
            - Comic and halftone effects
            - Photo effects (sepia, mono, noir, chrome, etc.)

            All filters are powered by CoreImage and optimized for \
            GPU acceleration.
            """,
        subcommands: [
            // BlurCommand.self,      // Task 7.1 实现
            // SharpenCommand.self,   // Task 7.1 实现
            // PixelCommand.self,     // Task 7.1 实现
            // NoiseCommand.self,     // Task 7.1 实现
            // ComicCommand.self,     // Task 7.1 实现
            // HalftoneCommand.self,  // Task 7.1 实现
            // SepiaCommand.self,     // Task 7.2 实现
            // MonoCommand.self,      // Task 7.2 实现
            // NoirCommand.self,      // Task 7.2 实现
            // FadeCommand.self,      // Task 7.2 实现
            // ChromeCommand.self,    // Task 7.2 实现
            // ProcessCommand.self,   // Task 7.2 实现
            // TransferCommand.self,  // Task 7.2 实现
            // InstantCommand.self,   // Task 7.2 实现
        ]
    )
}
