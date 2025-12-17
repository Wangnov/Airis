import ArgumentParser

struct DetectCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "detect",
            abstract: HelpTextFactory.text(
                en: "Detect objects and features in images",
                cn: "检测图像中的对象与特征"
            ),
            discussion: helpDiscussion(
                en: """
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
                cn: """
                    使用 Apple Vision 框架进行目标/特征检测。

                    QUICK START:
                      airis detect barcode qr_code.jpg
                      airis detect face portrait.jpg
                      airis detect animal pet.jpg

                    常用子命令：
                      barcode   条码/二维码
                      face      人脸（可选关键点）
                      animal    猫/狗
                      pose      人体 2D 姿态
                      pose3d    人体 3D 姿态（macOS 14.0+）
                      hand      手部关键点
                      petpose   宠物姿态（macOS 14.0+）

                    进一步帮助：
                      airis detect <command> --help
                    """
            ),
            subcommands: [
                BarcodeCommand.self,
                FaceCommand.self,
                AnimalCommand.self,
                PoseCommand.self,
                Pose3DCommand.self,
                HandCommand.self,
                PetPoseCommand.self,
            ],
            aliases: ["d"]
        )
    }
}
