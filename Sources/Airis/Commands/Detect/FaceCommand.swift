import ArgumentParser
@preconcurrency import Vision
import Foundation

struct FaceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "face",
        abstract: "Detect faces and facial landmarks in images",
        discussion: """
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
            """
    )

    @Argument(help: "Path to the image file(s)")
    var imagePaths: [String]

    @Flag(name: .long, help: "Fast detection mode (no landmarks)")
    var fast: Bool = false

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
            print("👤 Face Detection")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("⚡ Mode: \(fast ? "Fast (rectangles only)" : "Full (with landmarks)")")
            if threshold > 0 {
                print("🎯 Threshold: \(String(format: "%.2f", threshold))")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")

            // 执行检测
            let results: [VNFaceObservation]
            if fast {
                results = try await vision.detectFaceRectangles(at: url)
            } else {
                results = try await vision.detectFaceLandmarks(at: url)
            }

            // 过滤低置信度结果
            let filteredResults = results.filter { $0.confidence >= threshold }

            if filteredResults.isEmpty {
                print("No faces detected.")
                print("")
                continue
            }

            // 输出结果
            if format == "json" {
                printJSON(results: filteredResults, file: url.lastPathComponent, hasLandmarks: !fast)
            } else {
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
                if landmarks.faceContour != nil { pointCount += landmarks.faceContour!.pointCount }
                if landmarks.leftEye != nil { pointCount += landmarks.leftEye!.pointCount }
                if landmarks.rightEye != nil { pointCount += landmarks.rightEye!.pointCount }
                if landmarks.leftEyebrow != nil { pointCount += landmarks.leftEyebrow!.pointCount }
                if landmarks.rightEyebrow != nil { pointCount += landmarks.rightEyebrow!.pointCount }
                if landmarks.nose != nil { pointCount += landmarks.nose!.pointCount }
                if landmarks.noseCrest != nil { pointCount += landmarks.noseCrest!.pointCount }
                if landmarks.medianLine != nil { pointCount += landmarks.medianLine!.pointCount }
                if landmarks.outerLips != nil { pointCount += landmarks.outerLips!.pointCount }
                if landmarks.innerLips != nil { pointCount += landmarks.innerLips!.pointCount }
                if landmarks.leftPupil != nil { pointCount += landmarks.leftPupil!.pointCount }
                if landmarks.rightPupil != nil { pointCount += landmarks.rightPupil!.pointCount }

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
                    "height": face.boundingBox.height
                ]
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
            "faces": items
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
}
