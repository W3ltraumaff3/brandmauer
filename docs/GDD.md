# Game Design Document: "Brandmauer"

**Status:** Draft · **Last updated:** 2026-11-01 (synced with the implemented game, v0.2.0-beta)

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
| Encounter intro | Waves 5/10/15/20 open with an encounter card and **pause the game** (section 14) |
| End | Run summary (in co-op including **Steuermoral**), unlocks, Zitat-Album entries |

**Wave lengths:**

| Wave | 1–2 | 3–4 | 5–6 | 7 | 8 | 9 | 10–19 | 20 |
|---|---|---|---|---|---|---|---|---|
| Length | 30 s | 35 s | 40 s | 45 s | 50 s | 55 s | 60 s | boss |

**Time budget:** about 16 min of waves plus 1.5–2 min of boss, so **about 18 min of fighting**. Time in the Späti is **not** counted: players can stay as long as they like, so a run may take longer than 20 minutes.

**Späti without a timer:** the next wave starts when **every player has pressed "Bereit"**. In single player, that's just you. Players who are away (disconnected) don't block the Späti. If a Koalitionsvertrag vote is open, "Bereit" is only possible after voting or abstaining (section 16).

**Giving up / leaving:** the pause menu has *Aufgeben* and *Verlassen*, both with a confirmation ("Wirklich? Nochmal drücken.").

**Performance:** the frame rate is capped at **144 FPS during a run** and **60 FPS in menus** (main menu, lobby, end screen, Album, options); VSync stays on.

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
  - Weapons (**6 slots**; Lastenrad-Grüne has 7), items and stat upgrades (level-ups).
  - Reroll (some characters start with free rerolls), plus Brandmauer repairs.
  - Prices rise by 8 % per wave. Weapon tiers I–IV cost ×1.0 / 1.8 / 3.2 / 5.5.
  - A **Statistik** button (section 6c) and the weapon/item management below.
  - A **character portrait:** the local player's character drawn exactly as in the arena, at the **current Zusammenhalt stage**, with the stage name and progress to the next stage. Kept **small and calm**; it must not crowd the Späti, which is already dense (no held weapons, no extra panels; it fits into existing free space such as the header area or the bottom bar). It reminds you who you play and shows how far the team has come.
- **Character selection** (lobby) uses the same in-game drawings (stage 4, confident) instead of separate icons, so lobby and arena look alike.
- **In co-op:** each player has their own Späti and wallet, plus the shared **Koalitionskasse** (section 16).

### 6a. Weapon management in the Späti

| Action | Rule |
|---|---|
| **Combine** | Two weapons with the same id and the same tier become **one weapon of the next tier** (max tier IV), freeing a slot. Three ways: **automatic on buying** (an offer that matches a weapon you own is marked "kombiniert zu …" and needs no free slot), the **Kombinieren button** on an owned weapon that has a twin, and the button always asks for a **confirmation** ("Auseinandernehmen geht nicht."). Without a twin: "Zum Kombinieren brauchst du zwei gleiche Waffen gleicher Stufe." |
| **Sell** | Refund is 40 % of the current weapon price. **Asks for confirmation** ("Weg ist weg"). You can't sell your last weapon |
| **Throw away items** | Click an item in the item list: choose how many, or all. **No refund.** For undoing accidental buys (e.g. Schuldenbremse) |

### 6b. Targeting

- **No lead aiming:** shots fly at where the target is now.
- **Option Zielauswahl** (per player, default *Nächste:r Gegner:in*): **closest**, **most HP** (elites and bosses first) or **least HP** (clean up fast). Applies to all auto-aiming weapons and turrets.
- **Weapons face their target**; the character's facing follows the shots.
- **Line of sight:** AfD enemies behind the Brandmauer can be targeted and hit **only through holes**. An intact wall segment between you and them blocks the shot.

### 6c. Statistics panel

