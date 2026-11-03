# Sound effects: mix, rewards and implementation plan

**Status: Implemented** (D-151); the values are pending the listen test (§8). §1 describes
the v0.4.1 state it replaced. Music is out of scope (GDD §20).

Goal: weapon hits, Pfand, kills and purchases should feel rewarding. Combat noise stays in the
background, and the important sounds (level-up, down, boss) always get through.

## 0. Principles

1. **Rewards are made by contrast.** Routine sounds (shots, hits) are quiet, short and capped.
   Reward and alert sounds are louder, tonal and never cut off. Today every file peaks at the
   same level, so a shot is as loud as a level-up.
2. **Rising pitch marks a streak.** Pfand picked up in quick succession climbs a scale (the
   Peggle technique, sources 1–2). A streak you can hear makes you want to keep it going.
3. **Vary the routine, keep the cues.** Frequent combat sounds get variants and some pitch
   and volume spread against fatigue (sources 3, 6). Tonal cues (level-up, ka-ching, Pfand
   notes) are never detuned, so they stay recognisable and fit the music.
4. **A hit has three layers.** A short bright transient, a body, and a tail only for
   special hits like crits (sources 4–5).
5. **Your own sounds come first.** In co-op your shots, hits and Pfand are full volume, and
   your teammates' are quieter (a new option, §5). Team events (level-up, down, boss) are
   heard by everyone.
6. **Reward sounds only for real gains** (source 13: win sounds make players overestimate
   how often they won). Losses never get a reward sound: Maut deductions, Pfand spent on
   rerolls, a Wende. Being honest about this fits an anti-capitalist satire.

## 1. Current state (v0.4.1)

`tools/gen_sfx.py` renders 20 WAVs (stdlib Python, seeded, 16-bit mono, **22050 Hz**) into
`assets/sfx/` (D-040). Each file is peak-normalized to −1 dBFS.

`src/autoload/audio.gd` plays them:
- a 12-voice round-robin pool
- ±5 % pitch jitter on every sound
- anti-spam: at most 4 plays of the same id per 50 ms
- a 70 ms kill throttle
- distance falloff around the local player (full volume up to 200 px, silent at 900 px)
- buses Master → Music and SFX, with no effects

### 1.1 Bugs (each gets a regression test, §7)

| # | Bug | Where |
|---|---|---|
| B1 | **Hit and crit sounds are never played.** `hit.wav` and `crit.wav` exist, nothing emits them, and `Audio._on_events` ignores the `dmg` event | `audio.gd _on_events`; `sim.gd _damage_enemy` emits `["dmg", …]` only |
| B2 | **Kill plays twice.** The sim emits `["kill", pos, type]` and `["sfx", "kill", pos]`, and Audio turns both into a `kill` sound. It sounds like a flam and adds up to +6 dB | `sim.gd _kill_enemy` |
| B3 | **Seven event sounds play twice.** `EVENT_SFX` maps the events `wave_start`, `wave_end`, `levelup`, `down`, `revive`, `wende` and `streik` to sounds, and the sim emits an extra `["sfx", <same id>, …]` right after each of them. Down and revive are played once positional and once not | `audio.gd EVENT_SFX`; `sim.gd` start/end wave, `_add_xp`, `damage_player`, revive, Wende, Streik request |
| B4 | **Buy plays twice for the buyer.** `spaeti.gd _on_buy` plays `buy` locally, and the sim broadcasts `["sfx", "buy", INF]` to everyone | `spaeti.gd _on_buy`; `sim.gd` request `buy` |
| B5 | **Vote plays twice for the voter** (locally and from the sim broadcast) | `spaeti.gd _on_vote`; `sim.gd` request `vote` |
| B6 | **A combine plays `levelup` for everyone**, including teammates who aren't combining | `sim.gd _combine` |
| B7 | **Long sounds get cut off.** With 4 players × 6 weapons, the 12-voice round-robin turns over in about 150 ms. Boss intro, level-up and wave fanfare are stopped by shot sounds | `audio.gd play_sfx` |

### 1.2 Weaknesses
- No loudness hierarchy and no limiter, so 12 overlapping voices can clip.
- The Pfand clink is inharmonic (glass partials), sounds the same every time and isn't tied to
  streaks. A teammate's pickup sounds exactly like your own.
- Naive square waves at 22 kHz alias, so highs sound harsh. The 6.8× partial of the pickup
  (16–17.7 kHz) folds back to about 4–6 kHz.
- ±5 % jitter is almost a semitone on tonal sounds, so they clash with the music.
- Sell uses the purchase sound. Kasse and repair also use `buy`.

## 2. Sound table (target)

