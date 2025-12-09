import ArgumentParser
@preconcurrency import Vision
import Foundation

struct HandCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hand",
        abstract: "Detect hand pose (21 keypoints per hand)",
        discussion: """
            Detect hand poses in images using Apple's Vision framework.
            Returns 21 keypoints per hand with normalized coordinates.

            QUICK START:
              airis detect hand photo.jpg

            KEYPOINTS (21 per hand):
              WRIST:  wrist
              THUMB:  thumbCMC, thumbMP, thumbIP, thumbTip
              INDEX:  indexMCP, indexPIP, indexDIP, indexTip
              MIDDLE: middleMCP, middlePIP, middleDIP, middleTip
              RING:   ringMCP, ringPIP, ringDIP, ringTip
              LITTLE: littleMCP, littlePIP, littleDIP, littleTip

            JOINT NAMING:
              CMC = Carpometacarpal (base)
              MCP = Metacarpophalangeal (knuckle)
              MP  = Metacarpophalangeal (thumb knuckle)
              PIP = Proximal Interphalangeal (middle joint)
              IP  = Interphalangeal (thumb middle)
              DIP = Distal Interphalangeal (near tip)
              Tip = Fingertip

            CHIRALITY:
              Automatically detects left/right hand

            EXAMPLES:
              # Basic hand detection
              airis detect hand gesture.jpg

              # Detect up to 4 hands
              airis detect hand group.png --max-hands 4

              # Show pixel coordinates
              airis detect hand sign.jpg --pixels

              # Filter by confidence threshold
              airis detect hand action.jpg --threshold 0.5

              # JSON output for scripting
              airis detect hand pose.jpg --format json

            OUTPUT EXAMPLE:
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              🤚 Hand Pose Detection
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 File: gesture.jpg
              🎯 Threshold: 0.30
              🔢 Max hands: 2
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              Detected 2 hand(s)

              [1] Right Hand
                  Keypoints (21):
                    wrist:     (0.45, 0.32) - conf: 0.95
                    thumbTip:  (0.52, 0.45) - conf: 0.92
                    indexTip:  (0.48, 0.58) - conf: 0.94
                    ...

              [2] Left Hand
                  Keypoints (21):
                    wrist:     (0.65, 0.30) - conf: 0.93
                    ...

            OPTIONS:
              --threshold <val>   Minimum confidence threshold (0.0-1.0, default: 0.3)
              --max-hands <num>   Maximum number of hands to detect (default: 2)
              --pixels            Show pixel coordinates instead of normalized
              --format <fmt>      Output format: table (default), json
            """
    )

    @Argument(help: "Path to the image file(s)")
    var imagePaths: [String]

    @Option(name: .long, help: "Minimum confidence threshold (0.0-1.0)")
    var threshold: Float = 0.3

    @Option(name: .long, help: "Maximum number of hands to detect")
    var maxHands: Int = 2

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
            print("🤚 Hand Pose Detection")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("🎯 Threshold: \(String(format: "%.2f", threshold))")
            print("🔢 Max hands: \(maxHands)")
            if pixels && imageWidth > 0 {
                print("📐 Image Size: \(imageWidth)×\(imageHeight) px")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")

            // 执行检测
            let results = try await vision.detectHumanHandPose(at: url, maximumHandCount: maxHands)

            if results.isEmpty {
                print("No hands detected.")
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

    // 所有手部关键点名称（计算属性避免 Decodable 问题）
    private var allJointNames: [VNHumanHandPoseObservation.JointName] {
        [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexMCP, .indexPIP, .indexDIP, .indexTip,
        .middleMCP, .middlePIP, .middleDIP, .middleTip,
        .ringMCP, .ringPIP, .ringDIP, .ringTip,
        .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func jointNameString(_ name: VNHumanHandPoseObservation.JointName) -> String {
        switch name {
        case .wrist: return "wrist"
        case .thumbCMC: return "thumbCMC"
        case .thumbMP: return "thumbMP"
        case .thumbIP: return "thumbIP"
        case .thumbTip: return "thumbTip"
        case .indexMCP: return "indexMCP"
        case .indexPIP: return "indexPIP"
        case .indexDIP: return "indexDIP"
        case .indexTip: return "indexTip"
        case .middleMCP: return "middleMCP"
        case .middlePIP: return "middlePIP"
        case .middleDIP: return "middleDIP"
        case .middleTip: return "middleTip"
        case .ringMCP: return "ringMCP"
        case .ringPIP: return "ringPIP"
        case .ringDIP: return "ringDIP"
        case .ringTip: return "ringTip"
        case .littleMCP: return "littleMCP"
        case .littlePIP: return "littlePIP"
        case .littleDIP: return "littleDIP"
        case .littleTip: return "littleTip"
        default: return "unknown"
        }
    }

    private func chiralityString(_ chirality: VNChirality) -> String {
        switch chirality {
        case .left: return "Left Hand"
        case .right: return "Right Hand"
        case .unknown: return "Unknown Hand"
        @unknown default: return "Unknown Hand"
        }
    }

    private func printTable(results: [VNHumanHandPoseObservation], imageWidth: Int, imageHeight: Int) {
        print("Detected \(results.count) hand(s)")
        print("")

        for (index, observation) in results.enumerated() {
            print("[\(index + 1)] \(chiralityString(observation.chirality))")
            print("    Keypoints:")

            for jointName in allJointNames {
                guard let point = try? observation.recognizedPoint(jointName),
                      point.confidence >= threshold else {
                    continue
                }

                let name = jointNameString(jointName)
                let paddedName = name.padding(toLength: 12, withPad: " ", startingAt: 0)

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

    private func printJSON(results: [VNHumanHandPoseObservation], file: String,
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

            var chiralityValue: String
            switch observation.chirality {
            case .left: chiralityValue = "left"
            case .right: chiralityValue = "right"
            case .unknown: chiralityValue = "unknown"
            @unknown default: chiralityValue = "unknown"
            }

            return [
                "chirality": chiralityValue,
                "keypoint_count": keypoints.count,
                "keypoints": keypoints
            ]
        }

        var dict: [String: Any] = [
            "file": file,
            "count": results.count,
            "threshold": Double(threshold),
            "max_hands": maxHands,
            "hands": items
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
