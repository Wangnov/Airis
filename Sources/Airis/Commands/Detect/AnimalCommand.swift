import ArgumentParser
@preconcurrency import Vision
import Foundation

struct AnimalCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "animal",
        abstract: "Detect animals (cats and dogs) in images",
        discussion: """
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
            """
    )

    @Argument(help: "Path to the image file(s)")
    var imagePaths: [String]

    @Option(name: .long, help: "Filter by animal type (cat, dog)")
    var type: String?

    @Option(name: .long, help: "Minimum confidence threshold (0.0-1.0)")
    var threshold: Float = 0.0

    @Option(name: .long, help: "Output format (table, json)")
    var format: String = "table"

    func run() async throws {
        let vision = ServiceContainer.shared.visionService

        for imagePath in imagePaths {
            let url = try FileUtils.validateImageFile(at: imagePath)

            // 显示参数
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🐾 Animal Detection")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            if let type = type {
                print("🔖 Type filter: \(type.capitalized)")
            }
            if threshold > 0 {
                print("🎯 Threshold: \(String(format: "%.2f", threshold))")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")

            // 执行检测
            #if DEBUG
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_ANIMAL_STUB"] == "1" {
                let stub = Self._testObservations()
                try await handleResults(stub, url: url)
                continue
            }
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_ANIMAL_LOW_LABEL"] == "1" {
                let stub = Self._testLowConfidenceLabelObservations()
                try await handleResults(stub, url: url)
                continue
            }
            #endif

            let results = try await vision.recognizeAnimals(at: url)

            try await handleResults(results, url: url)
        }
    }

    private func handleResults(_ results: [VNRecognizedObjectObservation], url: URL) async throws {
        // 解析结果
        var animalResults: [AnimalResult] = []
        for observation in results {
            // 检查整体置信度
            guard observation.confidence >= threshold else { continue }

            for label in observation.labels {
                let combinedConfidence = observation.confidence * label.confidence

                // 检查组合置信度
                guard combinedConfidence >= threshold else { continue }

                // 类型过滤
                if let typeFilter = type?.lowercased() {
                    guard label.identifier.lowercased() == typeFilter else { continue }
                }

                animalResults.append(AnimalResult(
                    type: label.identifier,
                    confidence: combinedConfidence,
                    boundingBox: observation.boundingBox
                ))
            }
        }

        if animalResults.isEmpty {
            print("No animals detected.")
            print("")
            return
        }

        // 输出结果
        if format == "json" {
            printJSON(results: animalResults, file: url.lastPathComponent)
        } else {
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

#if DEBUG
extension AnimalCommand {
    /// 测试辅助：构造可控的识别结果，覆盖类型过滤与空结果分支
    static func _testObservations() -> [VNRecognizedObjectObservation] {
        func makeObservation(type: String, confidence: Float, box: CGRect) -> VNRecognizedObjectObservation {
            let obs = VNRecognizedObjectObservation(boundingBox: box)
            let label = VNClassificationObservation()
            label.setValue(type, forKey: "identifier")
            label.setValue(confidence, forKey: "confidence")
            obs.setValue([label], forKey: "labels")
            obs.setValue(confidence, forKey: "confidence")
            return obs
        }

        return [
            makeObservation(type: "cat", confidence: 0.92, box: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)),
            makeObservation(type: "dog", confidence: 0.85, box: CGRect(x: 0.5, y: 0.2, width: 0.25, height: 0.35))
        ]
    }

    /// 低标签置信度分支（覆盖 combinedConfidence < threshold）
    static func _testLowConfidenceLabelObservations() -> [VNRecognizedObjectObservation] {
        func makeObservation(type: String, confidence: Float, labelConfidence: Float, box: CGRect) -> VNRecognizedObjectObservation {
            let obs = VNRecognizedObjectObservation(boundingBox: box)
            let label = VNClassificationObservation()
            label.setValue(type, forKey: "identifier")
            label.setValue(labelConfidence, forKey: "confidence")
            obs.setValue([label], forKey: "labels")
            obs.setValue(confidence, forKey: "confidence")
            return obs
        }

        return [
            makeObservation(type: "cat", confidence: 0.98, labelConfidence: 0.4, box: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))
        ]
    }
}
#endif
