# Decision Log

Format: **ID · date · decision** — rationale. A decision is never edited; a new one supersedes it ("supersedes D-xxx").

| ID | Date | Decision | Rationale |
|---|---|---|---|
| D-001 | 2026-11-01 | Genre: arena roguelite in the vein of "arena survivor" games, with an original design | Fits short runs and many playstyles; small scope |
| D-002 | 2026-11-01 | German first (CDU/CSU, Merz, AfD); English US edition later | Focus |
| D-003 | 2026-11-01 | Engine: Godot 4 | Free, strong in 2D, cross-platform, built-in multiplayer, GDScript is close to Python |
| D-004 | 2026-11-01 | PC first; cross-platform later | Focus |
| D-005 | 2026-11-01 | Run: 15 waves × 60 s plus 1 boss wave; run ≤ 20 min | Time budget including the Späti |
| D-006 | 2026-11-01 | Currency: Pfandflaschen; shop: Späti | Funny, very German |
| D-007 | 2026-11-01 | The Brandmauer is a narrow strip (≤ 10%) at the top edge; holes become spawn gates | Most of the arena has to be arena |
| D-008 | 2026-11-01 | Gewerkschaft, Antifa-Ortsgruppe and Omas gegen Rechts are run modifiers ("Organisation"), not characters. Matching characters: Gewerkschaftsmitglied, Antifa-Aktivist, Oma gegen Rechts | User decision |
| D-009 | 2026-11-01 | "Kleiner Pascha" dropped. Replaced by "Das Stadtbild" as a crowd of everyone who keeps the city running (option 1) | Avoids playing into racist imagery |
| D-010 | 2026-11-01 | "Die Töchter" is an unlockable character | Strong satirical answer to the Stadtbild debate |
| D-011 | 2026-11-01 | Punch-up rule: characters answer the insult, never illustrate it; no ethnic stereotypes | See content guidelines |
| D-012 | 2026-11-01 | No antisemitic codes in anti-capitalist satire | See content guidelines §2 |
| D-013 | 2026-11-01 | Zusammenhalt progression: characters start exhausted and grow stronger by uniting; the arena goes from grey to color | Satire through gameplay, not text |
| D-014 | 2026-11-01 | Rejected: enemies shrinking visually over the run | Enemies get more dangerous, so the visuals would contradict the mechanics |
| D-015 | 2026-11-01 | Multiplayer: 1–4 players, optional but native; self-hosted (listen server, dedicated server), UPnP + IP + LAN | No lag from relays, no platform lock-in |
| D-016 | 2026-11-01 | No Steam networking or "play with friends". Steam allowed later for distribution | User decision |
| D-017 | 2026-11-01 | Single player = local host with 1 player; host-authoritative; seed-based spawns | One code path, no extra solo latency |
| D-018 | 2026-11-01 | Real politicians are never killed; bosses are parodies with invented names and get "in den Aufsichtsrat befördert" | Legal and platform risk; funnier |
| D-019 | 2026-11-01 | Only verified, verbatim, sourced quotes appear in the game | Accuracy and legal safety |
| D-020 | 2026-11-01 | Spec-driven development: docs are the source of truth | User decision |
| D-021 | 2026-11-01 | Engine version: Godot **4.7.2.stable.official** (ed1daf0bf) | Installed version; the project is pinned to it |
| D-022 | 2026-11-01 | Title: **Brandmauer** | Political reference everyone gets, and a real arena mechanic |
| D-023 | 2026-11-01 | Art style: Doodle / Paint | Fast to produce, fits the crass humor |
| D-024 | 2026-11-01 | 20 waves with ramping length (30 s → 60 s from wave 10); elites/minibosses in waves 5/10/15, boss in wave 20. **Supersedes D-005** | User decision; ramping keeps the fighting at about 18 min |
| D-025 | 2026-11-01 | No Späti timer, not even in co-op: the next wave starts when every player is "Bereit". Time in the Späti doesn't count toward the 20-minute target | User decision: players decide how long they shop |
| D-026 | 2026-11-01 | Each elite/miniboss/boss slot has a pool of encounters in a difficulty tier; one is picked at random per run. MVP: one encounter per tier | Variety between runs |
| D-027 | 2026-11-01 | Music adapts to Zusammenhalt (hold music → punk/ska). Source still open | Tells the progression without text |
| D-028 | 2026-11-01 | Music source: openly licensed tracks (CC0 / CC BY); a real band may come later. Licensing rules in the asset licensing spec | User decision; free and legally clean |
| D-029 | 2026-11-01 | Music: ska (and ska punk) throughout, no adaptive hold-music shift for now. **Supersedes D-027** | User decision: ska is more upbeat, and CC tracks can't deliver matching variants |
| D-030 | 2026-11-01 | Stat list (18 stats, GDD §8); Luck = **Eltern** (not Erbschaft), Crit = **Direkte Aktion** | User decision |
| D-031 | 2026-11-01 | Quotes: "said is said". Apologies don't matter; everything legal goes. `umstritten` only for disputed wording. Calling Höcke a fascist is allowed as our own opinion. The "Drecksarbeit" quote is allowed. Single sources get double-checked, and unclear ones are left out | User decision |
| D-032 | 2026-11-01 | Regular enemy roster: 12 enemies in 3 groups (GDD §13); no animal metaphors | Each mechanic carries the joke |
| D-033 | 2026-11-01 | MVP encounters: wave 5 Sylt-Clique, wave 10 Geschichtslehrer, wave 15 Sauerländer, **final boss wave 20: Weidel parody** (she "remigrates" to Switzerland) | User decision |
| D-034 | 2026-11-01 | Network ports: game UDP **24713**, LAN discovery UDP **24714** | Unused range; configurable via `--port=` |
| D-035 | 2026-11-01 | Projectiles are included in snapshots (quantized). Enemies are synced via snapshots, not seed-based schedules. Supersedes the projectile/seed part of D-017 | Simpler and robust; measured 4.8 KB per snapshot (about 0.75 Mbit/s per client at 20 Hz) |
| D-036 | 2026-11-01 | Elite waves: if the timer runs out while an elite is still alive, it flees ("Termin im Aufsichtsrat") with no reward | Keeps the run within the time budget |
| D-037 | 2026-11-01 | Players can't pass the Brandmauer; AfD enemies come through the holes. One hole exists from the start | Keeps the wall a strip and the arena playable |
| D-038 | 2026-11-01 | Final boss placeholder name "Die Eidgenossin" (alternatives: Die Remigrantin, Heidi aus Einsiedeln …). "Alice für Deutschland" rejected | Echoes the banned SA slogan; bosses get invented names (D-018) |
| D-039 | 2026-11-01 | Curated quotes: 62 of 110 verified quotes in the game (research/auswahl.json); the dropped ones are listed with reasons in research/auswahl.md | User: only really good quotes |
| D-040 | 2026-11-01 | All art is drawn procedurally in code (doodle style); fonts Patrick Hand + Courier Prime (OFL); music Kevin MacLeod & others (CC BY); SFX synthesized by tools/gen_sfx.py | No image assets needed; fully license-clean |
| D-041 | 2026-11-01 | Translations: one CSV per module in i18n/, imported as "keep" and loaded at runtime by `Loc` | Raw CSVs must ship in exports |
| D-042 | 2026-11-01 | Final boss name: **Die Remigrantin**. Supersedes D-038 | User decision |
| D-043 | 2026-11-01 | Beaten bosses/elites are "abgesetzt" and go "ins politische Abseits" instead of "in den Aufsichtsrat befördert". Supersedes that part of D-018 | User decision |
| D-044 | 2026-11-01 | Quotes: the most drastic ones are wanted (especially NS/Holocaust relativization, racism), always with speaker, **party**, date and a short context line (`kontext_kurz`). Quotes about groups (e.g. children) are fine: attributed, they always expose the speaker. The start screen always shows one of the strongest quotes | User decision |
| D-045 | 2026-11-01 | Menu subtitle "Halt die Brandmauer. Sonst macht's ja keiner."; options label just "Musik" | User feedback |
| D-046 | 2026-11-01 | Koalitionskasse: co-op only; taking out costs 25 % Kapitalertragsteuer (20 out, 15 received); Brandmauer repairs can be paid from the Kasse on purpose at 30 % discount | User decision: it must matter, but never automatically |
| D-047 | 2026-11-01 | Ranged damage stat renamed **Durchschlagskraft** (was Lautstärke) | Fits all ranged weapons, not only the Megafon |
| D-048 | 2026-11-01 | All our own person-related generic terms are gendered with a colon (Schwarzfahrer:innen-Mütze, Sozialtourist:in, Besorgte:r Bürger:in …). Real quotes are never changed; named parody figures stay as they are | User decision |
| D-049 | 2026-11-01 | Character insult quotes may also appear on the start screen | User decision; supersedes the 'unlock card only' rule |
| D-050 | 2026-11-01 | Ultimates: one per character, Space, once per wave (GDD §9a); Lastenrad's is "Critical Mass" | User decision |
| D-051 | 2026-11-01 | Targeting: no lead aiming; option Zielauswahl (closest/most HP/least HP, default closest); enemies behind the wall are targetable through holes | Genre standard; user feedback |
| D-052 | 2026-11-01 | Boss intro card pauses the game until every player presses W/A/S/D or Space | Time to read the quote |
| D-053 | 2026-11-01 | Frame rate capped at 144 FPS (`application/run/max_fps`), VSync stays on (Godot default) | Avoids uncapped GPU load when VSync is forced off by the driver |
| D-054 | 2026-11-01 | Koalitionsvertrag: "Bereit" only after voting or abstaining; abstentions don't count; nobody voted -> no contract; all votes equal -> that option; otherwise the worst | User: an unnoticed missing vote picked the worst option |
| D-055 | 2026-11-01 | Items can be thrown away (choose how many or all), no refund | Undo accidental buys (e.g. Schuldenbremse) |
| D-056 | 2026-11-01 | Item rarities green/blue/purple/red with wave-dependent shop weights; 26 new items, 8 red build items (melee, ranged, economy, summons, status, crit, lifesteal, dodge) | More build variety |
| D-057 | 2026-11-01 | Weapons combine: two of the same id and tier → next tier (auto on buy, button in the Späti, with confirmation); selling asks for confirmation | User decision |
| D-058 | 2026-11-01 | No real quotes as speech bubbles during waves (they block the view); invented lines and status bubbles stay, with an opacity option | User feedback |
| D-059 | 2026-11-01 | Window mode option: Vollbild / Maximiertes Fenster / Fenster | User decision |
| D-060 | 2026-11-01 | Current balancing is accepted as baseline (user beat Umfrage 10 %); refine incrementally with more playtesters. Funkloch easter egg made small and rare (it was mistaken for a network error) | User feedback |
| D-061 | 2026-11-01 | Housekeeping: D-005 → D-024, D-018 (Aufsichtsrat part) → D-043, D-027 → D-029, D-038 → D-042 are superseded. The elite-flee line (D-036) now reads "Kein Kommentar. Wir sehen uns nach der Wahl!". Internal ids (`eidgenossin`, `ach_aufsichtsrat`) stay as they are; only the displayed texts changed | Keep ids stable for saves and network |
| D-062 | 2026-11-01 | 12 politics items from the item research (GDD §12 "Politics items"); spec written before implementation | User asked for more funny items from recent German politics |
| D-063 | 2026-11-01 | 8 new weapons with distinct niches (GDD §11 "New weapons"): Kartoffelbrei (lob, pure AoE), Trillerpfeife (stun), Brandmauer-Ziegel (line wall), Normenkontrolle (mark), Unterschriftenliste (chain), Enthüllungs-Scheinwerfer (beam + crit debuff), 9-Euro-Ticket (fan), Weißer Overall (swarm). Regenschirm and Wasserwerfer rejected | Overlap with Mietspiegel; water cannon framing |
| D-064 | 2026-11-01 | Co-op survives short disconnects: mid-run the host keeps a dropped client as "away" (Sim player state 3: frozen, invulnerable, untargeted, never blocks the Späti or boss intro) for 60 s; the client keeps rendering with prediction and retries every 2 s for 60 s with a session token. A player keeps the peer id of its first join as its player id; only `Net` maps it to the current ENet peer (`Sim` stays unchanged). A lost connection alone never ends a run: while nobody is alive and someone is away the world waits. Lenient ENet timeouts (min 5 s, max 15 s). Protocol version 2 (networking.md §7.4) | User request: no instant drop on short lags |
| D-065 | 2026-11-01 | FPS cap: 60 in menus, 144 in runs. Full controller support (GDD §19b): focus navigation everywhere, gamepad glyphs in prompts, tooltips on focus | User request ("a game changer in Brotato") |
| D-066 | 2026-11-01 | CI/repo hardening (docs/specs/ci-cd.md §2, §5, §6): actions pinned to commit SHAs, top-level `contents: read`, concurrency, timeouts, shared `setup-godot` composite action; Dependabot (actions + pip) with a 5-day cooldown; CodeQL for `actions` and `python` (GDScript unsupported); new jobs `GDScript compile`, `GDScript lint` (gdlint, non-blocking), `Workflow lint` (actionlint) start as informational, not required; Dependabot alerts/security updates, secret scanning + push protection, private vulnerability reporting enabled; `SECURITY.md` | Public repo: reduce supply-chain and token risk. New checks prove themselves before they can block merges; gdlint stays non-blocking because 100+ style findings (mostly line length) predate it |
| D-067 | 2026-11-01 | Späti shows a character portrait at the current Zusammenhalt stage; lobby character selection uses the in-game drawings | User request; keeps lobby and arena consistent |
| D-068 | 2026-11-01 | Visuals of the 8 new weapons: our Kartoffelbrei target is a friendly green ring with a potato (never the red enemy lob X; one shared colour because hazards carry no owner in the snapshot), its impact is a mash splat; Brandmauer-Ziegel blocks are drawn front-on or end-on depending on the wall direction so the five pieces read as one wall; Normenkontrolle is a hovering "§" stamp with a countdown ring; Unterschriftenliste is a ballpoint signature line, Scheinwerfer a translucent light cone, Trillerpfeife sound waves with "PFIFF!". Lobby and Späti portraits reuse the arena meshes (`WorldView.character_preview`, `CharPortrait`); CharDoodle removed | GDD §6, §11; one drawing per character |
| D-069 | 2026-11-01 | Master volume slider and quieter defaults (master 70 %, music 50 %); rarity shown only by color; level-up stat names scale to one line | Playtest feedback |
| D-070 | 2026-11-01 | Bugfix 0.2.1: the Späti item list scrolls inside its card so the Bereit bar can never be pushed off screen; regression check `tools/spaeti_layout_check.gd` (full 20-wave run with maximum inventory + 80-item extreme case) runs in CI | Playtest bug: no Bereit button in wave 14 |
