import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

final class AirisSkillMetadataTests: XCTestCase {
    private struct UnknownCommand {}
    private struct UnknownNonCommandType {}

    func testHelpBlockForKnownCommandContainsMetadataHeader() {
        let block = AirisSkillMetadata.helpBlock(for: AirisCommand.self)
        XCTAssertTrue(block.contains("AI_SKILL_METADATA:"))
        XCTAssertTrue(block.contains("input_types:"))
        XCTAssertTrue(block.contains("output_types:"))
        XCTAssertTrue(block.contains("capabilities:"))
    }

    func testHelpBlockFallbackForUnknownCommandType() {
        let block = AirisSkillMetadata.helpBlock(for: UnknownCommand.self)
        XCTAssertTrue(block.contains("AI_SKILL_METADATA:"))
        XCTAssertTrue(block.contains("image/png"))
        XCTAssertTrue(block.contains("image_processing"))
    }

    func testHelpBlockFallbackForUnknownNonCommandType() {
        let block = AirisSkillMetadata.helpBlock(for: UnknownNonCommandType.self)
        XCTAssertTrue(block.contains("AI_SKILL_METADATA:"))
        XCTAssertTrue(block.contains("text/plain"))
        XCTAssertTrue(block.contains("cli"))
    }
}
