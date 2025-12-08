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

              pose      Human body pose detection (2D, 19 keypoints)
                        Returns: body joints, normalized coordinates

              pose3d    Human body pose detection (3D, 17 keypoints)
                        Returns: 3D positions in meters (macOS 14.0+)

              hand      Hand landmark detection (21 keypoints per hand)
                        Returns: finger joints, left/right detection

              petpose   Pet body pose detection (cats/dogs, 25 keypoints)
                        Returns: pet skeleton (macOS 14.0+)

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
            PoseCommand.self,
            Pose3DCommand.self,
            HandCommand.self,
            PetPoseCommand.self,
        ]
    )
}
