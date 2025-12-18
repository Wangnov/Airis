import ArgumentParser
import Foundation
@preconcurrency import Vision

struct TagCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "tag",
            abstract: HelpTextFactory.text(
                en: "Classify image scenes and objects",
                cn: "识别图片场景/对象标签"
            ),
            discussion: helpDiscussion(
                en: """
                Identify scenes, objects, and concepts in images using Apple's \
                Vision framework.

                QUICK START:
                  airis analyze tag photo.jpg

                EXAMPLES:
                  # Basic classification
                  airis analyze tag sunset.jpg

                  # Show top 10 results with confidence > 0.1
                  airis analyze tag photo.png --limit 10 --threshold 0.1

                  # JSON output for scripting
                  airis analyze tag image.heic --format json

                  # Show all results (no threshold)
                  airis analyze tag photo.jpg --threshold 0

                OUTPUT FORMAT (table):
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  🏷️  场景识别
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📁 文件: sunset.jpg
                  🎯 置信度阈值: 0.10
                  📊 显示数量: 10
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  检测到 15 个标签（显示前 10 个）

                  标签                          置信度
                  ─────────────────────────────────────
                  sunset                        0.95
                  sky                           0.92
                  outdoor                       0.88
                  cloud                         0.76

                OPTIONS:
                  --threshold <value>   Minimum confidence (0.0-1.0, default: 0.1)
                  --limit <count>       Maximum results to show (default: 20)
                  --format <type>       Output format: table, json (default: table)

                NOTES:
                  - Uses VNClassifyImageRequest from Apple Vision framework
                  - All processing is done locally on device
                  - Results are sorted by confidence (highest first)
                """,
                cn: """
                使用 Apple Vision 框架对图片进行场景/对象分类（标签识别）。

                QUICK START:
                  airis analyze tag photo.jpg

                EXAMPLES:
                  # 基础识别
                  airis analyze tag sunset.jpg

                  # 显示前 10 个结果，并设置阈值
                  airis analyze tag photo.png --limit 10 --threshold 0.1

                  # JSON 输出（便于脚本解析）
                  airis analyze tag image.heic --format json

                  # 显示全部（不设阈值）
                  airis analyze tag photo.jpg --threshold 0

                OPTIONS:
                  --threshold <value>   置信度阈值（0.0-1.0，默认：0.1）
                  --limit <count>       最大显示数量（默认：20）
                  --format <type>       输出格式：table（默认）或 json

                说明：
                  - 结果按置信度从高到低排序
                  - 全部本地执行（不上传图片）
                """
            )
        )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Minimum confidence threshold (0.0-1.0)", cn: "置信度阈值（0.0-1.0）"))
    var threshold: Float = 0.1

    @Option(name: .long, help: HelpTextFactory.help(en: "Maximum number of results to display", cn: "最大显示数量"))
    var limit: Int = 20

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format: table (default), json", cn: "输出格式：table（默认）或 json"))
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let vision = ServiceContainer.shared.visionService

        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        AirisOutput.printBanner([
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "🏷️  场景识别",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "📁 文件: \(url.lastPathComponent)",
            "🎯 置信度阈值: \(String(format: "%.2f", threshold))",
            "📊 显示数量: \(limit)",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ], enabled: showHumanOutput)

        // 执行分类
        #if DEBUG
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_TAG_STUB"] == "1" {
                let stub = Self.testObservations(count: 5)
                handleResults(stub, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
                return
            }
        #endif
        let results = try await vision.classifyImage(at: url, threshold: threshold)

        handleResults(results, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
    }

    private func handleResults(_ results: [VNClassificationObservation], outputFormat: OutputFormat, showHumanOutput: Bool) {
        if results.isEmpty {
            if outputFormat == .json {
                printJSON(results: [], total: 0)
            } else if showHumanOutput {
                print(Strings.get("error.no_results"))
            }
            return
        }

        // 限制结果数量
        let limitedResults = Array(results.prefix(limit))

        if outputFormat == .json {
            printJSON(results: limitedResults, total: results.count)
        } else if showHumanOutput {
            printTable(results: limitedResults, total: results.count)
        }
    }

    private func printTable(results: [VNClassificationObservation], total: Int) {
        if results.count < total {
            print("检测到 \(total) 个标签（显示前 \(results.count) 个）")
        } else {
            print("检测到 \(total) 个标签")
        }
        print("")

        // 表头
        let headerTag = "标签"
        let headerConf = "置信度"
        print("\(headerTag.padding(toLength: 30, withPad: " ", startingAt: 0))\(headerConf)")
        print(String(repeating: "─", count: 40))

        for observation in results {
            let identifier = observation.identifier
            let confidence = String(format: "%.2f", observation.confidence)
            print("\(identifier.padding(toLength: 30, withPad: " ", startingAt: 0))\(confidence)")
        }
    }

    private func printJSON(results: [VNClassificationObservation], total: Int) {
        let items = results.map { obs in
            [
                "identifier": obs.identifier,
                "confidence": obs.confidence,
            ] as [String: Any]
        }

        let dict: [String: Any] = [
            "total_count": total,
            "displayed_count": results.count,
            "tags": items,
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            print(jsonString)
        }
    }

    #if DEBUG
        /// 测试辅助：构造可控的标签列表，便于覆盖总数>显示数的分支
        static func testObservations(count: Int) -> [VNClassificationObservation] {
            // Vision 的 VNClassificationObservation 无公开 setter，测试仅需可控数量。
            (0 ..< count).map { _ in VNClassificationObservation() }
        }
    #endif
}
