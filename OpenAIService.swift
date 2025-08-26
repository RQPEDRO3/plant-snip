import Foundation
import UIKit

/// A lightweight service that performs the network request to OpenAI's chat completions API.
///
/// This struct builds the necessary JSON payload, encodes the image as a base64
/// data URI, attaches the provided system prompt and schema, and parses the
/// response into a `PlantResult` model. It includes minimal error handling for
/// demonstration purposes and could be extended with more robust retry logic.
struct OpenAIService {
    /// The API endpoint for OpenAI chat completions.
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    /// Identifies a plant from an image using the provided API key.
    ///
    /// - Parameters:
    ///   - image: The photo of the plant.
    ///   - apiKey: An OpenAI API key beginning with `sk-`.
    /// - Returns: A `PlantResult` representing the model’s best guess.
    func identifyPlant(from image: UIImage, apiKey: String) async throws -> PlantResult {
        // Convert the image to JPEG data and downscale if needed. For brevity
        // this implementation does not perform resizing; real apps should
        // resize the image to around 1600px on the longest side.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badURL)
        }
        let base64String = imageData.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64String)"

        // System prompt instructing the model to return strict JSON.
        let systemPrompt = """
        You are a plant identifier. Given one photo, return ONLY strict JSON matching the provided schema. If uncertain, set both names to 'unknown' and confidence ≤ 0.3. Keep care to two short, non-duplicative tips. No extra text.
        """

        // The expected JSON schema. We include this in the user message to help the model
        // generate properly structured output.
        let schema = """
        { "type": "object", "properties": { "commonName": { "type": "string" }, "scientificName": { "type": "string" }, "confidence": { "type": "number", "minimum": 0, "maximum": 1 }, "care": { "type": "array", "items": { "type": "string" }, "maxItems": 2 }, "notes": { "type": "string" } }, "required": ["commonName", "scientificName", "confidence", "care"] }
        """

        // Build the chat messages: system and user. The user message includes the image
        // data and the schema as separate content pieces.
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": dataUri]],
                ["type": "text", "text": "Schema: \(schema)"]
            ]]
        ]

        // Assemble the request body.
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Perform the network call using async/await.
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard httpResponse.statusCode < 400 else {
            // In a real implementation we would handle specific status codes.
            throw URLError(.badServerResponse)
        }

        // The API response returns a top-level structure with an array of choices.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        struct APIResponse: Decodable {
            let choices: [Choice]
            struct Choice: Decodable {
                let message: Message
                struct Message: Decodable {
                    let content: String
                }
            }
        }

        let apiResponse = try decoder.decode(APIResponse.self, from: data)
        guard let content = apiResponse.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }
        let jsonData = Data(content.utf8)
        return try decoder.decode(PlantResult.self, from: jsonData)
    }
}
