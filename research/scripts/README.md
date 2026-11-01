# Quote build scripts

These scripts regenerate `research/zitate_de.json` and `research/zitate_de.md` from the source data. Run them after any change to the data:

```sh
python -I research/scripts/build_all.py
```

What each file holds:
- `merz_data.py`: the Merz quotes, common misquotes and unverified quotes.
- `data/union/`, `data/afd/`: the researched quotes from the Union and the AfD.
- `pruefung.py`: the status rules (D-031) and the results of the single-source check, applied on top of the data.
- `build_union.py`: the script that originally produced `data/union/*.json`. It's only kept for reference.

**Never edit `zitate_de.*` by hand.** Change the data or the rules here, then rebuild.
