import ArgumentParser
@preconcurrency import Vision
import Foundation
import simd

struct Pose3DCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pose3d",
        abstract: "Detect human body pose (3D, 17 keypoints)",
        discussion: """
            Detect human body poses in 3D using Apple's Vision framework.
            Returns 17 body keypoints with 3D coordinates relative to camera.

            REQUIREMENTS:
              macOS 14.0 or later

            QUICK START:
              airis detect pose3d photo.jpg

            KEYPOINTS (17 total):
              HEAD:   topHead, centerHead
              TORSO:  centerShoulder, spine
              ARMS:   leftShoulder, leftElbow, leftWrist
                      rightShoulder, rightElbow, rightWrist
              ROOT:   root (hip center)
              LEGS:   leftHip, leftKnee, leftAnkle
                      rightHip, rightKnee, rightAnkle

            COORDINATE SYSTEM:
              • 3D coordinates in meters
              • Origin at root joint (hip center)
              • Camera-relative positioning

            EXAMPLES:
              # Basic 3D pose detection
              airis detect pose3d person.jpg

              # Filter by confidence threshold
              airis detect pose3d action.jpg --threshold 0.5

              # JSON output for scripting
              airis detect pose3d sport.jpg --format json

            OUTPUT EXAMPLE:
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              🧍 Human Body Pose Detection (3D)
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 File: person.jpg
              🎯 Threshold: 0.30
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              Detected 1 person(s)

              [1] Person
                  Estimated Height: 1.72 m
                  Keypoints (17):
                    topHead:        (0.02, 0.86, -1.50) m - conf: 0.92
                    centerShoulder: (0.00, 0.68, -1.48) m - conf: 0.95
                    ...

            OPTIONS:
              --format <fmt>     Output format: table (default), json

            NOTE:
              3D pose detection returns all detected joints without
              confidence filtering (3D points have no confidence scores).
            """
    )

    @Argument(help: "Path to the image file(s)")
    var imagePaths: [String]

    @Option(name: .long, help: "Minimum confidence threshold (0.0-1.0)")
    var threshold: Float = 0.3

    @Option(name: .long, help: "Output format (table, json)")
    var format: String = "table"

    func run() async throws {
        let forceUnsupported = ProcessInfo.processInfo.environment["AIRIS_FORCE_POSE3D_UNSUPPORTED"] == "1"
        #if DEBUG
        let forceEmpty = ProcessInfo.processInfo.environment["AIRIS_FORCE_POSE3D_EMPTY"] == "1"
        #else
        let forceEmpty = false
        #endif
        // 检查 macOS 版本
        guard #available(macOS 14.0, *), !forceUnsupported else {
            print("⚠️ 3D pose detection requires macOS 14.0 or later.")
            print("   Your current system does not support this feature.")
            return
        }

        let vision = ServiceContainer.shared.visionService

        for imagePath in imagePaths {
            let url = try FileUtils.validateImageFile(at: imagePath)

            // 显示参数
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🧍 Human Body Pose Detection (3D)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("🎯 Threshold: \(String(format: "%.2f", threshold))")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")

            // 执行检测
            let results: [VNHumanBodyPose3DObservation]
            #if DEBUG
            if forceEmpty {
                results = []
            } else {
                results = try await vision.detectHumanBodyPose3D(at: url)
            }
            #else
            results = try await vision.detectHumanBodyPose3D(at: url)
            #endif

            if results.isEmpty {
                print("No human body poses detected.")
                print("")
                continue
            }

            // 输出结果
            if format == "json" {
                printJSON(results: results, file: url.lastPathComponent)
            } else {
                printTable(results: results)
            }
        }
    }

    // 3D 关键点名称
    @available(macOS 14.0, *)
    private var allJointNames: [VNHumanBodyPose3DObservation.JointName] {
        [
            .topHead, .centerHead,
            .centerShoulder, .spine,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightShoulder, .rightElbow, .rightWrist,
            .root,
            .leftHip, .leftKnee, .leftAnkle,
            .rightHip, .rightKnee, .rightAnkle
        ]
    }

    @available(macOS 14.0, *)
    private func jointNameString(_ name: VNHumanBodyPose3DObservation.JointName) -> String {
        switch name {
        case .topHead: return "topHead"
        case .centerHead: return "centerHead"
        case .centerShoulder: return "centerShoulder"
        case .spine: return "spine"
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

    #if DEBUG
    /// 测试辅助：覆盖默认分支
    static func testJointNameString(_ raw: String) -> String {
        let key = VNRecognizedPointKey(rawValue: raw)
        let name = VNHumanBodyPose3DObservation.JointName(rawValue: key)
        return Pose3DCommand().jointNameString(name)
    }
    #endif

    @available(macOS 14.0, *)
    private func printTable(results: [VNHumanBodyPose3DObservation]) {
        print("Detected \(results.count) person(s)")
        print("")

        #if DEBUG
        let forceMissingJoint = ProcessInfo.processInfo.environment["AIRIS_FORCE_POSE3D_MISSING_JOINT"] == "1"
        #else
        let forceMissingJoint = false
        #endif

        for (index, observation) in results.enumerated() {
            print("[\(index + 1)] Person")
            print("    Estimated Height: \(String(format: "%.2f", observation.bodyHeight)) m")
            print("    Keypoints:")

        for jointName in allJointNames {
                let point: VNRecognizedPoint3D?
                if forceMissingJoint {
                    point = nil
                } else {
                    point = try? observation.recognizedPoint(jointName)
                }

                guard let point else { continue }

                let name = jointNameString(jointName)
                let paddedName = name.padding(toLength: 16, withPad: " ", startingAt: 0)

                // 获取 3D 位置 (simd_float4x4 变换矩阵)
                let position = point.position
                let x = position.columns.3.x
                let y = position.columns.3.y
                let z = position.columns.3.z

                // 注意：3D 姿态点没有直接的置信度，显示检测到的点
                print("      \(paddedName): (\(String(format: "%+.2f", x)), \(String(format: "%+.2f", y)), \(String(format: "%+.2f", z))) m")
            }

            print("")
        }
    }

    @available(macOS 14.0, *)
    private func printJSON(results: [VNHumanBodyPose3DObservation], file: String) {
        let items = results.map { observation -> [String: Any] in
            var keypoints: [[String: Any]] = []

            #if DEBUG
            let forceMissingJoint = ProcessInfo.processInfo.environment["AIRIS_FORCE_POSE3D_MISSING_JOINT"] == "1"
            #else
            let forceMissingJoint = false
            #endif

            for jointName in allJointNames {
                let point: VNRecognizedPoint3D?
                if forceMissingJoint {
                    point = nil
                } else {
                    point = try? observation.recognizedPoint(jointName)
                }
                guard let point else { continue }

                let position = point.position
                let keypointDict: [String: Any] = [
                    "name": jointNameString(jointName),
                    "x": Double(position.columns.3.x),
                    "y": Double(position.columns.3.y),
                    "z": Double(position.columns.3.z),
                    "coordinate_type": "meters"
                ]

                keypoints.append(keypointDict)
            }

            return [
                "body_height": Double(observation.bodyHeight),
                "keypoint_count": keypoints.count,
                "keypoints": keypoints
            ]
        }

        let dict: [String: Any] = [
            "file": file,
            "count": results.count,
            "threshold": Double(threshold),
            "coordinate_system": "camera_relative_3d",
            "unit": "meters",
            "persons": items
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}