The Späti has a **Statistik** button (Esc closes it): a recap after the last wave, per player.
- **Damage by source:** weapons by tier, ramming (Lastenrad), other. Shows last wave, total and share. Sold weapons are marked *(verkauft)*, combined ones *(kombiniert)*.
- **Survival:** healed by Umverteilung and by Krankenschein, damage taken, damage blocked by Kündigungsschutz, dodges.
- **Misc:** kills, crits, ultimates used, Pfand collected, income and spent.

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
| Melee damage | **Handarbeit** | manual labor |
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

Each character's insult-quote appears on the unlock card and may also appear on the start screen, always with its source. The character is the **answer** to the quote, not an illustration of it ([content guidelines](specs/content-guidelines.md)).

**Gendered texts:** all our own person-related terms use a colon (Sozialtourist:in, Klimakleber:in, Besorgte:r Bürger:in, Gegner:innen, Schwarzfahrer:innen-Mütze …). **Real quotes are never changed**, and named parody figures keep their form (Der Sauerländer, Die Remigrantin).

### MVP roster (8)

| Character | Playstyle | Notes |
|---|---|---|
| **Das Stadtbild** | Crowd that grows: you collect passers-by during the wave; the bigger and more mixed the crowd, the stronger you are | A crowd of everyone who keeps the city running: Pflegerin, Dönermann, Busfahrerin, Späti-Betreiber, Bauarbeiter, student, Oma. Nobody is drawn as a stereotype; each is simply their job. Barely moved by "Abschiebung" knockback, because it's a whole city |
| **Sozialtourist:in** | Economy: lots of starting money, free rerolls | |
| **Bürgergeld-Empfänger:in** | Extra Pfand each wave (Nebenjob +8), −% damage | The "lazy" build actually wins through economy |
| **Klimakleber:in** | Huge damage while standing still, slows enemies | |
| **Lastenrad-Grüne** | Fast, ramming damage, extra weapon slots in the cargo box | |
| **Gewerkschaftsmitglied** | Team/aura: stronger near other players (in solo, near own summons) | |
| **Antifa-Aktivist:in** | Fast, hits hard, bonus against Brandmauer gates | |
| **Oma gegen Rechts** | Slow and very tanky, **Stricknadeln** as a fast-firing starting weapon | |

### Unlockable

| Character | Playstyle | Unlock |
|---|---|---|
| **Die Töchter** | Damage rises the more old men in suits are on screen | Beat the boss "Der Sauerländer". Based on Merz's "Fragen Sie mal Ihre Töchter" (merz-02, verified, 2025-10-20) |

**Starting weapons:** Stadtbild Döner-Spieß, Sozialtourist Pfandflasche, Bürgergeld Gendersternchen, Klimakleber Kleber, Lastenrad Megafon, Gewerkschaft Infostand, Antifa Farbbeutel, Oma Stricknadeln, Töchter Transparent.

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

## 11. Weapons (12)

All weapons have tiers I–IV (combine two of the same tier, section 6a). Values from `Content.WEAPONS`:

| Weapon | Kind | Damage I–IV | Cooldown | Scales with | Notes |
|---|---|---|---|---|---|
| **Gendersternchen** | shot | 6 / 10 / 16 / 26 | 1.0 s | Durchschlagskraft | shuriken, bounces once |
| **Pfandflasche** | shot | 8 / 13 / 20 / 32 | 1.3 s | Durchschlagskraft | boomerang, pierces everything, 10 % chance of Pfand |
| **Megafon** | cone (60°) | 5 / 8 / 13 / 21 | 1.1 s | Durchschlagskraft | knockback |
| **Stricknadeln** | shot | 3 / 5 / 8 / 13 | 0.35 s | Durchschlagskraft | fast-firing |
| **Döner-Spieß** | melee cone (25°) | 12 / 20 / 32 / 50 | 0.9 s | Handarbeit | |
| **Grundgesetz** | melee cone (120°) | 9 / 15 / 24 / 38 | 1.2 s | Handarbeit | Article 1: strong knockback |
| **Transparent** | melee 360° | 7 / 12 / 19 / 30 | 1.4 s | Handarbeit | |
| **Mietspiegel** | melee orbit | 4 / 7 / 11 / 18 | 0.5 s | Handarbeit | orbits you, two orbiters from tier III |
| **Tofu** | shot | 2 / 3 / 5 / 8 | 1.0 s | Ziviler Ungehorsam | poison (3 / 5 / 8 / 13 over 3 s) |
| **Farbbeutel** | shot, splash | 5 / 8 / 13 / 20 | 1.3 s | Ziviler Ungehorsam, Durchschlagskraft | slows 40 % |
| **Kleber** | puddle | 2 / 4 / 6 / 10 | 2.2 s | Ziviler Ungehorsam | slows 70 % for 3 s |
| **Infostand** | turret (max 2) | 4 / 7 / 11 / 17 | 5.0 s | Ehrenamt | fires leaflets for 10 s |

