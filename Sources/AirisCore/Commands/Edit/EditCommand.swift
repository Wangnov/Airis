import ArgumentParser

struct EditCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "edit",
            abstract: HelpTextFactory.text(
                en: "Edit and transform images",
                cn: "编辑与转换图像"
            ),
            discussion: helpDiscussion(
                en: """
                Comprehensive image editing capabilities:
                - Background removal (cut)
                - Resizing and cropping
                - Auto-enhancement
                - Document scanning (scan)
                - Image straightening (straighten)
                - Vector tracing (trace)
                - Chromatic aberration removal (defringe)
                - Format conversion (fmt)
                - Thumbnail generation (thumb)
                - Artistic filters (via 'filter' subcommand)
                - Color adjustments (via 'adjust' subcommand)

                Most operations use CoreImage for GPU-accelerated processing.

                QUICK START:
                  # Remove background
                  airis edit cut photo.jpg -o cut.png

                  # Resize to 1920px width
                  airis edit resize photo.jpg --width 1920 -o resized.jpg

                  # Apply a photo filter
                  airis edit filter sepia photo.jpg -o sepia.jpg

                For detailed usage, run:
                  airis edit <subcommand> --help
                """,
                cn: """
                图像编辑与转换能力（主要基于 Core Image，支持 GPU 加速）：
                  - 背景移除（cut）
                  - 缩放 / 裁剪
                  - 自动增强（enhance）
                  - 文档扫描（scan）
                  - 自动拉直（straighten）
                  - 描边/矢量化（trace）
                  - 色边去除（defringe）
                  - 格式转换（fmt）
                  - 缩略图（thumb）
                  - 滤镜（filter）与色彩调整（adjust）

                QUICK START:
                  # 背景移除
                  airis edit cut photo.jpg -o cut.png

                  # 缩放到 1920px
                  airis edit resize photo.jpg --width 1920 -o resized.jpg

                  # 应用滤镜
                  airis edit filter sepia photo.jpg -o sepia.jpg

                进一步帮助：
                  airis edit <subcommand> --help
                """
            ),
            subcommands: [
                // 基础编辑命令（Task 6.2 实现）
                CutCommand.self,
                ResizeCommand.self,
                CropCommand.self,
                EnhanceCommand.self,

                // 高级编辑命令（Task 6.3 实现）
                ScanCommand.self,
                StraightenCommand.self,
                TraceCommand.self,
                DefringeCommand.self,
                FormatCommand.self,
                ThumbCommand.self,

                // 滤镜和调整子命令
                FilterCommand.self,
                AdjustCommand.self,
            ],
            aliases: ["e"]
        )
    }
}
