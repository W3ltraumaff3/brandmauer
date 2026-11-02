# Balancing and scaling

Source of truth for how difficulty, economy and player power scale. Every number lives in
`Content.BALANCE` (`src/data/content.gd`), so tuning never touches game logic.

## 1. Goals

- **Runs stay tense to the end.** Waves after 10 must not get easier. Measured as the
  damage the team takes per wave (as a share of max HP) with bots that can't die: it should
  stay level or rise from wave 10 to 19, not fall.
- **Umfrage 35 % (level 5) is hardly beatable.** Umfrage 10 % is beatable for a decent player.
- **Bosses feel hard** and take a while: elites around 20–40 s, the final boss around 60–120 s,
  for any player count.
- **Co-op is not easier than solo.** Pressure per player stays about the same for 1–4 players.
- **Less time in the Späti:** about 2–3 purchases per visit, never 6–8; at least one thing is
  always affordable; little money left over.
- **Fewer, bigger level-ups** (see §4).

## 2. Measuring (automated)

- `tools/balance_sim.gd`: kiting bots without cheats play one full run; one JSON line per run.
  - `players=1..4 umfrage=0..5 seed=N`
  - `immortal`: bots can't die (healed every frame). Measures pressure and kill speed
    independent of bot skill.
  - `random`: random level-ups and purchases. Over many runs this shows which characters,
    items, weapons and level-up stats go with better or worse runs.
  - `build=melee|ranged|status|summon|tank|crit`: plays like a human going for that build
    (fitting character, level-up priorities, weapons of the build's scaling or twins to
    combine, items whose stats fit).
- `tools/balance_matrix.sh <out.jsonl> [seeds] [mortal|immortal|random|builds] [umfragen]`
  runs every player count × Umfrage × seed in parallel (`JOBS`, default 16, longest runs first; builds: every
  build solo and with 4 players).
- `python tools/balance_report.py <out.jsonl>`:
  - win rates and median wave per player count × Umfrage (and per build)
  - per wave: damage taken (× max HP), DPS per player, enemies, boss kill time, Pfand on
    arrival, purchases, level-ups, Pfand left
  - per character, item, weapon and level-up stat: mean result with it vs. overall
  - weapon damage per Pfand spent
- The bot plays worse than a human. Use mortal runs for relative comparisons (Umfrage,
  player count) and immortal runs for the curves.

### Baseline (v0.2.2, 2026-11-01)
- Bots that survived wave 10 almost always won (2 of 96 runs died after wave 10).
- Player DPS grew ~200× from wave 1 to 19; enemy HP only ~8×.
- 1,000+ Pfand left unspent per Späti from wave 14 on; 5–8 purchases per Späti mid-run.
- Level-ups per Späti: 2–4 solo, 6–8 per player with 4 players (every team level gave every
  player a pick).
- Final boss: 7 s with 4 players; not killed by the solo bot. Elites 8–30 s.
- 4 players took only ~0.1× their HP per late wave.

### After tuning (v0.3.0, 2026-11-02; 8 quick rounds + 456-run batch + 152-run confirmation)
- Pressure (immortal bots, Umfrage 20 %) no longer drops late: solo ~2× max HP per wave from
  wave 8 to 19, 4 players ~2.5–4×. Co-op is no longer easier than solo.
- Purchases per Späti: 1–1.5 early, 2–3.5 mid and late, 20–60 Pfand left over.
- Bosses: solo elites ~16–35 s, final boss ~85–190 s; 4 players somewhat longer (bots clump).
- Build bots at Umfrage 10 % / 20 %: ranged 12/12 / 3/12, summon 10/12 / 6/12, crit 5/8 / 1/8,
  melee 2/8 / 0/8 (median wave 20), tank 0/8 (median wave 15–20), status 1/12 / 0/12
  (median wave 11.5 / 6). Umfrage 35 %: no bot wins.
- Open for playtests: status still the weakest build for bots, summon the strongest; the
  wave-15 elite takes long with 4 players; Normenkontrolle wastes its mark if the target dies
  first (design question).

## 3. Enemies

- **HP:** `base × (1 + hp_lin·w + hp_quad·w² + hp_cubic·w³) × Umfrage hp × co-op hp`, where
  co-op hp = `1 + coop_hp·(players − 1)`.
- **Damage:** `base × (dmg_base + dmg_lin·w) × Umfrage dmg`.
- **Spawn rate** (per second): `(spawn_base + spawn_lin·wave) × Umfrage spawn × (1 + coop_spawn·(players − 1))`.
  The base is lower than before the four walls, because enemies now come from every side.
- **Umfrage (difficulty) multipliers:** hp `1 + diff_hp·L`, dmg `1 + diff_dmg·L`,
  spawn `1 + diff_spawn·L` for level L = 0..5.
- **All Umfrage levels can be picked from the start** (no unlocking). The highest level
  reached is still recorded on the main menu.

## 4. Level-ups

- Level-up picks are **granted per Späti visit, not per team level**, the same for every
  player and every player count: 1 pick after waves 1–4, 2 after waves 5–11, 3 after waves
  12–19 (`levelup_schedule`).
- Each of the 4 options rolls a **rarity like the items** (green / blue / purple / red,
  shown in the same colors) with the item rarity weights for the current wave and Glück
  (luck). The stat amount is `LEVELUP_AMOUNTS × levelup_rarity_mult` (×1 / ×2 / ×3 / ×5).
- Zusammenhalt (team XP, Vernetzung) still raises team levels and the visual stages
  (GDD §7); it no longer hands out picks.
- Level-up reroll (GDD §6) rerolls the stats and rarities.

## 5. Economy

