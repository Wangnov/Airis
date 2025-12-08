import Foundation
import Security

/// Keychain 管理器 - 安全存储 API Key
/// 使用文件型 Keychain（CLI 工具推荐方式，无需 entitlements）
final class KeychainManager: Sendable {
    private let service = "live.airis.cli"

    /// 保存 API Key（使用 SecItemUpdate 优先策略）
    func saveAPIKey(_ key: String, for provider: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw AirisError.keychainError(errSecParam)
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        // 先尝试更新现有项
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // 不存在则添加新项
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            addQuery[kSecAttrSynchronizable] = false  // API Key 不应同步到 iCloud

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AirisError.keychainError(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw AirisError.keychainError(updateStatus)
        }
    }

    /// 获取 API Key
    func getAPIKey(for provider: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw AirisError.apiKeyNotFound(provider: provider)
        }

        return key
    }

    /// 删除 API Key
    func deleteAPIKey(for provider: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AirisError.keychainError(status)
        }
    }

    /// 检查 API Key 是否存在
    func hasAPIKey(for provider: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider,
            kSecReturnData: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
