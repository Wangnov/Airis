import Foundation
import XCTest

/// Mock URLProtocol 用于测试网络请求
/// 支持 mock 各种 HTTP 响应和网络错误
class MockURLProtocol: URLProtocol {

    /// Mock 响应配置
    struct MockResponse {
        let data: Data
        let statusCode: Int
        let headers: [String: String]
        let shouldReturnInvalidResponse: Bool  // 用于测试 invalidResponse

        init(data: Data = Data(), statusCode: Int = 200, headers: [String: String] = [:], shouldReturnInvalidResponse: Bool = false) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
            self.shouldReturnInvalidResponse = shouldReturnInvalidResponse
        }
    }

    /// Mock 响应存储
    nonisolated(unsafe) static var mockResponses: [URL: MockResponse] = [:]

    /// Mock 错误存储
    nonisolated(unsafe) static var mockErrors: [URL: Error] = [:]

    /// Mock 序列存储（用于重试测试）
    nonisolated(unsafe) static var mockSequences: [URL: [Result<MockResponse, Error>]] = [:]
    nonisolated(unsafe) static var sequenceIndices: [URL: Int] = [:]

    /// 重置所有 mock 数据
    static func reset() {
        mockResponses = [:]
        mockErrors = [:]
        mockSequences = [:]
        sequenceIndices = [:]
    }

    // MARK: - Mock 配置方法

    /// Mock 成功响应
    static func mockSuccess(url: URL, data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
        mockResponses[url] = MockResponse(data: data, statusCode: statusCode, headers: headers)
    }

    /// Mock invalidResponse（非 HTTPURLResponse）
    static func mockInvalidResponse(url: URL) {
        mockResponses[url] = MockResponse(shouldReturnInvalidResponse: true)
    }

    /// Mock 错误
    static func mockError(url: URL, error: Error) {
        mockErrors[url] = error
    }

    /// Mock 响应序列（用于重试测试）
    static func mockSequence(url: URL, responses: [Result<MockResponse, Error>]) {
        mockSequences[url] = responses
        sequenceIndices[url] = 0
    }

    // MARK: - URLProtocol 实现

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        // 只处理我们 mock 的 URL
        return mockResponses[url] != nil || mockErrors[url] != nil || mockSequences[url] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
            return
        }

        // 处理序列（用于重试测试）
        if let sequence = Self.mockSequences[url] {
            let index = Self.sequenceIndices[url] ?? 0
            guard index < sequence.count else {
                client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
                return
            }

            Self.sequenceIndices[url] = index + 1

            switch sequence[index] {
            case .success(let mockResponse):
                if mockResponse.shouldReturnInvalidResponse {
                    handleInvalidResponse()
                } else {
                    handleSuccess(mockResponse: mockResponse)
                }
            case .failure(let error):
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // 处理错误
        if let error = Self.mockErrors[url] {
            client?.urlProtocol(self, didFailWithError: error)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // 处理正常响应
        if let mockResponse = Self.mockResponses[url] {
            if mockResponse.shouldReturnInvalidResponse {
                handleInvalidResponse()
            } else {
                handleSuccess(mockResponse: mockResponse)
            }
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // 未配置的 URL
        client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
    }

    override func stopLoading() {
        // 不需要做什么
    }

    private func handleSuccess(mockResponse: MockResponse) {
        guard let url = request.url else { return }

        let response = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mockResponse.data)
    }

    private func handleInvalidResponse() {
        guard let url = request.url else { return }

        // 返回一个非 HTTPURLResponse（使用 URLResponse）
        let response = URLResponse(
            url: url,
            mimeType: "text/plain",
            expectedContentLength: 0,
            textEncodingName: nil
        )

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
    }
}
