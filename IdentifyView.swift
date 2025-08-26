import SwiftUI
import PhotosUI

/// The main screen for capturing/selecting a photo and displaying results.
///
/// Users can either take a new photo with the camera or pick one from their
/// library. Once a photo is selected, tapping "Identify Plant" sends the
/// image to the OpenAI API. The results appear below the button and include
/// the common name, scientific name, confidence score, and two care tips.
struct IdentifyView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = IdentifyViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Display the selected image if available.
                if let uiImage = viewModel.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }
                // Photo picker button to select or capture an image.
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Select or Take Photo", systemImage: "photo")
                        .font(.headline)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await viewModel.setImage(uiImage)
                        }
                    }
                }

                // Identify button and loading state.
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Button(action: identifyTapped) {
                        Text("Identify Plant")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.image == nil)
                }

                // Display the result if present.
                if let result = viewModel.result {
                    ResultView(result: result)
                        .padding(.top)
                }

                Spacer()
            }
            .navigationTitle("PlantSnapLite")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        authViewModel.clearApiKey()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle(isOn: $viewModel.demoMode) {
                        Text("Demo Mode")
                    }
                    .toggleStyle(.switch)
                }
            }
            .padding()
        }
    }

    /// Starts the plant identification process.
    private func identifyTapped() {
        guard let image = viewModel.image else { return }
        Task {
            if let apiKey = authViewModel.apiKey {
                await viewModel.identifyPlant(image: image, apiKey: apiKey)
            }
        }
    }
}

/// A subview that renders the plant identification result in a structured manner.
private struct ResultView: View {
    let result: PlantResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Common Name: \(result.commonName)")
                .font(.headline)
            Text("Scientific Name: \(result.scientificName)")
                .font(.subheadline)
            Text(String(format: "Confidence: %.2f", result.confidence))
                .font(.subheadline)
            Text("Care Tips:")
                .font(.headline)
            ForEach(result.care, id: \.self) { tip in
                Text("• \(tip)")
            }
            if let notes = result.notes, !notes.isEmpty {
                Text("Notes: \(notes)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
    }
}

struct IdentifyView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyView()
            .environmentObject(AuthViewModel())
    }
}
