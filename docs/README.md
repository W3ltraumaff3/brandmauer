# Project Docs

This project is **spec-driven**: the documents in this folder are the source of truth. Code implements specs, not the other way around.

## Workflow

1. **A new feature or change starts in the spec.** Update or create the spec first, then implement it.
2. **Decisions go into [decisions.md](decisions.md)** with an ID, a date and a short rationale. Never silently overwrite a decision; add a new one that supersedes it.
3. **Unresolved points go into [open-questions.md](open-questions.md).** When one is answered, move it to `decisions.md`.
4. **Every spec carries a status:** `Draft` (still being shaped), `Approved` (ready to implement), or `Implemented`.

## Index

| Document | Content | Status |
|---|---|---|
| [GDD.md](GDD.md) | Game design: run structure, Späti, characters, weapons, items, co-op, options, meta progression (synced with v0.2.0-beta) | Draft |
| [specs/architecture.md](specs/architecture.md) | Code architecture: modules, sim/view split, contracts (ultimates, run statistics, shop additions) | Approved |
| [specs/networking.md](specs/networking.md) | Multiplayer architecture: hosting, authority, sync | Approved (architecture), implemented |
| [specs/content-guidelines.md](specs/content-guidelines.md) | Satire rules, red lines, quote handling | Approved |
| [specs/ci-cd.md](specs/ci-cd.md) | CI/CD, tests, branch protection, release process | Approved |
| [specs/audio.md](specs/audio.md) | Sound effects: mix, reward sounds, analysis, listen test | Implemented (values pending the listen test) |
| [specs/asset-licensing.md](specs/asset-licensing.md) | Allowed licenses for third-party assets, credits duty | Approved |
| [../CREDITS.md](../CREDITS.md) | Credits for all third-party assets | living |
| [status-report.md](status-report.md) | Current status, beta plan, open points | living |
| [decisions.md](decisions.md) | Decision log | living |
| [open-questions.md](open-questions.md) | Unresolved questions | living |
| [../research/](../research/) | Quote research: source data and generator in `scripts/`, hand-kept selection `auswahl.json`; generated from them `zitate_de.json`/`.md` (all research), `auswahl.md` (selection view) and `zitate_spiel.json` (the only quote file the game reads and ships, D-159). Also item ideas (`item_ideen.md`), music candidates | in progress |
