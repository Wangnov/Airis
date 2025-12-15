import ArgumentParser

struct AdjustCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "adjust",
        abstract: HelpTextFactory.text(
            en: "Adjust colors and geometry",
            cn: "色彩与几何调整"
        ),
        discussion: helpDiscussion(
            en: """
                Fine-tune image properties with precise control.

                QUICK START:
                  # Adjust brightness and saturation
                  airis edit adjust color photo.jpg --brightness 0.2 --saturation 1.2 -o enhanced.jpg

                COLOR ADJUSTMENTS:
                  color       - Brightness, contrast, saturation (CIColorControls)
                  exposure    - Exposure value adjustment (CIExposureAdjust)
                  temperature - Color temperature and tint (CITemperatureAndTint)
                  vignette    - Darkened edges effect (CIVignette)

                TONE EFFECTS:
                  invert      - Invert colors (negative effect)
                  posterize   - Reduce color levels (poster effect)
                  threshold   - Black/white threshold conversion

                GEOMETRIC TRANSFORMS:
                  flip        - Mirror horizontally/vertically
                  rotate      - Rotate by any angle

                EXAMPLES:
                  # Adjust brightness and saturation
                  airis edit adjust color photo.jpg --brightness 0.2 --saturation 1.2 -o enhanced.jpg

                  # Brighten underexposed photo
                  airis edit adjust exposure dark.jpg --ev 1.5 -o brighter.jpg

                  # Warm up colors
                  airis edit adjust temperature photo.jpg --temp 2000 -o warm.jpg

                  # Add vignette effect
                  airis edit adjust vignette portrait.jpg --intensity 1.2 -o artistic.jpg

                  # Invert colors
                  airis edit adjust invert art.png -o negative.png

                  # Create poster effect
                  airis edit adjust posterize photo.jpg --levels 4 -o poster.jpg

                  # Convert to pure black/white
                  airis edit adjust threshold doc.png --threshold 0.5 -o bw.png

                  # Flip horizontally
                  airis edit adjust flip selfie.jpg --horizontal -o mirrored.jpg

                  # Rotate 90 degrees
                  airis edit adjust rotate photo.jpg --angle 90 -o rotated.jpg

                All adjustments use GPU-accelerated CoreImage filters.
                """,
            cn: """
                使用 Core Image 对图片进行色彩/几何调整（GPU 加速）。

                QUICK START:
                  # 调整亮度与饱和度
                  airis edit adjust color photo.jpg --brightness 0.2 --saturation 1.2 -o enhanced.jpg

                子命令：
                  color       - 亮度/对比度/饱和度
                  exposure    - 曝光（EV）
                  temperature - 色温与色调
                  vignette    - 暗角
                  invert      - 反相
                  posterize   - 色阶海报化
                  threshold   - 黑白阈值
                  flip        - 翻转
                  rotate      - 旋转

                EXAMPLES:
                  airis edit adjust exposure dark.jpg --ev 1.5 -o brighter.jpg
                  airis edit adjust vignette portrait.jpg --intensity 1.2 -o artistic.jpg
                  airis edit adjust rotate photo.jpg --angle 90 -o rotated.jpg
                """
        ),
        subcommands: [
            // 色彩调整
            ColorCommand.self,
            ExposureCommand.self,
            TemperatureCommand.self,
            VignetteCommand.self,
            // 色调效果
            InvertCommand.self,
            PosterizeCommand.self,
            ThresholdCommand.self,
            // 几何变换
            FlipCommand.self,
            RotateCommand.self,
        ]
    )
    }
}
