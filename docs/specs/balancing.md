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

- `tools/balance_sim.gd`: bots without cheats play one full run; one JSON line per run.
  - `players=1..4 umfrage=0..5 seed=N`
  - `immortal`: bots can't die (healed every frame). Measures pressure and kill speed
    independent of bot skill.
  - `random`: random level-ups and purchases. Over many runs this shows which characters,
    items, weapons and level-up stats go with better or worse runs.
  - `build=melee|ranged|status|summon|tank|crit`: plays like a human going for that build
    (the build's character unless `char=` is given, level-up priorities, weapons of the
    build's scaling or twins to combine, items whose stats fit, the red build item of its
    scaling: Hausbesetzung, Wurfmaschine, Kompost, Ehrenamtskarte, and Kritische Masse when
    crit is the build's first or second stat; other red build items score negative).
  - `char=<id>[,<id>...]`: bot i plays the i-th character (cycling). Crosses any build with
    any character, e.g. `build=status char=oma`, so build and character effects separate.
    The character keeps its own start weapon; add `start=` (e.g. `start=kleber`) to give it
    the build's weapon as well.
  - `start=<weapon>[:tier][,...]`: replaces the character's start weapon with these weapons.
  - `item=<item>[,...]`: start with these items (applied before wave 1).
  - `prefer=<weapon|item>[,...]`: bought first whenever offered and affordable, in every
    mode; a preferred weapon with full slots sells the lowest-tier non-preferred weapon.
    `prefer` only biases purchases; use `start=` to guarantee a weapon is played.
  - `buy=<item>:<wave>[,...]`: from the Späti after that wave on, until the bot owns it, the
    item is added as a fifth offer at its normal shop price and bought first once the bot
    can pay for it (D-136). Measures an item at the price and wave a player would really buy
    it (a red item first shows up after wave 7), unlike `item=`, which gives it for free
    from wave 1. A run that never affords it is identical to the run without `buy=`.
  - **Behaviour switches** (bot 3, D-105; on by default except `castult`; `=0` turns one off for A/B):
    - `ult=smart|1|boss|0` (default `smart`): the ultimate, once per wave (the final boss
      recharges it at her phase changes). `smart`: heal ultimates (Urlaubsantrag, Kaffee
      und Kuchen) below 45 % HP with an enemy near, or when a teammate is down (Kaffee);
      the Critical-Mass dash when ≥ 8 enemies are within 150 px, below 35 % HP, or on a
      boss; damage and control ultimates on a boss or elite in reach, in boss waves only
      then (or below 30 % HP), otherwise on ≥ 6 enemies within 260 px or below 40 % HP.
      `1` is the bot-2 rule, `boss` only on bosses and elites, `0` never.
    - `castult=1` (the one switch that is **off** by default): a stun ultimate (Flashmob,
      Fragen Sie mal uns) waits for a boss cast a stun can break (`Sim.boss_cast != ""` and
      `boss_can_stun()`, D-102), at most 20 s after the boss came into reach, or until HP
      drops below 30 %. It cost 0.7 ± 0.3 waves in the calibration batch.
    - `move=1`: the movement planner below; `move=0` is the bot-2 kiting.
    - `dodge=1`: avoids enemy telegraphs and zones, and steps into Plenum circles.
    - `spread=1`: keeps ≥ 180 px from teammates.
    - `target=1`: target mode "most HP" while a boss or elite is in reach and fewer than 4
      enemies are within 150 px; otherwise "closest". The planner keeps range to the boss.
    - `pickup=1`: walks to Pfand (0.5), Stullen when below 70 % HP (1.0), the Sauerländer's
      bills (1.6, he heals from every bill left lying) and, for Stadtbild, passers-by,
      weighed against danger.
    - `shop=1`: the smarter Späti below.
    - `streik=1`: the Gewerkschaft's Streik during a boss fight or at ≥ 25 enemies.
    - `metrics=1`: weapon delivery metrics (cost only; play is the same).
  - `tune=<key>:<value>[,...]`: planner tunables for experiments: `decide` (frames between
    decisions, 4), `look` (lookahead, 0.35 s), `contact_r` (65 px) and `contact_w` (4),
    `comfy` (0.9), `want` (0.75), `wall_w` (1.2), `approach_w` (0.8), `stand` (1.2).
  - `jobs=N`, `tag=<text>`: only recorded in the JSON line.
  - `stop=<wave>`: end the run at the Späti after that wave, e.g. `stop=1` for the wave-1
    income of a start weapon (D-117); the report then prints only the "Wave-1 income" table.
  - `retry`: Boss-Wiederholung on (§8): a lost boss wave starts over, the run goes on.
  - `mortal=<wave>[,...]`: the bots can't die except in these waves (healed every frame
    elsewhere, like `immortal`). `mortal=15,20 retry` plays the Sauerländer and the final
    boss for real with the loadout of a full run at any Umfrage, even 35 % where mortal
    bots never get there (D-146). The JSON line has `mortal`, `retry`, `retries`.
  - Boss waves record (D-146): `retries` (Boss-Wiederholungen in the wave), `enc_kill`
    (kill time of the winning attempt) and `enc_total` (incl. failed attempts), `tele_on`
    (share of the fight with a boss cast or boss telegraph up), `tele_in` (share of living
    player time inside an enemy danger zone: lob markers, cones, lanes, rotors, the band,
    the Reichweite outside its safe strips; `Sim.danger_at`), `enc_by` (damage taken by
    source during the fight, × max HP per player), `casts` (boss casts started, by id),
    `interrupts`, `phase_t` (seconds into the attempt at which each phase began).
  - Unknown ids or values stop the run with an error on stderr and no JSON line; so does a
    run that fails (e.g. a script error in the game code).
  - All bots of a run get the same options. For A/B, run the same seeds with and without an
    option and compare with `--ab` (below). Once the runs diverge (a different purchase
    changes the shop RNG), only the seed matches, so read paired means, not single pairs.
    Run both sides in one pool when the game code may change meanwhile (`code` hash).
