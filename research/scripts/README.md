# Quote build scripts

These scripts regenerate every quote file in `research/` from the source data. Run them after any change to the data or to `research/auswahl.json`:

```sh
python -I research/scripts/build_all.py
```

Each quote text is hand-kept in exactly one place: the source data here. Everything else is generated (D-159).

**Hand-kept (edit these):**
- `merz_data.py`: the Merz quotes, common misquotes and unverified quotes.
- `data/union/`, `data/afd/`: the researched quotes from the Union and the AfD (`*_extra.json` also hold misquotes and unverified quotes).
- `data/neu/kandidaten.json`: the 2026-11 batch (Union/AfD cooperation, NS relativization); `data/neu/unverifiziert.json` the finds from that batch that failed the check.
- `pruefung.py`: the status rules (D-031), the results of the single-source check and the wording corrections, applied on top of the data.
- `kontext_kurz.py`: the short context line per quote.
- `auswahl_notizen.py`: the reasons for the verified quotes that are *not* in the game, plus the prose of the selection view (targets, thin spots, checks before release, change log). No quote texts here, only ids.
- `research/auswahl.json` (one folder up): the curated selection: id, uses (`verwendung`) and reason (`begruendung`).
- `build_union.py`: the script that originally produced `data/union/*.json`. It's only kept for reference.

**Generated (never edit by hand):**
- `research/zitate_de.json`: all researched quotes with every field (status, notes, categories). Research data only; the game doesn't read it and it isn't exported.
- `research/zitate_de.md`: the reading copy of it.
- `research/auswahl.md`: the selection view (kept quotes by use, reasons, rejected verified quotes, notes).
- `research/zitate_spiel.json`: the game file. Only quotes that are in `auswahl.json` **and** `verifiziert`, only the fields the game reads, plus `verwendung`. It's the only quote file the game loads and ships (`src/data/quotes.gd`, `export_presets.cfg`).

The build refuses to run if the N-word appears in any output (D-156), if a verified quote is neither selected nor has a rejection reason, or if `auswahl.json` names a quote that isn't `verifiziert`.