Every sound id gets one row in a data table `Audio.SFX` (replacing `SFX_IDS`). Columns:

- **Peak:** the render level in `gen_sfx.py`, replacing normalization to −1 dBFS.
- **Bus:** see §3.
- **Prio:** 1 combat < 2 feedback < 3 alert/UI < 4 reward/event < 5 big event.
- **Cap:** the most voices of this id at once.
- **Gap:** the minimum time between two starts of this id; a start inside it is dropped.
- **Pitch / Vol:** random spread per play (Vol in ±dB).
- **Mates:** extra gain when a teammate caused the sound, on top of the option (§5). "—" means
  teammates don't hear it. "team" means everyone hears it at full volume.
- **Var:** number of rendered variants (`<id>_<n>.wav`, picked at random, never the same one
  twice in a row).

| Id | Peak dBFS | Bus | Prio | Cap | Gap ms | Pitch | Vol | Mates | Var | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| `shoot` | −16 | Combat | 1 | 3 | 25 | ±8 % | ±1.5 | −12 dB | 3 | sim `sfx` with peer |
| `melee` | −13 | Combat | 1 | 3 | 25 | ±8 % | ±1.5 | −12 dB | 3 | sim `sfx` with peer |
| `hit` | −14 | Combat | 1 | 3 | 35 | ±8 % | ±1.5 | — | 3 | `dmg`, own, not crit (§4.2) |
| `crit` | −8 | Combat | 2 | 2 | 70 | ±3 % | 0 | −12 dB | 1 | `dmg`, crit (§4.2) |
| `kill` | −11 | Combat | 2 | 3 | 40 | 0 | ±1 | −12 dB | 3 | `kill` event (§4.3) |
| `kill_elite` | −5 | Event | 4 | 1 | — | 0 | 0 | −6 dB | 1 | `kill` event with elite (§4.3) |
| `explosion` | −8 | Combat | 2 | 2 | 60 | ±6 % | ±1 | positional only | 2 | sim `sfx` |
| `pfand_0` … `pfand_10` | −10 … −11.2 (§4.1) | Reward | 2 | 4 (all notes together) | 35 | 0 | 0 | see §4.1 | — | sim `sfx pickup` with peer (§4.1) |
| `pfand_top` | −9 | Reward | 4 | 1 | — | 0 | 0 | — | 1 | top of a Pfand streak (§4.1) |
| `hurt` | −6 | Event | 3 | 1 | 150 | ±4 % | 0 | −9 dB | 1 | sim `sfx` with peer |
| `down` | −3 | Event | 5 | 2 | — | 0 | 0 | team | 1 | `down` event |
| `revive` | −4 | Event | 4 | 2 | — | 0 | 0 | team | 1 | `revive` event |
| `levelup` | −4 | Event | 4 | 1 | — | 0 | 0 | team | 1 | `levelup` event (§4.5); level-up pick in the Späti (local) |
| `wave_start` | −3 | Event | 5 | 1 | — | 0 | 0 | team | 1 | `wave_start` event |
| `wave_end` | −4 | Event | 5 | 1 | — | 0 | 0 | team | 1 | `wave_end` event |
| `boss_intro` | −2 | Event | 5 | 1 | — | 0 | 0 | team | 1 | `card` event |
| `wende` | −7 | Event | 4 | 1 | — | 0 | 0 | team | 1 | `wende` event |
| `streik` | −12 | Event | 4 | 2 | — | ±2 % | 0 | team | 1 | `streik` event; sim `sfx` for the Gewerkschaft ultimate and the failed boss vote |
| `vote` | −8 | UI | 3 | 2 | 60 | ±4 % | 0 | −6 dB | 1 | local on your vote; sim `sfx` with peer for others (§4.6) |
| `buy_1` … `buy_4` | −6 / −5 / −4 / −2 | Reward | 4 | 1 | — | 0 | 0 | — | 1 each | local in the Späti, by tier/rarity (§4.4) |
| `sell` | −8 | UI | 3 | 1 | — | 0 | 0 | — | 1 | local in the Späti |
| `combine_2` … `combine_4` | −4 / −3 / −2 | Reward | 4 | 1 | — | 0 | 0 | — | 1 each | `combine` event, own only (§4.4) |
| `ui_click` | −14 | UI | 3 | 2 | 30 | ±2 % | 0 | — | 1 | UI |
| `error` | −10 | UI | 3 | 1 | 100 | 0 | 0 | — | 1 | UI |

Ids that go away:
- `pickup` is replaced by the `pfand_*` notes. The options slider preview (`options.gd`) plays `pfand_4` instead.
- `buy` is replaced by `buy_1`…`buy_4`. Kasse in/out and repair use `buy_1`.