- **Bot behaviour (bot version 3, D-105; bot 2: D-090).** Code: `tools/balance_bot.gd`
  (movement, targeting, ultimates, Streik), `tools/balance_metrics.gd` (delivery metrics).
  - **Kiting distance** = the shortest range of the weapons that aim at a target. Trail,
    orbit and other no-target kinds (`aura`, `follower`, `patrol`, `tether`, `decoy`,
    `heal`), and definitions without `range`, don't count; a weapon definition may set
    `kite_range` to override.
  - **Movement planner** (15 decisions per second): scores standing still and 12
    directions by where they lead in 0.35 s. Enemies are predicted to chase the player.
    Costs: contact (within 65 px of an enemy's edge), crowding (closer than 0.9 × the wanted
    distance, which is 0.75 × the kiting distance), enemy projectiles on the path, enemy
    telegraphs and zones (lob markers, kerosin, Mietzone, the Kahlschlag cone, the
    Abschiebezone via `Sim.in_band`, and any unknown enemy hazard with damage), push-ring
    fronts and walls while rings are out (they knock toward the wall), walls and corners,
    open holes (AfD enemies come through them), teammates closer than 180 px. Rewards:
    keeping the wanted distance to the nearest enemy (or the focused boss), strafing
    sideways, the bot's own Plenum circle during an Abstimmung (the first
    `plenum_needed()` living bots by id each take one), revives, pickups, smooth movement.
  - **Final boss (D-146):** her lanes, rotor lines and the Reichweite cost what `Sim.danger_at`
    says; during a Reichweite the bot walks to `Sim.reich_safe_spot` (the nearest safe strip in
    front of the intact wall). While letterboxes stand it focuses and targets the nearest one
    (target mode "closest"), like a player who switches targets.
  - **Klimakleber:in** gets a standing bonus; with weapons that only work while moving
    (`trail`: Straßenkreide) it walks for a share of every 3 s cycle equal to
    (trail weapons ÷ weapons), so the marks keep coming.
  - **Wende / Rolle rückwärts**: the bot presses the other way on the flipped axis only
    (`Sim.reverse_dir`, Teilwende D-112).
  - **Späti** (`shop=1`): level-up rerolls (twice at most) when no option fits the build and
    the reroll costs ≤ a third of the Pfand; defensive level-ups (+3 score) and defensive
    items (max HP, armor, regen, dodge) first when the last wave took > 0.6 × max HP;
    build bots with full slots sell their lowest-tier off-build weapon for a build weapon
    of at least that tier; one wall repair per visit when there are more holes than
    players and it costs ≤ ¼ of the Pfand, and before the final wave every repair that
    costs ≤ ½ of the Pfand. Twins combine on purchase (sim rule).
  - Not done: going for boss adds on purpose (only through "closest" targeting), standing
    in front of holes to defend or repair them in-wave (only the Antifa character repairs,
    passively). Zone placement is a game rule, not bot behaviour (`place=` below).
