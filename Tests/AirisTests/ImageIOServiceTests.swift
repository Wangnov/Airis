import XCTest
@testable import Airis

final class ImageIOServiceTests: XCTestCase {
    var service: ImageIOService!

    override func setUp() {
        super.setUp()
        service = ImageIOService()
    }

    // MARK: - Service Creation Tests

    func testServiceInitialization() throws {
        XCTAssertNotNil(service)
    }

    func testServiceContainerAccess() throws {
        let containerService = ServiceContainer.shared.imageIOService
        XCTAssertNotNil(containerService)
    }

    // MARK: - Image Info Structure Tests

    func testImageInfoStructure() throws {
        let info = ImageIOService.ImageInfo(
            width: 1920,
            height: 1080,
            dpiWidth: 72,
            dpiHeight: 72,
            colorModel: "RGB",
            depth: 8,
            hasAlpha: false,
            orientation: .up
        )

        XCTAssertEqual(info.width, 1920)
        XCTAssertEqual(info.height, 1080)
        XCTAssertEqual(info.dpiWidth, 72)
        XCTAssertFalse(info.hasAlpha)
    }

    // 注意：实际的图像 I/O 测试需要测试图片资源
}
