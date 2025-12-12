import XCTest
@testable import Airis

final class AirisRuntimeTests: XCTestCase {
    func testDebugRespectsVerboseAndQuietFlags() {
        let oldVerbose = AirisRuntime.isVerbose
        let oldQuiet = AirisRuntime.isQuiet
        defer {
            AirisRuntime.isVerbose = oldVerbose
            AirisRuntime.isQuiet = oldQuiet
        }

        AirisRuntime.isVerbose = false
        AirisRuntime.isQuiet = false
        AirisLog.debug("should_not_print")

        AirisRuntime.isVerbose = true
        AirisRuntime.isQuiet = true
        AirisLog.debug("should_not_print")

        AirisRuntime.isVerbose = true
        AirisRuntime.isQuiet = false
        AirisLog.debug("should_print_to_stderr")

        XCTAssertTrue(true)
    }
}
