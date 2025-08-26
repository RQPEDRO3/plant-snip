import SwiftUI

/// A view that prompts the user to enter their OpenAI API key.
///
/// The API key is validated for a minimal pattern (starts with `sk-`) before
/// being saved into the Keychain via the AuthViewModel. Upon saving, the
/// app transitions to the plant identification screen.
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    /// Temporary storage for the entered API key.
    @State private var apiKey: String = ""
    /// Indicates whether an invalid key error should be shown.
    @State private var showError = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter OpenAI API Key")
                .font(.title2)
                .bold()
            SecureField("sk-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
            Button(action: validateAndSave) {
                Text("Validate and Save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            if showError {
                Text("Invalid API Key")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    /// Validates the API key and saves it if it looks correct.
    private func validateAndSave() {
        // Very basic validation: ensure it starts with "sk-" and has length > 20
        guard apiKey.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("sk-"),
              apiKey.count > 20 else {
            showError = true
            return
        }
        showError = false
        authViewModel.saveApiKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
