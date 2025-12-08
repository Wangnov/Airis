import ArgumentParser

struct AdjustCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "adjust",
        abstract: "Adjust colors and geometry",
        discussion: """
            Fine-tune image properties with precise control.

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
