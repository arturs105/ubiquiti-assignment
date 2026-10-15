# Decision log

Append-only. Each entry: date, decision, why, what it costs. The README tradeoffs section is distilled from here at submission time.

## 2026-10-15 Category mapping (OPEN)

The PDF promises a `line` mapping but does not include one. Proposed: **Cameras** = `line.id == "unifi-protect"`; **IoT** = `unifi-connect`, `unifi-access`, `unifi-led`, `unifi-talk`, `mfi`; **All** = everything. Confirm against the Figma file and the assignment email before implementing.

## 2026-10-15 Caching: store the raw JSON on disk, not SwiftData

Two options were compared. **A:** decode the feed into SwiftData `@Model` objects, populate the store on first launch, serve later launches from the store and upsert from a background fetch. **B:** keep the `Codable` structs as the only model layer, write the raw JSON to disk with a fingerprint next to it, decode the cached file on launch, fetch in the background and replace file and UI only when the fingerprint differs.

Chosen: **B**.

Why:

- The spec asks for "caching (in-memory or disk)" and grades Combine, states and tradeoffs, not persistence depth. One ~700-device blob decodes in milliseconds; a full re-decode on change is not a performance concern.
- One model layer. SwiftData needs a `Codable` DTO plus `@Model` classes plus mapping for nested optional structures (`unifi`, `uisp`, `power`, `compliance`), then a diff-and-delete pass so removed devices do not linger.
- Swift 6 strict concurrency. `@Model` objects are non-`Sendable` references, so crossing from a `ModelActor` to a `@MainActor` view model means passing identifiers and refetching, or projecting to value structs anyway. Value-type models plus a small `actor` store fit without friction.
- Combine stays visible. SwiftData's reactive surface is `@Query` in views, which bypasses the view model. With B, the pipeline is the cache design: cached publisher merged with network publisher, deduplicated on fingerprint.
- Offline launch works from the file alone, so the error state becomes "cached data plus a stale indicator" rather than an empty screen.

Fingerprint: compare the feed's top-level `version` string first; fall back to a content hash only if versions match but bytes differ. Try conditional requests (`If-None-Match` / `If-Modified-Since`) before downloading; if the server honours them, an unchanged feed costs one 304.

Costs: whole-file replacement instead of row-level upserts, so the UI receives a full array swap (fine with `id`-keyed `ForEach` at this size). Filtering stays in memory rather than in predicates. The file lifecycle (atomic temp-file-and-rename write, corrupt-file recovery, schema change between app versions) is ours to handle and test. A reviewer looking for persistence-framework experience will not see it.

## 2026-10-15 `@Observable` view models; Combine for data flow

View models use `@Observable`, not `ObservableObject` + `@Published`. On an iOS 26 target `ObservableObject` is the legacy API and invalidates the whole view on any change. The assignment lists Combine as a bare bullet in a stack list (Swift, SwiftUI, Combine), which reads as "Apple's reactive stack, not RxSwift" rather than "publish view state through Combine". Combine therefore owns the data flow where it earns its place: `dataTaskPublisher` + `decode` + typed errors, the cache-then-network `Merge` described in the caching entry, an image loader that shares in-flight publishers per URL, and a `CombineLatest` filtering pipeline fed by subjects that sinks into view state. Cost: filter inputs exist as both a stored property and a subject, and a reviewer who expected `@Published` state has to read Core to find the Combine. The README tradeoffs section states this reading explicitly.
