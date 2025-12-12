import Foundation
import Security
@testable import Airis

/// Mock Keychain 操作 - 用于测试错误路径
final class MockKeychainOperations: KeychainOperations {
    // 控制模拟的错误场景（通过初始化参数设置）
    let shouldFailStringToData: Bool
    let shouldFailAdd: Bool
    let shouldFailUpdate: Bool
    let shouldFailDelete: Bool
    let addErrorCode: OSStatus
    let deleteErrorCode: OSStatus

    init(
        shouldFailStringToData: Bool = false,
        shouldFailAdd: Bool = false,
        shouldFailUpdate: Bool = false,
        shouldFailDelete: Bool = false,
        addErrorCode: OSStatus = errSecIO,
        deleteErrorCode: OSStatus = errSecIO
    ) {
        self.shouldFailStringToData = shouldFailStringToData
        self.shouldFailAdd = shouldFailAdd
        self.shouldFailUpdate = shouldFailUpdate
        self.shouldFailDelete = shouldFailDelete
        self.addErrorCode = addErrorCode
        self.deleteErrorCode = deleteErrorCode
    }

    func itemUpdate(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus {
        if shouldFailUpdate {
            return errSecIO  // 模拟更新失败
        }
        return errSecItemNotFound  // 默认返回不存在（触发 add 路径）
    }

    func itemAdd(attributes: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if shouldFailAdd {
            return addErrorCode
        }
        return errSecSuccess
    }

    func itemCopyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        errSecItemNotFound
    }

    func itemDelete(query: CFDictionary) -> OSStatus {
        if shouldFailDelete {
            return deleteErrorCode
        }
        return errSecSuccess
    }

    func stringToData(_ string: String) -> Data? {
        if shouldFailStringToData {
            return nil  // 模拟编码失败
        }
        return string.data(using: .utf8)
    }

    func dataToString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}
