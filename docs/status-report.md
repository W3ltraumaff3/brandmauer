# Status Report: Brandmauer MVP

**As of:** 2026-11-01 · **Branch/PR:** `feat/game-mvp` (#2)

## Done

| Area | Status |
|---|---|
| **Simulation** (`src/sim/sim.gd`) | All MVP mechanics from the GDD: 20 waves (30 s → 60 s), elites in waves 5/10/15 and the final boss in wave 20; 12 regular enemies with their own AI; 4 encounters with phases and exits; 12 weapons (shots, cones, orbit, puddles, turrets); 31 items including cursed ones; 9 characters with passives; 3 Organisationen; Koalitionskasse plus Steuermoral; Koalitionsvertrag (if the vote isn't unanimous, the worst option wins); revives; Zusammenhalt with 5 stages; 8 achievements; Brandmauer with voting and repairs; Streik; BLACKROCK easter egg |
| **Networking** | Solo, host, client and dedicated server (`--server`); UPnP; LAN discovery; version handshake; quantized snapshots (about 4.8 KB) with interpolation and client prediction |
| **Graphics** | Everything drawn procedurally in the doodle style: 17 enemy types, 9 characters × 5 posture stages, the arena going from grey to color, effects, encounter cards, exit animations; 144 fps in the stress test |
| **UI** | Main menu, host/join dialogs (LAN list), lobby (character selection with the unlock quote), Späti, pause, end screen with Steuermoral, Zitat-Album, achievements, options, credits (in Amtsdeutsch plus the CC attributions) |
| **Audio** | 9 CC BY tracks (menu, gameplay, Späti, boss) with crossfades; 20 self-synthesized sound effects |
| **Content** | All German texts (`i18n/*.csv`); 62 curated, verified quotes (`research/auswahl.json`) |
| **Tests and CI** | 52 headless tests (sim including full runs of every character and Organisation, snapshot, net, lobby, audio, content, game flow); two-process net smoke test; e2e bot playthrough of the real game; CI jobs: Quote data, Godot tests, Net smoke; release workflow (Windows, Linux, macOS, Linux Server) |

## Open: needs your decision

1. **Final boss name.** The placeholder is "Die Eidgenossin". Suggestions: *Die Remigrantin* (my favorite), *Heidi aus Einsiedeln*, *Frau Dr. Windmühle*, *Die Steuerexilantin*. It's one entry in `i18n/content.csv` (`ENC_EIDGENOSSIN_NAME`, `ENEMY_EIDGENOSSIN_NAME`).
2. **Quote selection.** 62 of 110 are in the game. The dropped ones and the reasons are in `research/auswahl.md`; please skim it.
   - Weak slots: no quote fits the Bierdeckel phase or the Steuerparadies phase; besorgter Bürger and Immobilienerbe have only one bubble quote each; the unlock quotes for Oma and Antifa are makeshift.
3. **Balance.** The data so far comes only from a fairly dumb bot (`tools/balance_probe.gd`): without cheats it reaches waves 3–21 at Umfrage 10%, with Lastenrad/Gewerkschaft/Stadtbild sometimes winning and Klimakleber struggling. **We need human playtests.** The levers are spawn rate and enemy damage in `sim.gd` (`_step_spawning`, `spawn_enemy`) and the numbers in `content.gd`.
4. **Release.** Should the first version get a tag (`v0.1.0` → public GitHub release with downloads)? The release workflow is ready.
5. **Music.** Four gameplay tracks are thin. Good candidates need a browser login or download:
   - "Mission Accomplished" (FMA)
   - "Braineating Zombies" (ccMixter, real ska punk, for bosses)
   - the DavidKBD itch.io packs (check the license)

   The current boss tracks are rock rather than ska. A real band remains an option (D-028).

## Open: technical

- **Join codes / NAT punch-through** aren't built. Today it's UPnP, IP or LAN only (networking spec §4).
- **macOS** is only ad-hoc signed (no Apple certificate), so Gatekeeper warns on first launch.
- **Bandwidth:** a listen host with 3 clients uploads about 2.2 Mbit/s. Delta compression would be the next step.
- **Unlock characters** beyond Die Töchter (Gen Z, Teilzeit-Mama, Taugenichts, Totalverweigerer …) are in the GDD as candidates but not built yet.
- **English US version:** the text structure is ready (CSV with one column per language), but the content isn't written yet.

## Before a public launch (content guidelines §6)
- Playtest with people from the affected groups.
- Have someone check the quotes and boss parodies legally.
