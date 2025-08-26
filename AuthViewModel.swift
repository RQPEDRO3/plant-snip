import Foundation

/// A view model responsible for managing authentication and API key storage.
///
/// The AuthViewModel reads and writes an OpenAI API key from the system
/// Keychain. It publishes authentication state changes so the UI can
/// automatically react when a user logs in or out. The API key is stored
/// securely and never persisted to UserDefaults or source files.
final class AuthViewModel: ObservableObject {
    /// The saved OpenAI API key, if available.
    @Published var apiKey: String?
    /// Whether the user has saved a valid API key.
    @Published var isAuthenticated: Bool = false

    private let keychainHelper = KeychainHelper()

    /// Initializes the view model by reading any saved key from the Keychain.
    init() {
        self.apiKey = keychainHelper.read(service: "openai_api_key", account: "user")
        self.isAuthenticated = apiKey != nil
    }

    /// Saves an API key to the Keychain and updates authentication state.
    /// - Parameter key: The API key to store securely.
    func saveApiKey(_ key: String) {
        keychainHelper.save(key, service: "openai_api_key", account: "user")
        self.apiKey = key
        self.isAuthenticated = true
    }

    /// Deletes the stored API key and updates authentication state.
    func clearApiKey() {
        keychainHelper.delete(service: "openai_api_key", account: "user")
        self.apiKey = nil
        self.isAuthenticated = false
    }
}
