# Brandmauer

German political-satire arena roguelite, built in Godot 4. Single player plus 1–4 player self-hosted co-op.

## Spec-driven workflow

- **`docs/` is the source of truth.** Read [docs/README.md](docs/README.md) before working on anything.
- **Change the spec first, then the code.** Log decisions in [docs/decisions.md](docs/decisions.md) and unresolved points in [docs/open-questions.md](docs/open-questions.md).
- **All content must follow [docs/specs/content-guidelines.md](docs/specs/content-guidelines.md):** punch up, no ethnic stereotypes, no antisemitic codes, only verified quotes.
- **All gameplay code must follow [docs/specs/networking.md](docs/specs/networking.md):** single player is a local host, so there's one code path and no branching on solo vs. multiplayer.

## Conventions

- **Player-facing text is German and goes through Godot's translation system.** Never hard-code it, because the English edition is planned.
- **Quote data is generated** from `research/scripts/` (source data) and `research/auswahl.json` (selection) by `python -I research/scripts/build_all.py`. The game reads and ships only `research/zitate_spiel.json` (curated and `verifiziert`); `research/zitate_de.json` is the full research. Change the source and rebuild; never edit generated files (`zitate_de.*`, `auswahl.md`, `zitate_spiel.json`) by hand (D-159).
- **Our own texts are gendered with a colon** (Spieler:innen, Sozialtourist:in). Real quotes are never changed, with one exception: slurs, above all the N-word, are never shown. Censor them with asterisks plus `[N-Wort zensiert]` in the quote text, or drop the quote (D-156, [content guidelines](docs/specs/content-guidelines.md) §4); this also applies to notes, URLs and research files.
- **New `i18n/*.csv` files need a `.import` file with `importer="keep"`.** Otherwise exports lose the translations.

## GDScript pitfalls (Godot 4.7)

- **Run the affected headless tests after every GDScript change:** `python tools/affected_tests.py --run` (ci-cd.md §2a). It first checks that every script in `src/`, `tools/` and `tests/` compiles, then runs the tests of the touched areas; parse errors and script errors count as failures. Run the full suite (`--all --run`) only before a PR or release. New test files declare `const AREAS := [...]`; new source folders go into `tests/test_areas.json`.
- **Inner-class `match` patterns can't be variables.** Use `if`/`elif` when comparing against local variables.

## Shell

- **No bash heredocs** (`<<EOF`); they break on this Windows/Git Bash setup. Write scripts to a file and run them, or use the Edit tool.
