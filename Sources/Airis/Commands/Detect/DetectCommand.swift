import ArgumentParser

struct DetectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "detect",
        abstract: "Detect objects and features in images",
        discussion: """
            Detect specific objects using Vision framework:
            - Barcodes and QR codes
            - Faces and facial landmarks
            - Animals (cats and dogs)
            - Human poses (2D and 3D)
            - Hand gestures and landmarks
            - Pet body poses

            Detection results include bounding boxes, confidence scores, \
            and detailed feature information.
            """,
        subcommands: [
            // BarcodeCommand.self,   // Task 4.1 实现
            // FaceCommand.self,      // Task 4.1 实现
            // AnimalCommand.self,    // Task 4.1 实现
            // PoseCommand.self,      // Task 4.2 实现
            // Pose3DCommand.self,    // Task 4.2 实现
            // HandCommand.self,      // Task 4.2 实现
            // PetPoseCommand.self,   // Task 4.2 实现
        ]
    )
}
