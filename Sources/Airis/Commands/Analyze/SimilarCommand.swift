import ArgumentParser
@preconcurrency import Vision
import Foundation

struct SimilarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "similar",
        abstract: "Compare similarity between two images",
        discussion: """
            Calculate visual similarity between two images using Vision
            framework's feature fingerprinting.

            QUICK START:
              airis analyze similar image1.jpg image2.jpg

            EXAMPLES:
              # Compare two images
              airis analyze similar photo1.jpg photo2.jpg

              # JSON output for scripting
              airis analyze similar img1.png img2.png --format json

              # Find duplicates in a folder (use shell)
              for f1 in *.jpg; do
                for f2 in *.jpg; do
                  if [ "$f1" != "$f2" ]; then
                    airis analyze similar "$f1" "$f2" --format json
                  fi
                done
              done

            OUTPUT FORMAT (table):
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              🔍 图片相似度
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 图片 1: photo1.jpg
              📁 图片 2: photo2.jpg
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              相似度: 85.3%
              距离值: 0.29
              评价: 非常相似

            OUTPUT FORMAT (json):
              {
                "image1": "photo1.jpg",
                "image2": "photo2.jpg",
                "similarity": 0.853,
                "distance": 0.29,
                "rating": "very_similar"
              }

            DISTANCE INTERPRETATION:
              0.0 - 0.3  : 非常相似 (Very Similar)
              0.3 - 0.8  : 相似 (Similar)
              0.8 - 1.5  : 有些相似 (Somewhat Similar)
              1.5+       : 不同 (Different)

            ALGORITHM:
              Uses VNGenerateImageFeaturePrintRequest to generate visual
              fingerprints, then computes Euclidean distance between them.
              Lower distance means higher similarity.

            NOTES:
              - Comparison is based on visual features, not pixel values
              - Works well for detecting similar scenes/subjects
              - All processing is done locally using Vision framework
            """
    )

    @Argument(help: "Path to the first image file")
    var image1Path: String

    @Argument(help: "Path to the second image file")
    var image2Path: String

    @Option(name: .long, help: "Output format: table (default), json")
    var format: String = "table"

    func run() async throws {
        let url1 = try FileUtils.validateImageFile(at: image1Path)
        let url2 = try FileUtils.validateImageFile(at: image2Path)

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 图片相似度")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 图片 1: \(url1.lastPathComponent)")
        print("📁 图片 2: \(url2.lastPathComponent)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 生成特征指纹
        print("⏳ 正在分析图片...")

        let observation1 = try await generateFeaturePrint(for: url1)
        let observation2 = try await generateFeaturePrint(for: url2)

        // 计算距离
        var distance: Float = 0
        try observation1.computeDistance(&distance, to: observation2)

        // 计算相似度百分比（假设最大距离约为 2.0）
        let similarity = max(0, min(1, 1.0 - distance / 2.0))

        let result = SimilarityResult(
            image1: url1.lastPathComponent,
            image2: url2.lastPathComponent,
            distance: distance,
            similarity: similarity
        )

        print("")  // 清除进度提示

        // 输出结果
        if format.lowercased() == "json" {
            printJSON(result: result)
        } else {
            printTable(result: result)
        }
    }

    // MARK: - 特征提取

    /// 生成图像特征指纹
    private func generateFeaturePrint(for url: URL) async throws -> VNFeaturePrintObservation {
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try requestHandler.perform([request])
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        guard let observation = request.results?.first as? VNFeaturePrintObservation else {
            throw AirisError.visionRequestFailed("Failed to generate feature print")
        }

        return observation
    }

    // MARK: - 输出

    private func printTable(result: SimilarityResult) {
        let similarityPercent = String(format: "%.1f%%", result.similarity * 100)
        let distanceStr = String(format: "%.2f", result.distance)
        let rating = getRating(distance: result.distance)

        print("相似度: \(similarityPercent)")
        print("距离值: \(distanceStr)")
        print("评价: \(rating)")

        // 添加视觉指示器
        print("")
        printSimilarityBar(similarity: result.similarity)
    }

    private func printSimilarityBar(similarity: Float) {
        let barLength = 20
        let filledLength = Int(similarity * Float(barLength))
        let emptyLength = barLength - filledLength

        let filled = String(repeating: "█", count: filledLength)
        let empty = String(repeating: "░", count: emptyLength)

        // 根据相似度选择颜色
        let color: String
        if similarity >= 0.85 {
            color = "\u{001B}[32m"  // 绿色
        } else if similarity >= 0.6 {
            color = "\u{001B}[33m"  // 黄色
        } else {
            color = "\u{001B}[31m"  // 红色
        }

        print("[\(color)\(filled)\u{001B}[0m\(empty)]")
    }

    private func printJSON(result: SimilarityResult) {
        let dict: [String: Any] = [
            "image1": result.image1,
            "image2": result.image2,
            "similarity": Double(result.similarity),
            "distance": Double(result.distance),
            "rating": getRatingEnglish(distance: result.distance)
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func getRating(distance: Float) -> String {
        switch distance {
        case ..<0.3: return "非常相似"
        case 0.3..<0.8: return "相似"
        case 0.8..<1.5: return "有些相似"
        default: return "不同"
        }
    }

    private func getRatingEnglish(distance: Float) -> String {
        switch distance {
        case ..<0.3: return "very_similar"
        case 0.3..<0.8: return "similar"
        case 0.8..<1.5: return "somewhat_similar"
        default: return "different"
        }
    }

    // MARK: - 数据结构

    struct SimilarityResult {
        let image1: String
        let image2: String
        let distance: Float
        let similarity: Float
    }
}
