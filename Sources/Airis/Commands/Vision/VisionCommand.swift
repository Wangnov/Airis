import ArgumentParser

struct VisionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "vision",
        abstract: "Advanced vision operations",
        discussion: """
            Advanced image analysis using Vision framework:
            - Optical flow analysis between image pairs
            - Image registration and alignment
            - Attention-based and objectness-based saliency detection
            - Person instance segmentation

            These operations leverage Apple's Neural Engine for \
            optimal performance on Apple Silicon.
            """,
        subcommands: [
            // FlowCommand.self,      // Task 5.1 实现
            // AlignCommand.self,     // Task 5.1 实现
            // SaliencyCommand.self,  // Task 5.1 实现
            // PersonsCommand.self,   // Task 5.1 实现
        ]
    )
}
