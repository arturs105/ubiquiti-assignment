# Ubiquiti Assignment

iOS take-home for a job application: a SwiftUI + Combine app listing Ubiquiti products from the public UIDB JSON. The reviewer reads the code, the git history and the README, so every change is part of the submission.

## Commands

`make` is the single entry point. Run `make help` for targets. Always finish a change with `make build`; run `make test` when a test target exists. Never report a change as done with a failing build.

Xcode project, not SwiftPM: adding a file means adding it to the `Ubiquiti Assignment` target. Files sit under `Ubiquiti Assignment/` and the project uses folder-synchronised groups, so a new file placed in the right folder is picked up without editing `project.pbxproj`. Edit `project.pbxproj` only for build settings.

## Layout

```
Ubiquiti Assignment/
  App/            entry point, root navigation
  Features/       one folder per screen: View + ViewModel (+ subviews)
  Core/           Models, Networking, Caching, ImageLoading. No SwiftUI imports.
  UI/             shared components, design tokens from Figma
docs/             assignment transcript, standards, decision log
```

## Rules

- Specification is `docs/ASSIGNMENT.md`. When unsure what to build, read it before guessing.
- Before writing Swift, read `docs/CODING_STANDARDS.md` and follow it. Same once a review or refactor is asked for.
- Every assumption, tradeoff or library choice goes into `docs/DECISIONS.md` the moment it is made. The README's tradeoffs section is generated from that log at the end.
- Combine is a hard requirement. Reactive state (filtering, loading pipeline) runs through Combine publishers, visibly, not only through async/await.
- Third-party dependencies: none unless the decision log records why Foundation cannot do it.
- Loading, empty and error states are graded. Each screen handles all three with a dedicated view, never a bare `ProgressView` or empty screen.
- Commits: small, one concern each, present tense, gitmoji prefix as in existing history (`🏗️ XCode project scaffolding`). Commit only when asked.
- Figma file is the UI reference. When a Figma link is in context, pull exact spacing, colours and type from it rather than approximating.
