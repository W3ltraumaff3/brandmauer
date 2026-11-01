# Game Design Document: "Brandmauer"

**Status:** Draft · **Last updated:** 2026-11-01

## 1. Pitch

A funny, slightly crass political-satire **arena roguelite** in the vein of the "arena survivor" genre. You play the people that conservative and far-right rhetoric targets, and you fight back against the people and structures that actually make life hard. German first, about CDU/CSU, Merz and the AfD. An English US edition is planned later.

## 2. Pillars

1. **Short runs:** a full run takes at most 20 minutes.
2. **Many playstyles:** characters, weapons and items combine into very different builds.
3. **Satire through gameplay, not text:** almost no story. Mechanics, names, visuals and real quotes do the talking. Nobody has to read much.
4. **Easter eggs everywhere:** rewards for people who look closely.
5. **Native co-op:** single player and 1–4 player co-op, with self-hosting (see [networking spec](specs/networking.md)).
6. **Punch up:** see [content guidelines](specs/content-guidelines.md). The joke always lands on the powerful, never on the targeted groups.

## 3. Platform & tech

- **Engine:** Godot 4.7.2 (stable).
- **Platforms:** PC first (Windows, then Linux and macOS). Mobile is possible later. A web build would be single player only.
- **Language:** German. The English US edition comes later, so all text must be localizable from day one (no hard-coded strings).
- **Distribution:** Steam is possible later (store, achievements). Do **not** use Steam networking or "play with friends".

## 4. Run structure

| Phase | Content |
|---|---|
| Setup | Pick a character (each player), an **Organisation** modifier (as a group) and a difficulty (**Umfrage** level) |
| Waves 1–19 | Ramping length ("Sitzungswochen", table below), with the **Späti** shop after each wave |
| Waves 5 / 10 / 15 | **Elite waves**: an elite or miniboss from that wave's tier pool |
| Wave 20 | **Boss wave**: lasts until the boss is beaten (target 90–120 s) |
| End | Run summary (in co-op including **Steuermoral**), unlocks, Zitat-Album entries |

**Wave lengths:**

| Wave | 1–2 | 3–4 | 5–6 | 7 | 8 | 9 | 10–19 | 20 |
|---|---|---|---|---|---|---|---|---|
| Length | 30 s | 35 s | 40 s | 45 s | 50 s | 55 s | 60 s | boss |

**Time budget:** about 16 min of waves plus 1.5–2 min of boss, so **about 18 min of fighting**. Time in the Späti is **not** counted: players can stay as long as they like, so a run may take longer than 20 minutes.

**Späti without a timer:** the next wave starts when **every player has pressed "Bereit"**. In single player, that's just you.

**Wave difficulty:** enemies get steadily more dangerous over the run (more of them, stronger, new types). Enemies never get visually smaller or weaker as the run progresses.

## 5. Arena

- **View:** top-down, one fixed arena per run.
- **Brandmauer:** a narrow wall strip along the **top edge, at most about 10% of the area**. The rest is open arena.
  - AfD enemies gather behind the wall.
  - CDU-type enemies "abstimmen" during waves and knock holes in the wall. **Each hole becomes a spawn gate.**
  - Holes can be repaired in the Späti with Pfand. The trade-off: leave holes open for more enemies and more loot, or pay to repair them.
- **Visual progression:** the arena starts grey and desaturated and gains color with every Zusammenhalt stage (section 7).
- **Later arenas (not in the MVP):** Marktplatz, Bahnhof, Kleingartenanlage.

## 6. Economy: Pfandflaschen & the Späti

- **Currency: Pfandflaschen.** Enemies drop them.
- **The Späti** (shop between waves):
  - Weapons (**6 slots**), items and stat upgrades.
  - Reroll, plus Brandmauer repairs.
- **In co-op:** each player has their own Späti and wallet, plus the shared **Koalitionskasse** (section 10).

## 7. In-run progression: Zusammenhalt

**Zusammenhalt** replaces XP. You earn it by defeating enemies, with a **bonus when you're close to teammates or your own summons**. A level-up gives a stat choice as usual.

Characters start **exhausted by circumstances** and get stronger and more visibly confident as they band together:

