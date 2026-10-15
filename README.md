# ubiquiti-assignment

Home assignment for a job application at Ubiquiti: a SwiftUI + Combine app listing Ubiquiti products from the public UIDB.

## How to run

Requires Xcode 26 with an iOS 26 simulator.

```sh
open "Ubiquiti Assignment.xcodeproj"   # then ⌘R
make run                               # or from the terminal: build, pick a simulator, launch
make test                              # unit tests on a local simulator
make help                              # all targets
```

`make run` can also build on one Mac and launch on another's simulators: `RUN_HOST=user@laptop make run`. `SIM="iPhone 17 Pro"` skips the picker.

## Assumptions and tradeoffs

_To be distilled from `docs/DECISIONS.md` before submission._

## Libraries used and why

_None so far. See `docs/DECISIONS.md`._
