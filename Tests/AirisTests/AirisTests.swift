import XCTest
@testable import Airis

final class AirisTests: XCTestCase {
    func testAirisVersionExists() throws {
        XCTAssertEqual(Airis.configuration.version, "0.1.0")
    }

    func testAirisCommandName() throws {
        XCTAssertEqual(Airis.configuration.commandName, "airis")
    }
}
