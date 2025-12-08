import ArgumentParser

struct EditCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit and transform images",
        discussion: """
            Comprehensive image editing capabilities:
            - Background removal (cut)
            - Resizing and cropping
            - Auto-enhancement
            - Document scanning
            - Perspective correction
            - Format conversion
            - Artistic filters (via 'filter' subcommand)
            - Color adjustments (via 'adjust' subcommand)

            Most operations use CoreImage for GPU-accelerated processing.
            """,
        subcommands: [
            // 基础编辑命令（Task 6.2 实现）
            // CutCommand.self,
            // ResizeCommand.self,
            // CropCommand.self,
            // EnhanceCommand.self,
            // ScanCommand.self,
            // StraightenCommand.self,
            // TraceCommand.self,
            // DefringeCommand.self,
            // FormatCommand.self,
            // ThumbCommand.self,

            // 滤镜和调整子命令
            FilterCommand.self,
            AdjustCommand.self,
        ]
    )
}
