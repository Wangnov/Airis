// swiftlint:disable force_unwrapping
import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// HTTPClient 单元测试（使用 Mock 达到 100% 覆盖率）
final class HTTPClientTests: XCTestCase {
    var client: HTTPClient!
    var mockSession: URLSession!

    override func setUp() {
        super.setUp()

        // 配置使用 MockURLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)

        let clientConfig = HTTPClientConfiguration(
            timeoutIntervalForRequest: 30,
            maxRetries: 3,
            retryDelay: 0.01 // 快速重试
        )

        client = HTTPClient(configuration: clientConfig, session: mockSession)
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        client = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - POST Tests

    func testPOSTSuccess() async throws {
        let url = URL(string: "https://test.com/api")!
        let responseData = Data("{\"result\": \"ok\"}".utf8)

        MockURLProtocol.mockSuccess(url: url, data: responseData, statusCode: 200)

        let body = Data("{\"test\": \"data\"}".utf8)
        let (data, response) = try await client.post(url: url, body: body)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, responseData)
    }

    func testPOSTWithCustomHeaders() async throws {
        let url = URL(string: "https://test.com/api")!
        MockURLProtocol.mockSuccess(url: url, data: Data())

        let headers = ["X-Custom": "value"]
        let (_, response) = try await client.post(url: url, headers: headers, body: Data())

        XCTAssertEqual(response.statusCode, 200)
    }

    func testPOSTWithCustomContentType() async throws {
        let url = URL(string: "https://test.com/api")!
        MockURLProtocol.mockSuccess(url: url, data: Data())

        let headers = ["Content-Type": "text/plain"]
        let (_, response) = try await client.post(url: url, headers: headers, body: Data())

        XCTAssertEqual(response.statusCode, 200)
    }

    func testPOSTDefaultContentType() async throws {
        let url = URL(string: "https://test.com/api")!
        MockURLProtocol.mockSuccess(url: url, data: Data())

        // 不指定 Content-Type，应该默认为 application/json
        let (_, response) = try await client.post(url: url, body: Data())

        XCTAssertEqual(response.statusCode, 200)
    }

    // MARK: - GET Tests

