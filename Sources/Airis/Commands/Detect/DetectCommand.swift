import ArgumentParser

struct DetectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "detect",
        abstract: "Detect objects and features in images",
        discussion: """
            Detect specific objects using Apple's Vision framework.

            QUICK START:
              airis detect barcode qr_code.jpg
              airis detect face portrait.jpg
              airis detect animal pet.jpg

            AVAILABLE DETECTORS:

              barcode   Detect barcodes and QR codes
                        Supports: QR, EAN-13, Code 128, PDF417, and more

              face      Detect faces with optional landmarks
                        Returns: bounding boxes, head pose, 76 landmark points

              animal    Detect cats and dogs
                        Returns: animal type, confidence, bounding box

            COMING SOON (Task 4.2):
              pose      Human body pose detection (2D)
              pose3d    Human body pose detection (3D)
              hand      Hand landmark detection
              petpose   Pet body pose detection

            COMMON OPTIONS:
              --format <fmt>     Output format: table (default), json
              --threshold <val>  Minimum confidence threshold (0.0-1.0)

            EXAMPLES:
              # Detect QR codes
              airis detect barcode scan.png --type qr

              # Fast face detection
              airis detect face group.jpg --fast

              # Find cats only
              airis detect animal photo.jpg --type cat

              # JSON output for scripting
              airis detect face portrait.jpg --format json

            For detailed options, run:
              airis detect <command> --help
            """,
        subcommands: [
            BarcodeCommand.self,
            FaceCommand.self,
            AnimalCommand.self,
            // PoseCommand.self,      // Task 4.2 实现
            // Pose3DCommand.self,    // Task 4.2 实现
            // HandCommand.self,      // Task 4.2 实现
            // PetPoseCommand.self,   // Task 4.2 实现
        ]
    )
}
