# Status Report: Brandmauer

**As of:** 2026-11-05 · **Version:** 0.5.1-beta

## Done

| Area | Status |
|---|---|
| **Run** | 20 waves with ramping length (30 s to 60 s), elites in waves 5/10/15, final boss in wave 20 (Die Remigrantin); boss intro pause until every player presses W/A/S/D or Space; Umfrage levels 10 to 35 % |
| **Characters** | 8 playable plus Die Töchter as unlock, each with a passive and an ultimate (Space, once per wave); 3 Organisationen; Zusammenhalt with 5 stages; revives |
| **Weapons** | 31 weapons with tiers I to IV (incl. 8 status/summon weapons and 3 enemy status effects from v0.4, D-091 to D-096); combining (auto on buy, button, confirmation); selling with confirmation; tiers shown in the rarity colors (D-147) |
| **Items** | 69 items (incl. 2 hidden) in 4 rarities (green, blue, purple, red) with wave-dependent shop weights; the 8 politics items reach the shop since v0.5 (D-150); 12 red items, reworked in v0.4.1 so each pays back its price (D-127 to D-136); throwing items away |
| **Targeting** | no lead aiming; option Zielauswahl (closest, most HP, least HP); weapons face their target; line of sight through wall holes |
| **Co-op** | Koalitionskasse (25 % Kapitalertragsteuer, repairs from the Kasse, Steuermoral); Koalitionsvertrag (13 options since v0.5, D-155) with vote or abstain before "Bereit"; co-op-only content hidden in solo |
| **Späti** | Brandmauer repairs, rerolls, Reservieren (an offer keeps its slot and price for the next Späti, also by gamepad, D-148, D-153), offer mix with at most 3 weapons (D-149), statistics panel with the last wave on top and teammates side by side (D-152), item discarding |
| **UI** | main menu (rotating strong quote, "Bug melden", "Weiterspielen" for the saved run, D-162), host/join dialogs with LAN list, lobby, pause, end screen, Zitat-Album, achievements (8), credits in Amtsdeutsch; options: Musik, Geräusche, Zielauswahl, Fenstermodus, Sprechblasen-Transparenz, Eigene Effekte (Transparenz) |
| **Texts** | German only, all person-related terms gendered with a colon; real quotes unchanged except marked censoring of slurs (D-156); 95 curated verified quotes, shipped as the slim `research/zitate_spiel.json` (D-159); no real quotes as speech bubbles during waves |
| **Easter eggs** | BLACKROCK, Vogelschiss, Reichsausweis, Sylt hum, small and rare Funkloch |
| **Networking** | solo, host, client and dedicated server (`--server`); UPnP; LAN discovery; version handshake; quantized snapshots with interpolation and client prediction |
| **Graphics and audio** | everything drawn procedurally (doodle style), frame cap 144 FPS; CC BY music with crossfades, synthesized sound effects, remixed in v0.5 (audio.md, D-151: Pfand scale, tiered buy sounds, priority voices, limiter and ducking, option for teammates' sounds; values pending the listen test) |
| **Tests and CI** | headless tests (sim, snapshot, net, lobby, audio, content, game flow), net smoke test, e2e bot playthrough; release workflow for Windows, Linux, macOS, Linux Server |

| **Boss rules** | phase lock with Pressekonferenz at 66 % / 33 %, random targets every 4–7 s, half stuns + Standfest, stuns interrupt casts ("UNTERBROCHEN"), 40 % slow cap on bosses, boss-only HP lever; new abilities Wende rework, Abstimmung (holes + Plenum circles), Kahlschlag, Die Brandmauer hält; cast shown in the boss bar (GDD §14, D-102 to D-112). v0.4.1: Die Remigrantin as the final exam with Ansturm-Kette, Reichweite (safe only in front of intact wall), Briefkastenfirmen and the Wahlabend soft enrage (D-140 to D-146) |
| **Tests and CI areas** | every test file declares its areas; locally and on PRs only the touched areas run, `main` runs everything (ci-cd.md §2a, D-125) |

## In progress

- **Network resilience:** robustness against dropped connections and reconnects (players who are away don't block the Späti or the boss intro).
- **New UI features:** polish of the statistics panel, options and shop dialogs.

## Beta releases

- Released: `v0.2.0-beta` to `v0.2.2-beta`, `v0.3.0-beta`, `v0.4.0-beta` (new weapons, boss rules, summon area damage, balancing round D-113 to D-122); `v0.4.1-beta` (final boss rework, red items, tier colors, controller fixes, test areas); `v0.5.0-beta` (Reservieren, offer mix, sound redesign, statistics rework, six new Koalitionsverträge, staggered weapon copies, Pfandflasche buff, Pressekonferenz banner, slim quote data; network protocol 8); current: `v0.5.1-beta` (Weiterspielen: run save with continue from the main menu, D-162; Wellen-Wiederholung, D-163; Boss-Wiederholung restarts from the wave start, D-165; retry bug fix D-164; network protocol 9, so older versions can't join).
- Each tag `v*` runs the release workflow; a tag containing `-` becomes a GitHub pre-release.
- Downloads: a **plain Windows exe** (double-click, no installation, unsigned so SmartScreen warns) plus **zips** for Windows, Linux, macOS and the Linux server.
- Bug reporting: the **GitHub bug-report template** and the **"Bug melden" button** in the main menu. The log file path is in the release notes.
- Release notes for testers in `.github/release-notes.md` (start, co-op, bug reports).

## Balancing

The user asked to **keep the current balancing as the baseline**: solo at the top Umfrage feels hard in normal waves, and that should stay. v0.4.0 tuned bosses (more HP, final boss 50–60 s for strong builds), status/summon delivery and the new weapons with the balance bot; v0.4.1 made the final boss the hardest fight (about 145–155 s for ranged and summon at 35 %) and reworked the red items (summary in [balancing.md](specs/balancing.md) §2, raw runs in `balance/runs/`). It is refined incrementally with feedback from more playtesters. The levers are spawn rate and enemy damage in `sim.gd` and the numbers in `content.gd`.

## Open points

See [open-questions.md](open-questions.md): remaining music tracks, a real band, join codes / NAT punch-through, macOS signing, an installer, an English version, more unlock characters, item ideas not yet built, single-source quotes to verify, playtests with affected groups, a legal check, balancing with more playtesters.
