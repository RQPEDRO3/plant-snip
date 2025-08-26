# PlantSnapLite

PlantSnapLite is a simple SwiftUI iOS app that identifies plants from photos using OpenAI's vision model (defaulting to `gpt-4o`). Capture or select a photo of a plant and receive its common name, scientific name, confidence score, and brief care tips.

## Features

* **SwiftUI interface** with a single identification flow.
* Secure **login screen**: paste your OpenAI API key and store it in Keychain.
* Take a photo with the camera or choose one from your photo library.
* Sends the image to OpenAI's vision model and displays a structured result.
* Built-in **Demo Mode** for offline demos without consuming tokens.

## Requirements

* Xcode 15 or later
* iOS 17 or later device
* An OpenAI API key

## Setup

1. Clone this repository:

   ```sh
   git clone https://github.com/yourusername/plant-snip.git
   ```

2. Open `PlantSnapLite.xcodeproj` in Xcode.
3. Update the bundle identifier to your own reverse-DNS string if necessary. The default is `com.ray.plantsnaplite`.
4. Create an OpenAI API key at <https://platform.openai.com/account/api-keys>.
5. Build and run the app on your device via Xcode.
6. On first launch, enter your API key in the login screen.

### Demo Mode

Use the **Demo Mode** toggle in the app's navigation bar to bypass the API call. The app will return a static sample result, which is useful for screenshots and demonstrations without using API credits.

## API Call Example

Below is an example `curl` request similar to what the app sends. Replace `BASE64_IMAGE` with your JPEG image encoded in base64 and `YOUR_API_KEY` with your OpenAI API key.

```sh
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "system", "content": "You are a plant identifier. Given one photo, return ONLY strict JSON matching the provided schema. If uncertain, set both names to 'unknown' and confidence ≤ 0.3. Keep care to two short, non-duplicative tips. No extra text."},
      {"role": "user", "content": [
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,BASE64_IMAGE"}},
        {"type": "text", "text": "Schema: { \"type\": \"object\", \"properties\": { \"commonName\": { \"type\": \"string\" }, \"scientificName\": { \"type\": \"string\" }, \"confidence\": { \"type\": \"number\", \"minimum\": 0, \"maximum\": 1 }, \"care\": { \"type\": \"array\", \"items\": { \"type\": \"string\" }, \"maxItems\": 2 }, \"notes\": { \"type\": \"string\" } }, \"required\": [\"commonName\", \"scientificName\", \"confidence\", \"care\"] }"}
      ]}
    ],
    "max_tokens": 500,
    "temperature": 0
  }'
```

## Troubleshooting

* If you see an authentication error, double-check that your API key is valid and saved correctly.
* If you hit rate limits (HTTP 429), wait a short while and try again. The app contains basic retry logic but extreme usage may still require manual backoff.

---

This project is provided without a license. You may clone, build and modify it for personal use but should not redistribute it as-is without permission.
