import Foundation

/// 双语字符串表
struct Strings: Sendable {
    private static let dict: [String: [Language: String]] = [
        // ============ 通用错误 ============
        "error.file_not_found": [
            .en: "File not found: %@",
            .cn: "文件未找到：%@",
        ],
        "error.unsupported_format": [
            .en: "Unsupported format: %@",
            .cn: "不支持的格式：%@",
        ],
        "error.invalid_path": [
            .en: "Invalid path: %@",
            .cn: "无效路径：%@",
        ],
        "error.unknown": [
            .en: "Unknown error occurred",
            .cn: "发生未知错误",
        ],
        "error.file_read": [
            .en: "Failed to read file: %@",
            .cn: "读取文件失败：%@",
        ],
        "error.file_write": [
            .en: "Failed to write file: %@",
            .cn: "写入文件失败：%@",
        ],

        "error.requires_macos": [
            .en: "⚠️ %@ requires macOS %@ or later.",
            .cn: "⚠️ %@ 需要 macOS %@ 或更高版本。",
        ],

        "error.feature_unsupported": [
            .en: "   Your current system does not support this feature.",
            .cn: "   当前系统不支持该功能。",
        ],

        // ============ API Key 相关 ============
        "error.api_key_not_found": [
            .en: "API key not found for provider: %@",
            .cn: "未找到服务商的 API Key：%@",
        ],
        "error.api_key_recovery": [
            .en: "Run 'airis gen config set-key --provider %@' to configure",
            .cn: "运行 'airis gen config set-key --provider %@' 进行配置",
        ],
        "error.network": [
            .en: "Network error: %@",
            .cn: "网络错误：%@",
        ],
        "error.invalid_response": [
            .en: "Invalid response from server",
            .cn: "服务器返回无效响应",
        ],

        // ============ Vision 相关 ============
        "error.vision_failed": [
            .en: "Vision request failed: %@",
            .cn: "Vision 请求失败：%@",
        ],
        "error.no_results": [
            .en: "No results found",
            .cn: "未找到结果",
        ],

        // ============ 图像处理 ============
        "error.invalid_dimension": [
            .en: "Invalid dimension: %d×%d (max: %d)",
            .cn: "无效尺寸：%d×%d（最大：%d）",
        ],
        "error.image_decode": [
            .en: "Failed to decode image",
            .cn: "图像解码失败",
        ],
        "error.image_encode": [
            .en: "Failed to encode image",
            .cn: "图像编码失败",
        ],

        // ============ Keychain ============
        "error.keychain": [
            .en: "Keychain error: %d",
            .cn: "钥匙串错误：%d",
        ],

        // ============ 通用信息 ============
        "info.dimension": [
            .en: "Dimensions: %d × %d px",
            .cn: "尺寸：%d × %d 像素",
        ],
        "info.dpi": [
            .en: "DPI: %d",
            .cn: "DPI：%d",
        ],
        "info.file_size": [
            .en: "File size: %@",
            .cn: "文件大小：%@",
        ],
        "info.format": [
            .en: "Format: %@",
            .cn: "格式：%@",
        ],
        "info.success": [
            .en: "Success",
            .cn: "成功",
        ],
        "info.saved_to": [
            .en: "Saved to: %@",
            .cn: "已保存至：%@",
        ],
        "info.processing": [
            .en: "Processing...",
            .cn: "处理中...",
        ],

        // ============ SensitiveContentAnalysis ============
        "safe.disabled_hint": [
            .en: """
            ⚠️ Sensitive Content Analysis is not available.

            Possible reasons:
            1. System setting not enabled:
               System Settings > Privacy & Security > Sensitive Content Warning

            2. This version does not support this feature:
               - Developer ID distribution does NOT support this feature
               - Only App Store version or Development build can use it

            Solutions:
            • Enable the system setting above, OR
            • Use the App Store version of Airis, OR
            • Build from source with Xcode (Development signing)
            """,
            .cn: """
            ⚠️ 敏感内容分析功能不可用。

            可能原因：
            1. 系统设置未启用：
               系统设置 > 隐私与安全性 > 敏感内容警告

            2. 当前版本不支持此功能：
               - Developer ID 分发版本不支持此功能（Apple 限制）
               - 仅 App Store 版本或 Development 构建可用

            解决方案：
            • 启用上述系统设置，或
            • 使用 App Store 版本的 Airis，或
            • 使用 Xcode 自行编译（Development 签名）
            """,
        ],
        "safe.is_sensitive": [
            .en: "Contains sensitive content: %@",
            .cn: "包含敏感内容：%@",
        ],
        "safe.is_safe": [
            .en: "No sensitive content detected",
            .cn: "未检测到敏感内容",
        ],

        // ============ Analyze 命令 ============
        "analyze.processing": [
            .en: "Analyzing image...",
            .cn: "正在分析图像...",
        ],
        "analyze.tag.found": [
            .en: "Found %d tag(s)",
            .cn: "检测到 %d 个标签",
        ],
        "analyze.tag.showing": [
            .en: "Found %d tag(s), showing top %d",
            .cn: "检测到 %d 个标签（显示前 %d 个）",
        ],
        "analyze.ocr.found": [
            .en: "Recognized %d text segment(s)",
            .cn: "识别到 %d 段文字",
        ],
        "analyze.score.result": [
            .en: "Aesthetic score: %.2f",
            .cn: "美学评分：%.2f",
        ],
        "analyze.score.excellent": [
            .en: "Excellent",
            .cn: "优秀",
        ],
        "analyze.score.good": [
            .en: "Good",
            .cn: "良好",
        ],
        "analyze.score.fair": [
            .en: "Fair",
            .cn: "一般",
        ],
        "analyze.score.poor": [
            .en: "Poor",
            .cn: "较差",
        ],
        "analyze.score.utility": [
            .en: "This is a utility image (screenshot, document, etc.)",
            .cn: "这是一张实用性图像（截图、文档等）",
        ],
        "analyze.score.unavailable": [
            .en: "⚠️ Aesthetic scoring requires macOS 15.0 or later",
            .cn: "⚠️ 美学评分需要 macOS 15.0 或更高版本",
        ],
        "info.color_model": [
            .en: "Color Model: %@",
            .cn: "色彩模型：%@",
        ],
        "info.bit_depth": [
            .en: "Bit Depth: %d",
            .cn: "位深度：%d",
        ],
        "info.has_alpha": [
            .en: "Has Alpha: %@",
            .cn: "包含透明通道：%@",
        ],
        "info.yes": [
            .en: "Yes",
            .cn: "是",
        ],
        "info.no": [
            .en: "No",
            .cn: "否",
        ],

        // ============ 命令帮助 ============
        "help.image_path": [
            .en: "Path to the image file",
            .cn: "图像文件路径",
        ],
        "help.output_path": [
            .en: "Output file path",
            .cn: "输出文件路径",
        ],
        "help.language": [
            .en: "Output language (en/cn)",
            .cn: "输出语言（en/cn）",
        ],

        // ============ Gen 命令 ============
        "gen.connecting": [
            .en: "🌐 Connecting to AI Image API...",
            .cn: "🌐 正在连接 AI 图像 API...",
        ],
        "gen.model": [
            .en: "🔑 Model: %@",
            .cn: "🔑 模型：%@",
        ],
        "gen.prompt": [
            .en: "📝 Prompt: %@",
            .cn: "📝 提示词：%@",
        ],
        "gen.references": [
            .en: "🖼️ Processing %d reference image(s)...",
            .cn: "🖼️ 处理 %d 张参考图片...",
        ],
        "gen.placeholder_warning": [
            .en: "⚠️ Gemini Image API integration coming soon!",
            .cn: "⚠️ Gemini 图像 API 集成即将推出！",
        ],
        "gen.api_key_configured": [
            .en: "💡 API key is configured. Ready for integration.",
            .cn: "💡 API Key 已配置，准备集成。",
        ],
        "config.key_saved": [
            .en: "✅ API key saved for provider: %@",
            .cn: "✅ 已保存服务商的 API Key：%@",
        ],
        "config.key_deleted": [
            .en: "✅ API key deleted for provider: %@",
            .cn: "✅ 已删除服务商的 API Key：%@",
        ],
        "config.key_display": [
            .en: "API key for %@: %@",
            .cn: "%@ 的 API Key：%@",
        ],
        "config.enter_key": [
            .en: "Enter API key for %@: ",
            .cn: "请输入 %@ 的 API Key：",
        ],
        "config.no_changes": [
            .en: "No configuration changes specified",
            .cn: "未指定配置更改",
        ],
        "config.updated": [
            .en: "✅ Configuration updated for provider: %@",
            .cn: "✅ 已更新服务商配置：%@",
        ],
        "config.reset": [
            .en: "✅ Configuration reset to defaults for provider: %@",
            .cn: "✅ 已重置服务商配置为默认值：%@",
        ],
        "config.file_location": [
            .en: "Config file: %@",
            .cn: "配置文件：%@",
        ],
        "config.key_configured": [
            .en: "Configured",
            .cn: "已配置",
        ],
        "config.key_not_configured": [
            .en: "Not configured",
            .cn: "未配置",
        ],
        "config.default_set": [
            .en: "✅ Default provider set to: %@",
            .cn: "✅ 已设置默认 Provider：%@",
        ],
        "config.default_provider": [
            .en: "Default provider",
            .cn: "默认 Provider",
        ],

        // ============ Edit 命令 ============
        "edit.input": [
            .en: "Input",
            .cn: "输入",
        ],
        "edit.output": [
            .en: "Output",
            .cn: "输出",
        ],

        // Cut 命令
        "edit.cut.title": [
            .en: "Background Removal",
            .cn: "背景移除",
        ],

        // Resize 命令
        "edit.resize.title": [
            .en: "Image Resize",
            .cn: "图像缩放",
        ],
        "edit.resize.original": [
            .en: "Original size",
            .cn: "原始尺寸",
        ],
        "edit.resize.target": [
            .en: "Target size",
            .cn: "目标尺寸",
        ],
        "edit.resize.target_width": [
            .en: "Target width",
            .cn: "目标宽度",
        ],
        "edit.resize.target_height": [
            .en: "Target height",
            .cn: "目标高度",
        ],
        "edit.resize.result": [
            .en: "Result size",
            .cn: "结果尺寸",
        ],

        // Crop 命令
        "edit.crop.title": [
            .en: "Image Crop",
            .cn: "图像裁剪",
        ],
        "edit.crop.original": [
            .en: "Original size",
            .cn: "原始尺寸",
        ],
        "edit.crop.region": [
            .en: "Crop region",
            .cn: "裁剪区域",
        ],
        "edit.crop.result": [
            .en: "Result size",
            .cn: "结果尺寸",
        ],

        // Enhance 命令
        "edit.enhance.title": [
            .en: "Auto Enhancement",
            .cn: "自动增强",
        ],
        "edit.enhance.redeye_disabled": [
            .en: "Red-eye correction: disabled",
            .cn: "红眼校正：已禁用",
        ],
        "edit.enhance.no_filters": [
            .en: "No enhancement filters needed",
            .cn: "无需增强滤镜",
        ],
        "edit.enhance.filters_applied": [
            .en: "Filters to be applied",
            .cn: "将应用的滤镜",
        ],

        // Scan 命令（Task 6.3）
        "edit.scan.title": [
            .en: "Document Scan",
            .cn: "文档扫描",
        ],
        "edit.scan.detecting": [
            .en: "Detecting document edges...",
            .cn: "正在检测文档边界...",
        ],
        "edit.scan.found": [
            .en: "Document detected (confidence: %@)",
            .cn: "检测到文档（置信度：%@）",
        ],
        "edit.scan.correcting": [
            .en: "Applying perspective correction...",
            .cn: "正在应用透视校正...",
        ],
        "edit.scan.result_size": [
            .en: "Result size: %d × %d",
            .cn: "结果尺寸：%d × %d",
        ],

        // Straighten 命令（Task 6.3）
        "edit.straighten.title": [
            .en: "Image Straighten",
            .cn: "图像拉直",
        ],
        "edit.straighten.detecting": [
            .en: "Detecting horizon angle...",
            .cn: "正在检测地平线角度...",
        ],
        "edit.straighten.no_horizon": [
            .en: "No horizon detected, skipping rotation",
            .cn: "未检测到地平线，跳过旋转",
        ],
        "edit.straighten.detected": [
            .en: "Detected tilt: %@°",
            .cn: "检测到倾斜：%@°",
        ],
        "edit.straighten.already_level": [
            .en: "Image is already level",
            .cn: "图像已水平",
        ],
        "edit.straighten.manual": [
            .en: "Manual angle: %@°",
            .cn: "手动角度：%@°",
        ],
        "edit.straighten.rotating": [
            .en: "Rotating image...",
            .cn: "正在旋转图像...",
        ],
        "edit.straighten.rotated": [
            .en: "Rotated by %@°",
            .cn: "旋转了 %@°",
        ],

        // Trace 命令（Task 6.3）
        "edit.trace.title": [
            .en: "Vector Trace",
            .cn: "矢量描摹",
        ],
        "edit.trace.style": [
            .en: "Style",
            .cn: "样式",
        ],
        "edit.trace.intensity": [
            .en: "Intensity",
            .cn: "强度",
        ],
        "edit.trace.radius": [
            .en: "Radius",
            .cn: "半径",
        ],

        // Defringe 命令（Task 6.3）
        "edit.defringe.title": [
            .en: "Defringe",
            .cn: "去紫边",
        ],
        "edit.defringe.amount": [
            .en: "Amount",
            .cn: "强度",
        ],

        // Format 命令（Task 6.3）
        "edit.fmt.title": [
            .en: "Format Conversion",
            .cn: "格式转换",
        ],
        "edit.fmt.target_format": [
            .en: "Target format",
            .cn: "目标格式",
        ],
        "edit.fmt.quality": [
            .en: "Quality",
            .cn: "质量",
        ],
        "edit.fmt.converting": [
            .en: "Converting format...",
            .cn: "正在转换格式...",
        ],
        "edit.fmt.size_comparison": [
            .en: "Size: %@ → %@",
            .cn: "大小：%@ → %@",
        ],
        "edit.fmt.compressed": [
            .en: "Compressed by %@",
            .cn: "压缩了 %@",
        ],
        "edit.fmt.expanded": [
            .en: "Expanded by %@",
            .cn: "增大了 %@",
        ],

        // Thumb 命令（Task 6.3）
        "edit.thumb.title": [
            .en: "Thumbnail Generation",
            .cn: "生成缩略图",
        ],
        "edit.thumb.original_size": [
            .en: "Original size",
            .cn: "原始尺寸",
        ],
        "edit.thumb.target_size": [
            .en: "Target size",
            .cn: "目标尺寸",
        ],
        "edit.thumb.generating": [
            .en: "Generating thumbnail...",
            .cn: "正在生成缩略图...",
        ],
        "edit.thumb.result_size": [
            .en: "Result size",
            .cn: "结果尺寸",
        ],
        "edit.thumb.scale_factor": [
            .en: "Scale: %@",
            .cn: "缩放：%@",
        ],

        // ============ Filter 命令 ============
        "filter.blur.title": [
            .en: "Blur Effect",
            .cn: "模糊效果",
        ],
        "filter.blur.type": [
            .en: "Type",
            .cn: "类型",
        ],
        "filter.blur.radius": [
            .en: "Radius",
            .cn: "半径",
        ],
        "filter.blur.angle": [
            .en: "Angle",
            .cn: "角度",
        ],
        "filter.sharpen.title": [
            .en: "Sharpen",
            .cn: "锐化",
        ],
        "filter.sharpen.intensity": [
            .en: "Intensity",
            .cn: "强度",
        ],
        "filter.pixel.title": [
            .en: "Pixelate",
            .cn: "像素化",
        ],
        "filter.pixel.scale": [
            .en: "Scale",
            .cn: "比例",
        ],
        "filter.noise.title": [
            .en: "Noise Reduction",
            .cn: "降噪",
        ],
        "filter.noise.level": [
            .en: "Level",
            .cn: "级别",
        ],
        "filter.comic.title": [
            .en: "Comic Effect",
            .cn: "漫画效果",
        ],
        "filter.halftone.title": [
            .en: "Halftone",
            .cn: "半调网屏",
        ],
        "filter.halftone.center": [
            .en: "Center",
            .cn: "中心点",
        ],
        "filter.halftone.width": [
            .en: "Width",
            .cn: "宽度",
        ],
        "filter.sepia.title": [
            .en: "Sepia Tone",
            .cn: "怀旧色调",
        ],
        "filter.sepia.intensity": [
            .en: "Intensity",
            .cn: "强度",
        ],
        "filter.mono.title": [
            .en: "Monochrome",
            .cn: "黑白",
        ],
        "filter.chrome.title": [
            .en: "Chrome Effect",
            .cn: "铬黄效果",
        ],
        "filter.noir.title": [
            .en: "Film Noir",
            .cn: "黑色电影",
        ],
        "filter.instant.title": [
            .en: "Instant Photo",
            .cn: "即时照片",
        ],

        // ============ Adjust 命令 ============
        "adjust.color.title": [
            .en: "Color Adjustment",
            .cn: "颜色调整",
        ],
        "adjust.color.brightness": [
            .en: "Brightness",
            .cn: "亮度",
        ],
        "adjust.color.contrast": [
            .en: "Contrast",
            .cn: "对比度",
        ],
        "adjust.color.saturation": [
            .en: "Saturation",
            .cn: "饱和度",
        ],
        "adjust.exposure.title": [
            .en: "Exposure Adjustment",
            .cn: "曝光调整",
        ],
        "adjust.exposure.ev": [
            .en: "EV",
            .cn: "曝光值",
        ],
        "adjust.temperature.title": [
            .en: "Temperature Adjustment",
            .cn: "色温调整",
        ],
        "adjust.temperature.temp": [
            .en: "Temperature",
            .cn: "色温",
        ],
        "adjust.temperature.tint": [
            .en: "Tint",
            .cn: "色调",
        ],
        "adjust.vignette.title": [
            .en: "Vignette Effect",
            .cn: "暗角效果",
        ],
        "adjust.vignette.intensity": [
            .en: "Intensity",
            .cn: "强度",
        ],
        "adjust.vignette.radius": [
            .en: "Radius",
            .cn: "半径",
        ],
        "adjust.invert.title": [
            .en: "Invert Colors",
            .cn: "反转颜色",
        ],
        "adjust.posterize.title": [
            .en: "Posterize",
            .cn: "色调分离",
        ],
        "adjust.posterize.levels": [
            .en: "Levels",
            .cn: "级数",
        ],
        "adjust.threshold.title": [
            .en: "Threshold",
            .cn: "阈值",
        ],
        "adjust.threshold.value": [
            .en: "Value",
            .cn: "数值",
        ],
        "adjust.flip.title": [
            .en: "Flip Image",
            .cn: "翻转图像",
        ],
        "adjust.flip.direction": [
            .en: "Direction",
            .cn: "方向",
        ],
        "adjust.rotate.title": [
            .en: "Rotate Image",
            .cn: "旋转图像",
        ],
        "adjust.rotate.angle": [
            .en: "Angle",
            .cn: "角度",
        ],
    ]

    /// 获取本地化字符串
    static func get(_ key: String, args: [CVarArg] = []) -> String {
        let template = dict[key]?[Language.current] ?? key
        return args.isEmpty ? template : String(format: template, arguments: args)
    }

    /// 便捷方法：单参数
    static func get(_ key: String, _ arg: CVarArg) -> String {
        get(key, args: [arg])
    }

    /// 便捷方法：两个参数
    static func get(_ key: String, _ arg1: CVarArg, _ arg2: CVarArg) -> String {
        get(key, args: [arg1, arg2])
    }

    /// 便捷方法：三个参数
    static func get(_ key: String, _ arg1: CVarArg, _ arg2: CVarArg, _ arg3: CVarArg) -> String {
        get(key, args: [arg1, arg2, arg3])
    }
}
