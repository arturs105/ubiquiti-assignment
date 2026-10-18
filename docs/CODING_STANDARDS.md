# Coding standards

Swift 6 language mode (strict concurrency, errors not warnings), approachable concurrency on, default actor isolation is `MainActor`. iOS 26 and macOS 26 deployment targets. Formatting is enforced by `.swiftformat`; this file covers what a formatter cannot.

## Architecture

MVVM, one `View` + one `ViewModel` per screen under `Features/<Screen>/`.

- **ViewModel**: `final class`, `@MainActor`, `@Observable`. Exposes plain stored state and intent methods (`load()`, `select(category:)`). Holds no SwiftUI types. Not `ObservableObject`: Observation is the current API, and Combine lives in the derived-state pipelines inside the view model, not in the state properties themselves. Core is called with `await` from a `Task` an intent method starts.
- **View**: renders state, forwards intents. No networking, no business logic, no `Task {}` that does more than call an intent.
- **Core**: pure Swift. Services are protocols (`FeedRepository`, `ImageLoader`) with one production implementation and one in-memory fake for tests and previews. Inject through initialisers, never through singletons or `@Environment`. Every Core type and protocol is declared `nonisolated`: the target defaults to `MainActor`, and networking, decoding and caching must run off the main actor. An `actor` is its own isolation and takes no modifier. Shared mutable state in Core (caches, stores) lives in an `actor`; `Mutex` is for `Sendable` wrappers that must stay synchronous, never a plain class. No `nonisolated(unsafe)`, no `@preconcurrency import`; if one is ever unavoidable, log it in `docs/DECISIONS.md`.

Screen state is a single enum, so the view switches over it exhaustively. No `idle`: the pipeline emits `loading` as soon as it is wired. `failed` carries `FeedError` until #15 lands `DisplayError` (see `docs/DECISIONS.md`, 2026-10-18).

```swift
enum LoadState<Value: Equatable>: Equatable {
    case loading
    case loaded(Value)
    case empty
    case failed(FeedError)
}
```

## Concurrency and Combine

Core is async/await; Combine is the view model's derived-state pipeline. The assignment grades Combine use, so the pipeline is written out as publishers, never as a method the view model calls by hand. `docs/DECISIONS.md` (2026-10-17) records why Combine left Core.

- Services expose `async` methods with typed throws (`throws(NetworkError)`, `throws(FeedError)`); the failure type is the service's typed error, never `any Error`. Networking is `URLSession.data(for:)`; an untyped error it throws is wrapped into the typed one, never rethrown as is.
- `CachedFeedRepository` is an `actor` whose only state beyond its two files is the list of `feed()` subscribers. The files are touched only by methods that run on it, so reads and writes never interleave and no lock exists. The only suspension point inside a method is the network call.
- The repository is one read and one write. The read is `feed()`, an `AsyncStream<Feed?>` whose first element is the cached feed (or `nil` when there is none, so the screen shows loading) and whose later elements are every feed any refresh saves. The write is `refresh()`, the fetch keyed by the validators saved beside the cached feed. Cache-then-network is therefore: subscribe to `feed()` in `load()` with a task that iterates it and sends each element into the products subject, then call `refresh()`; the list renders from disk and refreshes behind it. The repository holds no feed between calls; the view model keeps the feed on screen and turns a refresh outcome (`unchanged`, `updated`, or an error) into its own state, stale included. The fetch never starts before the cache read, and a fail-fast offline error cannot outrun it (see `docs/DECISIONS.md`).
- Anything that wants the app to show a new feed (pull to refresh, a second screen, a background refresh, a push notification) only calls `refresh()`; every subscriber hears the result. Streams carry no failures: those stay typed on `refresh()`. Services expose `AsyncStream`, never a Combine publisher, because Combine's subjects are not `Sendable` and an actor cannot hand one out without unchecked code (see `docs/DECISIONS.md`, 2026-10-17 and 2026-10-18).
- The image loader is an actor that shares the in-flight `Task` per URL so concurrent requests fetch once.
- View models start a `Task` in the intent method (`load()`, `refresh()`), await Core, and assign state. The task is stored so a repeated intent cancels the one in flight, except a refresh, which joins the one in flight (see `docs/DECISIONS.md`, 2026-10-18). The view model is `@MainActor`, so the assignment needs no hop.
- Inputs that drive derived state (selected tab, products) are fed into subjects (`CurrentValueSubject`), the products subject from the `feed()` stream, and derived state (the filtered list) is a `CombineLatest` pipeline that sinks into the view model's stored property. Every subscription stores in `private var cancellables = Set<AnyCancellable>()`. The pipeline runs on the main actor with the view model, so no `receive(on:)` is needed.
- Nothing in Core imports Combine.

