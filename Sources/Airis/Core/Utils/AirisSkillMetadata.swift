import Foundation

/// AI tool integration metadata emitted inside `--help` output.
///
/// Format reference: docs/tasks/fix/FIX-8-Alias-BilingualHelp.md
enum AirisSkillMetadata {
    struct Entry: Sendable {
        var inputTypes: [String]
        var outputTypes: [String]
        var capabilities: [String]
        var languages: [String]?

        func render() -> String {
            var lines: [String] = []
            lines.append("AI_SKILL_METADATA:")
            lines.append("  input_types:  \(Self.renderArray(inputTypes))")
            lines.append("  output_types: \(Self.renderArray(outputTypes))")
            lines.append("  capabilities: \(Self.renderArray(capabilities))")
            if let languages {
                lines.append("  languages:    \(Self.renderArray(languages))")
            }
            return lines.joined(separator: "\n")
        }

        private static func renderArray(_ values: [String]) -> String {
            "[" + values.joined(separator: ", ") + "]"
        }
    }

    static func helpBlock(for commandType: Any.Type) -> String {
        let typeName = String(describing: commandType)
        let entry = entries[typeName] ?? fallback(for: typeName)
        return entry.render()
    }

    private static func fallback(for typeName: String) -> Entry {
        if typeName.hasSuffix("Command") {
            return Entry(
                inputTypes: commonImageInputTypes,
                outputTypes: ["text/plain"],
                capabilities: ["image_processing"]
            )
        }

        return Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["cli"]
        )
    }

    // MARK: - Common MIME Types

    private static let commonImageInputTypes: [String] = [
        "image/png",
        "image/jpeg",
        "image/heic",
        "image/tiff",
        "image/webp",
        "image/gif",
        "image/bmp",
    ]

    private static let commonImageOutputTypes: [String] = [
        "image/png",
        "image/jpeg",
        "image/heic",
        "image/tiff",
    ]

    // MARK: - Per-command mapping

    private static let entries: [String: Entry] = [
        // Root
        "Airis": Entry(
            inputTypes: ["text/plain", "image/png", "image/jpeg", "image/heic", "image/tiff"],
            outputTypes: ["text/plain", "application/json", "image/png", "image/jpeg", "image/heic", "image/tiff"],
            capabilities: ["image_processing_cli", "help", "multilingual_help"]
        ),

        // Groups
        "GenCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: commonImageOutputTypes,
            capabilities: ["image_generation"]
        ),
        "AnalyzeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["image_analysis"]
        ),
        "DetectCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["object_detection"]
        ),
        "VisionCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json", "image/png"],
            capabilities: ["vision_operations"]
        ),
        "EditCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["image_editing"]
        ),
        "AdjustCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["image_adjustment"]
        ),
        "FilterCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["image_filtering"]
        ),
        "ConfigCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["configuration", "api_key_management", "keychain"]
        ),

        // Gen leaf
        "DrawCommand": Entry(
            inputTypes: ["text/plain"] + commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["image_generation", "text_to_image", "image_to_image", "prompting"]
        ),
        "SetKeyCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["api_key_set", "keychain"]
        ),
        "GetKeyCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["api_key_get", "keychain"]
        ),
        "DeleteKeyCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["api_key_delete", "keychain"]
        ),
        "SetConfigCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["provider_config_set"]
        ),
        "ShowConfigCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["provider_config_show"]
        ),
        "ResetConfigCommand": Entry(
            inputTypes: ["text/plain"],
            outputTypes: ["text/plain"],
            capabilities: ["provider_config_reset"]
        ),

        // Analyze leaf
        "InfoCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["image_info", "dimensions", "dpi", "color_model", "file_size"]
        ),
        "MetaCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["metadata_extraction", "exif", "tiff_tags"]
        ),
        "OCRCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["ocr", "text_recognition"],
            languages: ["en", "zh-Hans", "zh-Hant", "ja", "ko"]
        ),
        "PaletteCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["color_palette", "dominant_colors"]
        ),
        "SafeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["sensitive_content_analysis"]
        ),
        "ScoreCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["aesthetic_scoring"]
        ),
        "SimilarCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["image_similarity", "perceptual_similarity"]
        ),
        "TagCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["image_classification", "tagging", "scene_recognition"]
        ),

        // Detect leaf
        "AnimalCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["animal_detection"]
        ),
        "BarcodeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["barcode_detection", "qr_code_detection"]
        ),
        "FaceCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["face_detection"]
        ),
        "HandCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["hand_pose_detection", "gesture_recognition"]
        ),
        "PetPoseCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["pet_pose_detection"]
        ),
        "PoseCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["human_pose_2d"]
        ),
        "Pose3DCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"],
            capabilities: ["human_pose_3d"]
        ),

        // Vision leaf
        "AlignCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json"] + commonImageOutputTypes,
            capabilities: ["image_alignment", "image_registration"]
        ),
        "FlowCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json", "image/png"],
            capabilities: ["optical_flow", "motion_estimation"]
        ),
        "PersonsCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json", "image/png"],
            capabilities: ["person_segmentation", "mask_generation"]
        ),
        "SaliencyCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["text/plain", "application/json", "image/png"],
            capabilities: ["saliency_detection", "heatmap_generation"]
        ),

        // Edit leaf
        "CropCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["crop", "image_editing"]
        ),
        "CutCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: ["image/png"],
            capabilities: ["background_removal", "foreground_segmentation"]
        ),
        "DefringeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["defringe", "chromatic_aberration_correction"]
        ),
        "EnhanceCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["auto_enhance", "photo_enhancement"]
        ),
        "FormatCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["format_conversion", "reencode"]
        ),
        "ResizeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["resize", "scaling"]
        ),
        "ScanCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["document_scanning", "perspective_correction"]
        ),
        "StraightenCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["straighten", "horizon_leveling"]
        ),
        "ThumbCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["thumbnail_generation", "downsampling"]
        ),
        "TraceCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["edge_detection", "sketch_effect"]
        ),

        // Adjust leaf
        "ColorCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["brightness", "contrast", "saturation", "color_adjustment"]
        ),
        "ExposureCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["exposure", "highlights", "shadows"]
        ),
        "FlipCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["flip", "mirror"]
        ),
        "InvertCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["invert_colors"]
        ),
        "PosterizeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["posterize"]
        ),
        "RotateCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["rotate"]
        ),
        "TemperatureCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["white_balance", "temperature"]
        ),
        "ThresholdCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["threshold", "binarization"]
        ),
        "VignetteCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["vignette"]
        ),

        // Filter leaf
        "BlurCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["blur", "image_filter"]
        ),
        "ChromeCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["chrome_filter", "image_filter"]
        ),
        "ComicCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["comic_filter", "image_filter"]
        ),
        "HalftoneCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["halftone_filter", "image_filter"]
        ),
        "InstantCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["instant_filter", "image_filter"]
        ),
        "MonoCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["mono_filter", "image_filter"]
        ),
        "NoirCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["noir_filter", "image_filter"]
        ),
        "NoiseCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["noise_filter", "image_filter"]
        ),
        "PixelCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["pixelate_filter", "image_filter"]
        ),
        "SepiaCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["sepia_filter", "image_filter"]
        ),
        "SharpenCommand": Entry(
            inputTypes: commonImageInputTypes,
            outputTypes: commonImageOutputTypes,
            capabilities: ["sharpen", "image_filter"]
        ),
    ]
}
