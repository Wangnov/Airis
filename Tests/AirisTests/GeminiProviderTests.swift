import Security

// swiftlint:disable force_unwrapping
import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

// MARK: - URLProtocol Stub

final class GeminiMockURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)
    nonisolated(unsafe) static var handler: Handler?

    override static func canInit(with _: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = GeminiMockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "NoHandler", code: -1))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mocks

struct MockKeychainOperationsWithKey: KeychainOperations, Sendable {
    var storedKey: String?
    var shouldThrow: Bool

    init(storedKey: String? = nil, shouldThrow: Bool = false) {
        self.storedKey = storedKey
        self.shouldThrow = shouldThrow
    }

    func itemUpdate(query _: CFDictionary, attributesToUpdate _: CFDictionary) -> OSStatus { errSecSuccess }
    func itemAdd(attributes _: CFDictionary, result _: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus { errSecSuccess }
    func itemCopyMatching(query _: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if shouldThrow { return errSecItemNotFound }
        if let key = storedKey {
            let data = key.data(using: .utf8)! as CFData
            result?.pointee = data
            return errSecSuccess
        }
        return errSecItemNotFound
    }

    func itemDelete(query _: CFDictionary) -> OSStatus { errSecSuccess }
    func stringToData(_ string: String) -> Data? { string.data(using: .utf8) }
    func dataToString(_ data: Data) -> String? { String(data: data, encoding: .utf8) }
}

// MARK: - Tests

@MainActor
final class GeminiProviderTests: XCTestCase {
    private let providerName = "gemini"

