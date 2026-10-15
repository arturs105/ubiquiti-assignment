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

## Assumptions and tradeoffs

_To be distilled from `docs/DECISIONS.md` before submission._

## Libraries used and why

[Swift LSP](https://claude.com/marketplace/plugins/swift-lsp) Decreases LLM token usage by offering compiler-verified facts about symbols, types and call sites, so that LLMs don't have rely on text lookup as much.
