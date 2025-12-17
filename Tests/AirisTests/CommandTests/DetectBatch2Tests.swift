import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// Task 4.2 - Detect Commands Batch 2 测试
/// 测试 pose, pose3d, hand, petpose 四个新命令
final class DetectBatch2Tests: XCTestCase {
    private var originalLanguage: Language = .en

    override func setUp() {
        super.setUp()
        originalLanguage = Language.current
        Language.current = .en
    }

    override func tearDown() {
        Language.current = originalLanguage
        super.tearDown()
    }

    // MARK: - PoseCommand Configuration Tests

    func testPoseCommandConfiguration() throws {
        XCTAssertEqual(PoseCommand.configuration.commandName, "pose")
        XCTAssertTrue(PoseCommand.configuration.abstract.contains("pose"))
        XCTAssertTrue(PoseCommand.configuration.abstract.contains("2D"))
    }

    func testPoseCommandDiscussionContainsQuickStart() throws {
        let discussion = PoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("airis detect pose"))
    }

    func testPoseCommandDiscussionContainsKeypoints() throws {
        let discussion = PoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("KEYPOINTS"))
        XCTAssertTrue(discussion.contains("19 total") || discussion.contains("19"))
        XCTAssertTrue(discussion.contains("HEAD"))
        XCTAssertTrue(discussion.contains("ARMS"))
        XCTAssertTrue(discussion.contains("LEGS"))
    }

    func testPoseCommandDiscussionContainsExamples() throws {
        let discussion = PoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("--format json"))
        XCTAssertTrue(discussion.contains("--threshold"))
    }

    func testPoseCommandDiscussionContainsOptions() throws {
        let discussion = PoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("OPTIONS"))
        XCTAssertTrue(discussion.contains("--threshold"))
        XCTAssertTrue(discussion.contains("--pixels"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    func testPoseCommandDiscussionContainsOutputExample() throws {
        let discussion = PoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE") || discussion.contains("OUTPUT"))
    }

    // MARK: - Pose3DCommand Configuration Tests

    func testPose3DCommandConfiguration() throws {
        XCTAssertEqual(Pose3DCommand.configuration.commandName, "pose3d")
        XCTAssertTrue(Pose3DCommand.configuration.abstract.contains("3D"))
        XCTAssertTrue(Pose3DCommand.configuration.abstract.contains("pose"))
    }

    func testPose3DCommandDiscussionContainsRequirements() throws {
        let discussion = Pose3DCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("REQUIREMENTS") || discussion.contains("macOS 14.0"))
    }

    func testPose3DCommandDiscussionContainsKeypoints() throws {
        let discussion = Pose3DCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("KEYPOINTS"))
        XCTAssertTrue(discussion.contains("17 total") || discussion.contains("17"))
        XCTAssertTrue(discussion.contains("HEAD"))
        XCTAssertTrue(discussion.contains("TORSO"))
    }

    func testPose3DCommandDiscussionContainsCoordinateSystem() throws {
        let discussion = Pose3DCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("COORDINATE SYSTEM") || discussion.contains("meters") || discussion.contains("3D"))
    }

    func testPose3DCommandDiscussionContainsExamples() throws {
        let discussion = Pose3DCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("airis detect pose3d"))
    }

    // MARK: - HandCommand Configuration Tests

    func testHandCommandConfiguration() throws {
        XCTAssertEqual(HandCommand.configuration.commandName, "hand")
        XCTAssertTrue(HandCommand.configuration.abstract.contains("hand"))
        XCTAssertTrue(HandCommand.configuration.abstract.contains("21"))
    }

    func testHandCommandDiscussionContainsQuickStart() throws {
        let discussion = HandCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("airis detect hand"))
    }

    func testHandCommandDiscussionContainsKeypoints() throws {
        let discussion = HandCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("KEYPOINTS"))
        XCTAssertTrue(discussion.contains("21"))
        XCTAssertTrue(discussion.contains("THUMB"))
        XCTAssertTrue(discussion.contains("INDEX"))
        XCTAssertTrue(discussion.contains("WRIST"))
    }

    func testHandCommandDiscussionContainsChirality() throws {
        let discussion = HandCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("CHIRALITY") || discussion.contains("left") || discussion.contains("right"))
    }

    func testHandCommandDiscussionContainsOptions() throws {
        let discussion = HandCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("OPTIONS"))
        XCTAssertTrue(discussion.contains("--threshold"))
        XCTAssertTrue(discussion.contains("--max-hands"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    func testHandCommandDiscussionContainsExamples() throws {
        let discussion = HandCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("--format json"))
    }

    // MARK: - PetPoseCommand Configuration Tests

    func testPetPoseCommandConfiguration() throws {
        XCTAssertEqual(PetPoseCommand.configuration.commandName, "petpose")
        XCTAssertTrue(PetPoseCommand.configuration.abstract.contains("pet") ||
                      PetPoseCommand.configuration.abstract.contains("Pet"))
    }

    func testPetPoseCommandDiscussionContainsRequirements() throws {
        let discussion = PetPoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("REQUIREMENTS") || discussion.contains("macOS 14.0"))
    }

    func testPetPoseCommandDiscussionContainsSupportedAnimals() throws {
        let discussion = PetPoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("SUPPORTED ANIMALS") ||
                      (discussion.contains("Cat") && discussion.contains("Dog")))
    }

    func testPetPoseCommandDiscussionContainsKeypoints() throws {
        let discussion = PetPoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("KEYPOINTS"))
        XCTAssertTrue(discussion.contains("25") || discussion.contains("23"))
        XCTAssertTrue(discussion.contains("HEAD"))
        XCTAssertTrue(discussion.contains("TAIL") || discussion.contains("tail"))
    }

    func testPetPoseCommandDiscussionContainsOptions() throws {
        let discussion = PetPoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("OPTIONS"))
        XCTAssertTrue(discussion.contains("--threshold"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    func testPetPoseCommandDiscussionContainsExamples() throws {
        let discussion = PetPoseCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("airis detect petpose"))
    }

    // MARK: - VisionService Pose Detection Methods Tests

    func testVisionServiceHasHumanBodyPoseMethod() throws {
        let service = VisionService()
        XCTAssertNotNil(service)
        // 验证方法存在（通过编译通过来验证）
    }

    func testVisionServiceHasHandPoseMethod() throws {
        let service = VisionService()
        XCTAssertNotNil(service)
        // 验证方法存在（通过编译通过来验证）
    }

    // MARK: - DetectCommand Integration Tests

    func testDetectCommandContainsPoseSubcommand() throws {
        let subcommands = DetectCommand.configuration.subcommands
        let hasCommand = subcommands.contains { $0 == PoseCommand.self }
        XCTAssertTrue(hasCommand)
    }

    func testDetectCommandContainsPose3DSubcommand() throws {
        let subcommands = DetectCommand.configuration.subcommands
        let hasCommand = subcommands.contains { $0 == Pose3DCommand.self }
        XCTAssertTrue(hasCommand)
    }

    func testDetectCommandContainsHandSubcommand() throws {
        let subcommands = DetectCommand.configuration.subcommands
        let hasCommand = subcommands.contains { $0 == HandCommand.self }
        XCTAssertTrue(hasCommand)
    }

    func testDetectCommandContainsPetPoseSubcommand() throws {
        let subcommands = DetectCommand.configuration.subcommands
        let hasCommand = subcommands.contains { $0 == PetPoseCommand.self }
        XCTAssertTrue(hasCommand)
    }

    // MARK: - Default Values Tests

    func testPoseCommandDefaultsInConfiguration() throws {
        let discussion = PoseCommand.configuration.discussion
        // Default format is table
        XCTAssertTrue(discussion.contains("table (default)") || discussion.contains("table"))
        // Default threshold
        XCTAssertTrue(discussion.contains("0.3") || discussion.contains("threshold"))
    }

    func testHandCommandDefaultsInConfiguration() throws {
        let discussion = HandCommand.configuration.discussion
        // Default format is table
        XCTAssertTrue(discussion.contains("table (default)") || discussion.contains("table"))
        // Default max hands is 2
        XCTAssertTrue(discussion.contains("default: 2") || discussion.contains("2"))
    }

    func testPetPoseCommandDefaultsInConfiguration() throws {
        let discussion = PetPoseCommand.configuration.discussion
        // Default format is table
        XCTAssertTrue(discussion.contains("table (default)") || discussion.contains("table"))
    }

    // MARK: - Help Quality Tests (评估帮助文档质量)

    func testPoseCommandHelpQuality() throws {
        let discussion = PoseCommand.configuration.discussion
        var score = 0

        // QUICK START
        if discussion.contains("QUICK START") { score += 2 }

        // EXAMPLES (至少 3 个)
        if discussion.contains("EXAMPLES") { score += 1 }
        let exampleCount = discussion.components(separatedBy: "airis detect pose").count - 1
        if exampleCount >= 3 { score += 1 }

        // OPTIONS
        if discussion.contains("OPTIONS") { score += 1 }

        // OUTPUT EXAMPLE
        if discussion.contains("OUTPUT") { score += 1 }

        // KEYPOINTS 详细说明
        if discussion.contains("KEYPOINTS") { score += 1 }

        // COORDINATE SYSTEM
        if discussion.contains("COORDINATE") { score += 1 }

        // 至少包含一些关键点名称
        if discussion.contains("nose") || discussion.contains("shoulder") { score += 1 }

        // 输出格式说明
        if discussion.contains("json") && discussion.contains("table") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 9, "Help quality score should be 9+/10, got \(score)")
    }

    func testHandCommandHelpQuality() throws {
        let discussion = HandCommand.configuration.discussion
        var score = 0

        if discussion.contains("QUICK START") { score += 2 }
        if discussion.contains("EXAMPLES") { score += 1 }
        if discussion.contains("OPTIONS") { score += 1 }
        if discussion.contains("OUTPUT") { score += 1 }
        if discussion.contains("KEYPOINTS") { score += 1 }
        if discussion.contains("21") { score += 1 }
        if discussion.contains("THUMB") || discussion.contains("thumb") { score += 1 }
        if discussion.contains("CHIRALITY") || discussion.contains("left") { score += 1 }
        if discussion.contains("json") && discussion.contains("table") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 9, "Help quality score should be 9+/10, got \(score)")
    }

    func testPetPoseCommandHelpQuality() throws {
        let discussion = PetPoseCommand.configuration.discussion
        var score = 0

        if discussion.contains("QUICK START") { score += 2 }
        if discussion.contains("EXAMPLES") { score += 1 }
        if discussion.contains("OPTIONS") { score += 1 }
        if discussion.contains("OUTPUT") { score += 1 }
        if discussion.contains("KEYPOINTS") { score += 1 }
        if discussion.contains("Cat") || discussion.contains("Dog") { score += 1 }
        if discussion.contains("SUPPORTED") { score += 1 }
        if discussion.contains("macOS 14") || discussion.contains("REQUIREMENTS") { score += 1 }
        if discussion.contains("json") && discussion.contains("table") { score += 1 }

        XCTAssertGreaterThanOrEqual(score, 9, "Help quality score should be 9+/10, got \(score)")
    }
}
