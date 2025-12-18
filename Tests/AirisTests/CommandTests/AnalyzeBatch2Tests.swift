import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// Analyze 命令组 Batch 2 测试
/// 测试 SafeCommand, PaletteCommand, SimilarCommand, MetaCommand
final class AnalyzeBatch2Tests: XCTestCase {
    private var originalLanguage: Language = .en

    override func setUp() {
        super.setUp()
        originalLanguage = Language.current
        Language.current = .en
    }

    override func tearDown() {
        Language.current = originalLanguage
        super.tearDown()
    }

    // MARK: - SafeCommand Configuration Tests

    func testSafeCommandConfiguration() throws {
        XCTAssertEqual(SafeCommand.configuration.commandName, "safe")
        XCTAssertTrue(SafeCommand.configuration.abstract.contains("sensitive"))
    }

    func testSafeCommandDiscussionContainsRequirements() throws {
        let discussion = SafeCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("REQUIREMENTS"))
        XCTAssertTrue(discussion.contains("macOS 14.0"))
        XCTAssertTrue(discussion.contains("OUTPUT FORMAT"))
    }

    func testSafeCommandDiscussionContainsPrivacyNotes() throws {
        let discussion = SafeCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("PRIVACY"))
        XCTAssertTrue(discussion.contains("locally"))
    }

    // MARK: - PaletteCommand Configuration Tests

    func testPaletteCommandConfiguration() throws {
        XCTAssertEqual(PaletteCommand.configuration.commandName, "palette")
        XCTAssertTrue(PaletteCommand.configuration.abstract.contains("color"))
    }

    func testPaletteCommandDiscussionContainsExamples() throws {
        let discussion = PaletteCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT FORMAT"))
        XCTAssertTrue(discussion.contains("ALGORITHM"))
    }

    func testPaletteCommandDiscussionContainsAlgorithmInfo() throws {
        let discussion = PaletteCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("K-means"))
        XCTAssertTrue(discussion.contains("CIKMeans"))
    }

    // MARK: - PaletteCommand Data Structure Tests

    func testPaletteColorInfoStructure() throws {
        let color = PaletteCommand.ColorInfo(hex: "#FF5733", r: 255, g: 87, b: 51)

        XCTAssertEqual(color.hex, "#FF5733")
        XCTAssertEqual(color.r, 255)
        XCTAssertEqual(color.g, 87)
        XCTAssertEqual(color.b, 51)
    }

    func testPaletteResultStructure() throws {
        let color1 = PaletteCommand.ColorInfo(hex: "#FF5733", r: 255, g: 87, b: 51)
        let color2 = PaletteCommand.ColorInfo(hex: "#3498DB", r: 52, g: 152, b: 219)

        var result = PaletteCommand.PaletteResult(colors: [color1, color2])

        XCTAssertEqual(result.colors.count, 2)
        XCTAssertNil(result.averageColor)

        let avgColor = PaletteCommand.ColorInfo(hex: "#808080", r: 128, g: 128, b: 128)
        result.averageColor = avgColor

        XCTAssertNotNil(result.averageColor)
        XCTAssertEqual(result.averageColor?.hex, "#808080")
    }

    // MARK: - SimilarCommand Configuration Tests

    func testSimilarCommandConfiguration() throws {
        XCTAssertEqual(SimilarCommand.configuration.commandName, "similar")
        XCTAssertTrue(SimilarCommand.configuration.abstract.contains("similarity"))
    }

    func testSimilarCommandDiscussionContainsExamples() throws {
        let discussion = SimilarCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT FORMAT"))
        XCTAssertTrue(discussion.contains("DISTANCE INTERPRETATION"))
    }

    func testSimilarCommandDiscussionContainsAlgorithmInfo() throws {
        let discussion = SimilarCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("VNGenerateImageFeaturePrintRequest"))
        XCTAssertTrue(discussion.contains("fingerprint"))
    }

    // MARK: - SimilarCommand Data Structure Tests

    func testSimilarityResultStructure() throws {
        let result = SimilarCommand.SimilarityResult(
            image1: "photo1.jpg",
            image2: "photo2.jpg",
            distance: 0.25,
            similarity: 0.875
        )

        XCTAssertEqual(result.image1, "photo1.jpg")
        XCTAssertEqual(result.image2, "photo2.jpg")
        XCTAssertEqual(result.distance, 0.25)
        XCTAssertEqual(result.similarity, 0.875)
    }

    func testSimilarityResultHighSimilarity() throws {
        let result = SimilarCommand.SimilarityResult(
            image1: "a.jpg",
            image2: "b.jpg",
            distance: 0.1,
            similarity: 0.95
        )

        XCTAssertLessThan(result.distance, 0.3)
        XCTAssertGreaterThan(result.similarity, 0.8)
    }

    func testSimilarityResultLowSimilarity() throws {
        let result = SimilarCommand.SimilarityResult(
            image1: "a.jpg",
            image2: "b.jpg",
            distance: 1.8,
            similarity: 0.1
        )

        XCTAssertGreaterThan(result.distance, 1.5)
        XCTAssertLessThan(result.similarity, 0.3)
    }

    // MARK: - MetaCommand Configuration Tests

    func testMetaCommandConfiguration() throws {
        XCTAssertEqual(MetaCommand.configuration.commandName, "meta")
        XCTAssertTrue(MetaCommand.configuration.abstract.contains("EXIF"))
    }

    func testMetaCommandDiscussionContainsExamples() throws {
        let discussion = MetaCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT FORMAT"))
        XCTAssertTrue(discussion.contains("CATEGORIES"))
    }

    func testMetaCommandDiscussionContainsCategories() throws {
        let discussion = MetaCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("exif"))
        XCTAssertTrue(discussion.contains("gps"))
        XCTAssertTrue(discussion.contains("tiff"))
        XCTAssertTrue(discussion.contains("iptc"))
    }

    func testMetaCommandDiscussionContainsWriteOperations() throws {
        let discussion = MetaCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("WRITE OPERATIONS"))
        XCTAssertTrue(discussion.contains("--set-comment"))
        XCTAssertTrue(discussion.contains("--clear-gps"))
        XCTAssertTrue(discussion.contains("--clear-all"))
    }

    // MARK: - Localization Tests for Batch 2

    func testSafeStringsExist() throws {
        XCTAssertFalse(Strings.get("safe.disabled_hint").isEmpty)
        XCTAssertFalse(Strings.get("safe.is_safe").isEmpty)
        XCTAssertFalse(Strings.get("safe.is_sensitive", "Yes").isEmpty)
    }

    // MARK: - Service Integration Tests

    func testCoreImageServiceAccessible() throws {
        let service = ServiceContainer.shared.coreImageService
        XCTAssertNotNil(service)
    }

    func testVisionServiceAccessibleForSimilar() throws {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    // MARK: - FileUtils Tests for Batch 2 Commands

    func testGenerateOutputPathForMeta() throws {
        let inputPath = "/path/to/photo.jpg"
        let outputPath = FileUtils.generateOutputPath(
            from: inputPath,
            suffix: "_meta",
            extension: "jpg"
        )

        XCTAssertTrue(outputPath.contains("_meta"))
        XCTAssertTrue(outputPath.hasSuffix(".jpg"))
    }

    func testSupportedFormatsForMetadata() throws {
        // JPEG 支持完整的 EXIF
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.jpg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.jpeg"))

        // PNG 支持有限的元数据
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.png"))

        // HEIC 支持元数据
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.heic"))

        // TIFF 支持完整的元数据
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.tiff"))
    }

    // MARK: - Help Quality Tests

    func testSafeCommandHelpQuality() throws {
        let discussion = SafeCommand.configuration.discussion

        // 检查 Help 文档质量指标
        var score = 0

        if discussion.contains("QUICK START") { score += 1 }
        if discussion.contains("EXAMPLES") { score += 1 }
        if discussion.contains("OUTPUT FORMAT") { score += 1 }
        if discussion.contains("REQUIREMENTS") { score += 1 }
        if discussion.contains("PRIVACY") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 4, "SafeCommand help should have quality score >= 4")
    }

    func testPaletteCommandHelpQuality() throws {
        let discussion = PaletteCommand.configuration.discussion

        var score = 0

        if discussion.contains("QUICK START") { score += 1 }
        if discussion.contains("EXAMPLES") { score += 1 }
        if discussion.contains("OUTPUT FORMAT") { score += 1 }
        if discussion.contains("ALGORITHM") { score += 1 }
        if discussion.contains("NOTES") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 4, "PaletteCommand help should have quality score >= 4")
    }

    func testSimilarCommandHelpQuality() throws {
        let discussion = SimilarCommand.configuration.discussion

        var score = 0

        if discussion.contains("QUICK START") { score += 1 }
        if discussion.contains("EXAMPLES") { score += 1 }
        if discussion.contains("OUTPUT FORMAT") { score += 1 }
        if discussion.contains("DISTANCE INTERPRETATION") { score += 1 }
        if discussion.contains("ALGORITHM") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 4, "SimilarCommand help should have quality score >= 4")
    }

    func testMetaCommandHelpQuality() throws {
        let discussion = MetaCommand.configuration.discussion

        var score = 0

        if discussion.contains("QUICK START") { score += 1 }
        if discussion.contains("EXAMPLES") { score += 1 }
        if discussion.contains("OUTPUT FORMAT") { score += 1 }
        if discussion.contains("CATEGORIES") { score += 1 }
        if discussion.contains("WRITE OPERATIONS") { score += 1 }
        if discussion.contains("NOTES") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 5, "MetaCommand help should have quality score >= 5")
    }
}
