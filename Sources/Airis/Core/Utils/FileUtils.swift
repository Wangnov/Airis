import Foundation

/// 文件工具类
struct FileUtils {
    /// 支持的图像格式
    static let supportedImageFormats = ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp", "gif", "bmp"]

    /// 验证文件是否存在
    static func validateFile(at path: String) throws -> URL {
        let expanded = expandPath(path)
        let url = URL(fileURLWithPath: expanded)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AirisError.fileNotFound(expanded)
        }
        return url
    }

    /// 验证并获取文件扩展名
    static func getExtension(from path: String) -> String {
        URL(fileURLWithPath: path).pathExtension.lowercased()
    }

    /// 检查是否为支持的图像格式
    static func isSupportedImageFormat(_ path: String) -> Bool {
        let ext = getExtension(from: path)
        return supportedImageFormats.contains(ext)
    }

    /// 验证图像文件（存在性 + 格式）
    static func validateImageFile(at path: String) throws -> URL {
        let url = try validateFile(at: path)
        guard isSupportedImageFormat(path) else {
            throw AirisError.unsupportedFormat(getExtension(from: path))
        }
        return url
    }

    /// 生成输出文件路径（如果未指定）
    static func generateOutputPath(
        from inputPath: String,
        suffix: String = "_output",
        extension newExtension: String? = nil
    ) -> String {
        let url = URL(fileURLWithPath: inputPath)
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = newExtension ?? url.pathExtension

        return directory
            .appendingPathComponent("\(filename)\(suffix)")
            .appendingPathExtension(ext)
            .path
    }

    /// 确保输出目录存在
    static func ensureDirectory(for path: String) throws {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()

        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            } catch {
                throw AirisError.fileWriteError(directory.path, error)
            }
        }
    }

    /// 获取文件大小（格式化字符串）
    static func getFormattedFileSize(at path: String) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// 获取文件大小（字节数）
    static func getFileSize(at path: String) -> Int64? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return size
    }

    /// 展开波浪号路径
    static func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    /// 获取绝对路径
    static func absolutePath(_ path: String) -> String {
        let expanded = expandPath(path)
        if expanded.hasPrefix("/") {
            return expanded
        }
        return FileManager.default.currentDirectoryPath + "/" + expanded
    }
}