| Stage | Visual cues |
|---|---|
| Erschöpft | stooped, coffee mug, Jobcenter letter in the pocket, yawning |
| Genervt | standing straight, eye-rolling, first sparks |
| Wütend | faster animations, clenched fists |
| Organisiert | crowd falls into step, banners |
| Unaufhaltsam | full color, music change |

**Rules for this system:**
- **They're tired from the circumstances, not from weakness.** The fatigue is shown through its causes (double shift, three jobs, a rent increase) and played for humor.
- **Characters are competent from the start.** Only the stats grow; nobody is ever helpless or pitiful.
- **There's no outside hero.** People empower themselves by uniting.
- **In co-op, Zusammenhalt is shared**, which rewards sticking together without explaining it.

## 8. Stats

| Effect | Name in game | Note |
|---|---|---|
| Max HP | **Solidarität** | |
| HP regen | **Krankenschein** | |
| Heal on hit | **Umverteilung** | you take from the enemies |
| Damage % | **Wut** | |
| Melee damage | **Handarbeit** | manual labor, and Oma's knitting |
| Ranged damage | **Durchschlagskraft** | all ranged weapons |
| Status damage (poison, slow) | **Ziviler Ungehorsam** | |
| Attack speed | **Akkord** | piece-rate work |
| Crit chance | **Direkte Aktion** | |
| Summon strength | **Ehrenamt** | |
| Range | **Reichweite** | double meaning: social media reach |
| Armor | **Kündigungsschutz** | |
| Dodge | **Schwarzfahren** | |
| Movement speed | **Deutschlandticket** | |
| Luck | **Eltern** | the tooltip notes that for some players it starts at 9,000 |
| Extra Pfand per wave | **Nebenjob** | a second job after hours, paid at the end of each wave |
| Pickup radius | **Pfandradar** | |
| Zusammenhalt gain (XP) | **Vernetzung** | |

## 9. Characters

Each character's insult-quote appears **only on the unlock card**, with its source. The character is the **answer** to the quote, not an illustration of it ([content guidelines](specs/content-guidelines.md)).

### MVP roster (8)

| Character | Playstyle | Notes |
|---|---|---|
| **Das Stadtbild** | Crowd that grows: you collect passers-by during the wave; the bigger and more mixed the crowd, the stronger you are | A crowd of everyone who keeps the city running: Pflegerin, Dönermann, Busfahrerin, Späti-Betreiber, Bauarbeiter, student, Oma. Nobody is drawn as a stereotype; each is simply their job. Barely moved by "Abschiebung" knockback, because it's a whole city |
| **Sozialtourist** | Economy: lots of starting money, free rerolls | |
| **Bürgergeld-Empfänger** | Extra Pfand each wave (Nebenjob +8), −% damage | The "lazy" build actually wins through economy |
| **Klimakleber** | Huge damage while standing still, slows enemies | |
| **Lastenrad-Grüne** | Fast, ramming damage, extra weapon slots in the cargo box | |
| **Gewerkschaftsmitglied** | Team/aura: stronger near other players (in solo, near own summons) | |
| **Antifa-Aktivist** | Fast, hits hard, bonus against Brandmauer gates | |
| **Oma gegen Rechts** | Slow and very tanky, knitting needles as a fast-firing weapon | |

### Unlockable

| Character | Playstyle | Unlock |
|---|---|---|
| **Die Töchter** | Damage rises the more old men in suits are on screen | Beat the boss "Der Sauerländer". Based on Merz's "Fragen Sie mal Ihre Töchter" (merz-02, verified, 2025-10-20) |

### Candidates (not yet decided)

- **Gen Z mit Work-Life-Balance:** only attacks 50% of the time, but every hit crits.
- **Teilzeit-Mama:** dual-wields summons.
- **Taugenichts:** luck build (Weidel quote; Eichendorff easter egg).
- **Totalverweigerer:** refuses to attack; contact damage aura.
- **Lifestyle-Teilzeitler:** plays only half of each wave, at double strength.
- **Versiffter 68er:** smoke cloud that confuses enemies.
- **Steuerfinanzierte NGO:** summoner whose minions carry clipboards.
- **Zahnarzt-Tourist:** heals off enemies.

