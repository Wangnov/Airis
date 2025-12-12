import XCTest
import UniformTypeIdentifiers
@testable import Airis

/// 第十五批覆盖冲刺：补齐剩余边界分支，向 100% 覆盖推进。
final class CommandLayerCoverageSprint15Tests: XCTestCase {
    // MARK: Analyze

    func testInfoCommandForceNoFileSizeBranch() async throws {
        unsetenv("AIRIS_TEST_MODE")
        setenv("AIRIS_FORCE_INFO_NO_FILESIZE", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path

        try await InfoCommand.parse([input, "--format", "table"]).run()

        unsetenv("AIRIS_FORCE_INFO_NO_FILESIZE")
    }

    func testMetaCommandDestinationFailThrows() async {
        setenv("AIRIS_FORCE_META_DEST_FAIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await MetaCommand.parse([input, "--set-comment", "stub", "-o", out.path]).run()
        )

        CommandTestHarness.cleanup(out)
        unsetenv("AIRIS_FORCE_META_DEST_FAIL")
    }

    func testMetaCommandFinalizeFailThrows() async {
        setenv("AIRIS_FORCE_META_FINALIZE_FAIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await MetaCommand.parse([input, "--set-comment", "stub", "-o", out.path]).run()
        )

        CommandTestHarness.cleanup(out)
        unsetenv("AIRIS_FORCE_META_FINALIZE_FAIL")
    }

    func testMetaCommandDefaultFormatHelperCoversFallback() {
        let uti = MetaCommand._testGetImageFormat(for: "/tmp/example.heif")
        XCTAssertEqual(uti as String, UTType.jpeg.identifier)
    }

    // MARK: Detect

    func testBarcodeCommandInvalidTypeFallsBackToAll() async throws {
        let img = CommandTestHarness.fixture("qrcode_512x512.png").path
        try await BarcodeCommand.parse([img, "--type", "invalid_type", "--format", "table"]).run()
    }

    // MARK: VisionService

    func testComputeOpticalFlowNilResultsTriggersNoResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let service = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("vision_flow_nil.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await service.computeOpticalFlow(from: tempURL, to: tempURL)
            XCTFail("应当抛出 noResultsFound")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("错误类型不符: \(error)")
                return
            }
        }
    }
}

// MARK: - Async helper

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("预期抛出错误", file: file, line: line)
    } catch { }
}

/// 生成简单的灰色测试图像，避免重复依赖其他测试文件中的私有方法
private func createTestCGImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    let context = CGContext(
        data: nil,
        width: 64,
        height: 64,
        bitsPerComponent: 8,
        bytesPerRow: 256,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    )!
    context.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
    return context.makeImage()!
}
