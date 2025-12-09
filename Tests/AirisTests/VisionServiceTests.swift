import XCTest
@testable import Airis

final class VisionServiceTests: XCTestCase {
    var service: VisionService!

    override func setUp() {
        super.setUp()
        service = VisionService()
    }

    // MARK: - Service Creation Tests

    func testServiceInitialization() throws {
        XCTAssertNotNil(service)
    }

    func testServiceContainerAccess() throws {
        let containerService = ServiceContainer.shared.visionService
        XCTAssertNotNil(containerService)
    }

    // MARK: - Comprehensive Analysis Tests

    func testComprehensiveAnalysisStructure() throws {
        let analysis = VisionService.ComprehensiveAnalysis(
            classifications: [],
            texts: [],
            barcodes: []
        )

        XCTAssertEqual(analysis.classifications.count, 0)
        XCTAssertEqual(analysis.texts.count, 0)
        XCTAssertEqual(analysis.barcodes.count, 0)
    }

    // 注意：实际的图像分析测试需要测试图片资源
    // 这些测试在有测试图片后可以取消 skip
}
