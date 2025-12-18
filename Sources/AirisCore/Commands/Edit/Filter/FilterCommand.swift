import ArgumentParser

struct FilterCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "filter",
            abstract: HelpTextFactory.text(
                en: "Apply artistic filters and effects",
                cn: "应用滤镜与艺术效果"
            ),
            discussion: helpDiscussion(
                en: """
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
                cn: """
                使用 Core Image 应用滤镜与艺术效果（GPU 加速）。

                QUICK START:
                  airis edit filter sepia photo.jpg -o sepia.jpg

                子命令：
                  blur / sharpen / pixel / noise
                  comic / halftone
                  sepia / mono / chrome / noir / instant
                """
            ),
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
}
