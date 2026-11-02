# Red items (v0.4.1-beta)

Red-item review, 2026-11-02, bot 3, Godot 4.7.2, solo, 16 jobs. Decisions D-127 to D-136.
Every side pairs with `<build>_base` of the same folder on Umfrage + seed: the B side gets
`buy=<item>:8` (balancing.md §2: the item is offered from the Späti after wave 8 on at its shop
price and bought first once affordable, the way a player would buy a red item when it shows up).
Outcome = wave reached, 21 = won.

| Folder | Game code (`code` / content `all`) | What |
|---|---|---|
| `before/` | 3589912e33 / 338ea2a918 (v0.4.0) | first pass, 6 seeds × Umfrage 10 / 20 %. The injected offer **replaced** a rolled offer, so runs that never bought the item still differ from base: noisier, superseded by `before2` |
| `before2/` | 3589912e33 / 338ea2a918 (v0.4.0) | the "before" numbers: 8 seeds; melee, tank, status (Oma + Kleber, `statoma`) at Umfrage 10 / 20 %; ranged, crit, summon at 20 / 35 %. Offer appended (unbought runs = base) |
| `r2before/` | 3589912e33 / 338ea2a918 (v0.4.0) | Robin-Hood-Kostüm and Fertigputz on the melee build (the tank bot rarely affords a red item), 8 seeds × 10 / 20 % |
| `after/` | b7be70502e / 9751f0a4c9 | round 1 of the rework, same runs as `before2` |
| `r2/` | 5f18a83a59 / 392b71c786 | round 2: crit and ranged 16 seeds at 20 %, melee Robin / Fertigputz 8 seeds × 10 / 20 % |
| `r3/` | **ddac79751b / ca56007c69 (final code)** | round 3: crit 16 seeds at 20 % (Entlassungsurkunde, Genossenschaftsanteil, Cum-Ex), melee Robin 8 seeds × 10 / 20 % |
| `final/` | **ddac79751b / ca56007c69 (final code)** | one confirmation pass, all 12 red items in one pool: crit and ranged 16 seeds at 20 %; melee (Hausbesetzung, Fertigputz, Robin), tank (Fertigputz), status (Oma + Kleber, Kompost) 8 seeds × 10 / 20 %; summon (Ehrenamtskarte) 8 seeds × 20 / 35 %. These are the numbers in balancing.md "Red items (v0.4.1)" (runs are deterministic, so the cells shared with `r2`/`r3` came out identical) |

- `runs.txt` in each folder: the sim command lines (side name first).
- `ab_tables.txt`: every side vs its base (wins, mean outcome, paired B−A ± SE, B>A/B=A/B<A,
  how often the item was bought, median buy wave and price; "late" = pairs where base reached
  wave 9). `ab_fine.txt`: from the buy on, paired dps and damage-taken ratios and median boss kill
  times (waves 10 / 15 / 20), only pairs where B bought the item.
- `econ_saving_items.txt`: Pfand on arrival, spent and purchases per wave, base vs Genossenschaftsanteil / Cum-Ex (final code).
- `scripts/`: `mklist.py` (run lists), `runlist.sh` (one parallel pool; `TREE=` runs a frozen copy
  of the old code), `abtab.py`, `abfine.py`, `econab.py` (Pfand per wave, base vs side).
- Tuned values per round (final in bold): Wurfmaschine ×1.4 Durchschlagskraft weapons + fan fix
  (**round 1**); Doppelwumms 20 + 3 × Durchschlagskraft, −10 armor (**round 1**); Genossenschaft
  price 80, 25 % +5 %/wave (round 1) → **price 60, 30 % +5 %/wave up to 50 %, cap = share price**
  (round 2); Cum-Ex cap 40 × price factor (round 1) → **price 60** (round 2); Kritische Masse ×2 / ×0.75
  (round 1) → **+15 crit** (round 2); Entlassungsurkunde +25 crit, 35 %, −10 Akkord (round 1) → +30,
  40 %, −10 Vernetzung (round 2) → **crits on elites and bosses ×1.5** (round 3); Tarnkappe +40
  (round 1) → **+50 dodge** (round 2); Robin Hood ×3 with Krankenschein → Umverteilung (round 1) →
  **4 HP per proc, +10 Umverteilung** (round 3).
