import ArgumentParser

struct AnalyzeCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "analyze",
            abstract: HelpTextFactory.text(
                en: "Analyze image properties and content",
                cn: "分析图像属性与内容"
            ),
            discussion: helpDiscussion(
                en: """
                Provides comprehensive image analysis including:
                - Basic info (dimensions, DPI, color space)
                - Content recognition (tags, objects)
                - Aesthetic scoring
                - Text extraction (OCR)
                - Color palette extraction
                - Image similarity comparison
                - EXIF metadata reading/writing

                All analysis is performed locally using Apple's Vision
                and CoreImage frameworks.

                QUICK START:
                  # Show basic image info
                  airis analyze info photo.jpg

                  # Recognize top tags
                  airis analyze tag photo.jpg

                  # Extract text (OCR)
                  airis analyze ocr document.png

                For detailed usage, run:
                  airis analyze <subcommand> --help
                """,
                cn: """
                提供本地（离线）图像分析能力，主要基于 Apple Vision 与 Core Image：
                  - 基础信息：尺寸、DPI、色彩空间等
                  - 内容识别：标签/类别
                  - 美学评分（受系统版本限制）
                  - OCR 文字识别
                  - 调色板提取
                  - 图片相似度
                  - EXIF 元数据读写

                QUICK START:
                  # 查看基础信息
                  airis analyze info photo.jpg

                  # 输出标签
                  airis analyze tag photo.jpg

                  # OCR
                  airis analyze ocr document.png

                进一步帮助：
                  airis analyze <subcommand> --help
                """
            ),
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
}
