import ArgumentParser
import SensitiveContentAnalysis
import Foundation

struct SafeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "safe",
        abstract: "Detect sensitive content in images",
        discussion: """
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
        print("🔒 敏感内容检测")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 创建分析器
        let analyzer = SCSensitivityAnalyzer()

        // 检查分析策略
        let policy = analyzer.analysisPolicy
        if policy == .disabled {
            print(Strings.get("safe.disabled_hint"))
            return
        }

        // 分析图片
        let result = try await analyzer.analyzeImage(at: url)

        if format.lowercased() == "json" {
            printJSON(result: result, filename: url.lastPathComponent)
        } else {
            printTable(result: result)
        }
    }

    private func printTable(result: SCSensitivityAnalysis) {
        if result.isSensitive {
            print("⚠️  检测到敏感内容")
        } else {
            print("✅ " + Strings.get("safe.is_safe"))
        }
    }

    private func printJSON(result: SCSensitivityAnalysis, filename: String) {
        let dict: [String: Any] = [
            "file": filename,
            "is_sensitive": result.isSensitive
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}
