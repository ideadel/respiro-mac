import CryptoKit
import Foundation
import Security

/// Offline license storage and validation. Active only on major version 2+.
enum LicenseService {
    private static let service = "com.personal.Respiro.license"
    private static let account = "licenseKey"

    /// 2.0+ builds require a valid key; 1.x grandfathered builds do not.
    static var requiresLicense: Bool {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return false
        }
        return version.compare("2.0", options: .numeric) != .orderedAscending
    }

    static var isLicensed: Bool {
        if !requiresLicense { return true }
        guard let key = storedKey else { return false }
        return validate(key)
    }

    static var storedKey: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func activate(_ rawKey: String) -> Bool {
        let key = normalize(rawKey)
        guard validate(key) else { return false }
        deleteStoredKey()
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func deactivate() {
        deleteStoredKey()
    }

    static func validate(_ rawKey: String) -> Bool {
        let key = normalize(rawKey)
        let parts = key.split(separator: "-").map(String.init)
        guard parts.count == 4, parts[0] == "RESPIRO" else { return false }
        guard parts[1].count == 4, parts[2].count == 4, parts[3].count == 2 else { return false }
        let charset = CharacterSet(charactersIn: "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ")
        for part in parts.dropFirst() where part.unicodeScalars.contains(where: { !charset.contains($0) }) {
            return false
        }
        let payload = parts[1] + parts[2]
        let expected = checksum(for: payload)
        return parts[3] == expected
    }

    private static func normalize(_ key: String) -> String {
        key.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "-")
    }

    private static func checksum(for payload: String) -> String {
        let digest = SHA256.hash(data: Data(payload.utf8))
        let byte = digest.withUnsafeBytes { $0.load(as: UInt8.self) }
        let alphabet = Array("0123456789ABCDEFGHJKLMNPQRSTUVWXYZ")
        let a = Int(byte >> 4) % alphabet.count
        let b = Int(byte & 0x0F) % alphabet.count
        return String(alphabet[a]) + String(alphabet[b])
    }

    private static func deleteStoredKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
