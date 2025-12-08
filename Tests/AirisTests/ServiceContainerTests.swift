import XCTest
@testable import Airis

final class ServiceContainerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = ServiceContainer.shared
        let instance2 = ServiceContainer.shared

        XCTAssertTrue(instance1 === instance2, "Should be the same instance")
    }

    // MARK: - Service Access Tests

    func testVisionServiceAccess() {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    func testImageIOServiceAccess() {
        let service = ServiceContainer.shared.imageIOService
        XCTAssertNotNil(service)
    }

    func testHTTPClientAccess() {
        let client = ServiceContainer.shared.httpClient
        XCTAssertNotNil(client)
    }

    func testKeychainManagerAccess() {
        let manager = ServiceContainer.shared.keychainManager
        XCTAssertNotNil(manager)
    }

    func testConfigManagerAccess() {
        let manager = ServiceContainer.shared.configManager
        XCTAssertNotNil(manager)
    }

    func testGeminiProviderAccess() {
        let provider = ServiceContainer.shared.geminiProvider
        XCTAssertNotNil(provider)
    }

    func testGetProviderByName() {
        let provider = ServiceContainer.shared.getProvider(name: "custom-provider")
        XCTAssertNotNil(provider)
    }

    // MARK: - Lazy Loading Tests

    func testLazyLoadingBehavior() {
        // 访问服务应该触发懒加载
        _ = ServiceContainer.shared.visionService
        _ = ServiceContainer.shared.imageIOService

        // 再次访问应该返回同一实例
        let service1 = ServiceContainer.shared.visionService
        let service2 = ServiceContainer.shared.visionService

        XCTAssertTrue(service1 === service2, "Lazy properties should return same instance")
    }
}
