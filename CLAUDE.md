# Brandmauer

German political-satire arena roguelite, built in Godot 4. Single player plus 1–4 player self-hosted co-op.

## Spec-driven workflow

- **`docs/` is the source of truth.** Read [docs/README.md](docs/README.md) before working on anything.
- **Change the spec first, then the code.** Log decisions in [docs/decisions.md](docs/decisions.md) and unresolved points in [docs/open-questions.md](docs/open-questions.md).
- **All content must follow [docs/specs/content-guidelines.md](docs/specs/content-guidelines.md):** punch up, no ethnic stereotypes, no antisemitic codes, only verified quotes.
- **All gameplay code must follow [docs/specs/networking.md](docs/specs/networking.md):** single player is a local host, so there's one code path and no branching on solo vs. multiplayer.

## Conventions

- **Player-facing text is German and goes through Godot's translation system.** Never hard-code it, because the English edition is planned.
- **Quote data lives in `research/zitate_de.json`.** Only use entries with status `verifiziert` in the game. It's generated: change `research/scripts/` and rebuild, never edit the JSON by hand.
- **Our own texts are gendered with a colon** (Spieler:innen, Sozialtourist:in). Real quotes are never changed.
- **New `i18n/*.csv` files need a `.import` file with `importer="keep"`.** Otherwise exports lose the translations.

## GDScript pitfalls (Godot 4.7)

- **Never use `:=` when the right side is untyped (Variant).** That covers dictionary access (`d["x"]`), untyped loop variables (`for p in players.values()`), properties of untyped objects, and expressions mixing those. Godot fails with "Cannot infer the type", and the **whole script stops compiling**, which breaks every caller. Write an explicit type (`var pos: Vector2 = e.pos`) or plain `=`.
- **Run the headless tests after every GDScript change.** `godot --headless --path . -s res://tests/godot/run_tests.gd` reports parse errors and script errors as failures.
- **Inner-class `match` patterns can't be variables.** Use `if`/`elif` when comparing against local variables.

## Shell

- **No bash heredocs** (`<<EOF`); they break on this Windows/Git Bash setup. Write scripts to a file and run them, or use the Edit tool.
