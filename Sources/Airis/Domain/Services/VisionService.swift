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

    // MARK: - 前景分割（抠图）

    /// 生成前景实例遮罩（用于背景移除）
    /// - Parameter url: 图像文件 URL
    /// - Returns: 带 alpha 通道的遮罩图像 CVPixelBuffer
    /// - Note: 仅支持 macOS 14.0+，需要 GPU 支持
    @available(macOS 14.0, *)
    func generateForegroundMask(at url: URL) async throws -> CVPixelBuffer {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])

                guard let observation = request.results?.first else {
                    continuation.resume(throwing: AirisError.noResultsFound)
                    return
                }

                // 获取所有前景实例
                let allInstances = observation.allInstances

                // 生成掩码图像（保持原始尺寸）
                let maskedImage = try observation.generateMaskedImage(
                    ofInstances: allInstances,
                    from: handler,
                    croppedToInstancesExtent: false
                )

                continuation.resume(returning: maskedImage)
            } catch let error as AirisError {
                continuation.resume(throwing: error)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }

    /// 生成前景分割遮罩（仅遮罩，不含原图）
    /// - Parameter url: 图像文件 URL
    /// - Returns: 遮罩 CVPixelBuffer（白色=前景，黑色=背景）
    @available(macOS 14.0, *)
    func generateForegroundMaskOnly(at url: URL) async throws -> CVPixelBuffer {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])

                guard let observation = request.results?.first else {
                    continuation.resume(throwing: AirisError.noResultsFound)
                    return
                }

                let allInstances = observation.allInstances

                // 仅获取遮罩
                let maskBuffer = try observation.generateScaledMaskForImage(
                    forInstances: allInstances,
                    from: handler
                )

                continuation.resume(returning: maskBuffer)
            } catch let error as AirisError {
                continuation.resume(throwing: error)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }
}
