# Final boss round (v0.4.1-beta, 2026-11-02)

Die Remigrantin as the final exam (GDD §14 "The final exam", decisions D-140 to D-146).
Bot 3, Godot 4.7.2, 14–16 jobs. Summary in [balancing.md](../../../../docs/specs/balancing.md) §7 "Final boss (v0.4.1)".

- **Code:** `baseline.jsonl` ran on the v0.4.0-beta game (`code` 3589912e33, content 338ea2a918) plus the new
  `balance_sim.gd` fight metrics, from a frozen copy, so it was not touched by the edits. `final.jsonl` ran on
  the final v0.4.1 code (`code` 321f6bbc59, content 784a46e251).
- **Pairing:** both files hold the same 80 runs (`runs.txt`: players, Umfrage, seed, build). Runs are
  deterministic, and waves 1–19 are unchanged: the Sauerländer's wave 15 came out identical in all 80 pairs,
  so every difference in wave 20 comes from her.
- **Sets:**
  - `mortal=15,20 retry`, 64 runs: the bots can't die except in waves 15 and 20, with Boss-Wiederholung on. That's
    the only way to get final-boss data at Umfrage 35 %, where mortal bots die before wave 20.
    - solo: ranged, summon, status, melee × Umfrage 10 / 20 / 35 % × 4 seeds
    - co-op: ranged and summon × 2 and 4 players × Umfrage 20 % × 2 seeds
  - `immortal`, 24 runs: ranged, summon, status, melee × 10 / 20 / 35 % × 2 seeds.
- **Fields used** (per boss wave, D-146): `enc_kill` (winning attempt), `retries`, `taken`/`t`, `tele_on`,
  `tele_in`, `enc_by`, `casts`, `phase_t`. A fight still running after 600 s is cut off (`stuck`).
- `tune_it1.jsonl` … `tune_it5.jsonl`: the tuning rounds in between (16 runs each, ranged/summon/status/melee
  × 20 / 35 % × 2 seeds, `mortal=15,20 retry`). Their content differs; see "Tuning history" below.
- `compare.md`: the full before/after table.

## Result (median kill time of the winning attempt, killed/fights, first tries lost)

| Build | Umfrage | Sauerländer (unchanged) | Remigrantin before | Remigrantin after |
|---|---|---|---|---|
| ranged | 10 % | 26 s, 4/4 | 37 s, 4/4, 0 lost | 49 s, 4/4, 0 lost |
| ranged | 20 % | 41 s, 4/4 | 59 s, 4/4, 0 lost | 71 s, 4/4, 0 lost |
| ranged | 35 % | flees at 60 s, 0/4 | 133 s, 3/4, 1 lost | **155 s**, 3/4, **2 lost** |
| summon | 10 % | 36 s, 2/4 | 109 s, 4/4 | 96 s, 3/4 |
| summon | 20 % | 47 s, 1/4 | 89 s, 4/4 | 134 s, 4/4 |
| summon | 35 % | flees, 0/4 | 104 s, 3/4 | **145 s**, 3/4 |
| status | 10 % | 44 s, 4/4 | 81 s, 3/4 | 123 s, 4/4 |
| status | 20 % | 46 s, 2/4 | 66 s, 3/4, 0 lost | 126 s, 4/4, 1 lost |
| status | 35 % | flees, 0/4 | 392 s, 2/4, 1 lost | 201 s, 1/4 |
| melee | 10 / 20 / 35 % | 30 s 2/4 · flees 0/4 · 48 s 1/4 | 1/4 · 0/4 · 1/4 | 1/4 · 0/4 · 0/4 |
| ranged, 4 players | 20 % | 46 s, 2/2 | 60 s, 2/2 | 77 s, 2/2 |
| summon, 4 players | 20 % | 35 s, 1/2 | 50 s, 2/2 | 87 s, 2/2 |
| immortal ranged | 10 / 20 / 35 % | 26 · 48 s · flees | 50 · 58 · 113 s | 60 · 71 · 138 s |
| immortal summon | 10 / 20 / 35 % | 37 · 47 s · flees | 65 · 90 · 104 s (1/2) | 95 · 309 · 254 s (1/2) |

n = 4 seeds per solo cell, 2 per co-op or immortal cell. "Flees" = the Sauerländer survives his 60 s wave timer.

**Pressure** (mortal set, damage taken per minute × max HP / share of time inside a danger zone):
- ranged at 35 %: Sauerländer 0.78 / 0.10; her before 0.66 / 0.14, after 1.13 / 0.25
- summon at 35 %: Sauerländer 0.72 / 0.04; her before 0.42 / 0.10, after 0.71 / 0.26

**Her damage by source** (mortal set, × max HP per fight, best-guess attribution):
- before: push rings 42 %, gold bars 20 %, unattributed 17 %
- after: push rings 39 %, Reichweite impact 11 %, her charges/contact 9 %, gold bars 8 %, during the Reichweite
  warning 8 %, rotor and lob lines 6 %

## Tuning history (`tune_it*.jsonl`)

| Round | Change | Effect |
|---|---|---|
| (smoke run, not kept) | first draft: Reichweite 2.0 s / 130 px / 2 × | ranged at 35 % lost 3 tries in a row: from the middle the safe strip is out of reach |
| it1 | Reichweite 3.0 s / 160 px / 1.5 ×; letterboxes back one by one (4 × 0.6 %/s, 2 % HP) | 3 of 4 fights stuck in phase 3 |
| it2 | letterboxes 0.3 %/s, 1.5 % HP; the bot targets them | still stuck at 33 %: one box always up, the bot never walked to the far one |
| it3 | shield breaks with the last box, all reopen together; 3 boxes solo; bot walks to the box | ranged 64–150 s; summon/status 140–500 s |
| it4 | boxes 0.15 %/s, 1 % HP, 20 s; `final_boss_mult` 5.5 | ranged 61–161 s, summon 170–224 s |
| it5 | shield 20 %, boxes back after 25 s, Reichweite 2 × | about the same; the summon build loses its damage when it walks to a corner |
| final | boxes 0.1 %/s, 0.7 % HP | table above |
