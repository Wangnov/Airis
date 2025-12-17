import ArgumentParser
@preconcurrency import Vision
import Foundation

struct AnimalCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "animal",
        abstract: HelpTextFactory.text(
            en: "Detect animals (cats and dogs) in images",
            cn: "检测图片中的动物（猫/狗）"
        ),
        discussion: helpDiscussion(
            en: """
                Detect cats and dogs in images using Apple's Vision framework.

                QUICK START:
                  airis detect animal photo.jpg

                SUPPORTED ANIMALS:
                  • Cat - Domestic cats of various breeds
                  • Dog - Domestic dogs of various breeds

                EXAMPLES:
                  # Detect animals in a photo
                  airis detect animal pet.jpg

                  # Filter by animal type
                  airis detect animal photo.png --type cat
                  airis detect animal photo.png --type dog

                  # Set confidence threshold
                  airis detect animal group.jpg --threshold 0.7

                  # JSON output for scripting
                  airis detect animal pets.jpg --format json

                OUTPUT EXAMPLE:
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Detected 2 animal(s)

                  [1] Cat
                      Confidence: 0.94
                      Bounding Box: (0.15, 0.30) - 0.35×0.45

                  [2] Dog
                      Confidence: 0.89
                      Bounding Box: (0.55, 0.25) - 0.40×0.50
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                OPTIONS:
                  --type <type>      Filter by animal type (cat, dog)
                  --threshold <val>  Minimum confidence threshold (0.0-1.0, default: 0.0)
                  --format <fmt>     Output format: table (default), json

                NOTE:
                  The Vision framework currently supports detection of cats and dogs.
                  Other animals are not recognized by this detector.
                """,
            cn: """
                使用 Apple Vision 框架检测图片中的猫/狗，输出类型、置信度与 bounding box。

                QUICK START:
                  airis detect animal photo.jpg

                EXAMPLES:
                  # 检测猫/狗
                  airis detect animal pet.jpg

                  # 按类型过滤
                  airis detect animal photo.png --type cat
                  airis detect animal photo.png --type dog

                  # 置信度阈值
                  airis detect animal group.jpg --threshold 0.7

                  # JSON 输出（便于脚本解析）
                  airis detect animal pets.jpg --format json

                OPTIONS:
                  --type <type>      类型过滤（cat / dog）
                  --threshold <val>  置信度阈值（0.0-1.0，默认：0.0）
                  --format <fmt>     输出格式：table（默认）或 json

                说明：
                  - 目前仅支持猫/狗
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file(s)", cn: "输入图片路径（可多个）"))
    var imagePaths: [String]

    @Option(name: .long, help: HelpTextFactory.help(en: "Filter by animal type (cat, dog)", cn: "类型过滤（cat / dog）"))
    var type: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Minimum confidence threshold (0.0-1.0)", cn: "置信度阈值（0.0-1.0）"))
    var threshold: Float = 0.0

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    func run() async throws {
        let vision = ServiceContainer.shared.visionService
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        for imagePath in imagePaths {
            let url = try FileUtils.validateImageFile(at: imagePath)

            var bannerLines = [
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "🐾 Animal Detection",
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "📁 File: \(url.lastPathComponent)"
            ]

            if let type = type {
                bannerLines.append("🔖 Type filter: \(type.capitalized)")
            }

            if threshold > 0 {
                bannerLines.append("🎯 Threshold: \(String(format: "%.2f", threshold))")
            }

            bannerLines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            AirisOutput.printBanner(
                bannerLines,
                enabled: showHumanOutput
            )

            // 执行检测
            #if DEBUG
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_ANIMAL_STUB"] == "1" {
                let stub = Self.testObservations()
                try await handleResults(stub, url: url, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
                continue
            }
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_ANIMAL_LOW_LABEL"] == "1" {
                let stub = Self.testLowConfidenceLabelObservations()
                try await handleResults(stub, url: url, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
                continue
            }
            #endif

            let results = try await vision.recognizeAnimals(at: url)
            let adapted = results.map { obs -> VisionAnimalObservation in
                let labels = obs.labels.map { VisionAnimalLabel(identifierValue: $0.identifier, confidenceValue: $0.confidence) }
                return VisionAnimalObservation(
                    confidenceValue: obs.confidence,
                    labelsValue: labels,
                    boundingBoxValue: obs.boundingBox
                )
            }

            try await handleResults(adapted, url: url, outputFormat: outputFormat, showHumanOutput: showHumanOutput)
        }
    }

    private func handleResults<T: AnimalObservationLike>(
        _ results: [T],
        url: URL,
        outputFormat: OutputFormat,
        showHumanOutput: Bool
    ) async throws {
        // 解析结果
        var animalResults: [AnimalResult] = []
        for observation in results {
            // 检查整体置信度
            guard observation.confidenceValue >= threshold else { continue }

            for label in observation.labelsValue {
                let combinedConfidence = observation.confidenceValue * label.confidenceValue

                // 检查组合置信度
                guard combinedConfidence >= threshold else { continue }

                // 类型过滤
                if let typeFilter = type?.lowercased() {
                    guard label.identifierValue.lowercased() == typeFilter else { continue }
                }

                animalResults.append(AnimalResult(
                    type: label.identifierValue,
                    confidence: combinedConfidence,
                    boundingBox: observation.boundingBoxValue
                ))
            }
        }

        if animalResults.isEmpty {
            if outputFormat == .json {
                printJSON(results: [], file: url.lastPathComponent)
            } else if showHumanOutput {
                print("No animals detected.")
                print("")
            }
            return
        }

        // 输出结果
        if outputFormat == .json {
            printJSON(results: animalResults, file: url.lastPathComponent)
        } else if showHumanOutput {
            printTable(results: animalResults)
        }
    }

    private func printTable(results: [AnimalResult]) {
        print("Detected \(results.count) animal(s)")
        print("")

        for (index, animal) in results.enumerated() {
            print("[\(index + 1)] \(animal.type.capitalized)")
            print("    Confidence: \(String(format: "%.2f", animal.confidence))")

            let box = animal.boundingBox
            let x = String(format: "%.2f", box.origin.x)
            let y = String(format: "%.2f", box.origin.y)
            let w = String(format: "%.2f", box.width)
            let h = String(format: "%.2f", box.height)
            print("    Bounding Box: (\(x), \(y)) - \(w)×\(h)")
            print("")
        }
    }

    private func printJSON(results: [AnimalResult], file: String) {
        let items = results.map { animal -> [String: Any] in
            [
                "type": animal.type,
                "confidence": animal.confidence,
                "bounding_box": [
                    "x": animal.boundingBox.origin.x,
                    "y": animal.boundingBox.origin.y,
                    "width": animal.boundingBox.width,
                    "height": animal.boundingBox.height
                ]
            ]
        }

        let dict: [String: Any] = [
            "file": file,
            "count": results.count,
            "animals": items
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}

// MARK: - Helper Types

private struct AnimalResult {
    let type: String
    let confidence: Float
    let boundingBox: CGRect
}

// MARK: - Observation Abstraction (avoid KVC in DEBUG stubs)

private protocol AnimalLabelLike {
    var identifierValue: String { get }
    var confidenceValue: Float { get }
}

private protocol AnimalObservationLike {
    var confidenceValue: Float { get }
    var labelsValue: [any AnimalLabelLike] { get }
    var boundingBoxValue: CGRect { get }
}

private struct VisionAnimalLabel: AnimalLabelLike {
    let identifierValue: String
    let confidenceValue: Float
}

private struct VisionAnimalObservation: AnimalObservationLike {
    let confidenceValue: Float
    let labelsValue: [any AnimalLabelLike]
    let boundingBoxValue: CGRect
}

#if DEBUG
extension AnimalCommand {
    /// 测试辅助：构造可控的识别结果，覆盖类型过滤与空结果分支
    private static func testObservations() -> [StubAnimalObservation] {
        func makeObservation(type: String, confidence: Float, box: CGRect) -> StubAnimalObservation {
            let label = StubAnimalLabel(identifierValue: type, confidenceValue: confidence)
            return StubAnimalObservation(
                confidenceValue: confidence,
                labelsValue: [label],
                boundingBoxValue: box
            )
        }

        return [
            makeObservation(type: "cat", confidence: 0.92, box: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)),
            makeObservation(type: "dog", confidence: 0.85, box: CGRect(x: 0.5, y: 0.2, width: 0.25, height: 0.35))
        ]
    }

    /// 低标签置信度分支（覆盖 combinedConfidence < threshold）
    private static func testLowConfidenceLabelObservations() -> [StubAnimalObservation] {
        func makeObservation(type: String, confidence: Float, labelConfidence: Float, box: CGRect) -> StubAnimalObservation {
            let label = StubAnimalLabel(identifierValue: type, confidenceValue: labelConfidence)
            return StubAnimalObservation(
                confidenceValue: confidence,
                labelsValue: [label],
                boundingBoxValue: box
            )
        }

        return [
            makeObservation(type: "cat", confidence: 0.98, labelConfidence: 0.4, box: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))
        ]
    }
}

private struct StubAnimalLabel: AnimalLabelLike {
    let identifierValue: String
    let confidenceValue: Float
}

private struct StubAnimalObservation: AnimalObservationLike {
    let confidenceValue: Float
    let labelsValue: [any AnimalLabelLike]
    let boundingBoxValue: CGRect
}
#endif
