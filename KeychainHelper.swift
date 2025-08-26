import Foundation
import Security

/// A small helper around the iOS Keychain API.
///
/// This wrapper simplifies reading, saving and deleting data. The values are
/// stored as UTF‑8 encoded strings under a given service and account.
final class KeychainHelper {
    /// Saves a string into the Keychain.
    ///
    /// If a value already exists for the given service and account it will be
    /// overwritten.
    func save(_ value: String, service: String, account: String) {
        // Remove any existing item first to avoid duplicates.
        delete(service: service, account: account)

        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Reads a string from the Keychain.
    /// - Parameters:
    ///   - service: The service under which the value was saved.
    ///   - account: The account name used when saving.
    /// - Returns: The stored string, if any.
    func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Deletes a value from the Keychain.
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