The architecture §8 id list is updated when this is implemented.

Starting values for the listen test (§8): the Peak column. Relative levels matter more than
absolute ones; the master and SFX sliders stay as they are.

Wende and Streik peak lower than the other events because they are near-pure sustained tones
(crest factor about 5 dB). At −5 dBFS they measured 4–9 LU louder than the level-up, and the
Streik whistle was louder than the down alert (§9).

## 3. Mixer

### 3.1 Buses
```
Master
├── Music
└── SFX                    (user slider "Geräusche"; AudioEffectHardLimiter, ceiling −1 dB, release 0.1 s)
    ├── SFX_Combat         (AudioEffectCompressor, sidechain = SFX_Event: threshold −14 dB,
    │                       ratio 3, attack 2 ms (Godot's maximum), release 300 ms → about −6 dB
    │                       while an event sound peaking at −4 dBFS plays)
    ├── SFX_Reward
    ├── SFX_Event
    └── SFX_UI
```
- The buses are created in code (`_ensure_bus` already does this for Music and SFX). There is no
  `default_bus_layout.tres`, so tests and headless runs stay unchanged.
- **Music ducking is on, and the listen test decides whether it stays:** a compressor on Music
  with sidechain SFX_Event, threshold −14 dB and ratio 1.6, so about −3 dB during the boss
  intro, down and level-up. The constants are `DUCK_THRESHOLD_DB`, `DUCK_RATIO` and
  `MUSIC_DUCK_RATIO` in `audio.gd`; ratio 1.0 turns it off.

### 3.2 Voices
- **Pool:** 24 `AudioStreamPlayer`s; each one remembers `id`, `prio` and its start time.
- **Choosing a voice for a new sound:**
  1. **Gap:** if the id started less than its Gap ago, drop the new sound.
  2. **Cap:** if the id already plays Cap times, restart its oldest voice of that id.
  3. **Free voice:** otherwise take one that isn't playing.
  4. **Steal:** otherwise take the voice with the lowest prio that is ≤ the new prio, oldest
     first. If every voice has a higher prio, drop the new sound.
- **Combat share:** prio 1 sounds use at most 12 voices together. So a firefight never takes
  more than half the pool, and a level-up always finds a voice.
- This replaces `SPAM_WINDOW_MS`, `SPAM_MAX`, `KILL_THROTTLE_MS` and the round-robin. It is a
  pure function (`pick_voice(voices, id, now_ms) -> int`, -1 = drop), so it can be tested
  headless (§7).

### 3.3 Volume per play
`gain_db` = table Vol jitter + distance + mate gain.
- **Distance:** `distance_gain()` as today, only for positional sounds caused by someone else.
  Your own sounds are never distance-attenuated (today they happen to be, at distance 0).
- **Mate gain:** the table's Mates value + the option (§5).
- **Pitch:** `pitch_scale = 1 + randf_range(-p, p)`, with p from the table. 0 means no jitter.

## 4. Sounds in detail

### 4.1 Pfand streak (the main reward)
- **Event:** the sim's `["sfx", "pickup", pos, peer]` for a Pfand or Geld pickup (§6). Audio
  plays a note only when `peer == local_id`.
- **Streak state:** `{"step": int, "last_ms": int, "topped": bool}`, local to Audio. The pure
  helper `pfand_step(state, now_ms) -> int` returns the note index, or −1 when merged:
  - If `now_ms - last_ms < 35` (Gap): return −1. The pickup is merged into the last note and
    doesn't advance the streak, so a burst of six elite drops doesn't skip half the scale.
  - If `now_ms - last_ms > 600`: the streak resets (`step = 0`, `topped = false`).
  - Otherwise `step = min(step + 1, 10)`. The top note holds while the streak goes on.
  - `last_ms = now_ms`.
- **Notes:** `pfand_0` … `pfand_10` follow the major pentatonic, semitones
  `[0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]` above the root `PFAND_ROOT = KEY_ROOT = 392 Hz` (G4),
  so the top note is G6 (1568 Hz). The root comes from the key analysis of the music (§9). G A B D E
  fits the most gameplay tracks (D major, A minor, E major, D minor). G4 instead of G5 keeps the
  top note out of the piercing range.
