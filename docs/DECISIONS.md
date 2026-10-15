# Decision log

Append-only. Each entry: date, decision, why, what it costs. The README tradeoffs section is distilled from here at submission time.

## 2026-10-15 Deployment target lowered from 27.0 to 26.0

Xcode's template set iOS/macOS 27.0. This machine runs macOS 26.5 with iOS 26.5 simulators, and a reviewer is unlikely to have a newer setup. 26.0 keeps current APIs without excluding reviewers.

## 2026-10-15 No third-party libraries

The assignment asks to justify every library. `URLSession` + Combine cover networking, `URLCache` + a JSON file cover caching, `AsyncImage` or a small Combine image loader covers images. Fewer dependencies is a stronger signal than a familiar package. Cost: a hand-rolled image cache instead of Kingfisher/Nuke.

## 2026-10-15 Category mapping (OPEN)

The PDF promises a `line` mapping but does not include one. Proposed: **Cameras** = `line.id == "unifi-protect"`; **IoT** = `unifi-connect`, `unifi-access`, `unifi-led`, `unifi-talk`, `mfi`; **All** = everything. Confirm against the Figma file and the assignment email before implementing.

## 2026-10-15 MVVM with Combine, no `@Observable`

`@Observable` would be the modern default, but Combine is a stated requirement and reviewers need to see it used for state. `ObservableObject` + `@Published` + Combine pipelines makes that visible without being contrived.

## 2026-10-15 Build tooling: Makefile plus one shell script for running on simulators

`make` stays the single entry point. `build` and `test` are plain `xcodebuild` calls. `run` delegates to `scripts/run.sh`, because an interactive simulator picker and an ssh hop are not expressible in Make: the script builds for the generic simulator destination on the current machine, optionally rsyncs the `.app` to another Mac (`RUN_HOST=user@host`), then lets you pick one or more simulators with arrow keys, or skips the picker with `SIM=<name or UDID>`. This supports developing on a headless build host while watching the app on a laptop. Cost: ~120 lines of bash, a Python one-liner for parsing `simctl` JSON, and a dependency on Homebrew rsync 3 when running remotely.

## 2026-10-15 Swift 6 language mode

The scaffold was generated in Swift 5 mode with approachable concurrency and `MainActor` default isolation already on, so the only real delta is strict concurrency checking as errors. Switching now, with two placeholder files, costs one build setting; switching later would be a noisy "fix concurrency errors" commit. It also makes the compiler enforce what the standards already promise (`@MainActor` view models, `Sendable` models). Cost: Core must be explicitly `nonisolated` and shared caches need an `actor` or lock. Combine's operators are not concurrency-annotated, so strict checking guards the boundaries of a pipeline, not the inside: the compiler cannot prove a `receive(on: DispatchQueue.main)` precedes a `sink` that touches published state. That stays a standards rule, not a compiler guarantee.
