@preconcurrency import Vision
import CoreImage
import Foundation

/// Vision 框架服务层封装
final class VisionService: Sendable {

    // MARK: - 图像分类

    /// 分类图像场景和物体
    func classifyImage(at url: URL, threshold: Float = 0.0) async throws -> [VNClassificationObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNClassifyImageRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNClassificationObservation]) ?? []
                let filtered = results.filter { $0.confidence >= threshold }
                continuation.resume(returning: filtered)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    /// 分类图像（CGImage 版本）
    func classifyImage(cgImage: CGImage, threshold: Float = 0.0) async throws -> [VNClassificationObservation] {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNClassifyImageRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNClassificationObservation]) ?? []
                let filtered = results.filter { $0.confidence >= threshold }
                continuation.resume(returning: filtered)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - OCR 文字识别

    /// 识别图像中的文本
    func recognizeText(
        at url: URL,
        languages: [String] = ["en", "zh-Hans"],
        level: VNRequestTextRecognitionLevel = .accurate
    ) async throws -> [VNRecognizedTextObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = level
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = languages.isEmpty

        if !languages.isEmpty {
            request.recognitionLanguages = languages
        }

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNRecognizedTextObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 条形码检测

    /// 检测条形码和二维码
    func detectBarcodes(
        at url: URL,
        symbologies: [VNBarcodeSymbology]? = nil
    ) async throws -> [VNBarcodeObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectBarcodesRequest()

        if let symbologies = symbologies {
            request.symbologies = symbologies
        }

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNBarcodeObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 人脸检测

    /// 检测人脸特征
    func detectFaceLandmarks(at url: URL) async throws -> [VNFaceObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectFaceLandmarksRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNFaceObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    /// 仅检测人脸位置（不含特征）
    func detectFaceRectangles(at url: URL) async throws -> [VNFaceObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectFaceRectanglesRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNFaceObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 动物检测

    /// 检测动物（猫和狗）
    func recognizeAnimals(at url: URL) async throws -> [VNRecognizedObjectObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNRecognizeAnimalsRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNRecognizedObjectObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 人体姿态检测

    /// 检测人体 2D 姿态（19 个关键点）
    func detectHumanBodyPose(at url: URL) async throws -> [VNHumanBodyPoseObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectHumanBodyPoseRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNHumanBodyPoseObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    /// 检测人体 3D 姿态（17 个关键点，需要 macOS 14.0+）
    @available(macOS 14.0, *)
    func detectHumanBodyPose3D(at url: URL) async throws -> [VNHumanBodyPose3DObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectHumanBodyPose3DRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNHumanBodyPose3DObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 手部姿态检测

    /// 检测手部姿态（21 个关键点）
    func detectHumanHandPose(at url: URL, maximumHandCount: Int = 2) async throws -> [VNHumanHandPoseObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = maximumHandCount

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNHumanHandPoseObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 动物姿态检测

    /// 检测动物身体姿态（猫/狗，23 个关键点，需要 macOS 14.0+）
    @available(macOS 14.0, *)
    func detectAnimalBodyPose(at url: URL) async throws -> [VNAnimalBodyPoseObservation] {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNDetectAnimalBodyPoseRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = (request.results as? [VNAnimalBodyPoseObservation]) ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - 批量请求

    /// 执行多个请求（复用同一个 handler）
    func performMultipleRequests(at url: URL) async throws -> ComprehensiveAnalysis {
        let handler = VNImageRequestHandler(url: url, options: [:])

        let classifyRequest = VNClassifyImageRequest()
        let textRequest = VNRecognizeTextRequest()
        let barcodeRequest = VNDetectBarcodesRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([classifyRequest, textRequest, barcodeRequest])

                let classifications = (classifyRequest.results as? [VNClassificationObservation]) ?? []
                let texts = (textRequest.results as? [VNRecognizedTextObservation]) ?? []
                let barcodes = (barcodeRequest.results as? [VNBarcodeObservation]) ?? []

                continuation.resume(returning: ComprehensiveAnalysis(
                    classifications: classifications,
                    texts: texts,
                    barcodes: barcodes
                ))
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    /// 综合分析结果
    struct ComprehensiveAnalysis {
        let classifications: [VNClassificationObservation]
        let texts: [VNRecognizedTextObservation]
        let barcodes: [VNBarcodeObservation]
    }
}
