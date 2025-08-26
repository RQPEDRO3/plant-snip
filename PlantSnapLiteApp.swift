import SwiftUI

/// The main entry point for the PlantSnapLite application.
///
/// The app uses a simple authentication flow: if an API key has been saved in
/// the Keychain, the app shows the IdentifyView for capturing or selecting a
/// photo; otherwise it presents a LoginView for entering the API key. The
/// AuthViewModel observes the Keychain state and publishes authentication
/// changes to update the UI accordingly.
@main
struct PlantSnapLiteApp: App {
    /// A shared view model that manages the API key and authentication state.
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                // When authenticated, present the plant identification flow.
                IdentifyView()
                    .environmentObject(authViewModel)
            } else {
                // Otherwise prompt the user to enter their OpenAI API key.
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