    func testGETSuccess() async throws {
        let url = URL(string: "https://test.com/data")!
        let responseData = Data("test data".utf8)

        MockURLProtocol.mockSuccess(url: url, data: responseData)

        let (data, response) = try await client.get(url: url)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, responseData)
    }

    func testGETWithHeaders() async throws {
        let url = URL(string: "https://test.com/data")!
        MockURLProtocol.mockSuccess(url: url, data: Data())

        let headers = ["Authorization": "Bearer token"]
        let (_, response) = try await client.get(url: url, headers: headers)

        XCTAssertEqual(response.statusCode, 200)
    }

    // MARK: - Error Handling Tests

    func testPOST404Error() async throws {
        let url = URL(string: "https://test.com/notfound")!
        MockURLProtocol.mockSuccess(url: url, data: Data(), statusCode: 404)

        // 4xx 错误现在返回响应数据（让调用者处理），而不是抛出错误
        let (_, response) = try await client.post(url: url, body: Data())
        XCTAssertEqual(response.statusCode, 404)
    }

    func testGET404Error() async throws {
        let url = URL(string: "https://test.com/notfound")!
        MockURLProtocol.mockSuccess(url: url, data: Data(), statusCode: 404)

        do {
            _ = try await client.get(url: url)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func testPOST500WithRetrySuccess() async throws {
        let url = URL(string: "https://test.com/retry")!

        // Mock 序列：第1次500，第2次200
        MockURLProtocol.mockSequence(url: url, responses: [
            .success(MockURLProtocol.MockResponse(data: Data(), statusCode: 500)),
            .success(MockURLProtocol.MockResponse(data: Data("{\"ok\": true}".utf8), statusCode: 200)),
        ])

        let (data, response) = try await client.post(url: url, body: Data())

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertFalse(data.isEmpty)
    }

    func testPOST500RetryExhausted() async throws {
        let url = URL(string: "https://test.com/always-fail")!

        // Mock 序列：所有请求都返回 500
        MockURLProtocol.mockSequence(url: url, responses: [
            .success(MockURLProtocol.MockResponse(statusCode: 500)),
            .success(MockURLProtocol.MockResponse(statusCode: 500)),
            .success(MockURLProtocol.MockResponse(statusCode: 500)),
            .success(MockURLProtocol.MockResponse(statusCode: 500)),
        ])

        // 5xx 错误在重试耗尽后返回响应数据（让调用者处理），而不是抛出错误
        let (_, response) = try await client.post(url: url, body: Data())
        XCTAssertEqual(response.statusCode, 500)
    }

    func testNetworkErrorRetry() async throws {
        let url = URL(string: "https://test.com/timeout")!

        // Mock 序列：第1次超时，第2次成功
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        MockURLProtocol.mockSequence(url: url, responses: [
            .failure(timeoutError),
            .success(MockURLProtocol.MockResponse(data: Data("ok".utf8), statusCode: 200)),
        ])

        let (data, response) = try await client.post(url: url, body: Data())

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, Data("ok".utf8))
    }

    func testNetworkErrorRetryExhausted() async throws {
        let url = URL(string: "https://test.com/always-timeout")!

        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        MockURLProtocol.mockSequence(url: url, responses: [
            .failure(timeoutError),
            .failure(timeoutError),
            .failure(timeoutError),
            .failure(timeoutError),
        ])

        do {
            _ = try await client.post(url: url, body: Data())
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func testNonRetryableNetworkError() async throws {
        let url = URL(string: "https://test.com/bad-url")!

        // 不可重试的错误（如 DNS 解析失败以外的错误）
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)
        MockURLProtocol.mockError(url: url, error: error)

        do {
            _ = try await client.post(url: url, body: Data())
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func testInvalidResponse() async throws {
        let url = URL(string: "https://test.com/invalid-post")!

        // Mock 返回非 HTTPURLResponse
        MockURLProtocol.mockInvalidResponse(url: url)

        do {
            _ = try await client.post(url: url, body: Data())
            XCTFail("应该抛出 invalidResponse 错误")
        } catch let error as AirisError {
            if case .invalidResponse = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("错误类型不正确: \(error)")
            }
        }
    }

    func testGETInvalidResponse() async throws {
        let url = URL(string: "https://test.com/invalid-get")!

        // Mock GET 返回非 HTTPURLResponse
        MockURLProtocol.mockInvalidResponse(url: url)

        do {
            _ = try await client.get(url: url)
            XCTFail("应该抛出 invalidResponse 错误")
        } catch let error as AirisError {
            if case .invalidResponse = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("错误类型不正确: \(error)")
            }
        }
    }

    func testCancellationError() async throws {
        let url = URL(string: "https://test.com/cancel")!

        let cancelError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        MockURLProtocol.mockError(url: url, error: cancelError)

        do {
            _ = try await client.post(url: url, body: Data())
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    // MARK: - postJSON Tests

    func testPOSTJSON() async throws {
        struct TestData: Codable {
            let key: String
            let value: Int
        }

        let url = URL(string: "https://test.com/json")!
        MockURLProtocol.mockSuccess(url: url, data: Data())

        let testData = TestData(key: "test", value: 42)
        let (_, response) = try await client.postJSON(url: url, body: testData)

        XCTAssertEqual(response.statusCode, 200)
    }

    // MARK: - Configuration Tests

    func testDefaultConfiguration() throws {
        let client = HTTPClient()
        XCTAssertNotNil(client)
    }

    func testCustomConfiguration() throws {
        let config = HTTPClientConfiguration(
            timeoutIntervalForRequest: 30,
            timeoutIntervalForResource: 300,
            waitsForConnectivity: false,
            maxRetries: 5,
            retryDelay: 2.0
        )
        let client = HTTPClient(configuration: config)
        XCTAssertNotNil(client)
    }
}
