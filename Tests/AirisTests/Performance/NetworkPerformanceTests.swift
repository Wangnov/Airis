import XCTest
@testable import Airis

/// HTTP 网络性能基准测试
///
/// 测试目标:
/// - 测试 HTTP 请求性能
/// - 测试重试机制性能
/// - 测试超时处理性能
/// - 测试并发请求性能
///
/// 注意: 这些测试依赖网络连接，可能会因网络状况而波动
final class NetworkPerformanceTests: XCTestCase {

    // MARK: - HTTP 客户端配置测试

    /// 测试 HTTP 客户端创建性能
    func testHTTPClientCreationPerformance() {
        measure {
            let config = HTTPClientConfiguration(
                timeoutIntervalForRequest: 30,
                waitsForConnectivity: false,
                maxRetries: 3
            )
            let _ = HTTPClient(configuration: config)
        }
    }

    /// 测试多个客户端创建性能
    func testMultipleHTTPClientCreationPerformance() {
        measure {
            for _ in 0..<10 {
                let config = HTTPClientConfiguration()
                let _ = HTTPClient(configuration: config)
            }
        }
    }

    // MARK: - GET 请求性能

    /// 测试简单 GET 请求性能
    func testGETRequestPerformance() async throws {
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/get")!

        // 预热
        _ = try? await client.get(url: url)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await client.get(url: url)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试带头部的 GET 请求性能
    func testGETRequestWithHeadersPerformance() async throws {
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/headers")!
        let headers = [
            "X-Custom-Header": "TestValue",
            "Accept": "application/json",
            "User-Agent": "Airis-Test/1.0"
        ]

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await client.get(url: url, headers: headers)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - POST 请求性能

    /// 测试 POST 请求性能 - 小数据
    func testPOSTRequestPerformance_SmallPayload() async throws {
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/post")!
        let body = "{\"test\": \"data\"}".data(using: .utf8)!

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await client.post(url: url, body: body)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试 POST 请求性能 - 中等数据
    func testPOSTRequestPerformance_MediumPayload() async throws {
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/post")!

        // 生成 10KB 数据
        let testData = String(repeating: "x", count: 10 * 1024)
        let body = "{\"data\": \"\(testData)\"}".data(using: .utf8)!

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await client.post(url: url, body: body)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 超时处理性能

    /// 测试超时配置的客户端创建
    func testShortTimeoutClientCreation() {
        measure {
            let config = HTTPClientConfiguration(
                timeoutIntervalForRequest: 5,
                timeoutIntervalForResource: 10,
                waitsForConnectivity: false,
                maxRetries: 0
            )
            let _ = HTTPClient(configuration: config)
        }
    }

    /// 测试超时错误处理性能
    func testTimeoutErrorHandling() async throws {
        let config = HTTPClientConfiguration(
            timeoutIntervalForRequest: 1,
            waitsForConnectivity: false,
            maxRetries: 0
        )
        let client = HTTPClient(configuration: config)
        let url = URL(string: "https://httpbin.org/delay/10")!

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                do {
                    _ = try await client.get(url: url)
                } catch {
                    // 预期会超时
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 并发请求性能

    /// 测试并发 GET 请求性能
    func testConcurrentGETRequests() async throws {
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/get")!

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for _ in 0..<5 {
                        group.addTask {
                            _ = try? await client.get(url: url)
                        }
                    }
                    try await group.waitForAll()
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 响应大小测试

    /// 测试大响应处理性能
    func testLargeResponseHandling() async throws {
        let client = HTTPClient()
        // 请求返回指定大小的数据
        let url = URL(string: "https://httpbin.org/bytes/10240")! // 10KB

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await client.get(url: url)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
