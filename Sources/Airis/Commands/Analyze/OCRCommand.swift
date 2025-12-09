import ArgumentParser
@preconcurrency import Vision
import Foundation

struct OCRCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Extract text from images (OCR)",
        discussion: """
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
            """
    )

    @Argument(help: "Path to the image file")
    var imagePath: String

    @Option(name: .long, help: "Comma-separated language codes (default: zh-Hans,en)")
    var languages: String = "zh-Hans,en"

    @Option(name: .long, help: "Recognition level: fast, accurate (default: accurate)")
    var level: String = "accurate"

    @Option(name: .long, help: "Output format: table (default), json, text")
    var format: String = "table"

    @Flag(name: .long, help: "Show bounding box coordinates")
    var showBounds: Bool = false

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let vision = ServiceContainer.shared.visionService

        // 解析语言列表
        let languageList = languages.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        // 解析识别级别
        let recognitionLevel: VNRequestTextRecognitionLevel = level.lowercased() == "fast" ? .fast : .accurate

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 文字识别 (OCR)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("🌐 语言: \(languageList.joined(separator: ", "))")
        print("⚡ 识别级别: \(level.lowercased())")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 执行 OCR
        let results = try await vision.recognizeText(
            at: url,
            languages: languageList,
            level: recognitionLevel
        )

        if results.isEmpty {
            print(Strings.get("error.no_results"))
            return
        }

        // 提取文本
        let textResults = extractTextResults(from: results)

        switch format.lowercased() {
        case "json":
            printJSON(results: textResults)
        case "text":
            printPlainText(results: textResults)
        default:
            printTable(results: textResults)
        }
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
