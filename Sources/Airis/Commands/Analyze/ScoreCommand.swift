import ArgumentParser
@preconcurrency import Vision
import Foundation

struct ScoreCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "score",
        abstract: "Calculate image aesthetic score",
        discussion: """
            Analyze image aesthetic quality using Apple's Vision framework.
            Returns an overall score and utility classification.

            QUICK START:
              airis analyze score photo.jpg

            EXAMPLES:
              # Get aesthetic score
              airis analyze score sunset.jpg

              # JSON output for scripting
              airis analyze score photo.png --format json

              # Batch scoring (use shell loop)
              for f in *.jpg; do airis analyze score "$f" --format json; done

            OUTPUT FORMAT (table):
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              ⭐ 美学评分
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 文件: sunset.jpg
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              综合评分: 0.85
              评价: 优秀
              实用性图像: 否

            OUTPUT FORMAT (json):
              {
                "overall_score": 0.85,
                "is_utility": false,
                "rating": "excellent"
              }

            SCORE INTERPRETATION:
              -1.0 to -0.5  : 较差 (Poor)
              -0.5 to  0.0  : 一般 (Fair)
               0.0 to  0.5  : 良好 (Good)
               0.5 to  1.0  : 优秀 (Excellent)

            UTILITY IMAGES:
              Screenshots, documents, QR codes, whiteboards are marked as
              "utility" images. They may have good technical quality but
              lack aesthetic appeal.

            REQUIREMENTS:
              macOS 15.0 or later (uses CalculateImageAestheticsScoresRequest)

            NOTES:
              - All processing is done locally on device
              - Score range: -1.0 (worst) to 1.0 (best)
            """
    )

    @Argument(help: "Path to the image file")
    var imagePath: String

    @Option(name: .long, help: "Output format: table (default), json")
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⭐ 美学评分")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 执行美学评分
        if #available(macOS 15.0, *) {
            let result = try await calculateAestheticsScore(url: url)

            if format.lowercased() == "json" {
                printJSON(result: result)
            } else {
                printTable(result: result)
            }
        } else {
            print("⚠️ 此功能需要 macOS 15.0 或更高版本")
            print("   当前系统版本不支持美学评分 API")
        }
    }

    @available(macOS 15.0, *)
    private func calculateAestheticsScore(url: URL) async throws -> AestheticsResult {
        let request = CalculateImageAestheticsScoresRequest()
        let observation = try await request.perform(on: url)

        return AestheticsResult(
            overallScore: observation.overallScore,
            isUtility: observation.isUtility
        )
    }

    private func printTable(result: AestheticsResult) {
        let scoreStr = String(format: "%.2f", result.overallScore)
        let rating = getRating(score: result.overallScore)

        print("综合评分: \(scoreStr)")
        print("评价: \(rating)")
        print("实用性图像: \(result.isUtility ? "是" : "否")")

        if result.isUtility {
            print("")
            print("💡 提示: 实用性图像（如截图、文档）通常评分较低，")
            print("   但这不代表图像质量差，而是缺乏美学吸引力。")
        }
    }

    private func printJSON(result: AestheticsResult) {
        let dict: [String: Any] = [
            "overall_score": result.overallScore,
            "is_utility": result.isUtility,
            "rating": getRatingEnglish(score: result.overallScore)
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func getRating(score: Float) -> String {
        switch score {
        case 0.5...: return "优秀"
        case 0.0..<0.5: return "良好"
        case -0.5..<0.0: return "一般"
        default: return "较差"
        }
    }

    private func getRatingEnglish(score: Float) -> String {
        switch score {
        case 0.5...: return "excellent"
        case 0.0..<0.5: return "good"
        case -0.5..<0.0: return "fair"
        default: return "poor"
        }
    }

    /// 美学评分结果
    struct AestheticsResult {
        let overallScore: Float
        let isUtility: Bool
    }
}
