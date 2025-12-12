import ArgumentParser
@preconcurrency import Vision
import Foundation

struct TagCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        abstract: "Classify image scenes and objects",
        discussion: """
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
            """
    )

    @Argument(help: "Path to the image file")
    var imagePath: String

    @Option(name: .long, help: "Minimum confidence threshold (0.0-1.0)")
    var threshold: Float = 0.1

    @Option(name: .long, help: "Maximum number of results to display")
    var limit: Int = 20

    @Option(name: .long, help: "Output format: table (default), json")
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let vision = ServiceContainer.shared.visionService

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🏷️  场景识别")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("🎯 置信度阈值: \(String(format: "%.2f", threshold))")
        print("📊 显示数量: \(limit)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 执行分类
#if DEBUG
        if ProcessInfo.processInfo.environment["AIRIS_FORCE_TAG_STUB"] == "1" {
            let stub = Self._testObservations(count: 5)
            handleResults(stub)
            return
        }
#endif
        let results = try await vision.classifyImage(at: url, threshold: threshold)

        handleResults(results)
    }

    private func handleResults(_ results: [VNClassificationObservation]) {
        if results.isEmpty {
            print(Strings.get("error.no_results"))
            return
        }

        // 限制结果数量
        let limitedResults = Array(results.prefix(limit))

        if format.lowercased() == "json" {
            printJSON(results: limitedResults, total: results.count)
        } else {
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
                "confidence": obs.confidence
            ] as [String: Any]
        }

        let dict: [String: Any] = [
            "total_count": total,
            "displayed_count": results.count,
            "tags": items
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    #if DEBUG
    /// 测试辅助：构造可控的标签列表，便于覆盖总数>显示数的分支
    static func _testObservations(count: Int) -> [VNClassificationObservation] {
        (0..<count).map { idx in
            let obs = VNClassificationObservation()
            obs.setValue("tag_\(idx)", forKey: "identifier")
            obs.setValue(Float(1.0 - Double(idx) * 0.1), forKey: "confidence")
            return obs
        }
    }
    #endif
}