### New weapons (v0.2, spec; from `research/waffen_ideen.md`)
Each one fills a niche no other weapon covers. Tier damage follows the existing curve (×1.67 / ×2.67 / ×4.3 of tier I).

| Weapon | Kind | Tier-I dmg | Cooldown | Range | Scales with | Special / niche |
|---|---|---|---|---|---|---|
| **Kartoffelbrei** | lob | 18 | 3.0 s | 340 | Durchschlagskraft | target marker on the ground, impact after 0.8 s, radius 110; pure area burst, no slow. Flavor: keep your distance from paintings |
| **Trillerpfeife** | cone 360° | 4 | 2.0 s | 150 | Handarbeit 0.6 | stuns everything around for 0.6 s instead of knockback; control, barely any damage |
| **Brandmauer-Ziegel** | line wall | 3 per 0.5 s | 4.0 s | 220 | Ehrenamt | a wall 140 px wide across the target direction for 6 s, slows enemies inside by 40 % and damages them; max 2 |
| **Normenkontrolle** | mark | 30 | 4.5 s | 360 | Ziviler Ungehorsam | marks the strongest enemy in range; after 3 s it's "nichtig erklärt" (burst); boss killer |
| **Unterschriftenliste** | chain | 5 | 1.4 s | 260 | Durchschlagskraft 0.9 | instant hit that jumps to 3 more enemies within 120 px, −20 % per jump |
| **Enthüllungs-Scheinwerfer** | beam | 14 | 2.2 s | 400 | Durchschlagskraft | instant straight beam that hits everything in line; hit enemies are "enthüllt": +15 % crit chance against them for 5 s |
| **9-Euro-Ticket** | fan | 2 × 9 tickets | 1.5 s | 180 | Durchschlagskraft 0.5 | 9 projectiles in a 60° fan; from wave 4 only 5 ("läuft ab") |
| **Weißer Overall** | swarm | 6 per activist | 4.0 s | 300 | Ehrenamt | 3 activists in white overalls each run at a different enemy, hit once, leave |

## 12. Items (57, incl. 2 hidden)

Every item is a stat change and/or a rule flag. Throwing items away: section 6a.

### Rarities and shop weights
| Rarity | Color | Meaning | In the shop (weight at wave *w*) |
|---|---|---|---|
| 1 | green | one simple bonus | always (10) |
| 2 | blue | good bonus, sometimes with a malus | always, more often later (3 + 0.35·*w*) |
| 3 | purple | very good bonus, malus if very very good | from wave 4 (0.35·(*w*−3)) |
| 4 | red | game-changing, only for one specific build | from wave 8, rare (0.12·(*w*−7)) |

Luck (**Eltern**) shifts the weights toward rarer tiers. Red items carry a **"ROT · Build-Item"** stamp in the Späti. Item prices grow by 8 % per wave.

### Green
| Item | Effect |
|---|---|
| Bierdeckel-Steuererklärung | Does absolutely nothing. The tooltip is the joke |
| Thermoskanne | +2 Krankenschein |
| Kirschkernkissen | +1 Krankenschein |
| Soli-Button | +10 Solidarität |
| Fahrradhelm | +4 Solidarität |
| Isomatte | +1 Kündigungsschutz |
| Strickliesel | +3 Durchschlagskraft |
| Frisbee | +2 Durchschlagskraft |
| Deutschlandticket-Abo | +10 Deutschlandticket |
| Pfandring | +60 Pfandradar |
| Minijob | +5 Nebenjob |
| Anruf bei Mama | +15 Eltern |
| Signal-Gruppe | +15 Vernetzung |
| Sekundenkleber | +3 Ziviler Ungehorsam |
| Vereinsheim | +3 Ehrenamt |
| Flugblatt-Stapel | +2 Ehrenamt |
| Fernglas | +50 Reichweite |
| Club-Mate (eine Flasche) | +6 Akkord |
| Taschenlampe | +3 Direkte Aktion |

