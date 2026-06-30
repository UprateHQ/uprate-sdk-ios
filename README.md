<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="assets/logo.svg">
    <img alt="UprateHQ" src="assets/logo.svg" width="200">
  </picture>
</p>

<p align="center">
  <strong>UprateSDK for iOS</strong><br>
  Roadmap voting, in-app feedback, and review insights for your iOS app.
</p>

<p align="center">
  <a href="https://app.upratehq.com">Dashboard</a> &bull;
  <a href="https://upratehq.com">Website</a> &bull;
  <a href="#quick-start">Quick Start</a>
</p>

---

## Requirements

- iOS 16.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add UprateSDK to your project via Xcode:

1. Go to **File > Add Package Dependencies**
2. Enter the repository URL
3. Select the latest version

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/UprateHQ/uprate-sdk-ios.git", from: "0.1.1")
]
```

## Quick Start

### 1. Get Your API Key

Create a publishable API key in your [UprateHQ dashboard](https://app.upratehq.com). Navigate to your app's **Settings > SDK** to generate one.

### 2. Configure the SDK

Call `configure` once at app launch, before using any features:

```swift
import UprateSDK

UprateSDK.configure(apiKey: "uprt_pub_your_publishable_key")
```

### 3. Set User Context

After the user logs in, set their identity:

```swift
await UprateSDK.shared.setUserContext(
    userId: "user_123",
    email: "jane@example.com",
    name: "Jane"
)
```

Call `clearUserContext()` on logout.

### 4. Use Features

#### Roadmap

```swift
// Fetch roadmap items
let roadmap = try await UprateSDK.shared.roadmap.getItems()

// Vote on an item
let result = try await UprateSDK.shared.roadmap.vote(itemId: item.id)

// Submit a feature request
let request = try await UprateSDK.shared.roadmap.submitRequest(
    title: "Dark mode",
    description: "Please add dark mode support"
)
```

#### Feedback

```swift
// Submit feedback with optional rating
let result = try await UprateSDK.shared.feedback.submit(
    message: "Checkout is slow but the app looks great",
    rating: 4,
    metadata: ["screen": "checkout"]
)

// List user's submissions
let submissions = try await UprateSDK.shared.feedback.getMySubmissions()
```

#### Review Signals

Record when you show the App Store review prompt to enrich review data in your dashboard:

```swift
import StoreKit

SKStoreReviewController.requestReview(in: windowScene)
Task { _ = try? await UprateSDK.shared.reviews.recordPrompt() }
```

## Features

- **Roadmap & Voting** — Let users browse your roadmap and vote on features
- **In-App Feedback** — Collect feedback with optional ratings and device metadata
- **Review Signals** — Match App Store reviews to users for richer insights
- **Async/Await** — Modern Swift concurrency throughout
- **Swift 6 Strict Concurrency** — Zero data races, compile-time verified
- **Lightweight** — No dependencies, pure Foundation networking
- **Testable** — Protocol-based design with `RoadmapProviding`, `FeedbackProviding`, and `ReviewSignalProviding` for easy mocking
- **Privacy-Conscious** — No tracking, no advertising identifiers, no fingerprinting. Device metadata (model, OS version) is collected only with feedback and review signals, and can be disabled

## Testing

The SDK provides protocols for each feature module, making it easy to mock in your tests:

```swift
class MockRoadmap: RoadmapProviding {
    func getItems() async throws -> UprateRoadmapResponse { ... }
    func vote(itemId: String) async throws -> VoteResult { ... }
    // ...
}
```

## Privacy

The SDK includes an Apple Privacy Manifest (`PrivacyInfo.xcprivacy`).

- **No tracking** — no advertising identifiers (IDFA), no vendor identifiers, no fingerprinting
- **No required-reason APIs** — no UserDefaults, no file timestamps, no disk space APIs that require declarations
- **Device metadata** (model, OS version, locale, RAM, free disk) is collected with feedback submissions and review signals. Disable it per-feature with `feedback.collectDeviceMetadata = false`
- **User identity** (`userId`, `email`, `name`) is provided by your app — the SDK does not gather it independently

## License

UprateSDK is available under the MIT License. See [LICENSE](LICENSE) for details.
