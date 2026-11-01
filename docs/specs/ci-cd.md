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
  - Required status checks: see the "Required" column in §2.
- **Commits:** clear messages. Commits Claude makes carry a `Co-Authored-By` trailer.
- **Security settings** (enabled via the GitHub API, see §5): Dependabot alerts and security updates, secret scanning with push protection, private vulnerability reporting. How to report a vulnerability: [`SECURITY.md`](../../SECURITY.md).

## 2. CI (GitHub Actions, `.github/workflows/ci.yml`, `codeql.yml`)

Runs on every PR and every push to `main`. The plan grows with the project.

**Required** checks block merging (branch protection). **Informational** checks run on every PR but don't block. New checks start as informational and are made required once they've been green and stable for a while (D-066).

| Stage | Content | Job (check name) | Required |
|---|---|---|---|
| Quote data | `tests/test_quotes.py` validates `zitate_de.json` against the content guidelines. A rebuild must produce no diff | `Quote data` | yes |
| Godot unit tests | headless Godot 4.7.2 (official Linux build, SHA-512 checked, cached), `--import`, then the custom runner `tests/godot/run_tests.gd` over `tests/godot/test_*.gd` | `Godot tests` | yes |
| Network tests | `tools/net_smoke.sh`: headless host plus clients in one CI job: handshake, sync, disconnect, reconnect | `Net smoke` (skips with a notice while the script doesn't exist) | yes |
| GDScript compile | `tools/check_script.gd` compiles every tracked `.gd` file on its own (after `--import`, so `class_name`s resolve). A script that stops compiling is named directly, with an error annotation, instead of surfacing as many unrelated test failures | `GDScript compile` | no (candidate) |
| GDScript lint | `gdlint` (gdtoolkit 4.x, hash-pinned in `tools/requirements-lint.txt`) with `.gdlintrc`: tabs count as 4 columns, lines up to 140, `class-definitions-order`, `max-file-lines` and `max-public-methods` disabled. Findings become warning annotations; the step has `continue-on-error`, so the job stays green | `GDScript lint` | no (non-blocking by design) |
| Workflow lint | `actionlint` (pinned release binary, SHA-256 checked) over all workflows, including shellcheck on `run:` scripts | `Workflow lint` | no (candidate) |
| Code scanning | CodeQL, see §5 | `CodeQL (actions)`, `CodeQL (python)` | no (candidate) |
| Export check | export all four presets (no publishing) | via `release.yml` on manual dispatch (`workflow_dispatch`), not on every PR | — |

Not in CI yet: `gdformat --check`. It would currently reformat most files (47 of 55), so adopting it means one big formatting PR first.

Running the checks locally:

```sh
pip install --require-hashes -r tools/requirements-lint.txt   # once, ideally in a venv
gdlint .
godot --headless --path . -s res://tools/check_script.gd -- res://src/sim/sim.gd
actionlint    # https://github.com/rhysd/actionlint/releases
```

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

## 5. Security & supply chain

- **Code scanning (`.github/workflows/codeql.yml`):** CodeQL with the `security-extended` queries on PRs, pushes to `main` and weekly (Monday). Languages:
  - `actions`: the workflow files and `.github/actions/*` (e.g. script injection, overly broad permissions).
  - `python`: `research/scripts/`, `tools/*.py`, `tests/test_quotes.py`.
  - **GDScript is not supported by CodeQL.** The game code is covered by the `GDScript compile` and `GDScript lint` jobs and the tests instead; network input handling is covered by the networking spec and `Net smoke`.
  - Results appear under *Security → Code scanning*. CodeQL "default setup" stays off, because it can't run next to this workflow.
- **Dependabot (`.github/dependabot.yml`):**
  - `github-actions` (`/` and `/.github/actions/*`) and `pip` (`/tools`, the gdtoolkit pins), weekly on Monday.
  - Minor and patch updates come grouped in one PR per ecosystem, majors come separately. Commit prefix `ci:`, labels `dependencies` plus `github-actions` or `python`.
  - A 5-day cooldown skips brand-new releases. Security updates are not delayed.
  - The game's own Python scripts use only the standard library, so there's nothing else to track. Godot itself and actionlint are pinned by version and checksum in the workflows and updated by hand.
- **Repository settings:** Dependabot alerts and security updates, secret scanning with push protection, private vulnerability reporting ([`SECURITY.md`](../../SECURITY.md)).

## 6. Workflow rules

These apply to every workflow in `.github/workflows/` and every action in `.github/actions/`:

- **Third-party actions are pinned to a full commit SHA** with the version as a comment (`uses: actions/checkout@<sha> # v7.0.1`). Dependabot updates both.
- **`permissions: contents: read` at the top level.** A job that needs more asks for it itself (e.g. `security-events: write` for CodeQL, `contents: write` for publishing a release).
- **`actions/checkout` uses `persist-credentials: false`.** No job pushes with git.
- **`concurrency`:** a new push to a PR cancels the superseded run. On `main` a newer push replaces a queued run, but a started run is never cancelled. Releases are never cancelled.
- **Every job has `timeout-minutes`.**
- **Downloaded tools are verified** (Godot and export templates: SHA-512 from the release; actionlint: pinned SHA-256; pip: `--require-hashes`).
- **Godot comes from the composite action `.github/actions/setup-godot`.** All jobs share one cache key per version (`godot-<version>-linux-x86_64`).
- **Job names are check names.** Renaming a required job breaks branch protection, so update the protection rule in the same PR.
