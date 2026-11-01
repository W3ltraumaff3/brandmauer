# Status Report: Brandmauer

**As of:** 2026-11-01 · **Version:** 0.2.0-beta (in preparation)

## Done

| Area | Status |
|---|---|
| **Run** | 20 waves with ramping length (30 s to 60 s), elites in waves 5/10/15, final boss in wave 20 (Die Remigrantin); boss intro pause until every player presses W/A/S/D or Space; Umfrage levels 10 to 35 % |
| **Characters** | 8 playable plus Die Töchter as unlock, each with a passive and an ultimate (Space, once per wave); 3 Organisationen; Zusammenhalt with 5 stages; revives |
| **Weapons** | 12 weapons with tiers I to IV; combining (auto on buy, button, confirmation); selling with confirmation |
| **Items** | 57 items in 4 rarities (green, blue, purple, red) with wave-dependent shop weights; 8 red build items; throwing items away |
| **Targeting** | no lead aiming; option Zielauswahl (closest, most HP, least HP); weapons face their target; line of sight through wall holes |
| **Co-op** | Koalitionskasse (25 % Kapitalertragsteuer, repairs from the Kasse, Steuermoral); Koalitionsvertrag with vote or abstain before "Bereit"; co-op-only content hidden in solo |
| **Späti** | Brandmauer repairs, rerolls, statistics panel (damage by source, survival, misc), item discarding |
| **UI** | main menu (rotating strong quote, "Bug melden"), host/join dialogs with LAN list, lobby, pause, end screen, Zitat-Album, achievements (8), credits in Amtsdeutsch; options: Musik, Geräusche, Zielauswahl, Fenstermodus, Sprechblasen-Transparenz |
| **Texts** | German only, all person-related terms gendered with a colon; real quotes unchanged; 62 curated verified quotes; no real quotes as speech bubbles during waves |
| **Easter eggs** | BLACKROCK, Vogelschiss, Reichsausweis, Sylt hum, small and rare Funkloch |
| **Networking** | solo, host, client and dedicated server (`--server`); UPnP; LAN discovery; version handshake; quantized snapshots with interpolation and client prediction |
| **Graphics and audio** | everything drawn procedurally (doodle style), frame cap 144 FPS; CC BY music with crossfades, synthesized sound effects |
| **Tests and CI** | headless tests (sim, snapshot, net, lobby, audio, content, game flow), net smoke test, e2e bot playthrough; release workflow for Windows, Linux, macOS, Linux Server |

## In progress

- **Network resilience:** robustness against dropped connections and reconnects (players who are away don't block the Späti or the boss intro).
- **New UI features:** polish of the statistics panel, options and shop dialogs.

## Beta release plan: v0.2.0-beta

- Tag `v0.2.0-beta`; a tag containing `-` becomes a GitHub pre-release.
- Downloads: a **plain Windows exe** (double-click, no installation, unsigned so SmartScreen warns) plus **zips** for Windows, Linux, macOS and the Linux server.
- Bug reporting: the **GitHub bug-report template** and the **"Bug melden" button** in the main menu. The log file path is in the release notes.
- Release notes for testers in `.github/release-notes.md` (start, co-op, bug reports).

## Balancing

The user asked to **keep the current balancing as the baseline** (the user beat Umfrage 10 %). It is refined incrementally with feedback from more playtesters. The levers are spawn rate and enemy damage in `sim.gd` and the numbers in `content.gd`.

## Open points

See [open-questions.md](open-questions.md): remaining music tracks, a real band, join codes / NAT punch-through, macOS signing, an installer, an English version, more unlock characters, item ideas not yet built, single-source quotes to verify, playtests with affected groups, a legal check, balancing with more playtesters.