### Blue
| Item | Effect |
|---|---|
| Schuldenbremse | +15 Wut. **Curse:** you may only spend a limited amount per Späti visit (30 + 10 per wave) |
| DB-Ticket | +30 Deutschlandticket. **Curse:** random "Verspätung" stuns |
| Betriebsrat | +3 Kündigungsschutz, −3 Deutschlandticket |
| Mate-Kiste | +15 Akkord, −3 Solidarität |
| Gewerkschaftsweste | +2 Kündigungsschutz, +5 Solidarität |
| Wut-Tagebuch | +12 Wut |
| Lautsprecherwagen | +3 Durchschlagskraft, +30 Reichweite |
| Bolzenschneider | +5 Direkte Aktion, +2 Handarbeit |
| Schwarzfahrer:innen-Mütze | +8 Schwarzfahren |
| Spendendose | +2 Umverteilung |
| Mietendeckel | +1 Kündigungsschutz, immune to Mietzonen |
| Erste-Hilfe-Kurs | +5 Solidarität, reviving costs you half as much HP. **Co-op only** |
| Späti-Sonnenbrille | +5 Direkte Aktion, +5 Eltern |
| Megafon-Akku | +5 Durchschlagskraft, −5 Akkord |
| Arbeitshandschuhe | +4 Handarbeit, +2 Kündigungsschutz |
| Demosani-Weste | +3 Krankenschein, +5 Solidarität |
| Pfandrucksack | +60 Pfandradar, +3 Nebenjob |
| Protestschild | +10 Wut, +15 Reichweite, −5 Deutschlandticket |
| Kiezkarte | +8 Eltern, +8 Vernetzung |

### Purple
| Item | Effect |
|---|---|
| Sondervermögen | +5 Nebenjob, lifts the Schuldenbremse cap |
| Faxgerät | +40 Wut. **Curse:** every attack is delayed by 3 s |
| Streikkasse | At wave end +10 % of your unspent Pfand (max 20) |
| Aus dem Leben eines Taugenichts | +20 Eltern, −10 Akkord; every wave +1 random stat level |
| Lastenrad-Anhänger | +1 weapon slot, −10 Deutschlandticket |
| Tarifvertrag | +25 Wut, +5 Kündigungsschutz, −10 Akkord |
| Volksküche | +5 Krankenschein, +5 Umverteilung |
| Generalschlüssel | +20 Direkte Aktion, −10 Solidarität |
| Soli-Konzert | +30 Akkord, +10 Eltern, −8 Solidarität |

### Red (build items, `Content.RED_BUILD`)
| Item | Build | Effect |
|---|---|---|
| Hausbesetzung | melee | melee weapons ×2 damage, all others ×0.5 |
| Wurfmaschine | ranged | projectiles pierce +1 target and fly 50 % faster; melee ×0.5 |
| Genossenschaftsanteil | saving | each wave end +15 % of your Pfand (max 50), but only 2 purchases per Späti visit |
| Ehrenamtskarte | summons | Infostände and Genoss:innen ×2 damage and duration, own weapons ×0.6 |
| Kompost | status | poison and glue ×2, poison spreads to neighbors on death, direct damage ×0.7 |
| Kritische Masse | crit | crits hit ×1.5 harder, all other hits ×0.7 |
| Robin-Hood-Kostüm | lifesteal | Umverteilung heals ×3, but Krankenschein no longer works |
| Tarnkappe | dodge | Schwarzfahren cap 80 % instead of 60 %, but Kündigungsschutz drops to 0 |

