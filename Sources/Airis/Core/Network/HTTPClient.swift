import Foundation

/// HTTP 客户端配置
struct HTTPClientConfiguration: Sendable {
    var timeoutIntervalForRequest: TimeInterval = 60
    var timeoutIntervalForResource: TimeInterval = 600  // 增加到 10 分钟
    var waitsForConnectivity: Bool = true
    var maxRetries: Int = 3
    var retryDelay: TimeInterval = 1.0
}

/// HTTP 客户端 - 网络请求封装（遵循 Apple 最佳实践）
final class HTTPClient: Sendable {
    private let session: URLSession
    private let configuration: HTTPClientConfiguration

    init(configuration: HTTPClientConfiguration = HTTPClientConfiguration(), session: URLSession? = nil) {
        self.configuration = configuration

        if let customSession = session {
            // 使用注入的 session（用于测试）
            self.session = customSession
        } else {
            // 创建默认 session
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
            config.timeoutIntervalForResource = configuration.timeoutIntervalForResource
            config.waitsForConnectivity = configuration.waitsForConnectivity

            // 标准配置
            config.httpShouldSetCookies = true
            config.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain
            config.allowsCellularAccess = true

            self.session = URLSession(configuration: config)
        }
    }

    deinit {
        session.invalidateAndCancel()
    }

    /// 发送 POST 请求（带自动重试）
    func post(
        url: URL,
        headers: [String: String] = [:],
        body: Data,
        retryCount: Int = 0
    ) async throws -> (Data, HTTPURLResponse) {
        // 检查任务是否已取消
        try Task.checkCancellation()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body

        // 设置默认 Content-Type
        if headers["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: request)

            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AirisError.invalidResponse
            }

            // 处理 HTTP 状态码
            switch httpResponse.statusCode {
            case 200...299:
                // 成功
                return (data, httpResponse)

            case 500...599:
                // 5xx 服务器错误 - 可重试
                if retryCount < configuration.maxRetries {
                    let delay = configuration.retryDelay * Double(retryCount + 1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await post(
                        url: url,
                        headers: headers,
                        body: body,
                        retryCount: retryCount + 1
                    )
                }
                throw AirisError.networkError(
                    NSError(
                        domain: "HTTPClient",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"]
                    )
                )

            default:
                // 4xx 客户端错误 - 不重试
                throw AirisError.networkError(
                    NSError(
                        domain: "HTTPClient",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                    )
                )
            }

        } catch let error as AirisError {
            throw error
        } catch {
            // 网络错误 - 判断是否可重试
            let nsError = error as NSError
            let retryableCodes: Set<Int> = [
                NSURLErrorTimedOut,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorDNSLookupFailed
            ]

            if retryableCodes.contains(nsError.code) && retryCount < configuration.maxRetries {
                let delay = configuration.retryDelay * Double(retryCount + 1)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await post(
                    url: url,
                    headers: headers,
                    body: body,
                    retryCount: retryCount + 1
                )
            }

            throw AirisError.networkError(error)
        }
    }

    /// 发送 GET 请求
    func get(
        url: URL,
        headers: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        try Task.checkCancellation()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AirisError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AirisError.networkError(
                NSError(
                    domain: "HTTPClient",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                )
            )
        }

        return (data, httpResponse)
    }

    /// 发送 JSON POST 请求
    func postJSON<T: Encodable>(
        url: URL,
        headers: [String: String] = [:],
        body: T
    ) async throws -> (Data, HTTPURLResponse) {
        var allHeaders = headers
        allHeaders["Content-Type"] = "application/json"

        let jsonData = try JSONEncoder().encode(body)
        return try await post(url: url, headers: allHeaders, body: jsonData)
    }
}