## 9a. Ultimates (Space, once per wave)

| Character | Ultimate | Effect |
|---|---|---|
| Das Stadtbild | **Flashmob** | the crowd storms outward: enemies nearby are stunned for 2 s, take damage (more with followers) and are knocked back |
| Sozialtourist:in | **Urlaubsantrag** | 4 s on a sun lounger: invulnerable, can't move, heals |
| Bürgergeld-Empfänger:in | **Antrag gestellt** | paperwork storm: all enemies 60 % slower for 6 s |
| Klimakleber:in | **Straßenblockade** | a glue strip across the whole arena at your height; enemies get stuck for 6 s |
| Lastenrad-Grüne | **Critical Mass** | dash ramming everything in the way, then double speed for 5 s |
| Gewerkschaftsmitglied | **Tarifrunde** | +50 % damage for all players and summons for 8 s |
| Antifa-Aktivist:in | **Schwarzer Block** | 6 comrades storm out for 6 s, push enemies back and deal damage |
| Oma gegen Rechts | **Kaffee und Kuchen** | heals the whole team fully, revives downed teammates, +regeneration for 10 s |
| Die Töchter | **Fragen Sie mal uns** | all "old men in suits" (Union, Kapital, Sauerländer) are stunned for 2 s and take double damage for 6 s |

## 10. Organisation (run modifier)

Chosen before the run, by the group in co-op:

| Organisation | Effect |
|---|---|
| **Gewerkschaft** | Every 5th wave you can call a **Streik**: enemies freeze for 5 s and the Späti gets cheaper. Income rises each wave (**Tarifvertrag**) |
| **Antifa-Ortsgruppe** | The Brandmauer slowly repairs itself, bonus against AfD enemies, occasional **Sitzblockade** zone that slows enemies |
| **Omas gegen Rechts** | Extra HP regen. An Oma NPC hits enemies with her umbrella and hands out Pfand |

**Later:** Mieterverein, Seenotrettung, Tafel.

## 11. Weapons (MVP: 12)

