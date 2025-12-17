import ArgumentParser
@preconcurrency import Vision
import Foundation

struct PetPoseCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "petpose",
        abstract: HelpTextFactory.text(
            en: "Detect pet body pose (cats and dogs, 25 keypoints)",
            cn: "检测宠物姿态（猫/狗，25 个关键点）"
        ),
        discussion: helpDiscussion(
            en: """
                Detect body poses of cats and dogs using Apple's Vision framework.
                Returns 25 keypoints per animal with normalized coordinates.

                REQUIREMENTS:
                  macOS 14.0 or later

                QUICK START:
                  airis detect petpose pet.jpg

                SUPPORTED ANIMALS:
                  • Cats
                  • Dogs

                KEYPOINTS (25 total):
                  HEAD (10):
                    nose, leftEye, rightEye
                    leftEarTop, leftEarMiddle, leftEarBottom
                    rightEarTop, rightEarMiddle, rightEarBottom
                    neck

                  FRONT LEGS (6):
                    leftFrontElbow, leftFrontKnee, leftFrontPaw
                    rightFrontElbow, rightFrontKnee, rightFrontPaw

                  BACK LEGS (6):
                    leftBackElbow, leftBackKnee, leftBackPaw
                    rightBackElbow, rightBackKnee, rightBackPaw

                  TAIL (3):
                    tailTop, tailMiddle, tailBottom

                EXAMPLES:
                  # Basic pet pose detection
                  airis detect petpose dog.jpg

                  # Show pixel coordinates
                  airis detect petpose cat.png --pixels

                  # Filter by confidence threshold
                  airis detect petpose pet.jpg --threshold 0.5

                  # JSON output for scripting
                  airis detect petpose animals.jpg --format json

                OUTPUT EXAMPLE:
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  🐾 Pet Body Pose Detection
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📁 File: dog.jpg
                  🎯 Threshold: 0.30
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  Detected 1 animal(s)

                  [1] Animal
                      Keypoints (25):
                        nose:           (0.52, 0.65) - conf: 0.95
                        leftEye:        (0.48, 0.68) - conf: 0.93
                        rightEye:       (0.56, 0.67) - conf: 0.92
                        leftFrontPaw:   (0.35, 0.25) - conf: 0.88
                        ...

                OPTIONS:
                  --threshold <val>  Minimum confidence threshold (0.0-1.0, default: 0.3)
                  --pixels           Show pixel coordinates instead of normalized
                  --format <fmt>     Output format: table (default), json
                """,
            cn: """
                使用 Apple Vision 框架检测猫/狗的身体姿态（25 个关键点）。

                REQUIREMENTS:
                  macOS 14.0+

                QUICK START:
                  airis detect petpose pet.jpg

                EXAMPLES:
                  # 基础检测
                  airis detect petpose dog.jpg

                  # 输出像素坐标
                  airis detect petpose cat.png --pixels

                  # 置信度阈值过滤
                  airis detect petpose pet.jpg --threshold 0.5

                  # JSON 输出（便于脚本解析）
                  airis detect petpose animals.jpg --format json

                OPTIONS:
                  --threshold <val>  置信度阈值（0.0-1.0，默认：0.3）
                  --pixels           输出像素坐标（默认输出归一化）
                  --format <fmt>     输出格式：table（默认）或 json
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file(s)", cn: "输入图片路径（可多个）"))
    var imagePaths: [String]

    @Option(name: .long, help: HelpTextFactory.help(en: "Minimum confidence threshold (0.0-1.0)", cn: "置信度阈值（0.0-1.0）"))
    var threshold: Float = 0.3

    @Flag(name: .long, help: HelpTextFactory.help(en: "Show pixel coordinates instead of normalized", cn: "输出像素坐标（默认输出归一化坐标）"))
    var pixels: Bool = false

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    func run() async throws {
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        // 检查 macOS 版本（测试可通过环境变量强制触发降级分支）
        let forceUnsupported = ProcessInfo.processInfo.environment["AIRIS_FORCE_PETPOSE_UNSUPPORTED"] == "1"
        guard #available(macOS 14.0, *), !forceUnsupported else {
            if outputFormat == .json {
                let payload: [String: Any] = [
                    "supported": false,
                    "required_macos": "14.0",
                    "error": "unsupported_os_version"
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            } else if showHumanOutput {
                print(Strings.get("error.requires_macos", "Pet pose detection", "14.0"))
                print(Strings.get("error.feature_unsupported"))
            }
            return
        }

        let vision = ServiceContainer.shared.visionService

        for imagePath in imagePaths {
            let url = try FileUtils.validateImageFile(at: imagePath)

            // 获取图像尺寸（用于像素坐标转换）
            var imageWidth: Int = 0
            var imageHeight: Int = 0
            if pixels {
                let imageIO = ServiceContainer.shared.imageIOService
                if let info = try? imageIO.getImageInfo(at: url) {
                    imageWidth = info.width
                    imageHeight = info.height
                }
            }

            AirisOutput.printBanner([
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "🐾 Pet Body Pose Detection",
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "📁 File: \(url.lastPathComponent)",
                "🎯 Threshold: \(String(format: "%.2f", threshold))",
            ] + ((pixels && imageWidth > 0) ? ["📐 Image Size: \(imageWidth)×\(imageHeight) px"] : []) + [
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ], enabled: showHumanOutput)

            // 执行检测
            let results = try await vision.detectAnimalBodyPose(at: url)

            if results.isEmpty {
                if outputFormat == .json {
                    printJSON(results: [], file: url.lastPathComponent, imageWidth: imageWidth, imageHeight: imageHeight)
                } else if showHumanOutput {
                    print("No pet poses detected.")
                    print("Note: This feature works best with cats and dogs.")
                    print("")
                }
                continue
            }

            // 输出结果
            if outputFormat == .json {
                printJSON(results: results, file: url.lastPathComponent, imageWidth: imageWidth, imageHeight: imageHeight)
            } else if showHumanOutput {
                printTable(results: results, imageWidth: imageWidth, imageHeight: imageHeight)
            }
        }
    }

    // 所有动物关键点名称
    @available(macOS 14.0, *)
    private var allJointNames: [VNAnimalBodyPoseObservation.JointName] {
        [
            // Head
            .nose, .leftEye, .rightEye,
            .leftEarTop, .leftEarMiddle, .leftEarBottom,
            .rightEarTop, .rightEarMiddle, .rightEarBottom,
            .neck,
            // Front legs
            .leftFrontElbow, .leftFrontKnee, .leftFrontPaw,
            .rightFrontElbow, .rightFrontKnee, .rightFrontPaw,
            // Back legs
            .leftBackElbow, .leftBackKnee, .leftBackPaw,
            .rightBackElbow, .rightBackKnee, .rightBackPaw,
            // Tail
            .tailTop, .tailMiddle, .tailBottom
        ]
    }

    @available(macOS 14.0, *)
    private func jointNameString(_ name: VNAnimalBodyPoseObservation.JointName) -> String {
        switch name {
        case .nose: return "nose"
        case .leftEye: return "leftEye"
        case .rightEye: return "rightEye"
        case .leftEarTop: return "leftEarTop"
        case .leftEarMiddle: return "leftEarMiddle"
        case .leftEarBottom: return "leftEarBottom"
        case .rightEarTop: return "rightEarTop"
        case .rightEarMiddle: return "rightEarMiddle"
        case .rightEarBottom: return "rightEarBottom"
        case .neck: return "neck"
        case .leftFrontElbow: return "leftFrontElbow"
        case .leftFrontKnee: return "leftFrontKnee"
        case .leftFrontPaw: return "leftFrontPaw"
        case .rightFrontElbow: return "rightFrontElbow"
        case .rightFrontKnee: return "rightFrontKnee"
        case .rightFrontPaw: return "rightFrontPaw"
        case .leftBackElbow: return "leftBackElbow"
        case .leftBackKnee: return "leftBackKnee"
        case .leftBackPaw: return "leftBackPaw"
        case .rightBackElbow: return "rightBackElbow"
        case .rightBackKnee: return "rightBackKnee"
        case .rightBackPaw: return "rightBackPaw"
        case .tailTop: return "tailTop"
        case .tailMiddle: return "tailMiddle"
        case .tailBottom: return "tailBottom"
        default: return "unknown"
        }
    }

    #if DEBUG
    /// 测试辅助：覆盖默认分支
    static func testJointNameString(_ raw: String) -> String {
        let key = VNRecognizedPointKey(rawValue: raw)
        let name = VNAnimalBodyPoseObservation.JointName(rawValue: key)
        return PetPoseCommand().jointNameString(name)
    }
    #endif

    @available(macOS 14.0, *)
    private func printTable(results: [VNAnimalBodyPoseObservation], imageWidth: Int, imageHeight: Int) {
        print("Detected \(results.count) animal(s)")
        print("")

        for (index, observation) in results.enumerated() {
            print("[\(index + 1)] Animal")
            print("    Keypoints:")

            for jointName in allJointNames {
                guard let point = try? observation.recognizedPoint(jointName),
                      point.confidence >= threshold else {
                    continue
                }

                let name = jointNameString(jointName)
                let paddedName = name.padding(toLength: 17, withPad: " ", startingAt: 0)

                if pixels && imageWidth > 0 {
                    let px = Int(point.location.x * CGFloat(imageWidth))
                    let py = Int(point.location.y * CGFloat(imageHeight))
                    print("      \(paddedName): (\(px), \(py)) px - conf: \(String(format: "%.2f", point.confidence))")
                } else {
                    let x = String(format: "%.3f", point.location.x)
                    let y = String(format: "%.3f", point.location.y)
                    let conf = String(format: "%.2f", point.confidence)
                    print("      \(paddedName): (\(x), \(y)) - conf: \(conf)")
                }
            }

            print("")
        }
    }

    @available(macOS 14.0, *)
    private func printJSON(results: [VNAnimalBodyPoseObservation], file: String,
                           imageWidth: Int, imageHeight: Int) {
        let items = results.map { observation -> [String: Any] in
            var keypoints: [[String: Any]] = []

            for jointName in allJointNames {
                guard let point = try? observation.recognizedPoint(jointName),
                      point.confidence >= threshold else {
                    continue
                }

                var keypointDict: [String: Any] = [
                    "name": jointNameString(jointName),
                    "confidence": Double(point.confidence)
                ]

                if pixels && imageWidth > 0 {
                    keypointDict["x"] = Int(point.location.x * CGFloat(imageWidth))
                    keypointDict["y"] = Int(point.location.y * CGFloat(imageHeight))
                    keypointDict["coordinate_type"] = "pixels"
                } else {
                    keypointDict["x"] = Double(point.location.x)
                    keypointDict["y"] = Double(point.location.y)
                    keypointDict["coordinate_type"] = "normalized"
                }

                keypoints.append(keypointDict)
            }

            return [
                "keypoint_count": keypoints.count,
                "keypoints": keypoints
            ]
        }

        var dict: [String: Any] = [
            "file": file,
            "count": results.count,
            "threshold": Double(threshold),
            "supported_animals": ["cat", "dog"],
            "animals": items
        ]

        if pixels && imageWidth > 0 {
            dict["image_width"] = imageWidth
            dict["image_height"] = imageHeight
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}
