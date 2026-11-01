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
