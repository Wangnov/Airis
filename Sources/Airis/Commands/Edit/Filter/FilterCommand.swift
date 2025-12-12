import ArgumentParser

struct FilterCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "filter",
        abstract: "Apply artistic filters and effects",
        discussion: """
            Apply various artistic filters powered by CoreImage.

            QUICK START:
              # Apply a sepia tone
              airis edit filter sepia photo.jpg -o sepia.jpg

            BASIC FILTERS:
              blur       Blur effects (gaussian, motion, zoom)
              sharpen    Sharpen image details
              pixel      Pixelate/mosaic effect
              noise      Reduce image noise

            ARTISTIC EFFECTS:
              comic      Comic book style
              halftone   Halftone/dot screen printing effect

            PHOTO EFFECTS:
              sepia      Vintage sepia tone
              mono       Black and white
              chrome     Vivid chrome effect
              noir       High-contrast film noir
              instant    Polaroid/instant camera style

            All filters are optimized for GPU acceleration.
            """,
        subcommands: [
            // 基础滤镜
            BlurCommand.self,
            SharpenCommand.self,
            PixelCommand.self,
            NoiseCommand.self,
            // 艺术效果
            ComicCommand.self,
            HalftoneCommand.self,
            // 照片效果
            SepiaCommand.self,
            MonoCommand.self,
            ChromeCommand.self,
            NoirCommand.self,
            InstantCommand.self,
        ]
    )
}
