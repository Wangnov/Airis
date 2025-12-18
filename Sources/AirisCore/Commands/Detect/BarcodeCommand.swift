import ArgumentParser
import Foundation
@preconcurrency import Vision

struct BarcodeCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "barcode",
            abstract: HelpTextFactory.text(
                en: "Detect barcodes and QR codes in images",
                cn: "识别图片中的条码/二维码"
            ),
            discussion: helpDiscussion(
                en: """
                Detect and decode various barcode types including QR codes, EAN, \
                Code 128, and more.

                QUICK START:
                  airis detect barcode image.jpg

                SUPPORTED BARCODE TYPES:
                  QR          - QR Code (most common 2D code)
                  Aztec       - Aztec Code
                  Code128     - Code 128 (logistics, shipping)
                  Code39      - Code 39 (industrial)
                  Code93      - Code 93
                  EAN8        - EAN-8 (small products)
                  EAN13       - EAN-13 (retail products)
                  PDF417      - PDF417 (ID cards, tickets)
                  DataMatrix  - Data Matrix (electronics)
                  ITF14       - ITF-14 (shipping containers)
                  UPCE        - UPC-E (small retail items)

                EXAMPLES:
                  # Detect all barcode types
                  airis detect barcode photo.jpg

                  # Filter by type (QR codes only)
                  airis detect barcode scan.png --type qr

                  # JSON output for scripting
                  airis detect barcode receipt.jpg --format json

                  # Multiple images
                  airis detect barcode *.jpg

                OUTPUT EXAMPLE:
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Detected 2 barcode(s)

                  [1] QR Code
                      Data: https://example.com
                      Confidence: 0.98

                  [2] EAN-13
                      Data: 4006381333931
                      Confidence: 0.95
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                OPTIONS:
                  --type <type>    Filter by barcode type (qr, ean13, code128, etc.)
                  --format <fmt>   Output format: table (default), json
                """,
                cn: """
                使用 Apple Vision 框架识别并解码图片中的条码/二维码（QR、EAN、Code128 等）。

                QUICK START:
                  airis detect barcode image.jpg

                EXAMPLES:
                  # 识别全部类型
                  airis detect barcode photo.jpg

                  # 仅识别二维码（QR）
                  airis detect barcode scan.png --type qr

                  # JSON 输出（便于脚本解析）
                  airis detect barcode receipt.jpg --format json

                  # 多张图片
                  airis detect barcode *.jpg

                OPTIONS:
                  --type <type>    类型过滤（qr、ean13、code128 等）
                  --format <fmt>   输出格式：table（默认）或 json
                """
            )
        )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file(s)", cn: "输入图片路径（可多个）"))
    var imagePaths: [String]

    @Option(name: .long, help: HelpTextFactory.help(
        en: "Filter by barcode type (qr, aztec, code128, code39, ean8, ean13, pdf417, datamatrix, itf14, upce)",
        cn: "按类型过滤（qr、aztec、code128、code39、ean8、ean13、pdf417、datamatrix、itf14、upce）"
    ))
    var type: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    func run() async throws {
        let vision = ServiceContainer.shared.visionService
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        for imagePath in imagePaths {
            let url = try FileUtils.validateImageFile(at: imagePath)

            AirisOutput.printBanner([
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "🔍 Barcode Detection",
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "📁 File: \(url.lastPathComponent)",
            ] + (type.map { ["🔖 Type filter: \($0.uppercased())"] } ?? []) + [
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ], enabled: showHumanOutput)

            // 获取符号类型过滤
            let symbologies = type.flatMap { parseSymbology($0) }

            // 执行检测
            let results = try await vision.detectBarcodes(at: url, symbologies: symbologies)

            // 过滤结果（如果指定了类型）
            let filteredResults: [VNBarcodeObservation] = if let typeFilter = type, let symbology = parseSymbology(typeFilter)?.first {
                results.filter { $0.symbology == symbology }
            } else {
                results
            }

            if filteredResults.isEmpty {
                if outputFormat == .json {
                    printJSON(results: [], file: url.lastPathComponent)
                } else if showHumanOutput {
                    print("No barcodes detected.")
                    print("")
                }
                continue
            }

            // 输出结果
            if outputFormat == .json {
                printJSON(results: filteredResults, file: url.lastPathComponent)
            } else if showHumanOutput {
                printTable(results: filteredResults)
            }
        }
    }

    private func parseSymbology(_ type: String) -> [VNBarcodeSymbology]? {
        let mapping: [String: [VNBarcodeSymbology]] = [
            "qr": [.qr],
            "aztec": [.aztec],
            "code128": [.code128],
            "code39": [.code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum],
            "code93": [.code93, .code93i],
            "ean8": [.ean8],
            "ean13": [.ean13],
            "pdf417": [.pdf417],
            "datamatrix": [.dataMatrix],
            "itf14": [.itf14],
            "upce": [.upce],
        ]
        return mapping[type.lowercased()]
    }

    private func formatSymbology(_ symbology: VNBarcodeSymbology) -> String {
        let mapping: [VNBarcodeSymbology: String] = [
            .qr: "QR Code",
            .aztec: "Aztec",
            .code128: "Code 128",
            .code39: "Code 39",
            .code39Checksum: "Code 39",
            .code39FullASCII: "Code 39",
            .code39FullASCIIChecksum: "Code 39",
            .code93: "Code 93",
            .code93i: "Code 93",
            .ean8: "EAN-8",
            .ean13: "EAN-13",
            .pdf417: "PDF417",
            .dataMatrix: "Data Matrix",
            .itf14: "ITF-14",
            .upce: "UPC-E",
        ]

        if ProcessInfo.processInfo.environment["AIRIS_FORCE_BARCODE_UNKNOWN"] == "1" {
            let custom = VNBarcodeSymbology(rawValue: "custom_unknown")
            return mapping[custom] ?? custom.rawValue
        }
        return mapping[symbology] ?? symbology.rawValue
    }

    #if DEBUG
        /// 测试辅助：直接调用格式化函数
        static func testFormatSymbology(_ symbology: VNBarcodeSymbology) -> String {
            BarcodeCommand().formatSymbology(symbology)
        }
    #endif

    private func printTable(results: [VNBarcodeObservation]) {
        print("Detected \(results.count) barcode(s)")
        print("")

        for (index, observation) in results.enumerated() {
            print("[\(index + 1)] \(formatSymbology(observation.symbology))")
            if let payload = observation.payloadStringValue {
                print("    Data: \(payload)")
            }
            print("    Confidence: \(String(format: "%.2f", observation.confidence))")
            print("")
        }
    }

    private func printJSON(results: [VNBarcodeObservation], file: String) {
        let items = results.map { obs -> [String: Any] in
            var item: [String: Any] = [
                "type": formatSymbology(obs.symbology),
                "symbology": obs.symbology.rawValue,
                "confidence": obs.confidence,
                "bounding_box": [
                    "x": obs.boundingBox.origin.x,
                    "y": obs.boundingBox.origin.y,
                    "width": obs.boundingBox.width,
                    "height": obs.boundingBox.height,
                ],
            ]
            if let payload = obs.payloadStringValue {
                item["payload"] = payload
            }
            return item
        }

        let dict: [String: Any] = [
            "file": file,
            "count": results.count,
            "barcodes": items,
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            print(jsonString)
        }
    }
}
