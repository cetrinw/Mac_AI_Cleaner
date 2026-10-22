# 🧹 Mac AI Cleaner

[中文说明](README.zh-CN.md)

**Read-only, explainable storage analysis for AI developer tools on macOS.**

Mac AI Cleaner finds data locations for coding agents, AI editors, local model runtimes, creative tools and common development tools. It reports size, file counts, risk, impact and recovery notes while protecting sessions, credentials, configuration, projects, model blobs and worktrees by default.

> **Safety boundary:** scanning is read-only. Cleanup is limited to explicitly approved cache candidates and moves them to macOS Trash after confirmation; it never uses arbitrary shell deletion or uploads file contents.

## Screenshot

![Mac AI Cleaner scan results](docs/screenshot.svg)

## What is implemented

- Swift 5.10 / SwiftUI macOS 14 app and `cleaner-scan` JSON CLI.
- 51 discovery definitions covering the planned AI tool and development-tool categories.
- Environment-aware hints for Qoder, OpenCode, Codex, Ollama and Hugging Face.
- Read-only metadata traversal with duplicate inode accounting, symlink refusal, limits, inaccessible-path reporting and cancellation hooks.
- Safety classifications A/B/C foundations; all current findings remain protected or manual-review only.
- Path redaction mode for sharing scan summaries without local paths.
- Automatic discovery of custom AI tool locations under home, Application Support, Caches, Applications and configured environment paths.
- Large file ranking and a separate memory monitor showing VM totals and top resident-memory processes.
- Recoverable cleanup path for approved cache candidates: move to macOS Trash only after revalidation and confirmation.
- Safe junk rules currently cover user caches, `~/.cache`, npm cache, and Xcode-style rebuildable caches; sessions, credentials, models, projects, and unknown data stay protected.
- Large-file workspace sorted by size, with protected and recoverable candidates clearly separated.
- Disk-management style capacity ring, scan scope/progress, Finder reveal action, multi-select, and batch Trash action.
- Memory monitor with system totals, a usage progress bar, and a safe process list when macOS permissions allow it.
- Navigation now switches the main pane immediately for scanning, large files, memory, and settings; settings includes the language control.
- Large-file scanning stays inside user cache/download locations by default and does not request Calendar or Contacts access.
- Memory monitoring shows used/available/active/wired/compressed memory, pressure, RSS, virtual memory, PID, and thread count for readable running processes.
- Finder reveal and path-copy actions are available on every large-file row; batch cleanup removes only items that successfully reach Trash.

Mac AI Cleaner is a safety-first macOS analyzer for AI tooling and general disk waste. It discovers custom locations in the home directory, Application Support, caches, user applications, and environment-variable paths, so users are not limited to vendor defaults.

The app includes AI tool analysis, junk candidates, a size-sorted large-file view, and a memory monitor with system totals and readable top resident-memory processes. Cleanup is limited to policy-approved cache candidates and moves them to the macOS Trash after revalidation and confirmation. Credentials, sessions, projects, models, unknown paths, and system paths remain protected.

The memory view supports Chinese/English switching. File contents are never uploaded.

## Build, test, and package

```sh
# Debug build
swift build

# Run the app and read-only CLI
swift run MacAICleaner
swift run cleaner-scan --redact
swift run cleaner-scan --memory

# Run XCTest (requires full Xcode on macOS)
swift test

# Release build
swift build -c release

# Build the distributable app bundle and zip
./scripts/package_app.sh
```

The scanner reads metadata only. It does not read file contents. Use a temporary directory with `--home` for a fixture scan. The package script creates `dist/MacAICleaner.app` and an Apple Silicon zip; signing is ad hoc unless a Developer ID identity is configured.

## Safety model

The scan/cleanup boundary is deliberate. The future cleanup executor must re-check path identity, process use, permissions, references and rule version immediately before a user-confirmed operation. Unknown, linked, active, credential-bearing, session, project, configuration and model data stay protected. No `sudo rm -rf`, arbitrary shell rules, remote executable rules or default deletion are permitted.

## Evidence status

- **L1:** package, CLI and SwiftUI structure compile on the available macOS toolchain.
- **L2:** realistic temporary fixtures cover protected Codex data and a symlinked model path; tests assert zero deletion and no link traversal.
- **L3/L4:** not claimed. Full 40+ real installation coverage, 15+ deletion adapters, Intel/macOS matrix, signing/notarization and live GitHub release require additional machines, fixtures and release credentials.

## License

MIT. See [LICENSE](LICENSE).

## Screenshots

### Storage overview and large files

![Storage overview](docs/screenshot.svg)

### Safe scanning

![Safe scanning](docs/screenshot-scan.svg)

### Memory monitor

![Memory monitor](docs/screenshot-memory.svg)

### Finder actions and cleanup

![Finder actions and cleanup](docs/screenshot-cleanup.svg)

## Release notes

### 0.2.0

- Read-only AI tool discovery with protected-path rules.
- Storage-style disk overview and large-file ranking.
- Finder reveal, copy path, multi-select, and recoverable Trash cleanup.
- Memory pressure, active/wired/compressed memory, RSS, virtual memory, PID, and thread details.
- Chinese and English documentation with language selection in Settings.
