import ArgumentParser

struct EditCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit and transform images",        discussion: """
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
            """,
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