- Prices: `base × (1 + price_lin·w + price_quad·w² + price_cubic·w³)` with `w = wave − 1`, for weapons and
  items. Quadratic, because income grows with the number of enemies.
- Pfand per kill: the enemy's `pfand` value (stronger enemies drop more: fodder 1, tanks 4–6,
  elites 15–90) × `pfand_mult`.
- Target: 2–3 purchases per Späti; at least one offer affordable on arrival; little money
  left over. Late in the run that can be one really good (purple/red) item or 4–5 medium to
  good ones, so progress stays visible without long shopping. Measured per wave by
  `balance_report.py`.
- **There is always a weapon for your build:** every Späti (and every reroll) offers at least
  one weapon that fits the scaling of the weapons you hold (match ≥ 0.5, see GDD §6), or a
  twin of one of your weapons to combine. If the roll has none, one item offer is replaced by
  such a weapon.

## 5a. Reichensteuer (co-op only)

At the end of every wave, with `c_i` = Pfand picked up by player i in that wave (pickups only,
not wave income), computed for every player at once from the values before any transfer
(`Sim.reichensteuer`):

1. **Benchmark** `avg_i` = average `c` of the players **poorer than i** (`reich_benchmark =
   "poorer"`). Several rich players therefore don't shield each other. The richest player of
   all has no poorer player only if everyone is equal; then nobody pays.
2. Excess `E = c_i − reich_threshold × avg_i` (1.5, i.e. +50 %). If `E < reich_min` (5),
   player i pays nothing.
3. Tax `T = rate(n) × E` with `reich_rate` = **50 % / 60 % / 70 %** for 2 / 3 / 4 players.
3a. **Richest first:** payers are accepted from the richest down (equally rich ones together).
   A candidate whom the pot of the richer payers would lift to their own level anyway pays
   nothing and receives instead (e.g. the 100 in 300 / 100 / 50), and so does everyone poorer.
4. **The pot goes to the poorest first** (water filling): all taxes form one pot; the
   poorest non-paying player is raised to the next poorest, then both rise together, and so
   on. Players who are neither paying nor poor enough get nothing. Order is preserved.
5. **Givers keep the lead:** no receiver is raised above a giver's remainder ÷ 1.1
   (`reich_keep` = 10 %), and a giver never pays so much that they fall below a non-paying
   player who was poorer. If a cap limits the pot, every giver pays less, in proportion.
6. Whole Pfand only: receivers get the rounded-down amount, givers pay exactly what was
   handed out (split by their share of the pot).

| Players | Before | Transfer | After |
|---|---|---|---|
| 2 | 150 / 100 | 0 / 0 | 150 / 100 (exactly +50 %: nothing) |
| 2 | 200 / 100 | −25 / +25 | 175 / 125 |
| 2 | 300 / 100 | −75 / +75 | 225 / 175 |
| 2 | 100 / 0 | −45 / +45 | 55 / 45 |
| 3 | 300 / 100 / 100 | −90 / +45 / +45 | 210 / 145 / 145 |
| 3 | 300 / 100 / 50 | −112 / +31 / +81 | 188 / 131 / 131 |
| 3 | 300 / 300 / 100 | −45 / −45 / +90 | 255 / 255 / 190 |
| 4 | 300 / 100 / 100 / 100 | −105 / +35 / +35 / +35 | 195 / 135 / 135 / 135 |
| 4 | 300 / 200 / 100 / 100 | −66 / −34 / +50 / +50 | 234 / 166 / 150 / 150 |
| 4 | 300 / 300 / 100 / 100 | −77 / −77 / +77 / +77 | 223 / 223 / 177 / 177 |
| 4 | 400 / 300 / 100 / 100 | −77 / −77 / +77 / +77 | 323 / 223 / 177 / 177 |
| 4 | 300 / 300 / 300 / 100 | −25 / −25 / −27 / +77 | 275 / 275 / 273 / 177 |

- Players who are dead for good (state 2) take no part. Away players do (their character is
  still in the run).
- The Späti shows the local player's transfer of this wave; the run stats count paid and
  received totals (`tax_paid`, `tax_received`), shown on the end screen.

## 6. Lifesteal (like Brotato)

- 1 Lebensraub point = **1 % chance per hit** to heal 1 HP; at most 10 heals per second.
- The red lifesteal build keeps its bigger heal per proc.

## 7. Bosses and elites

- **HP:** `base × Umfrage hp × (elite_base + elite_coop·(players − 1))`: scales fully with the team
  (`elite_base` solo, + `elite_coop` per extra player). Die Remigrantin additionally × `final_boss_mult`.
- **Elites grow with the waves:** × `(enemy HP curve(wave) / curve(5)) ^ elite_wave_exp`, so the
  elites of waves 10 and 15 and the final boss keep up with the players' growing damage.
- **Focus on the boss:** while an elite or boss is alive, regular spawns run at
  `boss_wave_spawn` of the normal rate.
- **Phase 2 at `enrage_at` (50 %) HP:** the boss shouts "Jetzt reicht’s aber!" and its whole
  behaviour (movement and attack rhythm) runs `enrage_tempo` (1.4×) as fast.
- Unique multi-phase bosses: next batch (open-questions.md).

## 8. Retry for boss waves (option)

- Lobby option for the host, **"Boss-Wiederholung"** (off by default), part of the run config.
- Only in waves with an elite or boss (5, 10, 15, 20). If the whole team is down or dead
  there, the wave **starts over** instead of ending the run:
  - everyone is revived with full HP at the arena center
  - enemies, projectiles, hazards and pickups are cleared
  - the wave timer and the encounter start again (boss intro included)
  - items, weapons, stats and Pfand stay as they are
- Unlimited retries. The end screen shows how many were used; such a win still counts.
