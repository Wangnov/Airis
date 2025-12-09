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

            QUICK START:
              airis vision flow frame1.jpg frame2.jpg
              airis vision align ref.jpg target.jpg
              airis vision saliency photo.jpg -o heatmap.png
              airis vision persons portrait.jpg -o mask.png

            SUBCOMMANDS:
              flow      - Analyze optical flow between two images
              align     - Compute image registration transform
              saliency  - Detect visual attention regions
              persons   - Generate person segmentation mask
            """,
        subcommands: [
            FlowCommand.self,
            AlignCommand.self,
            SaliencyCommand.self,
            PersonsCommand.self,
        ],
        aliases: ["v"]
    )
}
