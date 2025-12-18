import ArgumentParser
import Foundation
@preconcurrency import Vision

struct ScoreCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "score",
            abstract: HelpTextFactory.text(
                en: "Calculate image aesthetic score",
                cn: "计算图片美学评分"
            ),
            discussion: helpDiscussion(
                en: """
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
                """,
                cn: """
                使用 Apple Vision 的美学评分能力给图片打分，并标注是否为“实用性图像”。

                QUICK START:
                  airis analyze score photo.jpg

                EXAMPLES:
                  # 获取评分
                  airis analyze score sunset.jpg

                  # JSON 输出（便于脚本解析）
                  airis analyze score photo.png --format json

                  # 批量评分（shell 示例）
                  for f in *.jpg; do airis analyze score "$f" --format json; done

                分数解释：
                  -1.0 ~ -0.5  : 较差
                  -0.5 ~  0.0  : 一般
                   0.0 ~  0.5  : 良好
                   0.5 ~  1.0  : 优秀

                实用性图像：
                  截图、文档、二维码、白板等通常会被标注为 utility。

                系统要求：
                  macOS 15.0+（CalculateImageAestheticsScoresRequest）

                说明：
                  - 全部本地执行（不上传图片）
                  - 分数范围：-1.0（最低）到 1.0（最高）
                """
            )
        )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format: table (default), json", cn: "输出格式：table（默认）或 json"))
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let testMode = ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1"
        let forceUtilityFalse = ProcessInfo.processInfo.environment["AIRIS_SCORE_UTILITY_FALSE"] == "1"
        let customScore = Float(ProcessInfo.processInfo.environment["AIRIS_SCORE_TEST_VALUE"] ?? "")

        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        AirisOutput.printBanner([
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "⭐ 美学评分",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "📁 文件: \(url.lastPathComponent)",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ], enabled: showHumanOutput)

        // 执行美学评分
        let result: AestheticsResult
        if testMode {
            // 测试模式：无需 macOS 15 API，直接构造结果覆盖所有输出分支
            result = AestheticsResult(
                overallScore: customScore ?? (forceUtilityFalse ? 0.12 : 0.62),
                isUtility: !forceUtilityFalse
            )
        } else {
            #if DEBUG
                // 测试/调试构建直接走降级提示，避免在较低系统调用不可用 API
                if outputFormat == .json {
                    printUnsupportedJSON()
                } else if showHumanOutput {
                    printUnsupportedHint()
                }
                return
            #else
                if #available(macOS 15.0, *) {
                    result = try await calculateAestheticsScore(url: url)
                } else {
                    if outputFormat == .json {
                        printUnsupportedJSON()
                    } else if showHumanOutput {
                        printUnsupportedHint()
                    }
                    return
                }
            #endif
        }

        if outputFormat == .json {
            printJSON(result: result)
        } else if showHumanOutput {
            printTable(result: result)
        }
    }

    #if !DEBUG
        @available(macOS 15.0, *)
        private func calculateAestheticsScore(url: URL) async throws -> AestheticsResult {
            let request = CalculateImageAestheticsScoresRequest()
            let observation = try await request.perform(on: url)

            return AestheticsResult(
                overallScore: observation.overallScore,
                isUtility: observation.isUtility
            )
        }
    #endif

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
            "rating": getRatingEnglish(score: result.overallScore),
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            print(jsonString)
        }
    }

    private func getRating(score: Float) -> String {
        switch score {
        case 0.5...: "优秀"
        case 0.0 ..< 0.5: "良好"
        case -0.5 ..< 0.0: "一般"
        default: "较差"
        }
    }

    private func getRatingEnglish(score: Float) -> String {
        switch score {
        case 0.5...: "excellent"
        case 0.0 ..< 0.5: "good"
        case -0.5 ..< 0.0: "fair"
        default: "poor"
        }
    }

    private func printUnsupportedHint() {
        print("⚠️ 此功能需要 macOS 15.0 或更高版本")
        print("   当前系统版本不支持美学评分 API")
    }

    private func printUnsupportedJSON() {
        let dict: [String: Any] = [
            "supported": false,
            "required_macos": "15.0",
            "error": "unsupported_os_version",
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            print(jsonString)
        }
    }

    /// 美学评分结果
    struct AestheticsResult {
        let overallScore: Float
        let isUtility: Bool
    }
}