Confirmed so far:
- **Gendersternchen:** shuriken.
- **Pfandflasche:** a boomerang that comes back as currency.
- **Döner-Spieß:** melee.
- **Grundgesetz:** Article 1 knockback.
- **Megafon:** cone attack.
- **Mietspiegel:** reflects projectiles.
- **Tofu:** poison.
- **Stricknadeln:** fast-firing (Oma's starting weapon).

The remaining weapons are still open.

## 12. Items (MVP: 30)

Confirmed **cursed items** (items with a downside):

| Item | Effect |
|---|---|
| **Schuldenbremse** | Caps how much you can spend per Späti visit |
| **Sondervermögen** | Removes the Schuldenbremse cap |
| **Bierdeckel-Steuererklärung** | Does absolutely nothing. The tooltip is the joke |
| **Faxgerät** | Every attack is delayed by 3 s |
| **DB-Ticket** | Big movement speed, but random +5 min "Verspätung" stuns |

## 13. Enemies

Regular enemies are **archetypes, never real people**. They get **more dangerous over the run**.

There are **no animal metaphors** for capitalists (no "Miethai"; see content guidelines §2).

### From behind the Brandmauer (they enter through the holes)
| Enemy | Role | Mechanic and joke |
|---|---|---|
| **Besorgter Bürger** | basic swarm | slow, lots of them. Speech bubble: "Man wird ja wohl noch sagen dürfen…" |
| **Telegram-Onkel** | ranged | throws a **Kettenbrief** that splits on every bounce ("forwarded") |
| **Identitärer Hipster** | fast melee | hits **push the player toward the Brandmauer** ("Remigration") |
| **Reichsbürger** | tank | **immune to status effects** (doesn't recognize your authority). Drops a worthless "Reichsausweis" (easter egg) |

### Union
| Enemy | Role | Mechanic and joke |
|---|---|---|
| **JU-Schnösel** | fast, weak | runs to the Brandmauer and **votes a hole in it**, so he's a priority target |
| **Hinterbänkler** | medium | **gets stronger near AfD enemies** ("Mehrheit beschaffen"). Speech bubble: merz quote "Eine richtige Entscheidung wird nicht dadurch falsch, dass die Falschen zustimmen." |

### Kapital
| Enemy | Role | Mechanic and joke |
|---|---|---|
| **Lobbyist** | support | a **Hausausweis** gives nearby enemies armor. Drops a lot of Pfand. Drawn tall and slick, with a lanyard |
| **Porsche-SUV** | charger | charges straight ahead, then **parks on the bike lane** and stays as an obstacle |
| **Immobilienerbe** | area control | lays down **Mietzonen** that drain Pfand while you stand in them |
| **Golfclub-Vorstand** | artillery | lobs golf balls from a distance |
| **FDP-Jungunternehmer** | splitter | when killed, **founds two startups**, which go **insolvent** (explode) shortly after |
| **Privatjet** | late flyer | ignores the Brandmauer, leaves kerosene trails |

### When each enemy shows up
| Waves | New enemies |
|---|---|
| 1–4 | Besorgter Bürger, JU-Schnösel, Telegram-Onkel |
| 6–9 | Lobbyist, Porsche-SUV, Hinterbänkler, Identitärer Hipster |
| 11–14 | Immobilienerbe, Golfclub-Vorstand, Reichsbürger, FDP-Jungunternehmer |
| 16–19 | Privatjet |

## 14. Elites, minibosses & bosses

There's a **pool per tier**. Each run randomly picks one encounter from each pool, so runs differ.

| Wave | Tier | Difficulty |
|---|---|---|
| 5 | Elite tier 1 | easy |
| 10 | Elite / miniboss tier 2 | medium |
| 15 | Miniboss tier 3 | hard |
| 20 | Boss | final |

- **The Umfrage difficulty** scales every encounter and can unlock harder variants.
- Elites, minibosses and bosses are **parodies with invented names**, recognizable but never named directly.
- They **don't die**. When beaten, they're **"abgesetzt"** and leave **"ins politische Abseits"**, with a fitting exit (yacht, walk-off, private jet, Switzerland).
- Every encounter has an intro card or speech bubble with a **real, verified quote**, and beating it unlocks the matching Zitat-Album card.
- **MVP: one encounter per tier** (3 elites/minibosses plus 1 boss). The pools grow after the MVP.

### MVP encounters
| Wave | Encounter | Parody of | Mechanic | Exit |
|---|---|---|---|---|
| 5 | **Die Sylt-Clique** | the 2024 Sylt video (anonymous archetypes, no recognizable real people) | a pack of 4 that buff each other while close together; they throw champagne and hum "♪ Döp dödö döp ♪" | sail off in a yacht |
| 10 | **Der Geschichtslehrer** | Höcke | **"Wende um 180 Grad"**: periodically **reverses the player's controls**. Quote hoecke-02 | walks off "ins politische Abseits" |
| 15 | **Der Sauerländer** | Merz | Phase 1 **Bierdeckel** (beer mats as shuriken) → phase 2 **Sondervermögen** (he breaks his own Schuldenbremse, and money rain heals him) → phase 3 **Zirkuszelt** (the arena turns into a circus tent). Unlocks **Die Töchter** | flies off in the private jet "ins politische Abseits" |
| 20 | **Final boss: Die Remigrantin** (Weidel parody) | Weidel | see below | **"remigrates" to Switzerland** |

### Final boss: Die Remigrantin (Weidel parody)
- **Phase 1 "Windmühlen der Schande":** she tears down the wind turbines in the arena, which are your cover. She charges like Don Quixote. Quote weidel-05.
- **Phase 2 "Remigration":** push waves drive all players toward the Brandmauer, and the arena edge becomes the danger zone.
- **Phase 3 "Steuerparadies":** she retreats behind a vault shield of gold bars in a Swiss chalet, and the players have to break the shield.
- **Exit:** she **emigrates to Switzerland**. That's the closing joke: the only person in the game who actually "remigriert".
- Content rule: none of her phases may summon or depict the groups she insults. Her attacks target only the players and the environment.

### Pool (after the MVP)
| Tier | Encounter | Mechanic |
|---|---|---|
| 1 | Der Generalsekretär (Linnemann) | **Sanktion** zones switch off Nebenjob income and HP regen |
| 2 | Der Weißwurst-Kaiser (Söder) | **switches positions every phase** (tree-hugger, anti-Green, #söderisst) |
| 2 | Die Präsidentin (Klöckner) | an **Ordnungsruf** silences weapons; rainbow-colored weapons are disabled. Quote merz-17 "kein Zirkuszelt" |
| 3 | Der Krawatten-Opa (Gauland) | a giant bird drops **Vogelschiss**; the "Fliegenschiss" dialogue (Merz/Brandner) plays on entry |

## 15. Quotes

- **Real, verbatim quotes with sources** appear on boss intro cards, as enemy speech bubbles, on loading screens and in the **Zitat-Album**.
- **Only quotes marked `verifiziert` in the research are used** (see [content guidelines](specs/content-guidelines.md)).
- **Source data:** `research/zitate_de.json`.

## 16. Co-op (1–4 players)

| Mechanic | Rule |
|---|---|
| **Koalitionskasse** | Co-op only (off in solo). Each player has their own wallet, plus a shared pot. Paying in: 10 Pfand. Taking out: 20 from the pot, you get 15 (25 % **Kapitalertragsteuer**). Shared things can be paid from the pot on purpose (never automatically): Brandmauer repairs cost 30 % less from the Kasse. The end screen shows a **Steuermoral** stat for who paid in and who only took out |
| **Koalitionsvertrag** | Before certain waves, everyone votes on a modifier. **If the vote isn't unanimous, the worst option wins** |
| **Solidaritätszuschlag** | Reviving a downed player costs the others HP or money |
| **Scaling** | More players means more enemies and stronger elites |
| **Späti** | One per player. No timer: the next wave starts when every player is "Bereit" |
| **Zusammenhalt** | Shared across the team |
| **Organisation** | Chosen together |

**Later, optional:** a PvP or "Wahlkampf" mode.

## 17. Meta progression

- **Unlocks** (characters, weapons, items) come from achievements, e.g. "Win as Bürgergeld-Empfänger without buying a weapon" or "Finish a run with an intact Brandmauer" (*Unmöglich*).
- **Zitat-Album:** collectible quote cards with source, date and context, unlocked by beating bosses and elites.
- **Difficulty = Umfrage levels:** 10% → 15% → 20% → 25% …, each step adding a modifier.
- **Saves are stored locally per player.** A host never stores a client's progress.

## 18. Easter eggs (candidates)

- In wave 20, the timer reads "Koalitionsverhandlungen" and runs 3x too long.
- A hidden "Vogelschiss" item.
- Typing `BLACKROCK` in the menu turns all currency into stock shares that lose value.
- A Funkloch randomly blacks out the minimap.
- The credits are written in Amtsdeutsch.
- The item "Aus dem Leben eines Taugenichts".

## 19. MVP scope

- 1 arena with the Brandmauer
- 8 characters, plus Die Töchter as an unlock
- 3 Organisationen
- 12 weapons, 30 items
- 20 waves (ramping), with 3 elites/minibosses (waves 5/10/15) and 1 boss (wave 20)
- The Späti
- Zusammenhalt progression
- Co-op for 1–4 players
- Local meta save, Zitat-Album

## 20. Art & audio

### Art style: Doodle / Paint
The art is deliberately crude and hand-drawn. It's fast to produce, it fits the crass humor, and the caricatures stay readable. Readability in gameplay still comes first: enemies, projectiles and pickups need clear silhouettes and contrast.

### Music: ska (punk) throughout
- **The style is upbeat ska from the very start, with ska punk** for the hotter moments (late waves, bosses).
- **Tracks:**
  - a gameplay playlist that rotates through several tracks
  - the Späti (laid back, e.g. dub or rocksteady)
  - bosses (more aggressive ska punk)
  - the main menu
- **Tech:** tracks are assigned through data, never in code, so they can be swapped without code changes.
- **Source:** openly licensed tracks for now (CC0 / CC BY, see [asset licensing spec](specs/asset-licensing.md)). We may switch to a real band later.
- **Possible later:** adaptive layers, e.g. a "hold music" opening that changes with Zusammenhalt, once we have stems from a band.
