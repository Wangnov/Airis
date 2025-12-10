import XCTest
@testable import Airis

final class ErrorTypesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Language.current = .en
    }

    // MARK: - Error Description Tests

    func testFileNotFoundError() throws {
        let error = AirisError.fileNotFound("/test/path.jpg")
        XCTAssertEqual(error.errorDescription, "File not found: /test/path.jpg")
    }

    func testInvalidPathError() throws {
        let error = AirisError.invalidPath("/invalid/path")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNil(error.recoverySuggestion)
    }

    func testUnsupportedFormatError() throws {
        let error = AirisError.unsupportedFormat("xyz")
        XCTAssertEqual(error.errorDescription, "Unsupported format: xyz")
    }

    func testFileReadError() throws {
        let underlyingError = NSError(domain: "test", code: -1)
        let error = AirisError.fileReadError("/path/to/file.jpg", underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.underlyingError as? NSError, underlyingError)
    }

    func testFileWriteError() throws {
        let underlyingError = NSError(domain: "test", code: -1)
        let error = AirisError.fileWriteError("/path/to/output.jpg", underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.underlyingError as? NSError, underlyingError)
    }

    func testVisionRequestFailedError() throws {
        let error = AirisError.visionRequestFailed("Request timeout")
        XCTAssertEqual(error.errorDescription, "Vision request failed: Request timeout")
    }

    func testNoResultsFoundError() throws {
        let error = AirisError.noResultsFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNil(error.recoverySuggestion)
    }

    func testApiKeyNotFoundError() throws {
        let error = AirisError.apiKeyNotFound(provider: "gemini")
        XCTAssertEqual(error.errorDescription, "API key not found for provider: gemini")
        XCTAssertEqual(error.recoverySuggestion, "Run 'airis gen config set-key --provider gemini' to configure")
    }

    func testNetworkError() throws {
        let underlyingError = URLError(.notConnectedToInternet)
        let error = AirisError.networkError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.underlyingError as? URLError, underlyingError)
    }

    func testInvalidResponseError() throws {
        let error = AirisError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNil(error.recoverySuggestion)
    }

    func testInvalidDimensionError() throws {
        let error = AirisError.invalidImageDimension(width: 10000, height: 10000, max: 4096)
        XCTAssertEqual(error.errorDescription, "Invalid dimension: 10000×10000 (max: 4096)")
    }

    func testImageDecodeFailedError() throws {
        let error = AirisError.imageDecodeFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNil(error.underlyingError)
    }

    func testImageEncodeFailedError() throws {
        let error = AirisError.imageEncodeFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNil(error.underlyingError)
    }

    func testKeychainError() throws {
        let error = AirisError.keychainError(errSecItemNotFound)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNil(error.underlyingError)
    }

    // MARK: - Localization Tests

    func testErrorDescriptionInChinese() throws {
        Language.current = .cn
        let error = AirisError.fileNotFound("/test/path.jpg")
        XCTAssertEqual(error.errorDescription, "文件未找到：/test/path.jpg")
    }

    // MARK: - Underlying Error Tests

    func testUnderlyingError() throws {
        let nsError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = AirisError.networkError(nsError)
        XCTAssertNotNil(error.underlyingError)
    }

    func testNoUnderlyingError() throws {
        let error = AirisError.noResultsFound
        XCTAssertNil(error.underlyingError)
    }
}
