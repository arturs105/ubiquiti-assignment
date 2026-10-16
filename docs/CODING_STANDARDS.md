# Coding standards

Swift 6 language mode (strict concurrency, errors not warnings), approachable concurrency on, default actor isolation is `MainActor`. iOS 26 and macOS 26 deployment targets. Formatting is enforced by `.swiftformat`; this file covers what a formatter cannot.

## Architecture

MVVM, one `View` + one `ViewModel` per screen under `Features/<Screen>/`.

- **ViewModel**: `final class`, `@MainActor`, `@Observable`. Exposes plain stored state and intent methods (`load()`, `select(category:)`). Holds no SwiftUI types. Not `ObservableObject`: Observation is the current API, and Combine lives in Core and in the pipelines the view model subscribes to, not in the state properties themselves.
- **View**: renders state, forwards intents. No networking, no business logic, no `Task {}` that does more than call an intent.
- **Core**: pure Swift. Services are protocols (`ProductRepository`, `ImageLoader`) with one production implementation and one in-memory fake for tests and previews. Inject through initialisers, never through singletons or `@Environment`. Every Core type and protocol is declared `nonisolated`: the target defaults to `MainActor`, and networking, decoding and caching must not be inferred as main-actor work that Combine then runs on background queues. Shared mutable state in Core (caches, stores) lives in an `actor` or behind a `Mutex`, never in a plain class. No `nonisolated(unsafe)`, no `@preconcurrency import`; if one is ever unavoidable, log it in `docs/DECISIONS.md`.

Screen state is a single enum, so the view switches over it exhaustively:

```swift
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(DisplayError)
}
```

## Combine

- Networking returns `AnyPublisher<Output, NetworkError>` built on `URLSession.dataTaskPublisher`; the failure type is the service's typed error, never `Error`.
- Inputs that drive derived state (selected tab, products) are fed into subjects (`CurrentValueSubject`) and derived state (the filtered list) is a `CombineLatest` pipeline that sinks into the view model's stored property, so filtering never calls a method by hand.
- Cache-then-network is one pipeline: `Merge` of the cache-read publisher and the network publisher, so the list renders from disk and refreshes behind it.
- The image loader shares in-flight publishers per URL (`share()` + a dictionary of pending publishers) so concurrent requests fetch once.
- Every subscription stores in `private var cancellables = Set<AnyCancellable>()`. Receive on `DispatchQueue.main` before touching published state.
- Reach for async/await only at the edges where Combine has no equivalent. The assignment grades Combine use.

## Caching

One `Cache` protocol with `value(for:)` / `store(_:for:)`. Products cache on disk (JSON file in Caches directory) with the in-memory copy in front. Images cache through `URLCache` configured once at app start. Cache reads happen before the network call so the list renders from cache instantly and refreshes behind it.

## Errors

- Services throw typed errors (`enum NetworkError: Error`). Never `fatalError`, never force unwrap, never `try!` outside tests.
- One `DisplayError` mapper turns any `Error` into `title` + `message` + optional retry. Views show only `DisplayError`.

## Swift

- `private` by default; widen only when something else needs it.
- `let` over `var`; `struct` over `class` unless identity or reference semantics are needed.
- One type per file, file named after the type. Extensions in `Type+Purpose.swift`.
- `// MARK: -` separates lifecycle, public API, private helpers.
- Models are `Codable`, `Hashable`, `Identifiable`, `Sendable`. Decoding uses `CodingKeys` only when JSON names differ from Swift names.
- Guard-return early. No nesting deeper than three levels.
- Magic numbers and strings live in `enum Constants` or design tokens, never inline twice.
- Comments explain *why*. Code explains *what*. Write doc comments (`///`) on every public type and protocol requirement.

## SwiftUI

- Every view has a `#Preview` for each state it can render, fed by the in-memory fake.
- Subviews over long bodies: a `body` longer than roughly 40 lines gets split.
- Design tokens (`UI/Theme/`) hold colours, spacing, type ramp pulled from Figma. Views use tokens, never literal values.
- Accessibility: every image has a label or is `.accessibilityHidden(true)`; tappable rows have one accessibility element.
- Navigation through `NavigationStack` with a `Hashable` route value, not `NavigationLink(destination:)`.

## Tests

- Swift Testing (`import Testing`), one test file per ViewModel and per Core service.
- Test behaviour through the public API with fakes; no mocking frameworks.
- A bug fix lands with the test that would have caught it.

## Git

- Small commits, one concern each, gitmoji prefix as in history.
- Never commit secrets, `.DS_Store`, `xcuserdata`, or `.claude/settings.local.json`.
