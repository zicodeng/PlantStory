import Combine
import Foundation
import Security

@MainActor
final class OpenAIKeyStore: ObservableObject {
    @Published private(set) var hasAPIKey = false
    @Published private(set) var keyPreview: String?

    private let keychain = OpenAIKeychain()

    init() {
        refreshStatus()
    }

    func apiKey() -> String? {
        try? keychain.read()
    }

    func save(_ rawValue: String) throws {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 20 else {
            throw OpenAIKeyStoreError.invalidKey
        }

        try keychain.save(value)
        refreshStatus()
    }

    func delete() throws {
        try keychain.delete()
        refreshStatus()
    }

    private func refreshStatus() {
        let value = try? keychain.read()
        hasAPIKey = !(value?.isEmpty ?? true)
        keyPreview = value.map { "••••\($0.suffix(4))" }
    }
}

enum OpenAIKeyStoreError: LocalizedError {
    case invalidKey
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "Enter a valid OpenAI API key."
        case .keychain:
            return "PlantStory couldn’t securely update the API key."
        }
    }
}

private struct OpenAIKeychain {
    private let service = "com.zicodeng.PlantStory.openai"
    private let account = "user-api-key"

    func read() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw OpenAIKeyStoreError.keychain(status)
        }
        return value
    }

    func save(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw OpenAIKeyStoreError.invalidKey
        }

        SecItemDelete(baseQuery as CFDictionary)
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw OpenAIKeyStoreError.keychain(status)
        }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw OpenAIKeyStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