- **Equal loudness:** the per-note peaks are trimmed by a 45/55 blend of the ISO 226 70-phon
  contour and K-weighting, so the loudness spread is about 2 LU. The octave partial thins from
  −10 to about −15.6 dB toward the top.

  | Note | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
  |---|---|---|---|---|---|---|---|---|---|---|---|
  | Peak dBFS | −10.00 | −10.20 | −10.39 | −10.59 | −10.75 | −10.99 | −11.09 | −11.19 | −10.78 | −10.61 | −10.53 |
  - Each note is rendered as its own file. `pitch_scale` would make high notes too short.
  - Pentatonic avoids the worst clashes with any key the music is in. The root is one constant
    in `gen_sfx.py`, so the listen test can move it.
- **A note:** triangle body + sine one octave up (−10 dB) + 3 ms noise tick high-passed at 4 kHz
  (−12 dB). 2 ms attack, 70 ms exponential decay, 140 ms long. Harmonic, unlike today's glass clink.
- **Top of the streak:** the first time a streak reaches step 10, `pfand_top` plays once on top
  of the note: a short shimmer of two pentatonic notes 2 octaves up with tremolo, 0.3 s. It
  plays again only after a reset.
- **Teammates' pickups:** `pfand_0` with Mates −8 dB, which comes to about −14 dB at the
  default option of 50 %. Positional, without a streak; the streak state stays your own.
  Whether teammates' pickups should make a sound at all is an open question.
- **No sound for Pfand losses** (Maut, reroll, a deduction).

### 4.2 Hit and crit
- **Event:** `["dmg", pos, amount, crit, to_player, peer]` (§6). Audio ignores `to_player = true`,
  because the player's own hurt sound comes from the sim (`hurt`).
- **Hit** (not crit, `peer == local_id`): `hit_0..2`, at most 80 ms.
  - 1 ms noise click, high-passed at 3 kHz.
  - Body: a band-limited square (PolyBLEP, §4.8) falling 300 → 120 Hz, 40 ms decay.
  - The variants differ by ±2 semitones and click brightness.
  - Teammates' plain hits aren't played. In a 4-player fight they would drown out everything else.
- **Crit** (any peer; teammates −12 dB): `crit`, at most 200 ms.
  - 1 ms bright click (high-passed at 5 kHz).
  - 70 Hz sine thump with 80 ms decay.
  - From 10 ms: a short ring, triangle at 1975 Hz (B6, in key) band-passed with 50 ms decay.
  - A soft hit body underneath, so a crit is also a hit.
  - A crit always beats a plain hit: they share a frame → play only the crit.
- **DoT and zone damage** (`_damage_dot`, poison, Kleber, …) emit no `dmg` event today. That
  stays so; ticks must never make sounds.
- `DMG_EVENTS_PER_FRAME` (24) stays. Audio's Gap/Cap limit the hit sound further.

### 4.3 Kill and elite kill
- **Event:** `["kill", pos, enemy_type, peer, elite]` (§6). The extra `["sfx", "kill", pos]` is
  removed (B2).
- **Kill** (`kill_0..2`, 120 ms):
  - a pop: PolyBLEP square 700 → 150 Hz, 40 ms decay
  - a puff: noise low-passed 5 kHz → 400 Hz, 30 ms decay
  - a tonal tick a fifth above the pop's end pitch (225 Hz, triangle, 30 ms), kept out of the
    Pfand band
  - The variants sit at −1 / 0 / +1 semitone. The old vibrato "boing" goes away.
- **Elite kill** (`kill_elite`, 0.45 s, instead of `kill`):
  - a "coin burst": `pfand` notes 4, 7, 9 at 0 / 40 / 80 ms, mixed into the file
  - a 60 Hz thump
  - It plays on the Event bus, so the ducking (§3.1) dips the combat noise for a moment.
- **Bombs and `no_reward` kills:** keep the `kill` event (the view needs it), no sound
  (`elite = false`, flag `quiet`; see §6).
- **Boss units** (`encounter != ""`) emit no `kill` today. A boss-defeat fanfare is an open
  question.

### 4.4 Späti: ka-ching by tier, sell, combine
Tier and rarity use the colors 1–4 (D-147), and the Späti knows the offer locally, so no network
change is needed. The sim no longer broadcasts `buy` (B4).

| Id | Content | Length |
|---|---|---|
| `buy_1` | lever clack + drawer rattle + a **harmonic** bell "ching" (partials 1, 2, 3, 4.2 instead of the inharmonic 2.76/4.07) | 0.7 s |
| `buy_2` | `buy_1` + a fifth one bell later (60 ms) | 0.8 s |
| `buy_3` | `buy_1` + fifth + octave rising (60 ms apart) | 0.9 s |
| `buy_4` (red) | `buy_1` + major arpeggio root–third–fifth–octave (50 ms apart) + 60 Hz thump on the octave + 0.6 s shimmer (triangle two octaves up, 9 Hz tremolo) | ≤ 1.3 s |
| `sell` | a bell falling a fourth + a short coin rattle, no thump | 0.5 s |
| `combine_2` / `_3` / `_4` | two clinks 50 ms apart, then a chord of the new tier: a dyad / a triad / a triad + octave + thump | 0.6–0.9 s |

