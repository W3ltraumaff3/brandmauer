# Spec: CI/CD, Tests & Repository Rules

**Status:** Approved · **Last updated:** 2026-11-01

## 1. Repository

- **Public on GitHub**, with `main` as the only long-lived branch.
- **All changes reach `main` via pull request.** Only the owner and Claude (acting through the owner's account) may merge. Outside contributors can only open PRs from forks, and CI runs on their PRs only after the owner approves them.
- **Branch protection on `main`:**
  - A PR is required.
  - CI checks must be green.
  - No force pushes and no branch deletion.
  - Conversations must be resolved before merging.
- **Commits:** clear messages. Commits Claude makes carry a `Co-Authored-By` trailer.

## 2. CI (GitHub Actions, `.github/workflows/ci.yml`)

Runs on every PR and every push to `main`. The plan grows with the project:

| Stage | Content | Status |
|---|---|---|
| Quote data | `tests/test_quotes.py` validates `zitate_de.json` against the content guidelines. A rebuild must produce no diff | active |
| Godot unit tests | headless Godot 4.7.2 plus a test framework (GUT or gdUnit4) for game logic: economy, wave schedule, stats, shop | planned (with the project skeleton) |
| Network tests | headless host plus 1–3 clients in one CI job: handshake, sync, disconnect | planned |
| Lint | `gdlint` / `gdformat --check` (gdtoolkit) | planned |
| Export check | export Windows and Linux builds (no publishing) | planned |

## 3. CD

- **Release builds come from tags** (`v*`). Godot exports Windows, Linux and macOS builds, plus the headless dedicated-server build, and they're uploaded as a GitHub Release.
- **Steam upload (later, optional)** uses the same artifacts.

## 4. Tests: ground rules

- **Game logic lives in testable, scene-independent classes** (resources and plain scripts), so it can be tested headless.
- **Every spec'd mechanic gets at least one test once it's implemented.** The spec section is the reference for expected values.
- **Seeded randomness is deterministic**, so tests run with fixed seeds.
