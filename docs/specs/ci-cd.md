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
| Quote data | `tests/test_quotes.py` validates `zitate_de.json` against the content guidelines. A rebuild must produce no diff | active (job `Quote data`) |
| Godot unit tests | headless Godot 4.7.2 (official Linux build, SHA-512 checked, cached), `--import`, then the custom runner `tests/godot/run_tests.gd` over `tests/godot/test_*.gd` | active (job `Godot tests`) |
| Network tests | `tools/net_smoke.sh`: headless host plus clients in one CI job: handshake, sync, disconnect | active (job `Net smoke`; skips with a notice while the script doesn't exist) |
| Lint | `gdlint` / `gdformat --check` (gdtoolkit) | planned |
| Export check | export all four presets (no publishing) | via `release.yml` on manual dispatch (`workflow_dispatch`), not on every PR |

## 3. CD

- **Release builds come from tags** (`v*`). Godot exports Windows, Linux and macOS builds, plus the headless dedicated-server build, and they're uploaded as a GitHub Release. **Status: active** (`.github/workflows/release.yml`):
  - Presets live in `export_presets.cfg`: "Windows Desktop", "Linux", "macOS" (ad-hoc signed, not notarized) and "Linux Server" (feature tags `dedicated_server`, `server`).
  - The workflow downloads the official 4.7.2 export templates (SHA-512 checked; only the four needed templates are cached), exports every preset with `--export-release` and uploads the zips as one artifact.
  - On a `v*` tag it also runs `gh release create` with the zips; a tag containing `-` (e.g. `v0.2.0-beta`) becomes a pre-release.
  - A manual run (`workflow_dispatch`) only builds artifacts.
- **Steam upload (later, optional)** uses the same artifacts.

## 4. Tests: ground rules

- **Game logic lives in testable, scene-independent classes** (resources and plain scripts), so it can be tested headless.
- **Every spec'd mechanic gets at least one test once it's implemented.** The spec section is the reference for expected values.
- **Seeded randomness is deterministic**, so tests run with fixed seeds.
