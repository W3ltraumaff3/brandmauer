# Brandmauer

German political-satire arena roguelite, built in Godot 4. Single player plus 1–4 player self-hosted co-op.

## Spec-driven workflow

- **`docs/` is the source of truth.** Read [docs/README.md](docs/README.md) before working on anything.
- **Change the spec first, then the code.** Log decisions in [docs/decisions.md](docs/decisions.md) and unresolved points in [docs/open-questions.md](docs/open-questions.md).
- **All content must follow [docs/specs/content-guidelines.md](docs/specs/content-guidelines.md):** punch up, no ethnic stereotypes, no antisemitic codes, only verified quotes.
- **All gameplay code must follow [docs/specs/networking.md](docs/specs/networking.md):** single player is a local host, so there's one code path and no branching on solo vs. multiplayer.

## Conventions

- **Player-facing text is German and goes through Godot's translation system.** Never hard-code it, because the English edition is planned.
- **Quote data lives in `research/zitate_de.json`.** Only use entries with status `verifiziert` in the game.
