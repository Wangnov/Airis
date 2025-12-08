import XCTest
@testable import Airis

final class ErrorTypesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Language.current = .en
    }

    // MARK: - Error Description Tests

    func testFileNotFoundError() {
        let error = AirisError.fileNotFound("/test/path.jpg")
        XCTAssertEqual(error.errorDescription, "File not found: /test/path.jpg")
    }

    func testUnsupportedFormatError() {
        let error = AirisError.unsupportedFormat("xyz")
        XCTAssertEqual(error.errorDescription, "Unsupported format: xyz")
    }

    func testVisionRequestFailedError() {
        let error = AirisError.visionRequestFailed("Request timeout")
        XCTAssertEqual(error.errorDescription, "Vision request failed: Request timeout")
    }

    func testApiKeyNotFoundError() {
        let error = AirisError.apiKeyNotFound(provider: "gemini")
        XCTAssertEqual(error.errorDescription, "API key not found for provider: gemini")
        XCTAssertEqual(error.recoverySuggestion, "Run 'airis gen config set-key --provider gemini' to configure")
    }

    func testInvalidDimensionError() {
        let error = AirisError.invalidImageDimension(width: 10000, height: 10000, max: 4096)
        XCTAssertEqual(error.errorDescription, "Invalid dimension: 10000×10000 (max: 4096)")
    }

    // MARK: - Localization Tests

    func testErrorDescriptionInChinese() {
        Language.current = .cn
        let error = AirisError.fileNotFound("/test/path.jpg")
        XCTAssertEqual(error.errorDescription, "文件未找到：/test/path.jpg")
    }

    // MARK: - Underlying Error Tests

    func testUnderlyingError() {
        let nsError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = AirisError.networkError(nsError)
        XCTAssertNotNil(error.underlyingError)
    }

    func testNoUnderlyingError() {
        let error = AirisError.noResultsFound
        XCTAssertNil(error.underlyingError)
    }
}