## Caching

The feed repository owns its cache: raw feed bytes and validators as two files in the Caches directory, read by one `actor` on every call and never held in memory; a new `feed()` subscription opens with what is on disk, and hears of a downloaded feed only after its write is attempted. No separate store protocol (see `docs/DECISIONS.md`). Images cache through `URLCache` configured once at app start. The cache read happens before the network call so the list renders from cache instantly and refreshes behind it; the disk write happens before `refresh()` returns, on the actor, so a returned feed is also a saved one unless the write failed, which is logged and not surfaced.

## Errors

- Services throw typed errors (`enum NetworkError: Error`). Never `fatalError`, never force unwrap, never `try!` outside tests.
- One `DisplayError` mapper turns any `Error` into `title` + `message` + optional retry. Views show only `DisplayError` (from #15; until then `LoadState.failed` carries `FeedError`, see Architecture).

## Swift

- `private` by default; widen only when something else needs it.
- `let` over `var`; `struct` over `class` unless identity or reference semantics are needed.
- One type per file, file named after the type. Extensions in `Type+Purpose.swift`.
- `// MARK: -` separates lifecycle, public API, private helpers.
- Models are `Codable`, `Hashable`, `Identifiable`, `Sendable`. Decoding uses `CodingKeys` only when JSON names differ from Swift names.
- Guard-return early. No nesting deeper than three levels.
- Magic numbers and strings live in `enum Constants` or design tokens, never inline twice. Every `Constants` enum is `nonisolated`, in Core and in views alike: it holds only `Sendable` literals and reads the same from any isolation.
- Comments explain *why*. Code explains *what*. Write doc comments (`///`) on every public type and protocol requirement.

## SwiftUI

- Every view has a `#Preview` for each state it can render, fed by the in-memory fake.
- Subviews over long bodies: a `body` longer than roughly 40 lines gets split.
- Design tokens (`UI/Theme/`) hold colours, spacing, type ramp pulled from Figma. Views use tokens, never literal values.
- Accessibility: every image has a label or is `.accessibilityHidden(true)`; tappable rows have one accessibility element.
- Navigation through `NavigationStack` with a `Hashable` route value, not `NavigationLink(destination:)`.
- One `Dependencies` value, built once by the App, is the composition root. `RootView` takes it by initialiser, owns the `NavigationStack` path and the single `navigationDestination(for: Route.self)`, and is the only place screens are built. A screen owns its view model: the root (for the list) or the destination closure (for details) builds the view model from `Dependencies` and passes it to the view's initialiser, which keeps it as `@State`. `RootView.body` and the destination closure re-run on every path change, so the view model built there is allocated again on each render and `@State` keeps only the first: a view model's `init` only stores its dependencies and wires its Combine pipelines, and any `Task` or `feed()` subscription starts from `load()` in the view's `.task`. `Dependencies` never enters `Features/`, and a screen knows nothing about the stack it sits in, so it previews and reuses in isolation.

## Tests

- Swift Testing (`import Testing`), one test file per ViewModel and per Core service.
- Test behaviour through the public API with fakes; no mocking frameworks.
- A bug fix lands with the test that would have caught it.

## Git

- Small commits, one concern each, gitmoji prefix as in history.
- Never commit secrets, `.DS_Store`, `xcuserdata`, or `.claude/settings.local.json`.