- `spaeti.gd _on_buy` plays `buy_<tier>`: the weapon tier, or `rarity` for items. It plays once,
  locally, before the request, as today.
- `_on_sell` plays `sell`. Kasse in/out and repair play `buy_1`.
- **Combine** comes from the `combine` event `[peer, id, tier]` and plays only for
  `peer == local_id`, because a combine also happens on a buy with a twin. The sim's
  `["sfx", "levelup"]` in `_combine` is removed (B6). If a buy combines, the buyer hears
  `buy_<tier>` and then `combine_<tier+1>` about 0.1 s later. The voice rules (prio 4, cap 1 per
  id) let both play.

### 4.5 Team level-up
- `levelup`: a triangle + soft saw chord (root, third, fifth, octave, gently rolled over 60 ms),
  held 0.5 s, with an octave shimmer on top. 0.7 s long.
- **Rising within a wave:** each further team level-up in the same wave plays 2 semitones higher
  (`pitch_scale = 2^(2k/12)`, k = 0…3, then it stays). It resets on `wave_start`. This builds
  anticipation, and the release comes at the Späti.
- The level-up pick in the Späti (`spaeti.gd _on_levelup`) plays `levelup` at k = 0, locally.

### 4.6 Shots, melee, hurt, vote
- `shoot` and `melee` from the sim carry the peer (§6). Your own play at full volume without
  distance; teammates' are −12 dB, distance-attenuated. The cap of 3 voices means rapid fire
  never piles up.
- `hurt` has the hit player as peer. Your own plays without distance; teammates' are −9 dB, positional.
- `vote`: the voter hears it locally from `_on_vote`. The sim's `["sfx", "vote", INF, peer]` is
  skipped for `peer == local_id` (B5), and teammates hear it at −6 dB as "someone voted".
- **Shot and melee moved out of the reward band** (§9 masking): `shoot` is a low "thup"
  (square 340 → 100 Hz, low-passed at 700 Hz, plus a 3 kHz click) instead of the old 1500 Hz
  "pew". The `melee` swish sits above 2.5 kHz. The hit body falls fast and is low-passed at 1.2 kHz.
- **Others unchanged in content**, only re-rendered with the quality pass (§4.8): explosion, down,
  revive, wave_start, wave_end, boss_intro, wende, streik, ui_click, error.
- **One key for all tonal cues:** level-up, wave fanfares, revive sparkle, the buy ching, sell,
  combine chords and the crit ring are semitone offsets from `KEY_ROOT` in `gen_sfx.py`. One
  constant re-tunes them all. Boss intro, down, hurt, Wende, Streik and error keep fixed pitches.

### 4.7 Jitter
Spread per play only on combat and noise sounds (table §2). Tonal sounds play at exactly their
pitch:
- levelup, wave_*, boss_intro, buy_*, combine_*, pfand_*, kill_elite, revive, down, wende, sell, error

Variants (§2 Var) replace part of the jitter on the most frequent sounds.

### 4.8 Synthesis quality (`tools/gen_sfx.py`)
- **`RATE = 44100`.**
- **Band-limited squares and saws (PolyBLEP)** instead of naive ones. `osc()` gets a
  `bandlimited=True` default; triangle and sine stay.
- **No partials above 0.45 × RATE.** `bell()` skips them.
- **High-pass at 150 Hz** on small sounds (shoot, hit, melee, kill, ui_click, pfand), against
  masking (source 12). Thumps (crit, buy_4, kill_elite, explosion, boss_intro) keep their lows.
- **Loudness tiers:** `finish(sig, peak_db)` normalizes to the Peak column (§2) instead of
  −1 dBFS.
- **Variants** come from the same function with a variant index: an index-dependent detune and
  seed. Files are named `<id>_<n>.wav`.
- **Stays deterministic:**
  - per-file seed `"brandmauer-sfx:" + file name`
  - running it twice gives byte-identical files
  - duration limits: 1.0 s, LONG 1.5 s (`buy_4` counts as LONG)
- **New asserts:** each file's peak is within ±0.3 dB of its tier, and nothing clips.
- New `.wav.import` files come from Godot's import, as before. The sounds are our own work, so
  no CREDITS entry.

## 5. Option "Geräusche der Mitspieler:innen" (GDD §19a)

| Option | Values |
|---|---|
| **Geräusche der Mitspieler:innen** | volume of the sounds your teammates cause (default 50 %, 0 % = off) |

