import ArgumentParser
@preconcurrency import Vision
import Foundation

struct OCRCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "ocr",
        abstract: HelpTextFactory.text(
            en: "Extract text from images (OCR)",
            cn: "从图片中提取文字（OCR）"
        ),
        discussion: helpDiscussion(
            en: """
                Recognize and extract text from images using Apple's Vision \
                framework. Supports multiple languages including Chinese and English.

                QUICK START:
                  airis analyze ocr document.jpg

                EXAMPLES:
                  # Extract text from image
                  airis analyze ocr screenshot.png

                  # Specify languages (Chinese + English)
                  airis analyze ocr doc.jpg --languages zh-Hans,en

                  # Fast mode (less accurate but faster)
                  airis analyze ocr photo.png --level fast

                  # JSON output for scripting
                  airis analyze ocr image.heic --format json

                  # Extract text with bounding boxes
                  airis analyze ocr scan.jpg --show-bounds

                OUTPUT FORMAT (table):
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📝 文字识别 (OCR)
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📁 文件: document.jpg
                  🌐 语言: zh-Hans, en
                  ⚡ 识别级别: accurate
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  识别到 5 段文字

                  [1] Hello World
                  [2] 你好世界
                  [3] Welcome to Airis
                  ...

                OPTIONS:
                  --languages <list>    Comma-separated language codes
                                        (default: zh-Hans,en)
                  --level <mode>        Recognition level: fast, accurate
                                        (default: accurate)
                  --format <type>       Output format: table, json, text
                                        (default: table)
                  --show-bounds         Show bounding box coordinates

                SUPPORTED LANGUAGES:
                  en (English), zh-Hans (Simplified Chinese), zh-Hant (Traditional Chinese),
                  ja (Japanese), ko (Korean), de (German), fr (French), es (Spanish),
                  pt (Portuguese), it (Italian), ru (Russian), and more.

                NOTES:
                  - Uses VNRecognizeTextRequest from Apple Vision framework
                  - All processing is done locally on device
                  - 'accurate' level provides better results but is slower
                  - Language correction is enabled by default
                """,
            cn: """
                使用 Apple Vision 的文本识别能力从图片中提取文字（OCR）。
                支持中英文等多语言。

                QUICK START:
                  airis analyze ocr document.jpg

                EXAMPLES:
                  # 从图片提取文字
                  airis analyze ocr screenshot.png

                  # 指定语言（简体中文 + 英文）
                  airis analyze ocr doc.jpg --languages zh-Hans,en

                  # 快速模式（速度更快，精度更低）
                  airis analyze ocr photo.png --level fast

                  # JSON 输出（便于脚本解析）
                  airis analyze ocr image.heic --format json

                  # 输出文字坐标框
                  airis analyze ocr scan.jpg --show-bounds

                OPTIONS:
                  --languages <list>    语言代码列表（逗号分隔，默认：zh-Hans,en）
                  --level <mode>        识别级别：fast / accurate（默认：accurate）
                  --format <type>       输出格式：table / json / text（默认：table）
                  --show-bounds         输出 bounding box 坐标

                说明：
                  - 全部本地执行（不上传图片）
                  - accurate 更慢但更准
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Comma-separated language codes (default: zh-Hans,en)", cn: "语言代码列表（逗号分隔，默认：zh-Hans,en）"))
    var languages: String = "zh-Hans,en"

    @Option(
        name: .long,
        help: HelpTextFactory.help(
            en: "Recognition level: fast, accurate (default: accurate)",
            cn: "识别级别：fast / accurate（默认：accurate）"
        )
    )
    var level: String = "accurate"

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format: table (default), json, text", cn: "输出格式：table（默认）/ json / text"))
    var format: String = "table"

    @Flag(name: .long, help: HelpTextFactory.help(en: "Show bounding box coordinates", cn: "输出文字坐标框（bounding box）"))
    var showBounds: Bool = false

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let vision = ServiceContainer.shared.visionService

        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        // 解析语言列表
        let languageList = languages.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        // 解析识别级别
        let recognitionLevel: VNRequestTextRecognitionLevel = level.lowercased() == "fast" ? .fast : .accurate

        AirisOutput.printBanner([
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "📝 文字识别 (OCR)",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "📁 文件: \(url.lastPathComponent)",
            "🌐 语言: \(languageList.joined(separator: ", "))",
            "⚡ 识别级别: \(level.lowercased())",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ], enabled: showHumanOutput)

        #if DEBUG
        // 测试/调试环境下可注入桩结果，覆盖低置信度与坐标分支
        if ProcessInfo.processInfo.environment["AIRIS_FORCE_OCR_FAKE"] == "1" {
            let fakeResults = [
                TextResult(text: "低置信度", confidence: 0.42, boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.25)),
                TextResult(text: "高置信度", confidence: 0.95, boundingBox: CGRect(x: 0.55, y: 0.6, width: 0.2, height: 0.15))
            ]
            handleResults(fakeResults, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
            return
        }
        #endif

        // 执行 OCR
        let results = try await vision.recognizeText(
            at: url,
            languages: languageList,
            level: recognitionLevel
        )

        let textResults = extractTextResults(from: results)
        handleResults(textResults, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
    }

    private func extractTextResults(from observations: [VNRecognizedTextObservation]) -> [TextResult] {
        observations.compactMap { observation -> TextResult? in
            guard let topCandidate = observation.topCandidates(1).first else { return nil }

            let boundingBox = observation.boundingBox

            return TextResult(
                text: topCandidate.string,
                confidence: topCandidate.confidence,
                boundingBox: boundingBox
            )
        }
    }

    private func handleResults(_ textResults: [TextResult], outputFormat: OutputFormat, showHumanOutput: Bool) {
        if textResults.isEmpty {
            switch outputFormat {
            case .json:
                printJSON(results: [])
            case .text:
                break
            case .table:
                if showHumanOutput {
                    print(Strings.get("error.no_results"))
                }
            }
            return
        }

        switch outputFormat {
        case .json:
            printJSON(results: textResults)
        case .text:
            printPlainText(results: textResults)
        case .table:
            if showHumanOutput {
                printTable(results: textResults)
            }
        }
    }

#if DEBUG
    /// 测试辅助：覆盖 topCandidates 为空的分支
    static func testExtractEmptyCandidate() -> [TextResult] {
        let obs = VNRecognizedTextObservation()
        return OCRCommand().extractTextResults(from: [obs])
    }
#endif

    private func printTable(results: [TextResult]) {
        print("识别到 \(results.count) 段文字")
        print("")

        for (index, result) in results.enumerated() {
            print("[\(index + 1)] \(result.text)")

            if showBounds {
                let box = result.boundingBox
                let x = String(format: "%.2f", box.origin.x)
                let y = String(format: "%.2f", box.origin.y)
                let w = String(format: "%.2f", box.width)
                let h = String(format: "%.2f", box.height)
                print("    位置: (\(x), \(y)) 大小: \(w) × \(h)")
            }

            // 仅当置信度低时显示
            if result.confidence < 0.9 {
                print("    置信度: \(String(format: "%.2f", result.confidence))")
            }
        }
    }

    private func printJSON(results: [TextResult]) {
        let items = results.map { result -> [String: Any] in
            var item: [String: Any] = [
                "text": result.text,
                "confidence": result.confidence
            ]

            if showBounds {
                item["bounding_box"] = [
                    "x": result.boundingBox.origin.x,
                    "y": result.boundingBox.origin.y,
                    "width": result.boundingBox.width,
                    "height": result.boundingBox.height
                ]
            }

            return item
        }

        let dict: [String: Any] = [
            "count": results.count,
            "texts": items
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func printPlainText(results: [TextResult]) {
        // 纯文本输出，适合管道处理
        for result in results {
            print(result.text)
        }
    }

    /// OCR 识别结果
    struct TextResult {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
    }
}
