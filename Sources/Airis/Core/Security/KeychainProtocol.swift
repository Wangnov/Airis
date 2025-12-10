import Foundation
import Security

/// Keychain 底层操作协议（用于依赖注入和测试 Mock）
protocol KeychainOperations {
    /// 更新 Keychain 项目
    func itemUpdate(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus

    /// 添加 Keychain 项目
    func itemAdd(attributes: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

    /// 复制匹配的 Keychain 项目
    func itemCopyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

    /// 删除 Keychain 项目
    func itemDelete(query: CFDictionary) -> OSStatus

    /// 将字符串转换为 Data
    func stringToData(_ string: String) -> Data?

    /// 将 Data 转换为字符串
    func dataToString(_ data: Data) -> String?
}

/// Keychain 默认实现（调用真实的 Security framework API）
struct DefaultKeychainOperations: KeychainOperations, Sendable {
    func itemUpdate(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus {
        SecItemUpdate(query, attributesToUpdate)
    }

    func itemAdd(attributes: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemAdd(attributes, result)
    }

    func itemCopyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemCopyMatching(query, result)
    }

    func itemDelete(query: CFDictionary) -> OSStatus {
        SecItemDelete(query)
    }

    func stringToData(_ string: String) -> Data? {
        string.data(using: .utf8)
    }

    func dataToString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}
