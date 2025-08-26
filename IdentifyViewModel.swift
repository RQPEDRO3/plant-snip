import Foundation
import UIKit

/// A view model that coordinates selecting images and calling the OpenAI API.
///
/// This class handles three responsibilities:
///  1. Managing the selected `UIImage` and resetting results when a new image
///     is chosen.
///  2. Sending the image to the OpenAI API via the `OpenAIService` and
///     decoding the JSON response into a `PlantResult` model.
///  3. Exposing a `demoMode` toggle that, when enabled, returns a static
///     result instead of calling the network. This helps with demos and
///     screenshots without spending tokens.
@MainActor
final class IdentifyViewModel: ObservableObject {
    /// The currently selected image.
    @Published var image: UIImage?
    /// The parsed result from the OpenAI API.
    @Published var result: PlantResult?
    /// Whether a network call is currently in progress.
    @Published var isLoading = false
    /// When set to true, the network call will be skipped and a static result returned.
    @Published var demoMode = false

    private let service = OpenAIService()

    /// Sets the currently selected image and clears any previous result.
    func setImage(_ newImage: UIImage) async {
        self.image = newImage
        self.result = nil
    }

    /// Sends the image to the OpenAI API and updates the result.
    /// - Parameters:
    ///   - image: The image to identify.
    ///   - apiKey: The user’s OpenAI API key.
    func identifyPlant(image: UIImage, apiKey: String) async {
        if demoMode {
            // In demo mode we return a static, plausible result.
            await withCheckedContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.result = PlantResult(
                        commonName: "Peace Lily",
                        scientificName: "Spathiphyllum",
                        confidence: 0.95,
                        care: ["Keep soil moist", "Bright indirect light"],
                        notes: nil
                    )
                    continuation.resume()
                }
            }
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let plant = try await service.identifyPlant(from: image, apiKey: apiKey)
            self.result = plant
        } catch {
            // If decoding fails or the API returns invalid data, we show unknown.
            print("Error identifying plant: \(error)")
            self.result = PlantResult(commonName: "unknown",
                                      scientificName: "unknown",
                                      confidence: 0.0,
                                      care: [],
                                      notes: "Unable to parse response")
        }
    }
}
