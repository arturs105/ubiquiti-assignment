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

_More to be distilled from `docs/DECISIONS.md` before submission._

## Libraries used and why

[Swift LSP](https://claude.com/marketplace/plugins/swift-lsp) Decreases LLM token usage by offering compiler-verified facts about symbols, types and call sites, so that LLMs don't have rely on text lookup as much.
