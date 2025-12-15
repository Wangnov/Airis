import ArgumentParser
import SensitiveContentAnalysis
import Foundation

struct SafeCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "safe",
        abstract: HelpTextFactory.text(
            en: "Detect sensitive content in images",
            cn: "检测图片是否包含敏感内容"
        ),
        discussion: helpDiscussion(
            en: """
                Analyze images for sensitive content (nudity) using Apple's
                SensitiveContentAnalysis framework.

                ⚠️  IMPORTANT REQUIREMENTS:
                ────────────────────────────────────────
                This feature requires ALL of the following:

                1. macOS 14.0 or later

                2. System setting enabled:
                   System Settings > Privacy & Security > Sensitive Content Warning

                3. App signed with PAID Apple Developer Program:
                   - Free developer accounts CANNOT use this feature
                   - Requires entitlement: com.apple.developer.sensitivecontentanalysis.client
                   - CLI must be code-signed with Developer ID

                If ANY requirement is not met, the command will show a warning
                and exit without analysis.
                ────────────────────────────────────────

                QUICK START:
                  airis analyze safe photo.jpg

                EXAMPLES:
                  # Basic sensitive content check
                  airis analyze safe photo.jpg

                  # JSON output for scripting
                  airis analyze safe image.png --format json

                  # Batch checking (use shell loop)
                  for f in *.jpg; do airis analyze safe "$f" --format json; done

                OUTPUT FORMAT (table):
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  🔒 敏感内容检测
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📁 文件: photo.jpg
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  ✅ 未检测到敏感内容

                OUTPUT FORMAT (json):
                  {
                    "file": "photo.jpg",
                    "is_sensitive": false
                  }

                PRIVACY NOTES:
                  - All analysis is performed locally on device
                  - Results are never transmitted off-device
                  - This feature respects user privacy settings
                """,
            cn: """
                使用 SensitiveContentAnalysis 检测图片是否包含敏感内容（如裸露）。

                ⚠️  重要要求（缺一不可）：
                  1) macOS 14.0+
                  2) 系统设置已开启：
                     系统设置 > 隐私与安全性 > 敏感内容警告
                  3) 需要付费 Apple Developer Program 签名：
                     - 免费开发者账号无法使用
                     - 需要 entitlement: com.apple.developer.sensitivecontentanalysis.client
                     - CLI 需使用 Developer ID 进行代码签名

                QUICK START:
                  airis analyze safe photo.jpg

                EXAMPLES:
                  # 基础检测
                  airis analyze safe photo.jpg

                  # JSON 输出（便于脚本解析）
                  airis analyze safe image.png --format json

                  # 批量检测（shell 示例）
                  for f in *.jpg; do airis analyze safe "$f" --format json; done

                隐私说明：
                  - 全部本地执行（不上传图片）
                  - 结果不会离开设备
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format: table (default), json", cn: "输出格式：table（默认）或 json"))
    var format: String = "table"

    func run() async throws {
        let testMode = ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1"
        let forcePolicyDisabled = ProcessInfo.processInfo.environment["AIRIS_SAFE_POLICY_DISABLED"] == "1"
        let forceSensitive = ProcessInfo.processInfo.environment["AIRIS_SAFE_FORCE_SENSITIVE"] == "1"
        let filename = URL(fileURLWithPath: imagePath).lastPathComponent
        let url = try FileUtils.validateImageFile(at: imagePath)

        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        AirisOutput.printBanner([
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            testMode ? "🔒 敏感内容检测 (TEST MODE)" : "🔒 敏感内容检测",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "📁 文件: \(url.lastPathComponent)",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ], enabled: showHumanOutput)

        // 选择分析器或测试桩
        let policy: SCSensitivityAnalysisPolicy
        let isSensitive: Bool

        if testMode {
            policy = forcePolicyDisabled ? .disabled : .simpleInterventions
            isSensitive = forceSensitive
        } else {
            #if DEBUG
            // 测试/调试构建走轻量桩，避免依赖真实敏感内容分析（需签名 & 系统设置）
            policy = .simpleInterventions
            isSensitive = false
            #else
            let analyzer = SCSensitivityAnalyzer()
            policy = analyzer.analysisPolicy
            if policy == .disabled {
                if outputFormat == .json {
                    printDisabledJSON(filename: filename)
                } else if showHumanOutput {
                    print(Strings.get("safe.disabled_hint"))
                }
                return
            }
            let result = try await analyzer.analyzeImage(at: url)
            isSensitive = result.isSensitive
            #endif
        }

        if policy == .disabled {
            // 测试模式下强制覆盖 policy 分支
            if outputFormat == .json {
                printDisabledJSON(filename: filename)
            } else if showHumanOutput {
                print(Strings.get("safe.disabled_hint"))
            }
            return
        }

        outputResult(isSensitive: isSensitive, filename: filename, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
    }

    private func outputResult(isSensitive: Bool, filename: String, outputFormat: OutputFormat, showHumanOutput: Bool) {
        if outputFormat == .json {
            let dict: [String: Any] = [
                "file": filename,
                "is_sensitive": isSensitive
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            return
        }

        // table
        guard showHumanOutput else { return }

        if isSensitive {
            print("⚠️  检测到敏感内容")
        } else {
            print("✅ " + Strings.get("safe.is_safe"))
        }
    }

    private func printDisabledJSON(filename: String) {
        let dict: [String: Any] = [
            "file": filename,
            "supported": false,
            "error": "policy_disabled"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}
