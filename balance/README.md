# Balance run data

Raw bot runs (one JSON line per run from `tools/balance_sim.gd`) kept as baselines.
How the bots and tools work: [docs/specs/balancing.md](../docs/specs/balancing.md) §2.

## runs/v0.4.1-beta/

Red-item review (2026-11-02/03, bot 3, `buy=<item>:8` A/B, final code `ddac79751b`); summary in
[balancing.md](../docs/specs/balancing.md) §2 "Red items (v0.4.1)", decisions D-127 to D-136.
Folder layout and code hashes: [runs/v0.4.1-beta/README.md](runs/v0.4.1-beta/README.md).

## runs/v0.4.0-beta/

Balancing round for v0.4.0-beta (2026-11-02, bot 3, Godot 4.7.2, 16 jobs); summary in
[balancing.md](../docs/specs/balancing.md) §2 "After tuning (v0.4.0)", decisions D-113 to D-122.

- **Code:** `baseline_*` ran on the v0.3.0-beta game code (`code` 58064148f5) or on it plus the
  placement option at its old default (`9b6a01fe15`, checked to give identical runs; content hash
  7e8dcbd314 / 30fbbde2a0 differ only by the new `place` key), so the baseline report warns about
  mixed hashes. `final_*` ran on the released v0.4.0 code: `code` **3589912e33**, content **338ea2a918**.
- Delivery metrics: the runs with code 58064148f5 (most of `baseline_immb`, `baseline_coop`, two of
  `baseline_imm`) still had the metrics bug fixed in this round (zones and summons cleared at a wave's
  end kept counting); use delivery numbers only from the other runs.
- Every final file repeats its baseline file's runs (same players, Umfrage, seed, build, char,
  start), so they pair with `python tools/balance_report.py --ab baseline_x.jsonl final_x.jsonl`.

| File | What |
|---|---|
| `*_solo.jsonl` | 132 mortal runs: 6 builds × own character and the Oma (ranged: own = Oma) × Umfrage 10 / 20 / 35 % × 4 seeds |
| `*_immb.jsonl` | 24 immortal build runs (6 builds × Umfrage 10 / 20 % × 2 seeds): boss times without survival bias |
| `*_imm.jsonl` | 12 immortal priority-bot runs (1 player Umfrage 10 / 20 % × 4 seeds, 2 and 4 players Umfrage 20 % × 2 seeds): pressure curves |
| `*_coop.jsonl` | 16 mortal co-op runs: ranged, status, summon, melee × 2 and 4 players × Umfrage 20 % × 2 seeds |
| `*_eq.jsonl` | 16 equal-footing runs: the Oma with the build's start weapon (summon + Infostand, status + Kleber) × Umfrage 10 / 20 % × 4 seeds |
| `*_w1.jsonl` | 120 `stop=1` runs: wave-1 income of the Oma with 9 start weapons and the Gewerkschaft's own start, 12 seeds each |
| `baseline_report.txt`, `final_report.txt` | `balance_report.py` on solo + immb + imm + coop, then the wave-1 table |
| `compare_baseline_final.txt` | the paired comparison behind the "After tuning (v0.4.0)" summary (calibration, boss times, pressure, delivery, Krankenschein vs Umverteilung, wave-1 income, equal footing) |

## runs/v0.3.0-beta/

Matches the released balance values (v0.3.0-beta):

| File | What |
|---|---|
| `confirm.jsonl` + `confirm_report.txt` | 152-run confirmation batch: every build, 1 and 4 players, Umfrage 10 % / 20 % |
| `status3.jsonl` + `status3_report.txt` | final check of the status build after its buffs |

Tuning history (older values, only for comparison):

| File | What |
|---|---|
| `base_mortal.jsonl`, `base_immortal.jsonl` | v0.2.2 baseline before the overhaul |
| `it1`–`it8.jsonl` | quick tuning rounds 1–8 |
| `big.jsonl` | 456-run batch (random + builds, all player counts) before the last tuning step |
| `status.jsonl`, `status2.jsonl` | status build tuning rounds |
| `cpu_test.jsonl`, `fma_*.jsonl` | throughput test and earlier one-off probes |

## Checking a new weapon or item

1. Run the same matrix as the baseline, e.g.
   `GODOT=... tools/balance_matrix.sh balance/runs/<version>/confirm.jsonl 4 builds "0 2"`
2. `python tools/balance_report.py <that file>` and compare it with
   `runs/v0.3.0-beta/confirm_report.txt`: build win rates, the new weapon's row in the
   weapon table (mean wave with it, damage per Pfand) next to weapons of the same build.
