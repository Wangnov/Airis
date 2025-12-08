import ArgumentParser

struct AdjustCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "adjust",
        abstract: "Adjust colors and geometry",
        discussion: """
            Fine-tune image properties:
            - Color controls (brightness, contrast, saturation)
            - Exposure and highlights/shadows
            - Temperature and tint (white balance)
            - Vignette effects
            - Geometric transformations (flip, rotate)

            Adjustments are non-destructive and can be combined.
            """,
        subcommands: [
            // ColorCommand.self,       // Task 8.1 实现
            // ExposureCommand.self,    // Task 8.1 实现
            // TemperatureCommand.self, // Task 8.1 实现
            // VignetteCommand.self,    // Task 8.1 实现
            // FlipCommand.self,        // Task 8.2 实现
            // RotateCommand.self,      // Task 8.2 实现
        ]
    )
}
