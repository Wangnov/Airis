import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

final class ServiceContainerTests: XCTestCase {
    // MARK: - Singleton Tests

    func testSharedInstance() throws {
        let instance1 = ServiceContainer.shared
        let instance2 = ServiceContainer.shared

        XCTAssertTrue(instance1 === instance2, "Should be the same instance")
    }

    // MARK: - Service Access Tests

    func testVisionServiceAccess() throws {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    func testImageIOServiceAccess() throws {
        let service = ServiceContainer.shared.imageIOService
        XCTAssertNotNil(service)
    }

    func testHTTPClientAccess() throws {
        let client = ServiceContainer.shared.httpClient
        XCTAssertNotNil(client)
    }

    func testKeychainManagerAccess() throws {
        let manager = ServiceContainer.shared.keychainManager
        XCTAssertNotNil(manager)
    }

    func testConfigManagerAccess() throws {
        let manager = ServiceContainer.shared.configManager
        XCTAssertNotNil(manager)
    }

    func testGeminiProviderAccess() throws {
        let provider = ServiceContainer.shared.geminiProvider
        XCTAssertNotNil(provider)
    }

    func testGetProviderByName() throws {
        let provider = ServiceContainer.shared.getProvider(name: "custom-provider")
        XCTAssertNotNil(provider)
    }

    // MARK: - Lazy Loading Tests

    func testLazyLoadingBehavior() throws {
        // 访问服务应该触发懒加载
        _ = ServiceContainer.shared.visionService
        _ = ServiceContainer.shared.imageIOService

        // 再次访问应该返回同一实例
        let service1 = ServiceContainer.shared.visionService
        let service2 = ServiceContainer.shared.visionService

        XCTAssertTrue(service1 === service2, "Lazy properties should return same instance")
    }
}
