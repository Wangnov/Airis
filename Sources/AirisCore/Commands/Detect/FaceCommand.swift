import ArgumentParser
import Foundation
@preconcurrency import Vision

struct FaceCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "face",
            abstract: HelpTextFactory.text(
                en: "Detect faces and facial landmarks in images",
                cn: "检测图片中的人脸（可选关键点）"
            ),
            discussion: helpDiscussion(
                en: """
                Detect faces in images with optional facial landmark detection.

                QUICK START:
                  airis detect face photo.jpg

                DETECTION MODES:
                  • Rectangle only (--fast)
                    Fast detection, returns bounding boxes only

                  • Full landmarks (default)
                    Detailed 76-point facial landmarks including:
                    - Face contour
                    - Left/right eyebrow
                    - Left/right eye
                    - Left/right pupil
                    - Nose
                    - Nose crest
                    - Median line
                    - Outer/inner lips

                EXAMPLES:
                  # Detect faces with landmarks
                  airis detect face portrait.jpg

                  # Fast detection (bounding boxes only)
                  airis detect face group.jpg --fast

                  # JSON output
                  airis detect face photo.png --format json

                  # Set minimum confidence threshold
                  airis detect face crowd.jpg --threshold 0.7

                OUTPUT EXAMPLE:
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Detected 2 face(s)

                  [1] Face
                      Confidence: 0.95
                      Bounding Box: (0.23, 0.45) - 0.31×0.42
                      Roll: -2.3°
                      Yaw: 5.1°
                      Landmarks: 76 points detected

                  [2] Face
                      Confidence: 0.87
                      Bounding Box: (0.58, 0.40) - 0.28×0.38
                      Roll: 1.2°
                      Yaw: -3.8°
                      Landmarks: 76 points detected
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                OPTIONS:
                  --fast             Fast mode (bounding boxes only, no landmarks)
                  --threshold <val>  Minimum confidence threshold (0.0-1.0, default: 0.0)
                  --format <fmt>     Output format: table (default), json
                """,
                cn: """
                使用 Apple Vision 框架检测图片中的人脸，可选择输出人脸关键点。

                QUICK START:
                  airis detect face photo.jpg

                EXAMPLES:
                  # 默认模式：输出关键点（landmarks）
                  airis detect face portrait.jpg

                  # 快速模式：仅输出 bounding box
                  airis detect face group.jpg --fast

                  # JSON 输出（便于脚本解析）
                  airis detect face photo.png --format json

                  # 置信度阈值过滤
                  airis detect face crowd.jpg --threshold 0.7

                OPTIONS:
                  --fast             快速模式（不输出关键点）
                  --threshold <val>  置信度阈值（0.0-1.0，默认：0.0）
                  --format <fmt>     输出格式：table（默认）或 json
                """
            )
        )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file(s)", cn: "输入图片路径（可多个）"))
    var imagePaths: [String]

    @Flag(name: .long, help: HelpTextFactory.help(en: "Fast detection mode (no landmarks)", cn: "快速模式（不输出关键点）"))
    var fast: Bool = false

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

            AirisOutput.printBanner([
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "👤 Face Detection",
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "📁 File: \(url.lastPathComponent)",
                "⚡ Mode: \(fast ? "Fast (rectangles only)" : "Full (with landmarks)")",
            ] + (threshold > 0 ? ["🎯 Threshold: \(String(format: "%.2f", threshold))"] : []) + [
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ], enabled: showHumanOutput)

            // 执行检测
            let results: [VNFaceObservation] = if fast {
                try await vision.detectFaceRectangles(at: url)
            } else {
                try await vision.detectFaceLandmarks(at: url)
            }

            // 过滤低置信度结果
            let filteredResults = results.filter { $0.confidence >= threshold }

            if filteredResults.isEmpty {
                if outputFormat == .json {
                    printJSON(results: [], file: url.lastPathComponent, hasLandmarks: !fast)
                } else if showHumanOutput {
                    print("No faces detected.")
                    print("")
                }
                continue
            }

            // 输出结果
            if outputFormat == .json {
                printJSON(results: filteredResults, file: url.lastPathComponent, hasLandmarks: !fast)
            } else if showHumanOutput {
                printTable(results: filteredResults, hasLandmarks: !fast)
            }
        }
    }

    private func printTable(results: [VNFaceObservation], hasLandmarks: Bool) {
        print("Detected \(results.count) face(s)")
        print("")

        for (index, face) in results.enumerated() {
            print("[\(index + 1)] Face")
            print("    Confidence: \(String(format: "%.2f", face.confidence))")

            let box = face.boundingBox
            let x = String(format: "%.2f", box.origin.x)
            let y = String(format: "%.2f", box.origin.y)
            let w = String(format: "%.2f", box.width)
            let h = String(format: "%.2f", box.height)
            print("    Bounding Box: (\(x), \(y)) - \(w)×\(h)")

            // 头部姿态
            if let roll = face.roll {
                print("    Roll: \(String(format: "%.1f", roll.doubleValue * 180 / .pi))°")
            }
            if let yaw = face.yaw {
                print("    Yaw: \(String(format: "%.1f", yaw.doubleValue * 180 / .pi))°")
            }
            if let pitch = face.pitch {
                print("    Pitch: \(String(format: "%.1f", pitch.doubleValue * 180 / .pi))°")
            }

            // 特征点信息
            if hasLandmarks, let landmarks = face.landmarks {
                var pointCount = 0
                if let faceContour = landmarks.faceContour { pointCount += faceContour.pointCount }
                if let leftEye = landmarks.leftEye { pointCount += leftEye.pointCount }
                if let rightEye = landmarks.rightEye { pointCount += rightEye.pointCount }
                if let leftEyebrow = landmarks.leftEyebrow { pointCount += leftEyebrow.pointCount }
                if let rightEyebrow = landmarks.rightEyebrow { pointCount += rightEyebrow.pointCount }
                if let nose = landmarks.nose { pointCount += nose.pointCount }
                if let noseCrest = landmarks.noseCrest { pointCount += noseCrest.pointCount }
                if let medianLine = landmarks.medianLine { pointCount += medianLine.pointCount }
                if let outerLips = landmarks.outerLips { pointCount += outerLips.pointCount }
                if let innerLips = landmarks.innerLips { pointCount += innerLips.pointCount }
                if let leftPupil = landmarks.leftPupil { pointCount += leftPupil.pointCount }
                if let rightPupil = landmarks.rightPupil { pointCount += rightPupil.pointCount }

                print("    Landmarks: \(pointCount) points detected")
            }

            print("")
        }
    }

    private func printJSON(results: [VNFaceObservation], file: String, hasLandmarks: Bool) {
        let items = results.map { face -> [String: Any] in
            var item: [String: Any] = [
                "confidence": face.confidence,
                "bounding_box": [
                    "x": face.boundingBox.origin.x,
                    "y": face.boundingBox.origin.y,
                    "width": face.boundingBox.width,
                    "height": face.boundingBox.height,
                ],
            ]

            // 头部姿态
            var pose: [String: Double] = [:]
            if let roll = face.roll {
                pose["roll"] = roll.doubleValue * 180 / .pi
            }
            if let yaw = face.yaw {
                pose["yaw"] = yaw.doubleValue * 180 / .pi
            }
            if let pitch = face.pitch {
                pose["pitch"] = pitch.doubleValue * 180 / .pi
            }
            if !pose.isEmpty {
                item["pose"] = pose
            }

            // 特征点（简化输出）
            if hasLandmarks, let landmarks = face.landmarks {
                var landmarkInfo: [String: Any] = [:]

                if let contour = landmarks.faceContour {
                    landmarkInfo["face_contour_points"] = contour.pointCount
                }
                if let leftEye = landmarks.leftEye {
                    landmarkInfo["left_eye_points"] = leftEye.pointCount
                }
                if let rightEye = landmarks.rightEye {
                    landmarkInfo["right_eye_points"] = rightEye.pointCount
                }
                if let nose = landmarks.nose {
                    landmarkInfo["nose_points"] = nose.pointCount
                }
                if let outerLips = landmarks.outerLips {
                    landmarkInfo["outer_lips_points"] = outerLips.pointCount
                }
                if let innerLips = landmarks.innerLips {
                    landmarkInfo["inner_lips_points"] = innerLips.pointCount
                }

                item["landmarks"] = landmarkInfo
            }

            return item
        }

        let dict: [String: Any] = [
            "file": file,
            "count": results.count,
            "faces": items,
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            print(jsonString)
        }
    }
}