- Saved as `teammate_sfx` (0..1) in `Save`, with a slider in `options.gd` below "Geräusche".
- The i18n keys `OPTIONS_TEAMMATE_SFX` and `OPTIONS_TEAMMATE_SFX_TIP` go in `i18n/ui.csv`:
  - "Geräusche der Mitspieler:innen"
  - "Wie laut Schüsse, Treffer und Pfand deiner Mitspieler:innen sind. Wellen, Level-ups und Notrufe hörst du immer."
- It multiplies every sound with a Mates value in the table. Sounds marked "team" stay at full volume.
- It's a local setting, like "Eigene Effekte". It changes nothing for the others, and in solo
  it has no effect.

## 6. Contract changes (architecture §5, §8; networking)

| Event | Today | New |
|---|---|---|
| `sfx` | `[id, pos]` | `[id, pos, peer]`, where peer is the player who caused it, 0 = world or enemy. With peer: `shoot`, `melee`, `hurt` (the hit player), `pickup` (the collector), `vote`, `streik` (the ultimate's player) |
| `dmg` | `[pos, amount, crit, to_player]` | `[pos, amount, crit, to_player, peer]`, where peer is the attacker (enemy damage) or the hit player (`to_player`), 0 = none |
| `kill` | `[pos, enemy_type]` | `[pos, enemy_type, peer, elite, quiet]`, where peer is the killer (0 = none), `elite = e.elite`, and `quiet = true` for bombs and `no_reward` |

Removed from the sim:
- `["sfx", "kill"]`
- the extra `["sfx", <id>]` after the events `wave_start`, `wave_end`, `levelup`, `down`,
  `revive`, `wende` and `streik` (Audio plays these from the event)
- `["sfx", "buy"]` (the Späti plays it locally)
- `["sfx", "levelup"]` in `_combine`

**One sound path per event:** Audio maps semantic events (`EVENT_SFX` plus §4). The sim emits
`sfx` only for sounds without a semantic event of their own: shoot, melee, hurt, pickup, vote,
explosion, and streik from the ultimate and the failed boss vote.

**Protocol:** bump `PROTOCOL_VERSION` (networking.md), because the event payloads change. The
snapshot is unchanged. Events are reliable, batched per frame and lost while a client is away
(networking §7); sounds tolerate that.

**Audio API** (architecture §8), new or changed:
```
func play_sfx(id: String, pos := Vector2.INF, peer := 0)   # peer 0 = world; own = no distance
func set_teammate_volume(v: float)                          # 0..1, from Save "teammate_sfx"
static func pfand_step(state: Dictionary, now_ms: int) -> int
static func pick_voice(voices: Array, id: String, now_ms: int) -> int
static func plan_events(events: Array, local_id: int, state: Dictionary, now_ms: int) -> Array  # [[id, pos, gain_db, pitch], ...]
```
`plan_events` holds all the mapping logic from §4 as a pure function. `_on_events` only plays
its result. So everything can be tested headless, where Audio is disabled.

## 7. Implementation plan

Work packages in order. WP1 is a pure bug fix and can ship alone in a patch. WP2–WP8 belong
together in a sound update; one PR or several in this order. Spec first applies throughout: on
starting, write D-151 into the decisions log as "implemented", and update architecture §5/§8,
GDD §19a and §20, and networking.

### WP1: one sound per action (B2–B6) (S)
- **Steps:**
  - In `audio.gd`, extract `plan_events()` (for now with today's mapping) and add an optional
    `peer` to `play_sfx`.
  - In the sim, remove the double `sfx` events (§6) and add the peer to `vote`.
  - In `spaeti.gd`, play buy and vote once, locally.
  - In `_combine`, replace `levelup` with the `combine` event mapping (for now on the old
    `levelup` sound, own only).
- **Tests:**
  - New `test_audio_events.gd` (AREAS `["audio", "sim"]`) runs real sim actions and feeds the
    collected events into `plan_events(…, local_id = 1)`:
    - kill an enemy
    - team level-up
    - start and end a wave
    - down and revive
    - Wende
    - Streik (ultimate and request)
    - buy, vote and combine in the Späti
  - Each action must give **exactly one** play of its sound. A buy and a vote give **zero** from
    the sim, because the UI plays them.
  - Check that the test fails on today's code (CLAUDE.local.md).

### WP2: mixer: tiers, limiter, voices, jitter (S–M)
- **Steps:**
  - Add the `SFX` table (§2) to `audio.gd`.
  - Add a pool of 24 and `pick_voice()` (§3.2).
  - Add the sub-buses with the limiter and the combat compressor (§3.1).
  - Jitter per table (§4.7).
  - Remove the anti-spam constants.
- **Tests:**
  - `pick_voice`:
    - Cap restarts the oldest voice of the same id.
    - Gap drops.
    - With 24 busy combat voices, a `levelup` still gets a voice.
    - A shot never steals from a prio-4 voice.
    - Combat stays at ≤ 12 voices.
  - The table is complete: every id has bus, prio, cap and a file per variant.
  - `test_audio.gd`'s fixed count of 20 becomes a table check.

### WP3: peer in events, hit and crit (B1) (M)
- **Steps:**
  - Payloads per §6 in `sim.gd` (`_damage_enemy`, `damage_player`, `_kill_enemy`, shot and
    melee sites, pickup).
  - `plan_events` maps `dmg` to hit/crit (§4.2) and shot/melee/hurt to own/teammates (§4.6).
  - Bump the protocol.
- **Tests:**
  - Sim: `dmg`, `kill` and `sfx shoot` carry the right peer (two players, each one shoots).
  - Plan:
    - your own non-crit → `hit`
    - a teammate's non-crit → nothing
    - a teammate's crit → `crit` at −12 dB + option
    - `to_player` → no hit
    - crit and hit in the same batch → crit only
  - Net smoke (`tools/net_smoke.sh`) stays green.

### WP4: Pfand streak (M)
- **Steps:**
  - Render `pfand_0..10` and `pfand_top` in `gen_sfx.py`.
  - `pfand_step()` and the mapping (§4.1).
  - Remove `pickup`; the options slider preview plays `pfand_4`.
- **Tests:** `pfand_step`:
  - 0, 100, 200 ms → steps 0, 1, 2
  - +10 ms → −1 (merged)
  - 700 ms pause → 0
  - 15 quick pickups stay at 10
  - `pfand_top` exactly once per streak
  - a teammate's pickup doesn't change your streak

### WP5: kill, elite kill, level-up (S–M)
- **Steps:**
  - New `kill_0..2` and `kill_elite`; the elite/quiet mapping (§4.3).
  - New `levelup` chord with the per-wave rise (§4.5).
- **Tests:**
  - An elite kill → `kill_elite` and no `kill`.
  - A quiet kill → nothing.
  - The 2nd/3rd/5th level-up in a wave → pitch 2^(2/12), 2^(4/12), the cap 2^(6/12).
  - Reset after `wave_start`.

### WP6: Späti sounds (S)
- **Steps:**
  - `buy_1..4`, `sell`, `combine_2..4` (§4.4) in `gen_sfx.py`.
  - The calls in `spaeti.gd`.
- **Tests:** `test_spaeti_focus.gd` or a new UI test with a recording UIApi stub (`UIApi.sfx` is
  a static wrapper; add a test hook that records the ids):
  - buying a red item → `buy_4`
  - a tier-II weapon → `buy_2`
  - sell → `sell`
  - Kasse → `buy_1`

### WP7: synthesis quality (M)
- **Steps:**
  - 44.1 kHz, PolyBLEP, the Nyquist cut in `bell()`, high-pass, loudness tiers, variants (§4.8).
  - Re-render every file, then let Godot import them (the editor or `--import`).
- **Checks:**
  - `gen_sfx.py` asserts the peak per tier and the length.
  - Run it twice and compare the hashes.
  - `test_audio.gd` loads every file.

### WP8: option and docs (S)
- **Steps:**
  - The slider (§5), Save key, i18n keys.
  - Update the docs: GDD §19a, architecture §8 id list, release notes.
- **Tests:**
  - The option is saved and applied (`set_teammate_volume`).
  - In `plan_events`, a teammate's sound at option 0 gives nothing.

## 8. Listen test (manual, before the release)

`tools/sfx_board.gd` (windowed: `godot --path . -s res://tools/sfx_board.gd`) plays fixed
sequences through the real Audio mixer, with switchable music underneath. Each of the 48 files
also has its own button. `-- auto` prints the bus layout, plays every sequence once and quits;
together with `--audio-driver Dummy` it is a silent smoke test.

The sequences:
1. **Pfand streak:** 14 pickups 120 ms apart, then a 1 s pause, then 5 more.
2. **Firefight:** for 6 s, 4 players × shots every 80 ms + hits + 3 crits per second +
   2 kills/s. A level-up comes at 3 s and a down at 4.5 s; both must be clearly audible.
3. **Elite:** an elite kill + 6 Pfand drops.
4. **Späti:** buy_1 … buy_4 with 1 s between them, sell, combine_2 … combine_4, error.
5. **Events:** wave_start, wave_end, boss_intro, wende, streik, revive.

Acceptance by the user:
- Rewards are clearly louder than routine.
- Nothing clips.
- Nothing important is cut off.
- The Pfand scale fits the music.

Values change only in the §2 table and the `gen_sfx.py` constants.

## 9. Analysis (`tools/sfx_analyze.py`)

A dev tool (numpy, scipy, ffmpeg) that checks the rendered files against the music:
- `python tools/sfx_analyze.py`: per file the duration, sample and true peak, LUFS-M, DC, crest
  factor, centroid, and the band shares (sub < 60, low 60–250, low-mid 250–1k, mid 1–4k,
  presence 4–8k, air > 8k), plus energy above 16 kHz and the 2–5 kHz harshness share.
- `--music`: key and chroma per track (Krumhansl-Kessler), the pentatonic fit, and the music's
  band shares.
- `--mix`: a 4-player firefight for 6 s (shots every 80 ms, about 17 hits/s, 3 crits/s,
  2 kills/s) with the caps, gaps and jitter from §2, ducking, and the music at bus 0.5 vs SFX 0.8.
  It measures each cue in its main octave against the combat bed.
- `--all --passes`: everything, including the passed checks.

Results of the first full run (all checks pass, 294 PASS / 0 WARN):
- **Hierarchy:** shoot and hit are 15–19 LU below levelup, buy_1 and kill_elite. The loudest
  routine combat sound is −32 LUFS, the quietest reward −25.6. buy_1 → buy_4 and
  combine_2 → combine_4 rise in loudness, not only in peak.
- **Masking:** routine combat keeps its body below about 400 Hz and its clicks above 3 kHz, and
  the tonal rewards own 400 Hz–2.5 kHz. Every reward's main band is more than 6 dB above the
  routine combat energy there.
- **Music:** 60–85 % of the gameplay music's energy is in 60–250 Hz, only 4–11 % in 1–4 kHz, so no
  reward sits in the densest music band.
- **Firefight cues** (main octave, against combat / against combat + music): levelup +15.0 /
  +10.5 dB, Pfand streak +10.4 / +8.0, down +20.6 / +16.1, kill_elite +10.7 / +8.2. The tightest
  is `pfand_0` (+6.2 / +4.5): G4 shares its octave with the hit and shot bodies at the maximum
  hit rate. The mix peaks at −0.8 dBFS before the SFX limiter, so the limiter acts a little at
  the worst moments.
- **Clean:** no clipping (highest true peak −2.0 dBFS), DC under 1e-3, energy above 16 kHz under
  0.02 %, no sub-60 Hz energy on small sounds. The 2–5 kHz share is under 45 % everywhere except
  the Streik whistle (2.9 kHz by design).
- **Keys:** b_roll_ska E major, runaround D major, ska_track A minor, upbeat_forever D minor;
  boss ready_aim_fire A minor, summon_the_rawk E major, whats_it_to_ya_punk G major; menu B minor;
  Späti C major and D major. Average major-pentatonic fit over the gameplay tracks: G 0.497,
  D 0.493, C 0.471.

## 10. Sources
1. Peggle 2, ascending diatonic peg scales tied to the music: https://www.audiogang.org/peggle2-sonic-joy/
2. Peggle Blast, peg hits in harmony with the music: https://audiokinetic.com/fr/blog/peggle-blast-peg-hits-and-the-music-system
3. Random pitch against repetition: https://gamedeveloper.com/audio/the-power-of-pitch-shifting
4. Impact layering (transient, body, tail): https://violetrecording.com/how-to-make-impact-sounds/
5. Layering and sharpening the attack: https://www.liortega.com/post/first-person-shooter-gun-sound-design
6. Listener fatigue and variation: https://sounddesign.irpr.agency/solutions/game-audio-repetitive/
7. Voice limits per category, ducking: https://bugnet.io/blog/how-to-mix-game-audio-so-nothing-drowns-out
8. Priority and ducking: https://www.gamedeveloper.com/audio/game-audio-theory-ducking
9. Sidechaining: https://mcvuk.com/development-news/audio-guide-side-chaining-in-wwise/
10. Diablo 3 legendary drop sound and beam: https://di.diablowiki.net/Leg
11. Diablo designers on rare-drop sounds: https://mein-mmo.de/en/fathers-of-diablo-explain-how-they-invented-loot-in-video-games-that-makes-us-addicted,670631
12. Masking: https://sounddesign.irpr.agency/glossary/auditory-masking/
13. Dixon et al., win sounds inflate perceived wins: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4225056/
14. Juice and non-repetitive sound: https://gamejuice.pages.dev/articles/juice-it-or-lose-it-lessons