### Hidden
| Item | Effect |
|---|---|
| Vogelschiss | +1 Wut, price 3. Buying it grants the achievement *Fliegenschiss* |
| Reichsausweis | Worthless. Dropped by the Reichsbürger, never sold |

### Politics items (v0.2, spec; from `research/item_ideen.md`)
Twelve items built on real German political events of 2016–2026. The sources are in the research file.

| Item | Rarity | Effect | Event |
|---|---|---|---|
| Erinnerungslücke | purple | +15 Schwarzfahren, −10 Vernetzung | Cum-Ex inquiry, memory gaps |
| Treuhandkonto (Philippinen) | blue | at wave end: 50 % chance (+Eltern/2 %) of +30 Pfand | Wirecard, 2020 |
| Aufhören zu produzieren | blue | standing still for ≥ 2 s: +8 Krankenschein and +10 Kündigungsschutz while you stand | "nicht insolvent, nur aufhören zu produzieren" |
| Wahlversprechen | blue | first 10 s of each wave +40 Wut, afterwards −10 Wut | broken election promises |
| Maut-Vertrag | purple | +60 Pfand immediately on purchase; −8 Pfand at every wave end | PKW-Maut damages |
| BER-Eröffnungstermin | purple | waves 1–9: −10 Wut; from wave 10: +40 Wut, +20 Akkord | BER airport |
| Puma-Schützenpanzer | purple | +25 Durchschlagskraft, +10 Kündigungsschutz; every 18 s all weapons fail for 3 s | all 18 Pumas failed, 2022 |
| Zweiter Wahlgang | purple | once per run: when you'd go down, you're back at 50 % Solidarität instead; −10 Wut | chancellor election in the second round, 2025 |
| Cum-Ex-Erstattung | red (saving build) | at wave end your unspent Pfand is refunded once more (+100 %, max +40); at the end of wave 15 the Betriebsprüfung takes half your Pfand (once) | Cum-Ex |
| Doppelwumms | red (ranged build) | every kill by you explodes twice (150 px, damage 10 + 2 × Durchschlagskraft, scaled by Wut); explosions don't chain; −15 Kündigungsschutz | "Doppel-Wumms", 2022 |
| Brandmauer-Fertigputz | red (armor build) | +50 Kündigungsschutz, enemies touching you are knocked back, −30 Deutschlandticket | the Brandmauer |
| Entlassungsurkunde | red (crit build) | +20 Direkte Aktion; a crit on a non-elite enemy under 30 % HP takes it out at once; −15 Durchschlagskraft | Ampel-Aus, 2024 |

## 13. Enemies

Regular enemies are **archetypes, never real people**. They get **more dangerous over the run**.

There are **no animal metaphors** for capitalists (no "Miethai"; see content guidelines §2).

