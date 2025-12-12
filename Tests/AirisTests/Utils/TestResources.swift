import Foundation

/// 测试资源访问器。
///
/// - 优先使用 SPM 的 Bundle.module（需在 Package.swift 中声明 resources）。
/// - 若未打包资源，则回退到基于 #filePath 的仓库路径定位。
enum TestResources {
    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()

    private static let fallbackBase: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Utils
            .deletingLastPathComponent() // AirisTests
            .appendingPathComponent("Resources")
    }()

    /// 返回 Resources 根目录下的资源 URL（relativePath 形如 "images/assets/xxx.png"）。
    static func url(_ relativePath: String) -> URL {
        #if SWIFT_PACKAGE
        if let base = bundle.resourceURL {
            let candidate = base
                .appendingPathComponent("Resources")
                .appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        #endif
        return fallbackBase.appendingPathComponent(relativePath)
    }

    /// 便捷方法：返回 images 目录下的资源 URL（relativePath 形如 "assets/xxx.png"、"vision/face.png"）。
    static func image(_ relativePath: String) -> URL {
        url("images/" + relativePath)
    }
}

#if !SWIFT_PACKAGE
private final class BundleToken {}
#endif
