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
    .package(url: "https://github.com/UprateHQ/uprate-sdk-ios.git", from: "0.1.2")
]
```

## Quick Start

### 1. Get Your SDK Key

In your [UprateHQ dashboard](https://app.upratehq.com), open **Apps**, find your app, and choose **SDK API Keys** to generate a publishable key. It starts with `uprt_pub_` — that is the one the SDK needs.

> **Heads up:** keys from **Settings > API keys** are for the REST API and won't work with the SDK. The secret key (`uprt_secret_`) from the SDK key pair belongs on your server, never in the app.

### 2. Configure the SDK

Call `configure` once at app launch, before using any features:

```swift
import UprateSDK

UprateSDK.configure(apiKey: "uprt_pub_your_publishable_key")
```

### 3. Set User Context

After the user logs in, set their identity:

```swift
try await UprateSDK.shared.setUserContext(
    userId: "user_123",
    email: "jane@example.com",
    name: "Jane",
    userToken: tokenFromYourServer
)
```

`userToken` is optional. Your server signs the user ID with HMAC-SHA256 and returns the hex token to your app. Keep the signing secret on your server. See [Verify users](https://upratehq.com/docs/sdk#verify-users). When set, the SDK sends the token as `X-SDK-User-Token` on every request.

Call `clearUserContext()` on logout to clear the identity and token.

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

#### Replies in your app

Fetch unread replies when your app becomes active, display them, then mark them as read. The SDK adds no lifecycle observers, timers, persistence, or UI. For example, in SwiftUI:

```swift
import SwiftUI
import UprateSDK

struct ReplyInbox: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var replies: [FeedbackReply] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage { Text(errorMessage) }
            ForEach(replies) { reply in Text(reply.body) }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            do {
                errorMessage = nil
                replies = try await UprateSDK.shared.feedback.getUnreadReplies()
                try await UprateSDK.shared.feedback.markRead(replies)
            } catch UprateError.userContextChanged {
                replies = []
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Give each signed-in user a fresh inbox, so nobody sees the previous user's replies.
ReplyInbox().id(currentUser.id)
```

Each `FeedbackSubmission` also includes `replies`, an empty array when an older server omits them. Calling `markRead([])` sends no request. If the user changes while `getMySubmissions()`, `getUnreadReplies()` or `markRead` is in flight, the SDK drops the response and throws `UprateError.userContextChanged`, so one person's feedback and replies never reach the next one.

If the server requires a user token or rejects it, the SDK throws `UprateError.userTokenRejected(message:)` with the server's message. Other 401 responses still throw `UprateError.invalidApiKey(message:)`.

#### Push notifications

Uprate sends a notification when a feedback reply arrives, without the reply text. Upload your APNs `.p8` key, Key ID, and Team ID on your app's SDK page under **Push**. Apps made for kids can't use push; `registerPushToken` throws `UprateError.featureNotEnabled` for them.

Your app handles notification permission, APNs registration, and notification taps. iOS often hands you the device token before anyone has signed in, so keep it and register it both when it arrives and right after `setUserContext`:

```swift
var deviceToken: Data?

func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
    deviceToken = token
    Task { await registerForReplyPushes() }
}

// Also call this right after setUserContext.
func registerForReplyPushes() async {
    guard let deviceToken else { return }
    do {
        try await UprateSDK.shared.feedback.registerPushToken(deviceToken)
    } catch UprateError.userContextNotSet {
        // Nobody is signed in yet; your sign-in code calls this again after setUserContext.
    } catch {
        print("Uprate push registration failed: \(error)")
    }
}
```

On logout, unregister the device before clearing the user context, and clear it even when unregistering fails (for example offline). Until the device is unregistered or someone else registers it, it can still get the previous person's reply notifications (they never carry the reply text). If unregistering fails, keep that person's user ID, user token and the device token, and on the next start set that user context again, unregister, then clear it:

```swift
if let deviceToken {
    try? await UprateSDK.shared.feedback.unregisterPushToken(deviceToken)
}
try await UprateSDK.shared.clearUserContext()
```

In your notification tap handler, use `replyId(fromPush:)` to recognize an Uprate reply push, then show the unread replies and mark them read:

```swift
if UprateFeedback.replyId(fromPush: userInfo) != nil {
    let replies = try await UprateSDK.shared.feedback.getUnreadReplies()
    // Show the replies, then:
    try await UprateSDK.shared.feedback.markRead(replies)
}
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
