# Ubiquiti Home Assignment

SwiftUI app listing Ubiquiti products from the public UIDB.

## How to run

Requires Xcode 26 with an iOS 26 simulator.

### Option A
Open `Ubiquiti Assignment.xcodeproj` and run the app using XCode

### Option B
```sh
make run
```

#### Offloading CPU-intensive work to a remote computer.
The build system also supports a two-computer workflow over SSH, where a more powerful remote computer is used for CPU-intensive operations such as building, running tests or having multiple agents work in parallel.

This is achieved by setting a `RUN_HOST` variable.

```sh
export RUN_HOST="user@computer"
make run
```
❗ Note that this sort of workflow expects the run command to be executed on the remote computer and RUN_HOST is the computer where the app will be launched.

## Assumptions and tradeoffs

- Dark mode isn't supported since there are no desings for it. [ColorTokensKit](https://github.com/metasidd/ColorTokensKit-Swift) was considered for calculating dark mode colors, but that's probably an overkill for a home assignment.
- On a real project [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) library would probably be used to simplify dependency injection and avoid passing dependencies through view model hierarchies, but for a such a small project the view model tree isn't very deep, so no need for a dependency library.
- The assignment document names `line` as the filter field but never says which lines make a tab in the UI, and the feed has no category field of its own: beyond `line` and `deviceType`, its keys are identifiers, images, compliance data and setup flags. So the tabs are rules over those two fields.
  - **Cameras** is every product whose `deviceType` is `camera`.
  - **IoT** is the Access, Connect, LED and mFi lines in full, plus Protect's sensors, lights, locks, chimes and alarms; UniFi Talk is left out because its products are desk phones.

Both are judgment calls, recorded with the alternatives in `docs/DECISIONS.md` (2026-10-15 and 2026-10-19), and each is a short list in `ProductCategory` so a different reading is a one-line change.

## Libraries used and why

- [Kingfisher](https://github.com/onevcat/Kingfisher) loads and caches product images. Images are cached in memory and on disk.
- Formatting is enforced by [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) 0.63.1 or newer, configured in `.swiftformat`:

### LLM skills and plugins
- [Swift LSP](https://claude.com/marketplace/plugins/swift-lsp) Decreases LLM token usage by exposing compiler-verified facts about symbols, types and call sites, so that LLMs don't have rely on text lookup as much.
- [SwiftUI Pro](https://github.com/twostraws/swiftui-agent-skill) Is used to write better SwiftUI
- [Swift Testing Pro](https://github.com/twostraws/Swift-Testing-Agent-Skill) Is used to write better tests
- [Matt Pocock Skills](https://github.com/mattpocock/skills) Were used to drive the LLM development flow. Mainly the `/grill-with-docs`, `/to-spec` and the `/implement` skills were used
