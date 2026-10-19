# Ubiquiti Home Assignment

SwiftUI + Combine app listing Ubiquiti products from the public UIDB.

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

### Tooling

Formatting is enforced by [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) 0.63.1 or newer, configured in `.swiftformat`:

```sh
brew install swiftformat
make format   # rewrite app and test sources in place
make lint     # dry run, exits non-zero on any diff
```

`make lint` fails with an install hint when SwiftFormat is missing. GitHub Actions runs `make lint`, `make build` and `make test` on every pull request and on every push to `main` (`.github/workflows/ci.yml`), so the check on a PR means the branch is formatted, builds and passes its tests.

## Assumptions and tradeoffs

- Dark mode isn't supported since there are no desings for it. [ColorTokensKit](https://github.com/metasidd/ColorTokensKit-Swift) was considered for calculating dark mode colors, but that's probably an overkill for a home assignment.
- On a real project i'd probably use [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) library to simplify dependency injection, but for a such a small project direct dependencies through initialisers work just fine.

- The assignment names `line` as the filter field but never says which lines make a tab, and the feed has no category field of its own: beyond `line` and `deviceType`, its keys are identifiers, images, compliance data and setup flags. So the tabs are rules over those two fields. **Cameras** is every product whose `deviceType` is `camera`; a first version took the whole UniFi Protect line, which put speakers, sensors, NVRs and a door lock under a tab labelled Cameras. **IoT** is the Access, Connect, LED and mFi lines in full, plus Protect's sensors, lights, locks, chimes and alarms; UniFi Talk is left out because its products are desk phones. Both are judgment calls, recorded with the alternatives in `docs/DECISIONS.md` (2026-10-15 and 2026-10-19), and each is a short list in `ProductCategory` so a different reading is a one-line change.

_More to be distilled from `docs/DECISIONS.md` before submission._

## Libraries used and why

[Kingfisher](https://github.com/onevcat/Kingfisher) loads and caches product images: one download per URL however many rows ask, a memory cache that empties on a memory warning, and a disk cache with expiry and a size cap. Wrapped by one Core type behind an `ImageLoader` protocol, so nothing else imports it. See `docs/DECISIONS.md`, 2026-10-18, for why a library over a hand-rolled actor.

[Swift LSP](https://claude.com/marketplace/plugins/swift-lsp) Decreases LLM token usage by offering compiler-verified facts about symbols, types and call sites, so that LLMs don't have rely on text lookup as much.
