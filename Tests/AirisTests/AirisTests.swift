import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

final class AirisTests: XCTestCase {
    func testAirisVersionExists() throws {
        XCTAssertEqual(AirisCommand.configuration.version, "1.0.0")
    }

    func testAirisCommandName() throws {
        XCTAssertEqual(AirisCommand.configuration.commandName, "airis")
    }
}
