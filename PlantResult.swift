import Foundation

/// A model describing the structured result returned by the OpenAI API.
///
/// The app expects the API to return strict JSON containing these fields. When
/// the API is uncertain, the names are set to `unknown` and confidence is ≤ 0.3.
struct PlantResult: Decodable {
    let commonName: String
    let scientificName: String
    let confidence: Double
    let care: [String]
    let notes: String?
}