- **Placement experiments (`place=`, `zonetime=`; game rule in §9).** Ground weapons
  (`Content.PLACED_KINDS`: puddle, lob, wall) land where `Sim.place_mode` says, for every
  player alike (default `Content.BALANCE.place`); the bot run can override it for A/B:
  - `place=target`: on the target (the rule before v0.4)
  - `place=lead`: target position + its velocity (smoothed over a few frames) × the
    weapon's `delay` (Kartoffelbrei 0.8 s) or `BALANCE.place_lead`
  - `place=cluster`: among the 16 nearest visible enemies in range, the one with the most
    enemies within the zone's radius; the zone lands on the centre of that group
  - `place=between`: half way between the player and the target, to block the approach
  - `zonetime=<k>`: puddles and walls live k × as long and deal 1/k × the damage per second
    (same total), e.g. `zonetime=0.5` for shorter, stronger zones. Experiment only.
  - The Pappkamerad already lands half way to its target and the Infostand at your feet;
    neither changes with `place`.
- **JSON line** (fields of bot 1 and 2 unchanged; new ones are additive):
  - run: `bot` (version), `content` (short md5 of `Content.WEAPONS`, `ITEMS`, `BALANCE`,
    `RED_BUILD`, `CHARACTERS`, `ENEMIES`, `LEVELUP_AMOUNTS`, `BASE_STATS`, `ULTS` and `all`),
    `code` (md5 of `sim.gd`, `arena.gd`, `content.gd`: game logic changes), `char`, `start`,
    `item`, `prefer`, `ult`, `dodge`, `switches`, `tune`, `jobs`, `tag`, `args` (the command
    line), `ms_per_game_s` (wall-clock ms per simulated second).
  - per wave: `enc` / `enc_kill` (boss kill time) and `enc_left` (the encounter's HP share left
    when the wave ended; > 0 without `enc_kill` = it fled at the wave timer or the team died).
  - per wave: `effects` (share of enemy-seconds slowed, poisoned, stunned, on status-immune
    enemies, and `silence` / `reverse` / `sticker` / `file` when the sim has those effects),
    `summons_mean` (per player) and `summons_max`.
  - per player: `weapon_wave` (Späti wave a weapon was first owned; 0 = start), `buys`
    (`[Späti wave, id, tier, price]`), `offered` (how often each id was offered),
    `loadout` (per Späti visit: weapons, non-zero stats, damage per weapon in the wave before),
    `taken_by` (damage taken by enemy type, `proj:<type>` or `hazard:<type>`; a best guess
    per hit from what touched the player), `heal` (`regen` = Krankenschein, `lifesteal` =
    Umverteilung, `sani` = Demo-Sanis heal given, `other` = everything else the HP rose by:
    pickups, ultimates; a teammate's Demo-Sanis heal on this player is taken out of
    `other`), `still_share` (time standing ≥ 0.6 s), `summons_max`, `ults` (ultimates
    used), `shop3` (`sold`, `lu_rerolls`, `repairs`, `defensive` items bought).
  - per player `delivery` (`metrics=1`), per weapon id: `casts` (cooldown resets: shots,
    placements, marks), `first_s`/`first_n` (time from a cast to the weapon's next damage),
    `shots`/`hits` (player projectiles, summon shots included, and how many damaged at
    least one enemy), `zones`, `zone_life`, `zone_busy`, `zone_enemy_s` (damaging zones
    placed, seconds alive, seconds with an enemy inside, enemy-seconds inside),
    `summons`, `summon_s`, `summon_busy` (summons placed, seconds alive, seconds with an
    enemy within the summon's reach; 300 px for summons without a reach of their own).
  - Healing in immortal runs is meaningless (the bot is refilled every frame).
- `tools/balance_matrix.sh <out.jsonl> [seeds] [mortal|immortal|random|builds] [umfragen] [sim args...]`
  runs every player count × Umfrage × seed in parallel (longest runs first; builds: every
  build solo and with 4 players; one file per run, joined at the end). Extra arguments go
  to every run. Environment:
  - `JOBS` (default 16), `PLAYERS` (default `4 3 2 1`, builds `4 1`),
    `BUILDS` (default all six), `CHARS` (e.g. `"own oma antifa"`: every run once per
    character; `own` = the build's own or the rotating characters).
  - Fails (exit 1) when runs produced no line, e.g. after an unknown id.
  - Example A/B for a new status weapon on the same seeds:
    `BUILDS=status tools/balance_matrix.sh a.jsonl 6 builds "0 2"` and
    `BUILDS=status tools/balance_matrix.sh b.jsonl 6 builds "0 2" start=<new_id> prefer=<new_id>`.
  - Character confound: `BUILDS="status summon" CHARS="own oma antifa" tools/balance_matrix.sh x.jsonl 4 builds "0 2"`.
- **A/B runs: `tools/balance_ab.sh <out_dir> <seeds> <umfragen> <players> <builds> <side>=<args> ...`**
  runs every side on the same seeds in **one** parallel pool (so a code change or CPU load
  mid-batch hits all sides alike) and writes `<out_dir>/<side>.jsonl` per side. `builds`
  `-` = no build (priority bots, e.g. with `immortal`); `CHARS="own oma"` crosses with
  characters like the matrix; `JOBS` (16), `GODOT`. Example, placement on the status
  build: `CHARS="own oma" tools/balance_ab.sh ab/ 4 "0 2" 1 status base="" lead="place=lead"`.
  - A bot run is deterministic: the same code, seed and options give the same JSON line
    (checked 2026-11-02), so a side that matches an earlier run on the same code needn't
    be rerun, and a content change can be A/B'd by running the B side after the change.
  - `python tools/balance_report.py --sides <out_dir> <base side> [--group build,umfrage]`:
    every side against the base side on matching runs: wins, mean outcome, paired
    difference ± SE, B>A / B=A / B<A, and median boss kill times per boss wave.
- `python tools/balance_report.py <out.jsonl> [--min-n 8] [--build status]`:
  - header: bot versions, content hashes, wall time per run; warns when a file mixes them
  - win rates and median wave per player count × Umfrage, and per build (`build/char` when
    `char=` was given)
  - per wave: damage taken (× max HP), DPS per player, enemies, boss kill time, Pfand on
    arrival, purchases, level-ups, Pfand left
  - per character, item, weapon and level-up stat: mean result with it vs. overall (pooled)
  - weapon damage per Pfand spent
  - **per build** a weapon table: owners, win rate, Δwave with − without within the build,
    damage share, damage per Pfand (all and long runs ≥ wave 12), damage per Pfand per wave
    owned (bought copies), median first-buy wave
  - immortal runs get the same weapon table (no survival bias)
  - boss kill times per build (median, killed/fights)
  - healing by source per build, and Krankenschein vs. Umverteilung: HP per stat point and
    minute (from the per-wave loadout) and outcomes by end stats
  - damage taken by source, effect uptime, summons alive, standing-still share, ultimates per wave
  - Späti behaviour (bot 3): weapons sold, level-up rerolls, wall repairs, defensive items
  - weapon delivery (bot 3): per weapon with its kind and main scaling (read from
    `content.gd`): damage per cast, projectile hit rate, time from cast to first damage,
    enemy-seconds inside a zone per cast, share of a zone's / summon's life with an enemy
    inside / in reach
  - header: code hash next to the content hash, ms per simulated second, switches that were off
  - boss table: `Nf` = fights the team survived but the elite fled at the wave timer
  - "Wave-1 income" for `stop=1` runs: Pfand at the first Späti per start weapon, with a
    WARNING below 85 % of the ranged starters (Stricknadeln, Gendersternchen, Pfandflasche, Megafon)
  - `--min-n` sets the minimum player-runs per row (default 8)
- `python tools/balance_report.py --ab a.jsonl b.jsonl [--match players,umfrage,seed,build,char,immortal,random]`
  pairs runs with the same key and prints per build × players × Umfrage the wins, mean
  outcome, mean paired difference ± standard error and B>A / B=A / B<A counts, then median
  DPS and boss kill times A → B, how often B's `start`/`prefer`/`item` ids were owned and
  their damage share, healing A → B and B's weapon table. Drop `char` from `--match` to
  compare characters.
- **Weapon probe: `tools/weapon_probe.gd -- [ids=a,b] [tier=1] [dist=150]`** prints tier-I dps
  per base price against one dummy, a crowd of nine and a Reichsbürger, and dps per point of
  the scaling stat, for the design bands (status single target 0.30–0.45/P, crowd ≤ 1.5/P;
  summons 0.25–0.40/P; 0.8–1.5 dps per point). No bot, no RNG noise.
- Runtime (Godot 4.7.2, 14 jobs): bot 3 costs about 64 ms wall time per simulated second
  (bot 2: 49 ms; the planner adds about 30 %, the delivery metrics about 6 %), so a won
  solo run takes about 60 s and a 4-player run several minutes. An immortal run costs
  3–10× a mortal one.
- The bot plays worse than a human. Use mortal runs for relative comparisons (Umfrage,
  player count) and immortal runs for the curves.
- Raw runs and reports are kept per release under `balance/runs/` (see `balance/README.md`)
  as the baseline for new weapons, items and characters.

### Bot 3 calibration (2026-11-02, solo, 3 seeds per cell, boss rules D-102 to D-112 in)
Wins / median wave (21 = won) by Umfrage 10 % / 20 % / 35 %:

| Build | Bot 2 | Bot 3 |
|---|---|---|
| ranged | 1/3 w10 · 1/3 w10 · 0/3 w6 | 3/3 w21 · 3/3 w21 · 1/3 w11 |
| summon | 2/3 w21 · 1/3 w10 · 0/3 w5 | 3/3 w21 · 2/3 w21 · 1/3 w11 |
| crit | 2/3 w21 · 1/3 w6 · 0/3 w4 | 3/3 w21 · 1/3 w20 · 0/3 w4 |
| melee | 0/3 w20 · 0/3 w10 · 0/3 w20 | 3/3 w21 · 0/3 w14 · 0/3 w7 |
| status | 3/3 w21 · 1/3 w10 · 0/3 w5 | 2/3 w21 · 0/3 w11 · 0/3 w5 |
| tank | 0/3 w10 · 0/3 w20 · 0/3 w6 | 0/3 w20 · 0/3 w20 · 0/3 w7 |

- Paired over all 54 runs: bot 3 − bot 2 = +2.1 ± 1.0 waves, wins 22 vs 12.
- Each switch off (same seeds, 54 runs): `move=0` −1.3 ± 0.9, `dodge=0` −1.3 ± 0.7,
  `shop=0` −1.2 ± 0.5, `pickup=0` −0.9 ± 0.8, `target=0` −0.8 ± 0.6, `ult=0` −0.8 ± 0.6,
  `ult=1` −0.6 ± 0.7, `streik=0` −0.2 ± 0.3; `castult=1` −0.7 ± 0.3 (so it's off by default).
- Against the playtest anchors: at 35 % the bot still loses almost everything (a good human
  wins sometimes), so read relative numbers. Ranged and summon come out on top for the bot
  while players feel ranged clearly ahead of summon. Boss kill times are 20–35 s for elites
  and 22–35 s for the final boss with ranged, crit, status and summon (goal: elites 25–45 s,
  final boss 60–90 s).

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

### After tuning (v0.4.0, 2026-11-02; bot 3; 184-run baseline, ~1,100 A/B runs, 352-run confirmation)
Data: `balance/runs/v0.4.0-beta/` (final code 3589912e33); decisions D-113 to D-122.
- **Changes:** ground weapons land on the densest group (D-113); Ehrenamtskarte ×1.5 for every
  Ehrenamt weapon (D-114); Infostand leaflets bounce and the Weißer Overall splashes (D-115);
  the eight v0.3 weapons tuned into the bands (D-116); Infostand refill 1 s below its cap (D-117)
  and 5 / 8 / 12 / 17 damage (D-122); boss HP (D-118); Krankenschein 0.08 per point (D-119);
  Kreide chalk circle (D-120); melee ×2 against encounter units (D-121). Tool fix: delivery
  metrics no longer count zones and summons cleared at a wave's end (they inflated a zone's
  life ~7×; the earlier "Kleber 18 % / Kreide 7 % busy" was partly that artefact).
- **Builds (solo, own character), wins at Umfrage 10 / 20 / 35 %, paired mean wave vs baseline:**

  | Build | Baseline | Final | Δ wave (12 pairs) |
  |---|---|---|---|
  | ranged | 4/4 · 4/4 · 1/4 | 4/4 · 3/4 · 1/4 | −1.1 ± 0.9 |
  | crit | 4/4 · 1/4 · 1/4 | 4/4 · 2/4 · 0/4 | −0.8 ± 1.9 |
  | summon (Gewerkschaft) | 4/4 · 3/4 · 1/4 | 4/4 · 4/4 · 3/4 | +3.1 ± 1.6 |
  | status (Klimakleber) | 2/4 · 0/4 · 0/4 | 0/4 · 1/4 · 0/4 | −2.1 ± 2.3 |
  | melee | 3/4 · 2/4 · 0/4 | 1/4 · 0/4 · 0/4 | −1.0 ± 1.6 |
  | tank | 0/4 · 0/4 · 0/4 | 0/4 · 0/4 · 0/4 | +0.1 ± 1.7 |
  | all 132 pairs (incl. the Oma crossings) | | | −0.5 ± 0.4 |

- **Equal footing (Oma with the build's start weapon, Umfrage 10 / 20 %):** summon + Infostand
  3/4 · 0/4 → 4/4 · 4/4, status + Kleber 4/4 · 1/4 → 4/4 · 2/4, ranged 4/4 · 4/4 → 4/4 · 3/4,
  crit 4/4 · 4/4 → 4/4 · 4/4. Summon now sits level with ranged without the Gewerkschaft passive;
  status is closer but still behind at 20 %.
- **Bosses (median kill time, solo own character, mortal):** final boss ranged 22 → 59 s, crit
  29 → 57 s, summon 46 → 100 s, status 26 → 106 s, melee 182 → 386 s; elites (waves 5 / 10 / 15,
  ranged) 28 / 23 / 29 → 25 / 29 / 35 s. Immortal ranged final boss 21 / 44 → 50 / 58 s at
  Umfrage 10 / 20 %. 4 players: the wave-5 clique is now killed (30–38 s) instead of fleeing.
- **Normal-wave pressure (immortal priority bots, mean over waves 1–19 without boss waves, × max
  HP):** solo Umfrage 10 % 0.88 → 0.58, 20 % 1.43 → 1.13 (12 seeds each); 2 players 1.58 → 1.05,
  4 players 2.24 → 1.52 (2 seeds). Paired over 28 runs −16 ± 12 %: within noise, but every cell
  points the same way (random loadouts profit from the better ground and summon weapons).
  Co-op stays at or above solo per player except 2 players at 20 % (1.05 vs 1.13, n = 2).
- **Delivery per cast, baseline → final:** Kleber 111 → 192 (enemy-seconds 2.4 → 3.6, busy
  48 → 59 %), Kartoffelbrei 55 → 163, Brandmauer-Ziegel 333 → 401, Straßenkreide 3.3 → 7.6,
  Infostand 586 → 1,189 (leaflet hit rate 77 → 75 %), Weißer Overall 180 → 217.
- **Krankenschein vs Umverteilung** (HP per stat point and minute, solo builds): 1.45 vs 0.61 →
  1.15 vs 0.90.
- **Wave-1 income** (Pfand at the first Späti, Oma): Infostand 18.2 → 20.2; ranged starters
  17.8–19.5 (unchanged); Gewerkschaft's own start 19.4.
- **Open:** melee loses at the final boss (it can't stay next to her); the Klimakleber:in status
  bot dies to the wave-5 champagne lobs while standing; Kreide is still the weakest weapon; the
  summon build with Gewerkschaft is now the strongest bot build at 35 % (watch in playtests; the
  lever would be the passive's own-summon count); the rest of the boss-rule numbers.

### Red items (v0.4.1, 2026-11-03; bot 3, `buy=<item>:8`, solo)
Data: `balance/runs/v0.4.1-beta/` (final code ddac79751b); decisions D-127 to D-136. Each item
is offered from the Späti after wave 8 on at its shop price and bought first once affordable
(typically after wave 8–9, 145–250 Pfand), paired with the same seeds without it. Outcome = wave
reached (21 = won), B−A ± SE over the pairs.

| Item (build) | Before (v0.4.0) | After (final) | n | Wins A → B (after) |
|---|---|---|---|---|
| Hausbesetzung (melee, unchanged) | +0.25 ± 0.11 | +0.75 ± 0.56 | 16 | 4 → 8; final boss 105 → 81 s |
| Wurfmaschine (ranged) | −0.56 ± 0.56 | +1.25 ± 0.85 | 16 | 14 → 16 |
| Doppelwumms (ranged) | −0.12 ± 0.09 | +1.25 ± 0.85 | 16 | 14 → 16 |
| Genossenschaftsanteil (ranged / crit) | −2.38 ± 1.07 / — | +0.50 ± 0.65 / +0.06 ± 0.82 | 16 / 16 | 14 → 15 / 8 → 8 |
| Cum-Ex-Erstattung (ranged / crit) | −2.44 ± 1.09 / — | −0.12 ± 0.92 / +0.69 ± 1.05 | 16 / 16 | 14 → 14 / 8 → 9 |
| Ehrenamtskarte (summon, unchanged) | 0 (ceiling) | 0 (ceiling) | 16 | 15 → 15; final boss 165 → 92 s |
| Kompost (status Oma + Kleber, unchanged) | 0 (ceiling) | +0.56 ± 0.56 | 16 | 11 → 12 |
| Kritische Masse (crit) | −0.81 ± 1.09 | +2.75 ± 1.44 | 16 | 8 → 13; final boss 47 → 31 s |
| Entlassungsurkunde (crit) | −4.25 ± 1.40 | +1.38 ± 1.30 | 16 | 8 → 10 |
| Tarnkappe (crit / ranged) | −2.50 ± 1.19 / — | +1.12 ± 1.53 / +0.12 ± 0.92 | 16 / 16 | 8 → 10 / 14 → 14 |
| Robin-Hood-Kostüm (melee) | −1.62 ± 1.01 | +0.56 ± 1.00 | 16 | 4 → 5 |
| Brandmauer-Fertigputz (melee / tank, unchanged) | +0.50 ± 0.57 / +0.06 | +1.12 ± 0.73 / +0.06 ± 0.06 | 16 / 16 | 4 → 5 / 0 → 1 |

- "Before" cells: `before2` (v0.4.0, ranged and crit at Umfrage 20 / 35 %, the others 10 / 20 %) and
  `r2before` (melee); the "after" cells are crit and ranged at 20 % with 16 seeds, the others 10 / 20 %
  with 8 seeds each (summon 20 / 35 %). The bases differ a little between them because the four red
  politics items are now in the shop pool (D-127).
- Money items: with the Genossenschaftsanteil the bot spends 345 instead of 261 Pfand in the very next
  Späti and 1.5–1.8× as much from wave 12 on; Cum-Ex about +100 per visit until the audit at wave 15.
  The bot converts the extra money into few extra wins because ranged is at the win ceiling at 20 %
  and it never saves on purpose; a saving player gets more.
- Nothing trivializes the run: the largest gain is Kritische Masse (+2.8 waves, the crit bot from
  8 to 13 wins of 16 at Umfrage 20 %). Tarnkappe still costs armor builds (tank: −0.7 ± 0.6 waves with +40 in round 1); that
  build has Brandmauer-Fertigputz. The tank bot affords a red item in only 2–3 of 16 runs (it is poor
  and dies early), so tank numbers are thin.

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
- The red lifesteal build (Robin-Hood-Kostüm) heals 4 HP per proc instead of 1 and turns Krankenschein points into Umverteilung (D-134).
- **Krankenschein (HP regen): 0.08 HP per second per point** (v0.4, D-119; was 0.12), level-up
  +3 as before. Measured as HP actually healed per stat point and minute in bot runs, it now
  sits in the same band as Umverteilung (see "After tuning (v0.4.0)"; before 1.01–1.45 vs 0.47–0.61).

## 7. Bosses and elites

- **HP:** `base × Umfrage hp × (1 + diff_boss_hp·L) × hp_mult × (elite_base + elite_coop·(players − 1))`:
  scales with the team (`elite_base` 0.6 solo, + `elite_coop` 0.3 per extra player; v0.4, D-118,
  was 0.5). `diff_boss_hp` (0.15 per Umfrage level L) and the per-encounter `hp_mult`
  (`Content.ENCOUNTERS`: Sylt-Clique 1.25, Geschichtslehrer 2.2, Sauerländer 2.0; were 1.0 / 1.4 / 1.6)
  act only on encounter units. Die Remigrantin additionally × `final_boss_mult` (5.5 since v0.4.1, D-145; 4.5 in v0.4.0, D-118; 1.6 before). D-102, D-118.
- **Melee against encounter units: ×2** (`melee_vs_boss`, v0.4, D-121): every melee weapon deals
  double damage to elites, minibosses and bosses, because it has to stand next to them.
- **Elites grow with the waves:** × `(enemy HP curve(wave) / curve(5)) ^ elite_wave_exp`, so the
  elites of waves 10 and 15 and the final boss keep up with the players' growing damage.
- **Focus on the boss:** while an elite or boss is alive, regular spawns run at
  `boss_wave_spawn` of the normal rate.
- **Phases at 66 % / 33 % HP with phase lock and Pressekonferenz** (GDD §14 "Boss rules", D-102, D-106);
  this replaced the old "phase 2 at 50 %" switch. Movement and basic attacks run `Content.BOSS.phase_tempo`
  (×1.0 / ×1.2 / ×1.4) as fast per phase; signature abilities keep real time. Every boss-rule knob lives in `Content.BOSS`.
- Unique multi-phase bosses: spec in GDD §14 "Boss rules" (D-102 to D-104), tuned in the next balancing round.

### Final boss (v0.4.1, D-140 to D-146)
Data: `balance/runs/v0.4.1-beta/final_boss/` (80 paired runs, `mortal=15,20 retry` and `immortal`; the
Sauerländer's wave came out identical in all 80 pairs). Every number of her kit lives in `Content.BOSS`
(`kette_*`, `ansturm_*`, `rotor_*`, `reich_*`, `brief_*`, `wahl_*`, `shield`, `p3_ring_every`).
- **Why the Sauerländer felt harder:** he flees at his 60 s wave timer (killed 0 of 12 times by ranged,
  summon and status at Umfrage 35 %), he deals as much or more damage per minute (35 %: ranged 0.78 vs her
  0.66 × max HP), and ~70 % of her damage was unavoidable push-ring chip damage.
- **Median kill time, solo (before → after):** ranged 37 → 49 s / 59 → 71 s / 133 → 155 s at 10 / 20 / 35 %;
  summon 109 → 96 / 89 → 134 / 104 → 145 s; status 81 → 123 / 66 → 126 / 392 → 201 s. 4 players at 20 %:
  ranged 60 → 77 s, summon 50 → 87 s. Immortal ranged 50 / 58 / 113 → 60 / 71 / 138 s.
- **Pressure at 35 %:** damage taken per minute ranged 0.66 → 1.13, summon 0.42 → 0.71 (Sauerländer 0.78 /
  0.72); time inside a danger zone 0.14 → 0.25 and 0.10 → 0.26. First tries lost at 35 %: ranged 1 → 2 of 4.
- **Open:** summon and status lose much damage in phase 3 (stands and zones stay behind while they walk to the
  letterboxes and the safe strips; immortal summon at 20 % 90 → 309 s); melee still can't finish her (open
  questions); at 10–20 % the bot hardly ever loses a first try, humans will. Check in playtests.

## 8. Retry for boss waves (option)

- Lobby option for the host, **"Boss-Wiederholung"** (off by default), part of the run config.
- Only in waves with an elite or boss (5, 10, 15, 20). If the whole team is down or dead
  there, the wave **starts over** instead of ending the run:
  - everyone is revived with full HP at the arena center
  - enemies, projectiles, hazards and pickups are cleared
  - the wave timer and the encounter start again (boss intro included)
  - items, weapons, stats and Pfand stay as they are
- Unlimited retries. The end screen shows how many were used; such a win still counts.

## 9. Where ground weapons land (D-113)

- Ground weapons (`Content.PLACED_KINDS`: Kleber puddle, Kartoffelbrei lob, Brandmauer-Ziegel
  wall) land on the **densest group in range**: of the 16 nearest enemies in range that the
  player can see (not behind an intact wall), the one with the most enemies within the
  zone's radius (wall: half its width); the zone lands on the centre of that group, never
  beyond the weapon's range. With one enemy it's the old rule (on the target).
- `Content.BALANCE.place = "cluster"`; `target`, `lead` and `between` stay available as
  `Sim.place_mode` / `place=` for A/B runs (§2).
- Why (A/B, bot 3, solo, status/status-Oma/summon/ranged × Umfrage 10/20 % × 4 seeds, 32 runs
  per side, delivery per cast vs `target`):

  | Side | Kleber dmg/cast | Kleber enemy-s/cast | Kleber busy | Ziegel dmg/cast | Kartoffelbrei dmg/cast | mean wave B−A |
  |---|---|---|---|---|---|---|
  | target (old) | 114 | 2.34 | 48 % | 316 | 46 | — |
  | lead (0.5 s / delay) | 97 | 2.82 | 56 % | 227 | 46 | −0.97 ± 1.39 |
  | **cluster** | **180** | **3.64** | **58 %** | **379** | **160** | −0.16 ± 1.11 |
  | between | 32 | 1.97 | 37 % | 140 | 14 | −1.59 ± 0.71 |
  | target, zones ½ as long at 2× dps | 120 | 1.53 | 62 % | 292 | 46 | −0.50 ± 0.87 |

  Cluster is the only variant that raises every ground weapon's damage per cast (Kleber
  +58 %, Ziegel +20 %, Kartoffelbrei ×3.5, which was the weakest ranged weapon per Pfand);
  run outcomes stay within noise (ranged and summon are at the win ceiling). Shorter,
  stronger zones gain nothing; leading on velocity loses because chasers walk toward
  the player out of the zone's centre; "between" lands in empty space.
