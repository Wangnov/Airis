import Foundation
import Security
@testable import Airis

/// 内存版 KeychainOperations，用于命令/配置类测试，避免依赖系统 Keychain。
final class InMemoryKeychainOperations: KeychainOperations {
    private var store: [String: Data] = [:]

    func itemUpdate(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus {
        let q = query as NSDictionary
        let attrs = attributesToUpdate as NSDictionary
        guard
            let account = q[kSecAttrAccount] as? String,
            store[account] != nil,
            let newData = attrs[kSecValueData] as? Data
        else {
            return errSecItemNotFound
        }
        store[account] = newData
        return errSecSuccess
    }

    func itemAdd(attributes: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        let attrs = attributes as NSDictionary
        guard
            let account = attrs[kSecAttrAccount] as? String,
            let data = attrs[kSecValueData] as? Data
        else {
            return errSecParam
        }
        store[account] = data
        return errSecSuccess
    }

    func itemCopyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        let q = query as NSDictionary
        guard let account = q[kSecAttrAccount] as? String,
              let data = store[account] else {
            return errSecItemNotFound
        }
        result?.pointee = data as CFData
        return errSecSuccess
    }

    func itemDelete(query: CFDictionary) -> OSStatus {
        let q = query as NSDictionary
        if let account = q[kSecAttrAccount] as? String {
            store.removeValue(forKey: account)
        }
        return errSecSuccess
    }

    func stringToData(_ string: String) -> Data? {
        string.data(using: .utf8)
    }

    func dataToString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}
