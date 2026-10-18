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
    Fakes/        in-memory fakes of the Core protocols, for tests and previews
  UI/             shared components, design tokens from Figma
docs/             assignment transcript, standards, decision log
```

## Rules

- Specification is `docs/ASSIGNMENT.md`. When unsure what to build, read it before guessing.
- Before writing Swift, read `docs/CODING_STANDARDS.md` and follow it. Same once a review or refactor is asked for.
- Every assumption, tradeoff or library choice goes into `docs/DECISIONS.md` the moment it is made. The README's tradeoffs section is generated from that log at the end.
- Combine is a stated requirement, read as Apple's reactive stack for view state, not as the transport. Core is async/await: `FeedClient`, `FeedRepository` (an `actor`) and image loading expose `async` methods with typed throws, the feed is an `AsyncStream` (`FeedRepository.feed()`: cached feed first, then every update), and nothing in Core imports Combine. View models are `@Observable`; Combine runs the view-model data flow visibly: inputs (selected tab, loaded products) go into subjects and derived state (the filtered list) is a `CombineLatest` pipeline that sinks into view state. Never derive view state by hand where a publisher fits. See `docs/DECISIONS.md`, 2026-10-17.
- Loading, empty and error states are graded. Each screen handles all three with a dedicated view, never a bare `ProgressView` or empty screen.
- Commits: small, one concern each, present tense, gitmoji prefix as in existing history (`🏗️ XCode project scaffolding`). Commit only when asked.
- Before writing or reviewing SwiftUI, invoke the `swiftui-pro:swiftui-pro` skill when it is installed; before writing tests, invoke `swift-testing-pro:swift-testing-pro`. Where either skill disagrees with `docs/CODING_STANDARDS.md` or `docs/DECISIONS.md`, the repo docs win.
- Figma file is the UI reference. When a Figma link is in context, pull exact spacing, colours and type from it rather than approximating.

## Agent skills

### Issue tracker

Issues are GitHub Issues on `arturs105/ubiquiti-assignment`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root, created lazily. See `docs/agents/domain.md`.
