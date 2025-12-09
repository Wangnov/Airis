import ArgumentParser
@preconcurrency import Vision
import Foundation

struct PoseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pose",
        abstract: "Detect human body pose (2D, 19 keypoints)",
        discussion: """
            Detect human body poses in images using Apple's Vision framework.
            Returns 19 body keypoints with normalized coordinates and confidence.

            QUICK START:
              airis detect pose photo.jpg

            KEYPOINTS (19 total):
              HEAD:  nose, leftEye, rightEye, leftEar, rightEar, neck
              ARMS:  leftShoulder, leftElbow, leftWrist
                     rightShoulder, rightElbow, rightWrist
              TORSO: root (waist center)
              LEGS:  leftHip, leftKnee, leftAnkle
                     rightHip, rightKnee, rightAnkle

            COORDINATE SYSTEM:
              • Normalized coordinates (0.0 - 1.0)
              • Origin at bottom-left corner
              • Use --pixels to convert to pixel coordinates

            EXAMPLES:
              # Basic pose detection
              airis detect pose yoga.jpg

              # Show pixel coordinates
              airis detect pose dance.png --pixels

              # Filter by confidence threshold
              airis detect pose action.jpg --threshold 0.5

              # JSON output for scripting
              airis detect pose sport.jpg --format json

            OUTPUT EXAMPLE:
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              🤸 Human Body Pose Detection (2D)
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 File: yoga.jpg
              🎯 Threshold: 0.30
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              Detected 1 person(s)

              [1] Person
                  Keypoints (19):
                    nose:          (0.52, 0.85) - conf: 0.95
                    leftShoulder:  (0.45, 0.72) - conf: 0.92
                    rightShoulder: (0.59, 0.71) - conf: 0.93
                    ...

            OPTIONS:
              --threshold <val>  Minimum confidence threshold (0.0-1.0, default: 0.3)
              --pixels           Show pixel coordinates instead of normalized
              --format <fmt>     Output format: table (default), json
            """
    )

    @Argument(help: "Path to the image file(s)")
    var imagePaths: [String]

    @Option(name: .long, help: "Minimum confidence threshold (0.0-1.0)")
    var threshold: Float = 0.3

    @Flag(name: .long, help: "Show pixel coordinates instead of normalized")
    var pixels: Bool = false

    @Option(name: .long, help: "Output format (table, json)")
    var format: String = "table"

    func run() async throws {
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

            // 显示参数
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🤸 Human Body Pose Detection (2D)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("🎯 Threshold: \(String(format: "%.2f", threshold))")
            if pixels && imageWidth > 0 {
                print("📐 Image Size: \(imageWidth)×\(imageHeight) px")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")

            // 执行检测
            let results = try await vision.detectHumanBodyPose(at: url)

            if results.isEmpty {
                print("No human body poses detected.")
                print("")
                continue
            }

            // 输出结果
            if format == "json" {
                printJSON(results: results, file: url.lastPathComponent,
                          imageWidth: imageWidth, imageHeight: imageHeight)
            } else {
                printTable(results: results, imageWidth: imageWidth, imageHeight: imageHeight)
            }
        }
    }

    // 所有关键点名称（计算属性避免 Decodable 问题）
    private var allJointNames: [VNHumanBodyPoseObservation.JointName] {
        [
        .nose, .leftEye, .rightEye, .leftEar, .rightEar, .neck,
        .leftShoulder, .leftElbow, .leftWrist,
        .rightShoulder, .rightElbow, .rightWrist,
        .root,
        .leftHip, .leftKnee, .leftAnkle,
        .rightHip, .rightKnee, .rightAnkle
        ]
    }

    private func jointNameString(_ name: VNHumanBodyPoseObservation.JointName) -> String {
        switch name {
        case .nose: return "nose"
        case .leftEye: return "leftEye"
        case .rightEye: return "rightEye"
        case .leftEar: return "leftEar"
        case .rightEar: return "rightEar"
        case .neck: return "neck"
        case .leftShoulder: return "leftShoulder"
        case .leftElbow: return "leftElbow"
        case .leftWrist: return "leftWrist"
        case .rightShoulder: return "rightShoulder"
        case .rightElbow: return "rightElbow"
        case .rightWrist: return "rightWrist"
        case .root: return "root"
        case .leftHip: return "leftHip"
        case .leftKnee: return "leftKnee"
        case .leftAnkle: return "leftAnkle"
        case .rightHip: return "rightHip"
        case .rightKnee: return "rightKnee"
        case .rightAnkle: return "rightAnkle"
        default: return "unknown"
        }
    }

    private func printTable(results: [VNHumanBodyPoseObservation], imageWidth: Int, imageHeight: Int) {
        print("Detected \(results.count) person(s)")
        print("")

        for (index, observation) in results.enumerated() {
            print("[\(index + 1)] Person")
            print("    Keypoints:")

            for jointName in allJointNames {
                guard let point = try? observation.recognizedPoint(jointName),
                      point.confidence >= threshold else {
                    continue
                }

                let name = jointNameString(jointName)
                let paddedName = name.padding(toLength: 14, withPad: " ", startingAt: 0)

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

    private func printJSON(results: [VNHumanBodyPoseObservation], file: String,
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
            "persons": items
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
