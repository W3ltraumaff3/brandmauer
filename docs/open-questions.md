# Open Questions

When a question is answered, move it into [decisions.md](decisions.md) and remove it here.

## Content

- [ ] **Item ideas not yet built:** `research/item_ideen.md` has 31 concepts (8 green, 11 blue, 6 purple, 6 red), for example Cum-Ex-Erstattung (competes thematically with Genossenschaftsanteil), Doppelwumms, Untersuchungsausschuss. Pick which ones become items. Facts marked "nachprüfen" there need checking first.
- [ ] **Eight politics items are still never offered** (D-127): Erinnerungslücke, Treuhandkonto, Aufhören zu produzieren, Wahlversprechen, Maut-Vertrag, BER-Eröffnungstermin, Puma-Schützenpanzer and Zweiter Wahlgang are defined and tested but missing from `Content.ITEM_ORDER` (only the four red ones were added in the red-item round). Add them to the shop pool? Their Pfand amounts (Treuhand +30, Maut −8) are flat like the old red caps and would need the same price-factor check.
- [ ] **Red items in playtests** (D-127 to D-135): do the reworked red items feel like the run's big step without being a must-buy? Bot results in balancing.md "Red items (v0.4.1)". Watch especially Kritische Masse (+2.8 waves for the crit bot) and whether the Genossenschaftsanteil invites hoarding.
- [ ] **More unlock characters** (candidates in GDD §9: Gen Z mit Work-Life-Balance, Teilzeit-Mama, Taugenichts, Totalverweigerer …). Which ones, and what unlocks them.
- [ ] **Encounter pools beyond the MVP** (GDD §14: Generalsekretär, Weißwurst-Kaiser, Präsidentin, Krawatten-Opa) and later arenas.
- [ ] **Single-source quotes still to verify** (see `research/verifikation.md` and `research/auswahl.md`). Weak slots: Bierdeckel and Steuerparadies phases have no fitting quote, and the unlock quotes for Oma and Antifa are makeshift.
- [ ] **Umfrage difficulty levels:** levels exist (10 to 35 %); which extra modifier each step adds is TBD.
- [ ] **Quote cards for weapons:** Kleine Anfrage (cdu-fraktion-01) and Pappkamerad (soeder-04, both `verifiziert`) have a fitting real quote, but weapons have no place to show one yet (Album entry? Späti card?). Until then the flavor carries only facts and invented lines (D-095).

## Balancing (boss rules, D-102 to D-112)

- [ ] **Tune the rest of the boss rules** (research/boss_ideen.md §9): the HP lever is tuned (D-118); still at their starting values: phase tempo ×1.0/1.2/1.4, Standfest 10/15 s, vote time and damage threshold, Kahlschlag interval, band width.
- [ ] **Kahlschlag's aim:** now at his random target (D-110). The research aimed it at the densest group of summons and zones; decide after playtests whether summon builds still stand still.
- [ ] **Final exam, playtest checks (D-140 to D-145):** is the Reichweite (3.0 s, 2.4 s at 35 %) reachable for a human from the middle while dodging the opening push ring; does the letterbox rhythm (clear them, then a 25 s window) read without a tutorial; is 145–155 s at 35 % for ranged and summon bots the right length for humans (the bot is slower than a good player); at 10–20 % the bot hardly ever loses a first try.
- [ ] **Summon and status in her phase 3** (v0.4.1 round): their stands and zones stay behind while they walk to the letterboxes and the safe strips (immortal summon at 20 % 90 → 309 s, status 106 → 257 s; mortal 134 / 126 s). Levers: letterboxes closer to the middle, the Reichweite safe strips also around the chalet, or the stands following their owner in phase 3.
- [ ] **The rest of the boss shortlist** (research/boss_ideen.md §8): Sondervermögen rework, Geschichte umschreiben, Tafelbild, Sylt-Clique Absperrband and knockback (Briefkastenfirmen, Ansturm-Kette and Wahlabend came with the final exam, D-140 to D-144).
- [ ] **Melee against the final boss** (v0.4 round): even with ×2 melee damage on bosses (D-121) the melee bot needs 5–6 minutes for Die Remigrantin (ranged about 1) and dies there more often than in v0.3; its mean wave is ~2.7 below the v0.3 baseline. Charges, push rings and the band keep it from standing next to her. A boss-side answer (a window where she stands still, push rings that spare players in contact) or a playtest check of human melee first?
- [ ] **Wave-5 Sylt-Clique in co-op:** with 4 players it fled at the 40 s timer in 8 of 9 bot runs (no counting bug, D-118). With `elite_coop` 0.3 it is killed in most runs (30–38 s); if playtests still see it flee, lengthen wave 5 or let the timer wait for the clique.

## Balancing (status and summon, v0.4)

- [ ] **Klimakleber:in with the status build** dies at the wave-5 Sylt-Clique (8 of 12 bot deaths, champagne lobs while standing still); the Oma with Kleber does far better. Bot artefact (standing bonus vs. dodging telegraphs) or character? Check in a playtest before touching her numbers.
- [ ] **Straßenkreide** stays the weakest weapon per Pfand even with the chalk circle (D-120): enemies rarely walk the trail. Bigger marks, a longer life or a different niche?
- [ ] **Summon with the Gewerkschaft** is now the strongest bot build at Umfrage 35 % (3 of 4 wins, ranged 1 of 4) after D-114/D-115/D-117/D-122; at equal footing (Oma) it is level with ranged. If playtests agree, cap the passive's own summons (e.g. at most 2) rather than the Infostand.
- [ ] **Placement and area damage in human play:** cluster placement (D-113), leaflet bounce and Overall splash (D-115) were measured with bots only; check in a playtest that Kleber/Kartoffelbrei landing on the crowd reads clearly.

## Audio

- [ ] **The remaining music tracks:** gameplay playlist is thin, boss tracks are rock rather than ska. Candidates in `research/musik_cc.md` ("Mission Accomplished", "Braineating Zombies", the DavidKBD packs). Before use: download in a browser, screenshot each license, listen to vocal tracks for content.
- [ ] **A real band** for release (optional, later).

## Release and platforms

- [ ] **Join codes / NAT punch-through.** Today: UPnP, IP or LAN only.
- [ ] **macOS signing:** only ad-hoc signed, Gatekeeper warns.
- [ ] **An installer** (Windows). The beta ships a plain exe and zips.
- [ ] **An English version** (US edition). The CSV structure is ready, the texts aren't written.
- [ ] **Bandwidth:** a listen host with 3 clients uploads about 2.2 Mbit/s; delta compression is the next step if needed.

## Before a public launch

- [ ] **Playtests with people from the affected groups** (content guidelines §6).
- [ ] **A legal check** of quotes and boss parodies.
- [ ] **Balancing with more playtesters.** The current balancing is the baseline; refine incrementally.