### From behind the Brandmauer (they enter through the holes)
| Enemy | Role | Mechanic and joke |
|---|---|---|
| **Besorgte:r Bürger:in** | basic swarm | slow, lots of them. Speech bubble: "Man wird ja wohl noch sagen dürfen…" (an invented line) |
| **Telegram-Onkel** | ranged | throws a **Kettenbrief** that splits on every bounce ("forwarded") |
| **Identitärer Hipster** | fast melee | hits **push the player toward the Brandmauer** ("Remigration") |
| **Reichsbürger** | tank | **immune to status effects** (doesn't recognize your authority). Drops a worthless "Reichsausweis" (easter egg) |

### Union
| Enemy | Role | Mechanic and joke |
|---|---|---|
| **JU-Schnösel** | fast, weak | runs to the Brandmauer and **votes a hole in it**, so he's a priority target |
| **Hinterbänkler** | medium | **gets stronger near AfD enemies** ("Mehrheit beschaffen"). |

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
| 1–4 | Besorgte:r Bürger:in, JU-Schnösel, Telegram-Onkel |
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
- They **don't die**. When beaten, they're **"abgesetzt"** and leave **"ins politische Abseits"**, with a fitting exit (yacht, walk-off, private jet, Switzerland). Bosses are never "befördert" and never killed.
- Encounters have an intro card, most with a **real, verified quote** (Geschichtslehrer, Sauerländer, Remigrantin; the Sylt-Clique has none), and beating them unlocks the matching Zitat-Album card.
- **Intro pause:** when the card appears (after about 2.5 s), the game is **paused**: no enemies, no ultimates. It continues when **every player has pressed W, A, S, D or Space**, which gives time to read the quote. In co-op it **waits for everyone**; players who are away (disconnected) don't block it.
- **Elite flees:** if the wave timer runs out while an elite is still alive, it flees with a line ("Kein Kommentar. Wir sehen uns nach der Wahl!") and gives no reward. Only the final boss wave has no timer.
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

## 15. Quotes and speech bubbles

- **Real, verbatim quotes with sources** appear on encounter intro cards, on the start screen (always one of the strongest, also character insult quotes), in the character unlock cards and in the **Zitat-Album**. Each shows speaker, **party**, date and a short context line.
- **No real quotes as speech bubbles during waves.** They block the view. Enemy bubbles during waves are **invented lines** and **status bubbles** ("Verspätung aus betrieblichen Gründen", "Schwarz gefahren!"). Intro quotes stay on the card.
- **Option Sprechblasen** (opacity; *aus* turns bubbles off). Status bubbles stay readable at any setting except *aus*.
- **Only quotes marked `verifiziert` in the research are used** (see [content guidelines](specs/content-guidelines.md)). 62 of 110 verified quotes are curated into the game.
- **Source data:** `research/zitate_de.json`, selection in `research/auswahl.json`.

## 16. Co-op (1–4 players)

| Mechanic | Rule |
|---|---|
| **Solidaritätszuschlag** | Reviving a downed player costs the helper 10 % of their max HP (5 % with Erste-Hilfe-Kurs). The revived player returns with 40 % HP |
| **Scaling** | More players means more enemies and stronger elites |
| **Späti** | One per player. No timer: the next wave starts when every player is "Bereit" |
| **Zusammenhalt** | Shared across the team |
| **Organisation** | Chosen together |

### Koalitionskasse (co-op only; hidden in solo)
- Each player has their own wallet plus a shared pot.
- **Paying in:** 10 Pfand per click.
- **Taking out:** 20 are removed from the pot and you receive **15**: a **25 % Kapitalertragsteuer**.
- **Repairs from the Kasse:** a Brandmauer repair paid from the pot costs **30 % less**. Shared things are paid from the pot **only on purpose**, never automatically.
- The end screen shows **Eingezahlt / Entnommen / Steuermoral** per player. Achievement *Kassenwart:in*: pay in 200 in one run.

### Koalitionsvertrag (vote before waves 4, 8, 12, 16)
Offers a set of modifier options; the result applies for **4 waves** (`Content.VERTRAG`, worse options have a higher "badness"):

| Option | Badness | Effect |
|---|---|---|
| Digitalpakt | 0 | nothing happens |
| Tempolimit | 1 | players −10 Deutschlandticket, enemies 15 % slower |
| Mindestlohn | 2 | +3 Nebenjob for all, enemies +10 % HP |
| Bürokratieabbau | 2 | +25 Vernetzung, one Späti offer fewer |
| Aufrüstung | 3 | +20 Wut for players, enemies +20 % damage |
| Schuldenbremse | 4 | Späti prices −15 %, no regeneration |
| Sanktionen | 5 | income halved, 30 % fewer Pfand drops |

**Vote rules:**
- Everyone **votes or abstains ("Enthalten")**. **"Bereit" is only possible afterwards**, so an unnoticed missing vote can't pick the worst option.
- **Abstentions don't count.**
- **Nobody voted (all abstain): no contract.**
- All counted votes equal: **that option**. Otherwise the **worst option** (highest badness) wins.
- In solo you are the only voter, so your choice always applies.

**Later, optional:** a PvP or "Wahlkampf" mode.

## 17. Meta progression

- **Unlocks** (characters, weapons, items) come from achievements, e.g. "Win as Bürgergeld-Empfänger without buying a weapon" or "Finish a run with an intact Brandmauer" (*Unmöglich*).
- **Zitat-Album:** collectible quote cards with source, date and context, unlocked by beating bosses and elites.
- **Difficulty = Umfrage levels:** 10% → 15% → 20% → 25% …, each step adding a modifier.
- **Achievements (8):** Döp dödö döp (Sylt-Clique), 180 Grad (Geschichtslehrer), Abgesetzt (Sauerländer, unlocks Die Töchter), Remigration (Remigrantin), Unmöglich (intact Brandmauer), Faul, aber effizient (win as Bürgergeld-Empfänger:in without buying a weapon), Kassenwart:in (co-op), Fliegenschiss (hidden Vogelschiss).
- **Saves are stored locally per player.** A host never stores a client's progress.
- **Co-op-only content is hidden in solo:** the Koalitionskasse, its end-screen columns and the achievement *Kassenwart:in*, and the item Erste-Hilfe-Kurs (not offered in the shop).

## 18. Easter eggs

**Implemented:**
- **Vogelschiss:** a hidden item (+1 Wut) with the achievement *Fliegenschiss*.
- **Reichsausweis:** dropped by the Reichsbürger, worthless.
- **BLACKROCK:** typing `BLACKROCK` in the menu turns all currency into stock shares that lose 5 % per wave.
- **Funkloch:** during a wave, every 7–10 minutes a **small, harmless icon** appears at the HUD's right edge for 2 s (a joke "no signal"). It was deliberately made small and rare after it was mistaken for a network error, and it never appears during a real reconnect.
- **Sylt-Clique** hums "♪ Döp dödö döp ♪".
- **Credits** are written in Amtsdeutsch.
- **Aus dem Leben eines Taugenichts** item.
- **Koalitionsverhandlungen:** in wave 20 the HUD timer reads "Koalitionsverhandlungen" and counts up 3x slower than real time.

## 19. Scope (implemented)

- 1 arena with the Brandmauer
- 8 characters, plus Die Töchter as an unlock
- 3 Organisationen
- 12 weapons, 57 items (green/blue/purple/red)
- 20 waves (ramping), with 3 elites/minibosses (waves 5/10/15) and 1 boss (wave 20)
- The Späti with combine, sell, discard and statistics
- Zusammenhalt progression
- Co-op for 1–4 players, with Koalitionskasse and Koalitionsvertrag
- Local meta save, Zitat-Album, 8 achievements
- Options (section 19a)

### 19a. Options
Saved immediately.

| Option | Values |
|---|---|
| **Gesamtlautstärke** | master volume (default 70 %) |
| **Musik** | volume (default 50 %) |
| **Geräusche** | volume (sound effects) |
| **Zielauswahl** | Nächste:r Gegner:in (default) / Meiste Lebenspunkte / Wenigste Lebenspunkte |
| **Fenstermodus** | Vollbild / Maximiertes Fenster / Fenster (default) |
| **Sprechblasen** | opacity (default 70 %), *aus* |

The main menu also has a **Bug melden** button that opens the GitHub bug-report form.

### 19b. Controller support
The whole game is fully playable with a gamepad (Xbox/PlayStation/Switch layouts via Godot's joypad mapping), without touching mouse or keyboard.

| Action | Gamepad | Keyboard |
|---|---|---|
| Move | left stick / D-pad | W A S D / arrow keys |
| Ultimate, continue the boss card | X / □ | Space |
| Streik | Y / △ | Q |
| Pause / back | Start / Options | Esc |
| Confirm in menus | A / ✕ | Enter |
| Back / close dialog | B / ○ | Esc |
| Späti tabs/sections | LB / RB jump between the sections Angebote, Waffen, Items, Kasse, Mauer, Vertrag, Bereit and Werte; the right stick scrolls lists | — |

- **Every menu, dialog and the Späti are navigable with focus:** there's a visible focus frame, focus never gets lost, and the first sensible button gets focus.
- **Prompts show the input in use:** "[X]" instead of "[Leertaste]" once a gamepad was used last, and they switch back when the keyboard is used.
- **Tooltips** are shown for the focused element, not only on mouse hover.
- **Co-op:** each player plays on their own machine, so there's one controller per machine (no local split-screen).

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