    // Helper: create HTTPClient with stubbed handler
    private func makeHTTPClient(
        handler: @escaping GeminiMockURLProtocol.Handler
    ) -> HTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GeminiMockURLProtocol.self]
        GeminiMockURLProtocol.handler = handler
        addTeardownBlock { GeminiMockURLProtocol.handler = nil }
        let session = URLSession(configuration: config)
        return HTTPClient(session: session)
    }

    // Helper: create ConfigManager backed by temp file
    private func makeConfigManager(baseURL: String?, model: String?) throws -> ConfigManager {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_config_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("config.json")

        var appConfig = AppConfig()
        appConfig.providers = [
            providerName: ProviderConfig(baseURL: baseURL, model: model, customHeaders: nil),
        ]
        appConfig.defaultProvider = providerName

        let data = try JSONEncoder().encode(appConfig)
        try data.write(to: fileURL)

        return ConfigManager(configFile: fileURL)
    }

    // Helper: small base64 image string
    private static func sampleBase64Image() throws -> String {
        let data = try Data(contentsOf: TestResources.image("assets/small_100x100.png"))
        return data.base64EncodedString()
    }

    private static func extractBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            var data = Data()
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            return data.isEmpty ? nil : data
        }
        return nil
    }

    // MARK: - Tests

    func testGenerateImage_SuccessWithReferencesProModel() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(
            baseURL: "https://api.example.com",
            model: "gemini-3-pro-image-preview"
        )

        let expectationCall = expectation(description: "postJSON called")

        let httpClient = makeHTTPClient { request in
            guard let body = GeminiProviderTests.extractBody(from: request) else {
                XCTFail("Missing body")
                // 即便失败也返回空响应，避免真实网络调用
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, Data())
            }
            let decoded = try JSONDecoder().decode(GeminiGenerateRequest.self, from: body)

            // 验证 imageConfig 走 Pro 分支，imageSize 已大写
            XCTAssertEqual(decoded.generationConfig.imageConfig?.imageSize, "4K")
            XCTAssertEqual(decoded.generationConfig.imageConfig?.aspectRatio, "4:3")

            // 工具启用搜索
            XCTAssertNotNil(decoded.tools)

            // parts: 文本 + 参考图片
            XCTAssertEqual(decoded.contents.first?.parts.count, 2)

            // 头部带 api key
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-api-key")

            let base64 = try GeminiProviderTests.sampleBase64Image()
            let response = GeminiGenerateResponse(
                candidates: [
                    .init(content: .init(parts: [
                        .init(text: "ok", inlineData: .init(mimeType: "image/png", data: base64), thoughtSignature: nil),
                    ])),
                ]
            )
            let data = try JSONEncoder().encode(response)
            let responseURL = request.url ?? URL(string: "https://api.example.com")!
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: responseURL, statusCode: 200, httpVersion: nil, headerFields: headers)!
            expectationCall.fulfill()
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        // 准备参考图片与输出路径
        let reference = TestResources.image("assets/small_100x100.png")
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini_pro_output_\(UUID().uuidString).png")

        let resultURL = try await provider.generateImage(
            prompt: "画一只猫",
            references: [reference],
            model: nil,
            aspectRatio: "4:3",
            imageSize: "4k",
            outputPath: outputURL.path,
            enableSearch: true
        )

        XCTAssertEqual(resultURL, outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        try? FileManager.default.removeItem(at: outputURL)
        await fulfillment(of: [expectationCall], timeout: 2)
    }

    func testGenerateImage_FlashModelUsesAspectOnly() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(
            baseURL: "https://api.example.com",
            model: "gemini-2.5-flash-image"
        )

        let httpClient = makeHTTPClient { request in
            guard let body = GeminiProviderTests.extractBody(from: request) else {
                XCTFail("Missing body")
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, Data())
            }
            let decoded = try JSONDecoder().decode(GeminiGenerateRequest.self, from: body)
            // Flash 模型 imageSize 应为空
            XCTAssertNil(decoded.generationConfig.imageConfig?.imageSize)
            XCTAssertEqual(decoded.generationConfig.imageConfig?.aspectRatio, "16:9")

            let base64 = try GeminiProviderTests.sampleBase64Image()
            let response = GeminiGenerateResponse(
                candidates: [
                    .init(content: .init(parts: [
                        .init(text: nil, inlineData: .init(mimeType: "image/png", data: base64), thoughtSignature: nil),
                    ])),
                ]
            )
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini_flash_output_\(UUID().uuidString).png")

        let resultURL = try await provider.generateImage(
            prompt: "画一座山",
            references: [],
            model: nil,
            aspectRatio: "16:9",
            imageSize: "2k", // 应被忽略
            outputPath: outputURL.path,
            enableSearch: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        try? FileManager.default.removeItem(at: resultURL)
    }

    func testGenerateImage_InvalidBaseURLThrows() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(
            baseURL: "😀://",
            model: nil
        )
        let httpClient = makeHTTPClient { _ in
            XCTFail("HTTP should not be called for invalid URL")
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, Data())
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        do {
            _ = try await provider.generateImage(prompt: "test")
            XCTFail("应抛出 invalidPath")
        } catch {
            guard case AirisError.invalidPath = error else {
                XCTFail("期待 invalidPath，实际 \(error)")
                return
            }
        }
    }

    func testGenerateImage_MissingAPIKeyThrows() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: nil, shouldThrow: true))
        let configManager = try makeConfigManager(baseURL: nil, model: nil)
        let httpClient = makeHTTPClient { _ in
            XCTFail("HTTP should not be called when API key missing")
            throw AirisError.invalidResponse
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        do {
            _ = try await provider.generateImage(prompt: "test")
            XCTFail("应抛出 apiKeyNotFound")
        } catch {
            guard case AirisError.apiKeyNotFound = error else {
                XCTFail("期待 apiKeyNotFound，实际 \(error)")
                return
            }
        }
    }

    func testGenerateImage_TextOnlyResponseThrowsNoResults() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(baseURL: "https://api.example.com", model: nil)

        let httpClient = makeHTTPClient { request in
            let response = GeminiGenerateResponse(
                candidates: [
                    .init(content: .init(parts: [
                        .init(text: "Only text", inlineData: nil, thoughtSignature: nil),
                    ])),
                ]
            )
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        do {
            _ = try await provider.generateImage(prompt: "text only")
            XCTFail("应抛出 noResultsFound")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("期待 noResultsFound，实际 \(error)")
                return
            }
        }
    }

    func testGetResolutionForFlashMappingAndFallback() {
        let provider = GeminiProvider(providerName: providerName)
        // 命中已知纵横比
        XCTAssertEqual(provider.getResolutionForFlash(aspectRatio: "3:2"), "1248×832")
        // 未知纵横比走默认分支
        XCTAssertEqual(provider.getResolutionForFlash(aspectRatio: "weird"), "1024×1024")
    }

    func testGenerateImage_AutoOutputPathGenerated() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(baseURL: nil, model: nil)

        let httpClient = makeHTTPClient { request in
            let base64 = try GeminiProviderTests.sampleBase64Image()
            let response = GeminiGenerateResponse(
                candidates: [
                    .init(content: .init(parts: [
                        .init(text: nil, inlineData: .init(mimeType: "image/png", data: base64), thoughtSignature: nil),
                    ])),
                ]
            )
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        let resultURL = try await provider.generateImage(prompt: "auto path test")
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        try? FileManager.default.removeItem(at: resultURL)
    }

    func testGenerateImage_UnknownResolutionFallback() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        // baseURL 为默认值，model 为空 -> 使用 defaultModel
        let configManager = try makeConfigManager(baseURL: nil, model: nil)

        let httpClient = makeHTTPClient { request in
            guard let body = GeminiProviderTests.extractBody(from: request) else {
                XCTFail("Missing body")
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, Data())
            }
            let decoded = try JSONDecoder().decode(GeminiGenerateRequest.self, from: body)
            // 未知 size/aspect 应落到 "Unknown"
            XCTAssertEqual(decoded.generationConfig.imageConfig?.imageSize, "10K")
            XCTAssertEqual(decoded.generationConfig.imageConfig?.aspectRatio, "7:3")
            XCTAssertTrue(request.url?.absoluteString.contains(GeminiProvider.defaultModel) ?? false)

            let base64 = try GeminiProviderTests.sampleBase64Image()
            let response = GeminiGenerateResponse(
                candidates: [.init(content: .init(parts: [
                    .init(text: nil, inlineData: .init(mimeType: "image/png", data: base64), thoughtSignature: nil),
                ]))]
            )
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini_unknown_res_\(UUID().uuidString).png")

        let resultURL = try await provider.generateImage(
            prompt: "unknown resolution",
            references: [],
            model: nil,
            aspectRatio: "7:3",
            imageSize: "10k",
            outputPath: outputURL.path,
            enableSearch: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        try? FileManager.default.removeItem(at: resultURL)
    }

    func testGenerateImage_FlashUnknownAspectUsesDefaultResolution() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(baseURL: "https://api.example.com", model: "gemini-2.5-flash-image")

        let httpClient = makeHTTPClient { request in
            guard let body = GeminiProviderTests.extractBody(from: request) else {
                XCTFail("Missing body")
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, Data())
            }
            let decoded = try JSONDecoder().decode(GeminiGenerateRequest.self, from: body)
            // Flash 模型应忽略 imageSize，使用默认 aspect 处理
            XCTAssertNil(decoded.generationConfig.imageConfig?.imageSize)
            XCTAssertEqual(decoded.generationConfig.imageConfig?.aspectRatio, "5:7")

            let base64 = try GeminiProviderTests.sampleBase64Image()
            let response = GeminiGenerateResponse(
                candidates: [.init(content: .init(parts: [
                    .init(text: nil, inlineData: .init(mimeType: "image/png", data: base64), thoughtSignature: nil),
                ]))]
            )
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini_flash_unknown_\(UUID().uuidString).png")

        let resultURL = try await provider.generateImage(
            prompt: "flash unknown aspect",
            references: [],
            model: nil,
            aspectRatio: "5:7", // 未在表中，触发 getResolutionForFlash 默认
            imageSize: "2k",
            outputPath: outputURL.path,
            enableSearch: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        try? FileManager.default.removeItem(at: resultURL)
    }

    func testGenerateImage_UsesDefaultModelWhenConfigModelNil() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))

        // 写入一个没有 model 的配置，迫使 fallback 使用 Self.defaultModel
        let customConfigDir = FileManager.default.temporaryDirectory.appendingPathComponent("airis_config_defaultModel")
        try FileManager.default.createDirectory(at: customConfigDir, withIntermediateDirectories: true)
        let configFile = customConfigDir.appendingPathComponent("config.json")
        var minimalConfig = AppConfig()
        minimalConfig.providers = [
            providerName: ProviderConfig(baseURL: "https://api.example.com", model: nil, customHeaders: nil),
        ]
        minimalConfig.defaultProvider = providerName
        let data = try JSONEncoder().encode(minimalConfig)
        try data.write(to: configFile)
        let configManager = ConfigManager(configFile: configFile)

        let httpClient = makeHTTPClient { request in
            XCTAssertTrue(request.url?.absoluteString.contains(GeminiProvider.defaultModel) ?? false)

            let base64 = try GeminiProviderTests.sampleBase64Image()
            let response = GeminiGenerateResponse(
                candidates: [.init(content: .init(parts: [
                    .init(text: nil, inlineData: .init(mimeType: "image/png", data: base64), thoughtSignature: nil),
                ]))]
            )
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini_default_model_\(UUID().uuidString).png")

        let resultURL = try await provider.generateImage(
            prompt: "use default model",
            references: [],
            model: nil,
            aspectRatio: "1:1",
            imageSize: "2k",
            outputPath: outputURL.path,
            enableSearch: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        try? FileManager.default.removeItem(at: resultURL)
    }

    func testGenerateImage_NoCandidatesThrowsNoResults() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(baseURL: "https://api.example.com", model: nil)

        let httpClient = makeHTTPClient { request in
            let response = GeminiGenerateResponse(candidates: [])
            let data = try JSONEncoder().encode(response)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        do {
            _ = try await provider.generateImage(prompt: "empty")
            XCTFail("应抛出 noResultsFound")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("期待 noResultsFound，实际 \(error)")
                return
            }
        }
    }

    func testGenerateImage_APIErrorResponseShowsMessage() async throws {
        let keychain = KeychainManager(operations: MockKeychainOperationsWithKey(storedKey: "test-api-key"))
        let configManager = try makeConfigManager(baseURL: "https://api.example.com", model: nil)

        let httpClient = makeHTTPClient { request in
            // 模拟 API 返回错误响应
            let errorResponse = GeminiErrorResponse(
                error: .init(
                    code: 503,
                    message: "The model is overloaded. Please try again later.",
                    status: "UNAVAILABLE"
                )
            )
            let data = try JSONEncoder().encode(errorResponse)
            let headers = ["Content-Type": "application/json"]
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: headers)!
            return (httpResponse, data)
        }

        let provider = GeminiProvider(
            providerName: providerName,
            httpClient: httpClient,
            keychainManager: keychain,
            configManager: configManager
        )

        do {
            _ = try await provider.generateImage(prompt: "test")
            XCTFail("应抛出 apiError")
        } catch {
            guard case let AirisError.apiError(provider, message) = error else {
                XCTFail("期待 apiError，实际 \(error)")
                return
            }
            XCTAssertEqual(provider, "gemini")
            XCTAssertEqual(message, "The model is overloaded. Please try again later.")
        }
    }
}
