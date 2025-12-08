import Foundation

/// 双语字符串表
struct Strings: Sendable {
    private static let dict: [String: [Language: String]] = [
        // ============ 通用错误 ============
        "error.file_not_found": [
            .en: "File not found: %@",
            .cn: "文件未找到：%@"
        ],
        "error.unsupported_format": [
            .en: "Unsupported format: %@",
            .cn: "不支持的格式：%@"
        ],
        "error.invalid_path": [
            .en: "Invalid path: %@",
            .cn: "无效路径：%@"
        ],
        "error.unknown": [
            .en: "Unknown error occurred",
            .cn: "发生未知错误"
        ],
        "error.file_read": [
            .en: "Failed to read file: %@",
            .cn: "读取文件失败：%@"
        ],
        "error.file_write": [
            .en: "Failed to write file: %@",
            .cn: "写入文件失败：%@"
        ],

        // ============ API Key 相关 ============
        "error.api_key_not_found": [
            .en: "API key not found for provider: %@",
            .cn: "未找到服务商的 API Key：%@"
        ],
        "error.api_key_recovery": [
            .en: "Run 'airis gen config set-key --provider %@' to configure",
            .cn: "运行 'airis gen config set-key --provider %@' 进行配置"
        ],
        "error.network": [
            .en: "Network error: %@",
            .cn: "网络错误：%@"
        ],
        "error.invalid_response": [
            .en: "Invalid response from server",
            .cn: "服务器返回无效响应"
        ],

        // ============ Vision 相关 ============
        "error.vision_failed": [
            .en: "Vision request failed: %@",
            .cn: "Vision 请求失败：%@"
        ],
        "error.no_results": [
            .en: "No results found",
            .cn: "未找到结果"
        ],

        // ============ 图像处理 ============
        "error.invalid_dimension": [
            .en: "Invalid dimension: %d×%d (max: %d)",
            .cn: "无效尺寸：%d×%d（最大：%d）"
        ],
        "error.image_decode": [
            .en: "Failed to decode image",
            .cn: "图像解码失败"
        ],
        "error.image_encode": [
            .en: "Failed to encode image",
            .cn: "图像编码失败"
        ],

        // ============ Keychain ============
        "error.keychain": [
            .en: "Keychain error: %d",
            .cn: "钥匙串错误：%d"
        ],

        // ============ 通用信息 ============
        "info.dimension": [
            .en: "Dimensions: %d × %d px",
            .cn: "尺寸：%d × %d 像素"
        ],
        "info.dpi": [
            .en: "DPI: %d",
            .cn: "DPI：%d"
        ],
        "info.file_size": [
            .en: "File size: %@",
            .cn: "文件大小：%@"
        ],
        "info.format": [
            .en: "Format: %@",
            .cn: "格式：%@"
        ],
        "info.success": [
            .en: "Success",
            .cn: "成功"
        ],
        "info.saved_to": [
            .en: "Saved to: %@",
            .cn: "已保存至：%@"
        ],
        "info.processing": [
            .en: "Processing...",
            .cn: "处理中..."
        ],

        // ============ SensitiveContentAnalysis ============
        "safe.disabled_hint": [
            .en: """
                ⚠️ Sensitive Content Analysis is disabled.

                This feature requires:
                1. Enable: System Settings > Privacy & Security > Sensitive Content Warning
                2. App must be signed with Apple Developer Program (paid) entitlement:
                   com.apple.developer.sensitivecontentanalysis.client

                Note: Free developer accounts cannot use this feature due to Apple's restrictions.
                """,
            .cn: """
                ⚠️ 敏感内容分析已禁用。

                此功能需要：
                1. 启用：系统设置 > 隐私与安全性 > 敏感内容警告
                2. 应用需要使用付费 Apple Developer Program 签名，并包含权限：
                   com.apple.developer.sensitivecontentanalysis.client

                注意：由于 Apple 的限制，免费开发者账户无法使用此功能。
                """
        ],
        "safe.is_sensitive": [
            .en: "Contains sensitive content: %@",
            .cn: "包含敏感内容：%@"
        ],
        "safe.is_safe": [
            .en: "No sensitive content detected",
            .cn: "未检测到敏感内容"
        ],

        // ============ Analyze 命令 ============
        "analyze.processing": [
            .en: "Analyzing image...",
            .cn: "正在分析图像..."
        ],
        "analyze.tag.found": [
            .en: "Found %d tag(s)",
            .cn: "检测到 %d 个标签"
        ],
        "analyze.tag.showing": [
            .en: "Found %d tag(s), showing top %d",
            .cn: "检测到 %d 个标签（显示前 %d 个）"
        ],
        "analyze.ocr.found": [
            .en: "Recognized %d text segment(s)",
            .cn: "识别到 %d 段文字"
        ],
        "analyze.score.result": [
            .en: "Aesthetic score: %.2f",
            .cn: "美学评分：%.2f"
        ],
        "analyze.score.excellent": [
            .en: "Excellent",
            .cn: "优秀"
        ],
        "analyze.score.good": [
            .en: "Good",
            .cn: "良好"
        ],
        "analyze.score.fair": [
            .en: "Fair",
            .cn: "一般"
        ],
        "analyze.score.poor": [
            .en: "Poor",
            .cn: "较差"
        ],
        "analyze.score.utility": [
            .en: "This is a utility image (screenshot, document, etc.)",
            .cn: "这是一张实用性图像（截图、文档等）"
        ],
        "analyze.score.unavailable": [
            .en: "⚠️ Aesthetic scoring requires macOS 15.0 or later",
            .cn: "⚠️ 美学评分需要 macOS 15.0 或更高版本"
        ],
        "info.color_model": [
            .en: "Color Model: %@",
            .cn: "色彩模型：%@"
        ],
        "info.bit_depth": [
            .en: "Bit Depth: %d",
            .cn: "位深度：%d"
        ],
        "info.has_alpha": [
            .en: "Has Alpha: %@",
            .cn: "包含透明通道：%@"
        ],
        "info.yes": [
            .en: "Yes",
            .cn: "是"
        ],
        "info.no": [
            .en: "No",
            .cn: "否"
        ],

        // ============ 命令帮助 ============
        "help.image_path": [
            .en: "Path to the image file",
            .cn: "图像文件路径"
        ],
        "help.output_path": [
            .en: "Output file path",
            .cn: "输出文件路径"
        ],
        "help.language": [
            .en: "Output language (en/cn)",
            .cn: "输出语言（en/cn）"
        ],

        // ============ Gen 命令 ============
        "gen.connecting": [
            .en: "🌐 Connecting to AI Image API...",
            .cn: "🌐 正在连接 AI 图像 API..."
        ],
        "gen.model": [
            .en: "🔑 Model: %@",
            .cn: "🔑 模型：%@"
        ],
        "gen.prompt": [
            .en: "📝 Prompt: %@",
            .cn: "📝 提示词：%@"
        ],
        "gen.references": [
            .en: "🖼️ Processing %d reference image(s)...",
            .cn: "🖼️ 处理 %d 张参考图片..."
        ],
        "gen.placeholder_warning": [
            .en: "⚠️ Gemini Image API integration coming soon!",
            .cn: "⚠️ Gemini 图像 API 集成即将推出！"
        ],
        "gen.api_key_configured": [
            .en: "💡 API key is configured. Ready for integration.",
            .cn: "💡 API Key 已配置，准备集成。"
        ],
        "config.key_saved": [
            .en: "✅ API key saved for provider: %@",
            .cn: "✅ 已保存服务商的 API Key：%@"
        ],
        "config.key_deleted": [
            .en: "✅ API key deleted for provider: %@",
            .cn: "✅ 已删除服务商的 API Key：%@"
        ],
        "config.key_display": [
            .en: "API key for %@: %@",
            .cn: "%@ 的 API Key：%@"
        ],
        "config.enter_key": [
            .en: "Enter API key for %@: ",
            .cn: "请输入 %@ 的 API Key："
        ],
        "config.no_changes": [
            .en: "No configuration changes specified",
            .cn: "未指定配置更改"
        ],
        "config.updated": [
            .en: "✅ Configuration updated for provider: %@",
            .cn: "✅ 已更新服务商配置：%@"
        ],
        "config.reset": [
            .en: "✅ Configuration reset to defaults for provider: %@",
            .cn: "✅ 已重置服务商配置为默认值：%@"
        ],
        "config.file_location": [
            .en: "Config file: %@",
            .cn: "配置文件：%@"
        ],
        "config.key_configured": [
            .en: "Configured",
            .cn: "已配置"
        ],
        "config.key_not_configured": [
            .en: "Not configured",
            .cn: "未配置"
        ]
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
