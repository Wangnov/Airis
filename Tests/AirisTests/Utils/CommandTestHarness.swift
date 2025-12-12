import Foundation

enum CommandTestHarness {
    /// 返回测试资源目录下的图片 URL
    static func fixture(_ name: String) -> URL {
        TestResources.image("assets/\(name)")
    }

    /// 创建临时输出文件路径（不预创建文件）
    static func temporaryFile(ext: String) -> URL {
        let filename = "airis_cmd_test_\(UUID().uuidString).\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    /// 复制测试资源到临时目录并更换扩展名
    static func copyFixture(_ name: String, toExtension newExt: String) throws -> URL {
        let source = fixture(name)
        let dest = temporaryFile(ext: newExt)
        try FileManager.default.copyItem(at: source, to: dest)
        return dest
    }

    /// 删除文件（忽略错误）
    static func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
