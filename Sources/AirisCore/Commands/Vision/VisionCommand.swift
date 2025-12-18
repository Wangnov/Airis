import ArgumentParser

struct VisionCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "vision",
            abstract: HelpTextFactory.text(
                en: "Advanced vision operations",
                cn: "高级视觉能力"
            ),
            discussion: helpDiscussion(
                en: """
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
                cn: """
                基于 Vision 框架的高级视觉能力：
                  - 光流（两张图之间的运动）
                  - 图像对齐 / 配准
                  - 显著性检测（attention/objectness）
                  - 人物实例分割

                QUICK START:
                  airis vision flow frame1.jpg frame2.jpg
                  airis vision align ref.jpg target.jpg
                  airis vision saliency photo.jpg -o heatmap.png
                  airis vision persons portrait.jpg -o mask.png

                子命令：
                  flow      - 光流
                  align     - 对齐
                  saliency  - 显著性
                  persons   - 人物分割
                """
            ),
            subcommands: [
                FlowCommand.self,
                AlignCommand.self,
                SaliencyCommand.self,
                PersonsCommand.self,
            ],
            aliases: ["v"]
        )
    }
}
