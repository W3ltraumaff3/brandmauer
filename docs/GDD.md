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

**Wave won, short break:** when a wave is over, the arena stays visible for **2 s** with "Feierabend! Welle N geschafft – ab in den Späti." Then the Späti opens. Joining or rejoining while the Späti is open shows it at once.

**Späti without a timer:** the next wave starts when **every player has pressed "Bereit"**. In single player, that's just you. Players who are away (disconnected) don't block the Späti. If a Koalitionsvertrag vote is open, "Bereit" is only possible after voting or abstaining (section 16).

**Giving up / leaving:** the pause menu has *Aufgeben* and *Verlassen*, both with a confirmation ("Wirklich? Nochmal drücken.").

**Performance:** the frame rate is capped at **144 FPS during a run** and **60 FPS in menus** (main menu, lobby, end screen, Album, options); VSync stays on.

**Wave difficulty:** enemies get steadily more dangerous over the run (more of them, stronger, new types). Enemies never get visually smaller or weaker as the run progresses.

## 5. Arena

- **View:** top-down, one fixed arena per run.
- **Brandmauer:** a **rectangle of four straight walls** along the arena edges (top, bottom, left, right), closed all the way around (D-082, supersedes the top-only strip of D-007). It is not round: four straight sides meeting in four corner pillars. The wall and the staging area behind it together stay a narrow frame; the open arena inside is the rest.
  - AfD enemies gather **behind the wall on every side** and walk along it to the nearest hole.
  - CDU-type enemies "abstimmen" during waves and knock holes in the wall, **on any side**. **Each hole becomes a spawn gate.**
  - Holes can be repaired in the Späti with Pfand. The trade-off: leave holes open for more enemies and more loot, or pay to repair them.

### 5a. Arena geometry and wall pressure (D-082)

All numbers live in one place, `Arena` (`src/sim/arena.gd`): the geometry constants plus the `Arena.WALL` dict of tunables. Sim, view, HUD and tools read them from there.

| What | Value | Why |
|---|---|---|
| Sheet (whole world) | 1904 × 1224 px | staging + wall + arena on every side |
| Staging area ("Aufmarschgebiet") | the outer 78 px on every side; AfD enemies stand on a line 40 px from the sheet edge | same depth as the old top strip |
| Wall | 24 px thick, from 78 to 102 px in from every edge | same as the old top wall |
| Inner arena (players) | 1700 × 1020 px (x 102–1802, y 102–1122) | **+21 % area** over the old 1600 × 898, so 4 players have room |
| Segments | top and bottom **12** each (141.7 px), left and right **7** each (145.7 px): **38** in total | segment length stays about the old 133 px, so a hole is as wide as before |
| Corner pillars | four 24 × 24 px pillars, always intact | the corners never become holes; shots never pass them |
| Segment order | clockwise: 0–11 top (left → right), 12–18 right (top → bottom), 19–30 bottom (right → left), 31–37 left (bottom → top) | one index walks the ring |

**Start holes: one per player, at most four.** The middle segment of each side, in the order top, bottom, left, right. Solo keeps the single top hole ("Es gibt immer einen, der mit denen redet."), 2 players get top and bottom, 4 players one per side.

**Where AfD enemies spawn:** each spawn picks a side with weight `side_base + side_hole × holes on that side` (1 + 3 × holes), then a random point along that side's staging line. Every side can always get spawns; sides with holes get more. With one hole per player the spread evens out as the team grows (solo: about half the spawns at the top; 4 players: about a quarter per side).

**Behind the wall** AfD enemies walk along the staging band, around the corners, to the nearest hole (by distance along the ring) at **1.5× speed** (`staging_speed`), then step through it into the arena. With no hole at all they pace along their side, grumbling.

**Other spawns:** Union and Kapital enemies appear just inside the wall on all four sides (uniform over the whole edge), at least 260 px from every living player. The Privatjet still flies in from the left or right, over the wall.

**Hole opening scales with team size and wave:** a JU-Schnösel walks to the nearest intact segment on any side and votes for `vote_time / (1 + 0.25 × (players − 1) + 0.03 × (wave − 1))` seconds (`vote_per_player`, `vote_per_wave`). Base 3 s: solo wave 1 = 3 s, 4 players wave 1 = 1.7 s, 4 players wave 20 = 1.3 s.

**Everything else that touches the wall works on all four sides:**
- **Players** can't leave the inner arena; non-AfD enemies and enemies that came through a hole stay inside too. Pickups land inside.
- **Line of sight** (§6b): a shot or target line is blocked where it crosses an intact segment or a corner pillar, on any side; holes let it through. Projectiles hitting an intact segment or pillar disappear; bouncing projectiles bounce off the inner wall faces.
- **Repairs** (Späti, Koalitionskasse, Antifa-Ortsgruppe every 2nd wave) close the first hole in segment order. An Antifa-Ortsgruppe player standing within 60 px of a hole on any side repairs it in 3 s.
- **"Remigration" pushes:** an Identitärer Hipster pushes the player toward the wall **nearest to the player**. Each push ring of the Remigrantin drives everyone it hits toward **one** wall, the one **nearest to her** when she sends it (in "Steuerparadies" that is the top wall in front of her chalet, as before).
- **Abschiebezone** (Remigrantin phase 2): the 70 px band along the inside of **all four** walls hurts.
- Encounter, boss, turbine and respawn positions are placed relative to the arena centre.
- **HUD:** the wall panel shows the hole count plus a tiny map of the rectangle with holes as red gaps.
- **Visual progression:** the arena starts grey and desaturated and gains color with every Zusammenhalt stage (section 7).
- **Later arenas (not in the MVP):** Marktplatz, Bahnhof, Kleingartenanlage.

## 6. Economy: Pfandflaschen & the Späti

- **Currency: Pfandflaschen.** Enemies drop them.
- **The Späti** (shop between waves):
  - Weapons (**6 slots**; Lastenrad-Grüne has 7), items and stat upgrades (level-ups).
  - Reroll (some characters start with free rerolls), plus Brandmauer repairs.
  - **Offer mix (D-149): one weapon for your build is guaranteed, and so is one item.** The build weapon is placed first (balancing.md §5). Every other offer is a weapon with a chance that drops with each weapon already on the shelf: **35 % for a second weapon, 25 % for a third, never a fourth**; otherwise an item. Locked offers count. With 4 offers that means 1 weapon in 27.5 % of the visits, 2 in 51.5 %, 3 in 21 %, never 4 (before: every offer 35 %, and 4 weapons in about 1 of 70 visits).
  - **Reservieren (lock offers, D-148, D-153):** every unsold offer has a toggle, "Reservieren" / "Reserviert" (mouse: the button on the card; gamepad: **Y** on the focused offer; keyboard: **L**). It costs nothing and can be undone at any time in the Späti ("Reservierung aufheben").
    - **Gamepad and keyboard reach every unsold offer**, also one you can't buy right now (too expensive, no free slot): its Kaufen button keeps focus but looks disabled, and pressing it shows the reason. Saving up for an offer you can't afford yet is the main reason to reserve it.
    - The focused card shows the key on its button ("[Y] Reservieren", PS "[△]"), so the action can be found without the tooltip. With the mouse the key is hidden.
    - A locked offer is **kept exactly as it is** (weapon or item, tier, rarity, **price**) and appears in the **same slot** of the next Späti, at the price of the Späti it was locked in, not the higher new price.
    - Rerolling only replaces unlocked offers. Buying a locked offer uses it up as usual.
    - The lock carries over only one visit. In the next Späti the offer is unlocked again, and you can lock it again (still at the old price).
    - Each player locks their own offers. A Koalitionsvertrag that changes the number of offers never removes a locked offer.
  - **Weapon offers favour your style.** Each weapon scales with melee, ranged, status or summon. The shop looks at how the weapons you hold scale (the starting weapon counts) and favours weapons with the same scaling:
    - chance weight = 1 + 2 × (how well the weapon's scaling matches your weapons' scaling, 0–1)
    - Example: holding only melee weapons makes melee weapons 3× as likely as the others.
    - It is never exclusive: other weapons still show up.
  - **Level-ups can be rerolled too:** a "Neu würfeln" button on the level-up card draws 4 new stat options.
    - It costs the same as a shop reroll (`Content.reroll_price(wave, n)`), but with its own counter `n`. The counter resets in every Späti and whenever a level-up is picked.
    - Free rerolls (Sozialtourist:in) are one shared pool for both and are used first.
  - **"Bereit" must be unmistakable** (co-op Späti and lobby):
    - Not ready: a normal paper button "Bereit?".
    - Ready: the button turns **solid green with white text "Bereit!"**, and a line next to it says **"Du bist bereit"**, plus who the group is still waiting for. Pressing it again takes it back.
  - Prices rise with the wave, faster than 8 % per wave because the curve is cubic (balancing.md §5): ×2.4 in the Späti after wave 8, ×3.1 after wave 10, ×5.0 after wave 14, ×8.5 after wave 19. Weapon tiers I–IV cost ×1.0 / 1.8 / 3.2 / 5.5.
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
| **Tier colors** (D-147) | Weapon tiers use the item rarity colors (section 12): **I green, II blue, III purple, IV red**. A weapon offer gets the border and tier tag in its tier color like an item card (tier IV also the tinted background). The tier is colored wherever a weapon is named with it: the owned-weapon list, "kombiniert zu …" and the Kombinieren button (in the color of the tier it becomes), and the Statistik damage rows (sold or combined rows stay grey) |

### 6b. Targeting

- **No lead aiming:** shots fly at where the target is now.
- **Ground weapons land on the thickest crowd** (v0.4, D-113): Kleber, Kartoffelbrei and Brandmauer-Ziegel don't drop on your Zielauswahl target but on the middle of the densest group of enemies in range (among the 16 nearest you can see). One enemy alone still gets it. The Pappkamerad keeps landing half way to its target, the Infostand stays at your feet.
- **Option Zielauswahl** (per player, default *Nächste:r Gegner:in*): **closest**, **most HP** (elites and bosses first) or **least HP** (clean up fast). Applies to all auto-aiming weapons and turrets.
- **Weapons face their target**; the character's facing follows the shots.
- **Line of sight:** AfD enemies behind the Brandmauer can be targeted and hit **only through holes**, on any of the four sides. An intact wall segment or a corner pillar between you and them blocks the shot (§5a).

### 6c. Statistics panel

The Späti has a **Statistik** button (Esc closes it): a recap after the last wave. It is built top-down by importance (D-152):
- **"Letzte Woche" on top, the only thing that catches the eye:** a few values of the wave just survived, one row per player so the team can compare.
  - Columns: **Schaden** (all damage dealt), **Besiegt** (kills), **eingesammelt** (Pfand picked up), **Eingesteckt** (damage taken), **Geheilt** (Umverteilung + Krankenschein + Demo-Sanis) and **Stärkste Quelle** (the source with the most damage this wave, weapon in its tier color).
  - **Co-op:** one row per player in player order, the local player's row highlighted (tinted, name in red with "(du)"). Away players are greyed. The highest value of each number column is underlined, so you see who carried what.
  - **Solo:** the same strip with a single row and no name column, so there is no empty comparison.
- **"Ganzer Lauf" below, smaller and secondary:** the local player's run totals.
  - **Damage by source:** weapons by tier, ramming (Lastenrad), ultimate, other. Shows last wave, total and share. **Effective damage only:** a hit counts at most the HP the enemy had left (no overkill), so a killing blow on a nearly dead enemy counts little. Sold weapons are marked *(verkauft)*, combined ones *(kombiniert)*. Only this table scrolls when it doesn't fit.
  - **One compact value list** next to it: healed by Umverteilung, by Krankenschein and by Demo-Sanis, damage taken, damage blocked by Kündigungsschutz, dodges, kills, crits, ultimates used, Pfand collected, income and spent. No captions.

## 7. In-run progression: Zusammenhalt

**Zusammenhalt** replaces XP. You earn it by defeating enemies, with a **bonus when you're close to teammates or your own summons**. Team levels drive the stages below.

**Level-up picks** come per Späti visit instead: 1 after waves 1–4, 2 after waves 5–11, 3 after waves 12–19, the same for everyone. Each option has a rarity like the items (green/blue/purple/red, ×1/×2/×3/×5 of the base amount). Fewer, bigger picks keep the Späti short (docs/specs/balancing.md §4).

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
| HP regen | **Krankenschein** | 0.08 HP per second per point (v0.4, D-119) |
| Heal on hit | **Umverteilung** | you take from the enemies: each point is a 1 % chance per hit to heal 1 HP (at most 10 per second, like Brotato) |
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
| **Klimakleber:in** | Huge damage while standing still (+80 % after 0.6 s), slows enemies nearby; −10 Deutschlandticket, +3 Ziviler Ungehorsam | |
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
| Klimakleber:in | **Straßenblockade** | a glue strip across the whole arena at your height; enemies get stuck for 6 s. The strip's puddles overlap on purpose, so an enemy can take damage from several at once (D-101) |
| Lastenrad-Grüne | **Critical Mass** | dash ramming everything in the way, then double speed for 5 s; invulnerable for the whole time (dash + 5 s) |
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

## 11. Weapons (31)

All weapons have tiers I–IV (combine two of the same tier, section 6a). **Copies of the same weapon fire staggered** (D-160): with n copies, copy k is offset by k/n × min(cooldown, 0.5 s). At wave start copy k fires that much **earlier** (0.5 s − offset instead of 0.5 s), so no weapon starts later than before; after a pause without a target it waits that much longer (at most 0.5 s, 0.25 s for two copies). So they don't all fire at the same enemy in the same frame (the later shots were wasted on an enemy the first one had already killed). Values from `Content.WEAPONS`:

| Weapon | Kind | Damage I–IV | Cooldown | Scales with | Notes |
|---|---|---|---|---|---|
| **Gendersternchen** | shot | 6 / 10 / 16 / 26 | 1.0 s | Durchschlagskraft | shuriken, bounces once |
| **Pfandflasche** | shot | 12 / 20 / 32 / 52 (D-161; was 8 / 13 / 20 / 32) | 1.3 s | Durchschlagskraft (1.6; was 0.8) | boomerang, pierces everything, 10 % chance of Pfand |
| **Megafon** | cone (60°) | 5 / 8 / 13 / 21 | 1.1 s | Durchschlagskraft | knockback |
| **Stricknadeln** | shot | 3 / 5 / 8 / 13 | 0.35 s | Durchschlagskraft | fast-firing |
| **Döner-Spieß** | melee cone (25°) | 12 / 20 / 32 / 50 | 0.9 s | Handarbeit | |
| **Grundgesetz** | melee cone (120°) | 9 / 15 / 24 / 38 | 1.2 s | Handarbeit | Article 1: strong knockback |
| **Transparent** | melee 360° | 7 / 12 / 19 / 30 | 1.4 s | Handarbeit | |
| **Mietspiegel** | melee orbit | 6 / 10 / 16 / 26 | 0.5 s | Handarbeit | orbits you, two orbiters from tier III |
| **Tofu** | shot | 3 / 5 / 8 / 13 | 1.0 s | Ziviler Ungehorsam | poison (5 / 8 / 13 / 21 over 3 s) |
| **Farbbeutel** | shot, splash | 7 / 11 / 18 / 29 | 1.3 s | Ziviler Ungehorsam, Durchschlagskraft | slows 40 % |
| **Kleber** | puddle | 4 / 7 / 11 / 18 per s | 2.2 s | Ziviler Ungehorsam | puddle for 3 s: damage per second to everything inside, slows 70 % |
| **Infostand** | turret (max 2 / 2 / 3 / 4 per copy) | 5 / 8 / 12 / 17 (v0.4, D-122; was 4 / 6 / 10 / 15) | 5.0 s | Ehrenamt (0.8) | fires leaflets for 10 / 10 / 15 / 20 s (so the higher tiers really keep more stands up); every copy keeps its own stands (no cap per player); drawn at 55 % size so several stands don't cover the arena. **"Flugblatt wird weitergereicht"** (v0.4, D-115): a leaflet that hits jumps on to the nearest enemy it hasn't hit yet within 140 px, 1 / 1 / 2 / 2 times by tier, −20 % damage per jump (like Unterschriftenliste); no enemy in reach ends it. **"Schnell aufgebaut"** (v0.4, D-117): while a copy has fewer stands than its maximum (wave start, after Kahlschlag), the next stand follows after 1 s instead of the 5 s cooldown, so two stands are up within the first 1.5 s of a wave. A bounce, not pierce: Wurfmaschine's +1 pierce doesn't apply (the Infostand isn't a ranged weapon) |

### New weapons (v0.2, spec; from `research/waffen_ideen.md`)
Each one fills a niche no other weapon covers. Tier damage follows the existing curve (×1.67 / ×2.67 / ×4.3 of tier I).

| Weapon | Kind | Tier-I dmg | Cooldown | Range | Scales with | Special / niche |
|---|---|---|---|---|---|---|
| **Kartoffelbrei** | lob | 18 | 3.0 s | 340 | Durchschlagskraft | target marker on the ground, impact after 0.8 s, radius 110; pure area burst, no slow. Flavor: keep your distance from paintings |
| **Trillerpfeife** | cone 360° | 5 | 2.0 s | 150 | Handarbeit 0.6 | stuns everything around for 0.6 s instead of knockback; control, barely any damage |
| **Brandmauer-Ziegel** | line wall | 3 per 0.5 s | 4.0 s | 220 | Ehrenamt | a wall 140 px wide across the target direction for 6 s, slows enemies inside by 40 % and damages them; max 2. An enemy takes each wall's damage once, however many of its bricks it touches; standing in both walls hurts twice (D-089) |
| **Normenkontrolle** | mark | 45 | 4.5 s | 360 | Ziviler Ungehorsam | marks the strongest enemy in range; after 3 s it's "nichtig erklärt" (burst); boss killer |
| **Unterschriftenliste** | chain | 5 | 1.4 s | 260 | Durchschlagskraft 0.9 | instant hit that jumps to 3 more enemies within 120 px, −20 % per jump |
| **Enthüllungs-Scheinwerfer** | beam | 14 | 2.2 s | 400 | Durchschlagskraft | instant straight beam that hits everything in line; hit enemies are "enthüllt": +15 % crit chance against them for 5 s |
| **9-Euro-Ticket** | fan | 3 × 9 tickets | 1.5 s | 180 | Durchschlagskraft 0.5 | 9 projectiles in a 60° fan; from wave 4 only 5 ("läuft ab") |
| **Weißer Overall** | swarm | 6 per activist | 4.0 s | 300 | Ehrenamt | 3 activists in white overalls each run at a different enemy, hit once, leave. **"Blockade-Knäuel"** (v0.4, D-115): on arrival the activist also hits every other enemy within 55 px for half the damage, all knocked back from the impact point |

### More melee and zone weapons (v0.3, spec; user choice)

| Weapon | Kind | Tier-I dmg | Cooldown | Range | Scales with | Special / niche |
|---|---|---|---|---|---|---|
| **Demo-Fahnenstange** | melee thrust | 10 | 1.0 s | 190 | Handarbeit 0.9 | jabs straight at the target and hits everything in a 18 px wide line; small knockback. Niche: melee with reach |
| **Bierkiste vom Späti** | melee 360° | 22 | 2.4 s | 120 | Handarbeit 1.2 | slow, heavy slam all around: big knockback (220), stuns non-elites for 0.3 s. Niche: heavy hitter |
| **Straßenkreide** | trail zone | 9 per s | 0.35 s | — | Ziviler Ungehorsam 0.8 | needs no target: leaves chalk marks (radius 26, 4 s) behind you while you move; enemies on them take damage per second. Standing still renews the last mark instead of stacking, and the renewed mark grows into a **chalk circle** around you (+12 px per renewal up to radius 60), so enemies that reach a standing player stand in chalk (v0.4, so a standing Klimakleber:in isn't punished). Niche: kiting, making enemies chase you over your trail; standing: a small damage ring |

Like every weapon, they damage status-immune enemies too (D-079). Tier damage follows the usual curve.

### Status and summon weapons (v0.3, spec; from `research/waffen_ideen_status_beschwoerung.md`, D-091)

The status build needs **defence and damage that still lands on the Reichsbürger**; the summon build gets **utility instead of raw DPS** (balancing.md §2). Tier damage follows the usual curve (×1.67 / ×2.67 / ×4.3). Starting values; the balancing round tunes them with bot batches.

| Weapon | Kind | Tier-I dmg | Cooldown | Range | Scales with | Price | Special / niche |
|---|---|---|---|---|---|---|---|
| **Kleine Anfrage** | shot, pierces 1 | 12 (v0.4; was 10) | 1.2 s | 360 | Ziviler Ungehorsam 1.3 (was 1.0) | 24 | a file folder; a hit puts the enemy **"In Bearbeitung"** for 3 s. Aims first at enemies whose ability is running or coming (a voting JU-Schnösel, then any other enemy with an ability that isn't in Bearbeitung yet), else at your Zielauswahl target. Niche: the only answer to enemy abilities; protects the Brandmauer |
| **Lobbyregister** | shot | 3 | 0.7 s | 340 | Ziviler Ungehorsam 0.5 | 26 | fast sheets of paper; every hit adds one **"Aktenkundig"** stack (max 5). A hit on an enemy that already has 5 stacks is **"Offengelegt!"**: a burst of 16 / 27 / 43 / 69 (+1.2 × Ziviler Ungehorsam), the stacks drop to 0. Niche: single-target build-up that helps the whole team (+25 %) |
| **Faktencheck** | cone 90° | 10 (v0.4; was 12) | 1.6 s | 170 | Ziviler Ungehorsam 1.2 (was 1.3) | 22 | **"Rolle rückwärts"** for 1.2 / 1.3 / 1.4 / 1.6 s on everyone in the cone, no knockback; the damage goes to the 4 nearest only (crowd cap); wipes enemy projectiles (Kettenbriefe, Golfbälle …) inside the cone. Niche: defence for the status build, drives enemies back into your own zones |
| **Soli-Sticker** | shot | 6 + 3.5 per s for 4 s (v0.4; was 5 + 2.5) | 0.9 s | 320 | Ziviler Ungehorsam 0.6 (hit), 0.35 (per s; was 0.25) | 24 | the hit sticks a sticker on (poison 3.5 / 6 / 9 / 15 per s). Once per second every stuck enemy passes a fresh 4 s sticker to **one** sticker-free enemy within 50 px (the giver isn't refreshed; an enemy whose sticker just fell off takes no passed-on sticker for 4 s, so two enemies can't keep one alive forever); at most 12 stuck enemies per player. Niche: the only damage over time that grows with enemy density |
| **Menschenkette** | tether | 5 per 0.5 s (v0.4; was 4) | 5.0 s | 320 (chain) | Ehrenamt 0.8 (was 0.7) | 26 | for 6 s four activists hold hands from you to the **nearest living teammate within 320 px**; solo (or nobody close) to a **lamppost** set down toward your target (at most 220 px away). The chain moves with its ends and tears beyond 320 px (no damage while torn), it re-forms when the ends are close again. Enemies touching it take damage and are pushed back (120; elites only take damage). Max 1. Niche: a moving line the players lead together |
| **Pappkamerad** | decoy | 14 burst | 7.0 s | 220 (placing) | Ehrenamt 1.0 | 24 | sets down a cardboard straw man for 8 s (HP 25 + 15 × wave + 5 × Ehrenamt). Non-elite enemies within 240 px go for it instead of you; ranged enemies shoot at it. When it falls or its time is up it bursts into confetti (radius 90). Max 1. Niche: the decoy/tank, the only summon that binds enemies |
| **Demo-Sanis** | follower | 3 shove | 3.0 s | 160 (heal radius) | Ehrenamt 1.0 | 24 | a Demosanitäter:in follows you (40 px behind) for the whole wave. Every 3 s (faster with Akkord) she heals the most injured living player within 160 px by 2 / 3 / 5 / 8 (+0.3 × Ehrenamt) and shoves enemies within 70 px away ("Platz da!": small damage, knockback 100). A downed player next to her is revived 50 % faster. One per weapon copy. Niche: the only healing weapon, a support slot for co-op |
| **Lauti** | patrol | 12 per pulse (v0.4; was 8) | 6.0 s | 90 (orbit) | Ehrenamt 1.2 (was 1.0) | 24 | a small sound truck circles you for 10 s; every 1.0 s (faster with Akkord) a ska pulse hits the 4 nearest enemies within 120 px of the truck (so everything touching you is in reach), knockback 80. Max 1 (casting again refreshes it). Niche: the first summon that comes along, so a summon build can kite |

**Rules for all eight:**
- **Every one damages every enemy (D-079, D-096).** At least 60 % of a status weapon's damage still lands on status-immune enemies: Kleine Anfrage, Faktencheck 100 %, Lobbyregister ~85 % (the Offengelegt count runs on immune enemies too, only the +5 % doesn't), Soli-Sticker ~70 % (the hit).
- **One hit per enemy per tick per weapon:** a chain or a pulse hits an enemy once, however many of its parts touch it.
- **Ehrenamtskarte** (red, summon build): every weapon that scales with Ehrenamt gets ×1.5 damage and healing and twice the lifetime (D-114).
- **Gewerkschaftsmitglied's passive** counts the Pappkamerad like any other own summon, but not the Lauti, the Demo-Sanis or the Menschenkette: they are always next to you and would give a permanent bonus.
- **Kompost** (red, status build) doubles the Soli-Sticker poison; the Offengelegt burst counts as status damage (no ×0.7); control effects stay unchanged.
- **Away owner (networking.md §7.4):** a Demo-Sani stays with the frozen figure and keeps healing the others; the Lauti keeps circling it; the chain switches to the lamppost; a Pappkamerad stands until its time is up.

**Flavor (Späti description, invented satire lines; never presented as quotes):**
- Kleine Anfrage: "551 Fragen an die Zivilgesellschaft? Hier kommt Frage 552." (fact: 551 questions, Drucksache 20/15035; the real wording only ever appears as a verified quote card, cdu-fraktion-01)
- Lobbyregister: "Eintragungspflichtig. Jeder Treffer kommt in die Akte." A Leitz folder, no money bags or briefcases (content guidelines §2)
- Faktencheck: "Wirkt nur kurz. Aber es wirkt."
- Soli-Sticker: "Laternenmast, Stromkasten, Porsche-Heckscheibe. Hält überall." Generic own motifs only (heart, rainbow, bicycle), no real party logos, no banned symbols, not even crossed out
- Menschenkette: "Hand in Hand. Und wer durch will, fliegt zurück." (03.02.2024, "Wir sind die Brandmauer")
- Pappkamerad: "Sie kämpfen gegen einen Pappkameraden. Wie immer." A faceless cardboard figure holding a sign with a crossed-out schnitzel (the invented "Verbotspartei"). It shows **no real person** and **no real group**, in particular no queer figure: enemies would be hitting it
- Demo-Sanis: "Pflaster, Wasser, Rettungsdecke. Und niemand bleibt liegen." Drawn competent and as part of the group (§7: no outside hero). Green cross, **not the protected Red Cross emblem**
- Lauti: "Vorne Ska, hinten die Ordner:innen." Named "Lauti" because the item Lautsprecherwagen already exists

### Status effects on enemies (D-092)

Every status effect goes through the one immunity check (D-087): **the Reichsbürger is immune to all three.** Each has its own symbol above the enemy so it reads at a glance.

| Effect | From | Rule | Elites and bosses | Symbol |
|---|---|---|---|---|
| **In Bearbeitung** | Kleine Anfrage | 3 s without special ability: the JU-Schnösel's vote timer pauses, the Telegram-Onkel doesn't throw, the Golfclub-Vorstand doesn't lob, the Immobilienerbe lays no Mietzone, the Porsche-SUV doesn't start a charge, the Lobbyist's Hausausweis gives no armor, the Hipster doesn't push. An FDP-Jungunternehmer that dies "in Bearbeitung" founds no startups ("noch in Bearbeitung"). Moving and contact damage go on | their ability timers run at half speed instead of stopping | a numbered waiting ticket ("Nr. 552") |
| **Aktenkundig** | Lobbyregister | stacks 1–5; every stack is +5 % damage **from every player and every source** (hits, poison, zones); lasts 5 s, each Lobbyregister hit refreshes it; when it runs out all stacks go. A Lobbyist with 3 or more stacks loses his Hausausweis aura | full effect (a boss tool) | a stack of 1–5 file sheets |
| **Rolle rückwärts** | Faktencheck | walks backwards away from the nearest player at 70 % speed, still facing them; abilities pause; contact damage stays (whoever walks into it is hit). No knockback, so enemies keep their formation and walk back into Kleber or Kreide. Only inside the arena | immune (like stun) | "↺" above the head, the figure turns away |

Soli-Sticker's poison is its own effect (it doesn't replace a Tofu poison and isn't replaced by one); it shows as the usual poison tint plus a small sticker on the enemy.

## 12. Items (69 in the shop pool, incl. 2 hidden)

Every item is a stat change and/or a rule flag. Throwing items away: section 6a.

### Rarities and shop weights
| Rarity | Color | Meaning | In the shop (weight at wave *w*) |
|---|---|---|---|
| 1 | green | one simple bonus | always (10) |
| 2 | blue | good bonus, sometimes with a malus | always, more often later (3 + 0.35·*w*) |
| 3 | purple | very good bonus, malus if very very good | from wave 4 (0.35·(*w*−3)) |
| 4 | red | game-changing, only for one specific build | from wave 8, rare (0.12·(*w*−7)) |

Luck (**Eltern**) shifts the weights toward rarer tiers. Red items carry a **"ROT · Build-Item"** stamp in the Späti. Item prices grow with the wave like weapon prices (section 6).

**What a red item has to be worth (D-127):** when it shows up (Späti after wave 8–12) a red item costs about as much as a whole Späti visit's Pfand (90 base → about 220 after wave 8, 280 after wave 10, 450 after wave 14, against 200 / 245 / 510 Pfand on arrival in bot runs). So a red item must clearly beat what that visit would otherwise buy (2–3 blue or purple items, or a weapon tier): for its build it is the run's big step, about ×1.5–2 on what the build lives on, with a malus for everything else. Money items must pay back their price within about 3 waves and keep their value while prices grow, so their amounts scale with the price factor instead of being fixed.

### Green
| Item | Effect |
|---|---|
| Bierdeckel-Steuererklärung | Does absolutely nothing. The tooltip is the joke |
| Thermoskanne | +3 Krankenschein |
| Kirschkernkissen | +2 Krankenschein |
| Soli-Button | +10 Solidarität |
| Fahrradhelm | +6 Solidarität |
| Isomatte | +2 Kündigungsschutz |
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
| Mate-Kiste | +12 Akkord, −3 Solidarität |
| Gewerkschaftsweste | +2 Kündigungsschutz, +5 Solidarität |
| Wut-Tagebuch | +10 Wut |
| Lautsprecherwagen | +2 Durchschlagskraft, +30 Reichweite |
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
| Wurfmaschine | ranged | every weapon that scales with Durchschlagskraft ×1.4 damage; every player projectile (shots and the 9-Euro-Ticket fan) pierces +1 target and flies 50 % faster; melee ×0.5 (D-128, was pierce and speed only, and the fan was left out) |
| Genossenschaftsanteil | saving | price 60: at every wave end a **dividend on your Pfand**: 30 %, +5 % for every wave end you have held the share (up to 50 %), at most as much as a new share costs in that Späti. No purchase limit (D-129, was price 80, +15 % up to 50 Pfand and only 2 purchases per visit) |
| Ehrenamtskarte | summons | every weapon that scales with Ehrenamt (Infostand, Brandmauer-Ziegel, Weißer Overall, Menschenkette, Pappkamerad, Demo-Sanis, Lauti) and the Genoss:innen: ×1.5 damage and healing, twice the duration; all other weapons ×0.6 (D-114, was ×2 for summon kinds only and ×0.6 for Ziegel and Overall) |
| Kompost | status | poison and glue ×2, poison spreads to neighbors on death, direct damage ×0.7 |
| Kritische Masse | crit | +15 Direkte Aktion; weapon crits hit ×2 harder, all other weapon hits ×0.75 (D-131, was no crit, ×1.5 / ×0.7: a loss below ~30 % crit chance, where the crit build stands when red items show up) |
| Robin-Hood-Kostüm | lifesteal | +10 Umverteilung; every Umverteilung heal is 4 HP instead of 1; your Krankenschein counts as Umverteilung (it no longer heals over time, its points are added to Umverteilung) (D-134, was ×3 heals and Krankenschein simply stopped working) |
| Tarnkappe | dodge | +50 Schwarzfahren, cap 80 % instead of 60 %, but Kündigungsschutz drops to 0 (D-135, was without the +50) |

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
| Treuhandkonto (Philippinen) | blue | at wave end: 50 % chance (+Eltern/2 %) of +30 Pfand × the price factor of the next Späti (D-150) | Wirecard, 2020 |
| Aufhören zu produzieren | blue | standing still for ≥ 2 s: +8 Krankenschein and +10 Kündigungsschutz while you stand | "nicht insolvent, nur aufhören zu produzieren" |
| Wahlversprechen | blue | first 30 s of each wave −10 Wut (the promise), afterwards +30 Wut (broken again, D-154). Waves 1–2 last 30 s, so there it is only the malus | broken election promises |
| Maut-Vertrag | purple | +60 Pfand × price factor immediately on purchase; −8 Pfand × price factor at every wave end (D-150) | PKW-Maut damages |
| BER-Eröffnungstermin | purple | waves 1–9: −10 Wut; from wave 10: +40 Wut, +20 Akkord | BER airport |
| Puma-Schützenpanzer | purple | +25 Durchschlagskraft, +10 Kündigungsschutz; every 18 s all weapons fail for 3 s | all 18 Pumas failed, 2022 |
| Zweiter Wahlgang | purple | once per run: when you'd go down, you're back at 50 % Solidarität instead; −10 Wut | chancellor election in the second round, 2025 |
| Cum-Ex-Erstattung | red (saving build) | price 60 (was 80); at wave end your unspent Pfand is refunded once more (+100 %, max +40 × the price factor of the next Späti, so the cap keeps its value; D-130, was a flat 40); at the end of wave 15 (or the first wave end after it) the Betriebsprüfung takes half your Pfand (once) | Cum-Ex |
| Doppelwumms | red (ranged build) | every kill by you explodes twice (150 px, damage 20 + 3 × Durchschlagskraft, scaled by Wut; D-133, was 10 + 2 ×); explosions don't chain; −10 Kündigungsschutz (was −15) | "Doppel-Wumms", 2022 |
| Brandmauer-Fertigputz | red (armor build) | +50 Kündigungsschutz, enemies touching you are knocked back, −30 Deutschlandticket | the Brandmauer |
| Entlassungsurkunde | red (crit build) | +30 Direkte Aktion; a crit on a normal enemy under 40 % HP takes it out at once, a crit on an elite, miniboss or boss deals ×1.5 instead; −10 Vernetzung (D-132, was +20, under 30 %, −15 Durchschlagskraft, which took the crit build's damage away) | Ampel-Aus, 2024 |

All twelve politics items are in the shop pool: the four red ones since D-127, the other eight since D-150. Before, none of them could be offered: they were added to the item definitions in v0.2 but not to the shop list `Content.ITEM_ORDER`. A content test now requires every item definition to be in that list. With D-150 the flat Pfand amounts follow the price factor of the next Späti like Cum-Ex (D-130): Treuhandkonto +30 × factor, Maut-Vertrag +60 × factor on purchase and −8 × factor at each wave end.

## 13. Enemies

Regular enemies are **archetypes, never real people**. They get **more dangerous over the run**.

There are **no animal metaphors** for capitalists (no "Miethai"; see content guidelines §2).

### From behind the Brandmauer (they enter through the holes)
| Enemy | Role | Mechanic and joke |
|---|---|---|
| **Besorgte:r Bürger:in** | basic swarm | slow, lots of them. Speech bubble: "Man wird ja wohl noch sagen dürfen…" (an invented line) |
| **Telegram-Onkel** | ranged | throws a **Kettenbrief** that splits on every bounce ("forwarded") |
| **Identitärer Hipster** | fast melee | hits **push the player toward the Brandmauer** ("Remigration") |
| **Reichsbürger** | tank | **immune to status effects** (doesn't recognize your authority): no slow, poison or stun, from any source: weapons (Kleber, Farbbeutel, Tofu, Trillerpfeife, Bierkiste, Brandmauer-Ziegel), ultimates (Flashmob, Antrag gestellt, Straßenblockade, Fragen Sie mal uns) and the Streik freeze (D-087), and none of In Bearbeitung, Aktenkundig, Rolle rückwärts or the Soli-Sticker poison (§11, D-092). Every weapon still damages him (Kleber hurts, it just doesn't slow him); knockback and damage bonuses against him (Scheinwerfer "enthüllt", double damage) still apply. Drops a worthless "Reichsausweis" (easter egg) |

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
- **Phase 2 "Remigration":** push waves drive all players toward the Brandmauer wall nearest to her, and the arena edge (all four sides) becomes the danger zone.
- **Phase 3 "Steuerparadies":** she retreats behind a vault shield of gold bars in a Swiss chalet, and the players have to break the shield (from v0.4.1 fed by Briefkastenfirmen, see "The final exam").
- **Exit:** she **emigrates to Switzerland**. That's the closing joke: the only person in the game who actually "remigriert".
- Content rule: none of her phases may summon or depict the groups she insults. Her attacks target only the players and the environment.

#### The final exam (v0.4.1, D-140 to D-145)
Playtest (solo, v0.4.0): the Sauerländer was harder to beat than she was. She has to be the hardest fight of the run and can fail on a first try; Boss-Wiederholung (balancing.md §8) catches that. Three signature attacks of her own, denser phases, a soft enrage and more HP. Every number lives in `Content.BOSS`; telegraphs follow the boss-rule standard below (red dashed + growing fill, "stand here" blue-turquoise with a hand), shrink with Umfrage and never fade with Eigene Effekte.

| Phase | Her attacks (new in **bold**) | Cadence |
|---|---|---|
| 1 Windmühlen der Schande | **Ansturm-Kette** with falling turbines; wing fans (3, 5 from 25 %) | a chain every 3.5 s; wings every 2.2 s |
| 2 Remigration | Die Brandmauer hält (band + push rings); **wing fans** (she had no aimed attack here); **Reichweite** | rings 3.5 → 2.6 s; wings 2.6 s; Reichweite 6 s after the band arms, then every 16 s (13 s at 35 %) |
| 3 Steuerparadies | gold-bar shield 20 % (was 25 %) fed by **Briefkastenfirmen**; gold bars; push rings; **Reichweite** | gold every 1.2 s; rings every 4.5 s (was 6); Reichweite every 14 s (11 s at 35 %) |
| any, after 150 s (120 s from 30 %) | **Wahlabend**: every 15 s +10 % tempo and cadence, up to +50 % | |

**Signature attacks:**
- **Ansturm-Kette (P1, rework of her charge).**
  - Instead of one charge every 3 s she runs a chain of 2 charges (3 from Umfrage 30 %, +1 from 3 players), 0.25 s apart, every 3.5 s.
  - Each charge: an 0.8 s wind-up (cast "Ansturm!") with a red dashed **lane** (84 px wide, 380 px + her radius long) whose fill runs to the tip, then she sprints 380 px at 760 px/s and hits for 1.5× contact damage, once per charge and player. Every charge of a chain picks a new random living player.
  - Don Quixote: if a turbine stands within 160 px of her target, she charges the turbine. A turbine she runs into **falls in the charge direction**: a 1.0 s warning (the mast tips over a dashed red line), then the rotor lies there for 3 s as a 260 × 44 px line that hurts (1× contact damage per hit).
  - **Answer:** sidestep the lane; don't hide behind a turbine she is aiming for (turbines still block her wing fans, so cover is a trade-off); a stun during a wind-up breaks the whole chain (D-106).
  - **Satire:** the windmill speech (`weidel-05`, on the intro card): Don Quixote who actually wins against the windmills, and the players lose the cover the turbines gave them.
- **Reichweite (P2 and P3, new).**
  - Her broadcast floods the whole arena: a 3.0 s warning (cast "Reichweite sendet …", 2.4 s at 35 %; an arena change, B8; from the middle the nearest safe strip can be ~550 px away), the arena fills red from her outward. Only the strips **in front of intact Brandmauer segments that aren't next to a hole** stay blue-turquoise ("Brandmauer", hand icon), 160 px deep. Without any hole every segment is safe (the old 70 px band still burns along the wall then).
  - At the end every living player outside a safe strip takes 2× her contact damage, once. One safe player answers: "Hier endet eure Reichweite. Die Brandmauer steht!" (invented).
  - Combined pattern: the cast opens with a push ring toward the holes, so players get shoved toward exactly the places where they are not safe.
  - **Answer:** run to an intact stretch of wall, dodge or absorb the ring; stun interrupts it. Every hole the run left open (and every Sauerländer vote that passed) costs safe wall here, so repairing in the Späti and the Antifa-Ortsgruppe pay off. Co-op: start holes (one per player) leave fewer safe strips, teammates have to share them.
  - **Satire:** her message only reaches this far because a billionaire's platform amplifies it (the live talk on X, context of `weidel-03`); where the Brandmauer holds, her reach ends. That's the game's title as a mechanic: the players stand together at the firewall, they don't run from her.
- **Briefkastenfirmen (P3, new; research R3).**
  - With her gold-bar shield (20 % of max HP) come **letterboxes** ("Briefkastenfirma", a gold box covered in company plates): 3 solo, 4 from 2 players, in the corners 200 px from the walls. They don't move or attack; each has 0.7 % of her max HP (so they scale with players and Umfrage like she does).
  - While a letterbox stands, a gold dashed line with coins runs from it to her and it **recharges her shield** by 0.1 % of her max HP per second (up to the 20 %).
  - **When the last one falls, her shield breaks** ("Das Steuerparadies hat Risse!"). 25 s later (18 s at 35 %) all of them open again together at new free spots (corners and the middles of the sides, never her chalet): "Neue Adresse, gleiche Firma." (invented), and the shield regrows from zero. So the fight has a rhythm: clear the letterboxes, then a window on her. Single boxes don't come back on their own. They are not encounter units: she can be beaten with letterboxes standing.
  - **Answer:** switch targets (target mode "closest" and walk to a corner), split up in co-op (one person per corner), put summons in the corners.
  - **Satire:** structure, not person (content guidelines §2): the tax haven as an address with a hundred company plates. No money bag, no greed caricature, and no claim that she evades taxes; `weidel-09` (inheritance tax "gegen Null") and `weidel-10` ("Ich zahle hier meine Steuern", her Swiss residence) stand on the cards next to it.
- **Wahlabend (soft enrage, research R4).** From 150 s of her fight (120 s from Umfrage 30 %), every 15 s one step: +10 % movement, wing/gold tempo and signature cadence, up to 5 steps (+50 %). Her bubble "Neue Hochrechnung: Wir legen zu!" (invented); the boss bar shows "Hochrechnung +20 %". Keeps slow builds from sitting the fight out; with Boss-Wiederholung a failed try costs time, not the run.

**HP and tuning (D-145):** `final_boss_mult` 4.5 → 5.5, measurements in balancing.md §7 "Final boss (v0.4.1)". Target: with the same build she takes clearly longer than the Sauerländer; strong builds 90–150 s at the top Umfrage; a first try can fail.

**Co-op (networking.md: one code path):** chain length +1 from 3 players; every charge re-picks a random target; a fourth letterbox from 2 players and letterbox HP follows her max HP (which scales with the team); Reichweite and the safe strips work the same for everyone; the HUD and view read everything from the snapshot (letterboxes are enemies, lanes/rotors/Reichweite are hazards with `h_ang`, the Wahlabend step `hoch` is in the boss block: snapshot version 5, protocol 6).

### Boss rules (spec, D-102 to D-104; design in research/boss_ideen.md)
Goal: bosses take long enough for their mechanics to matter (elites 25–45 s, final boss 60–90 s for a strong build), and ultimates help without ending the fight. Normal waves stay as they are; only encounter units (elites, minibosses, boss) change. All numbers are starting values for the next balancing round.

**Rules for every encounter:**
- **Phase lock:** damage can't skip a phase boundary (66 % / 33 %); damage beyond the boundary is lost. At each phase change the boss holds a **"Pressekonferenz"** for 3.5 s (2.5 s from Umfrage 30 %, D-158): it's invulnerable (golden outline), walks to the middle, a banner above the boss bar shows the phase name, stun and slow on it end, and any running vulnerability is paused, not used up. This replaces the separate "faster below 50 %" rule.
- **Random targets:** encounter attacks don't always aim at the nearest player. Every 4–7 s (random) the boss picks a random player who is alive and not away; it may pick the same one again. Abilities that work "per player" create one instance per player.
- **Resistance:** a stun on an encounter unit lasts half as long, then the unit is **"Standfest"** for 10 s (15 s from Umfrage 30 %): immune to further stuns, shown by a press-spokesperson shield icon. Every stun **interrupts the ability the boss is casting** ("UNTERBROCHEN"). Slow from any source (Kleber, Straßenblockade, Antrag gestellt, …) is capped at 40 % on bosses and minibosses (the Sylt-Clique, tier 1, stays uncapped).
- **Melee hits harder:** melee weapons deal ×2 damage to elites, minibosses and bosses (v0.4, D-121); they have to stand next to them.
- **Ultimates:** "Fragen Sie mal uns" makes the Sauerländer take ×1.5 damage (was ×2) for 6 s. Against the final boss every player's ultimate recharges at each of her phase changes (up to 3 uses in the fight). Critical Mass and Urlaubsantrag stay unchanged.
- **HP:** new `diff_boss_hp` +0.15 per Umfrage level (×1.0 at 10 % up to ×1.75 at 35 %), on top of `diff_hp`, only for encounter units. Tuned in the v0.4 balancing round (D-118): `final_boss_mult` 4.5 (D-102: 1.6; 5.5 since v0.4.1, D-145), per-encounter `hp_mult` Sylt-Clique 1.25, Geschichtslehrer 2.2, Sauerländer 2.0 (D-102: 1.0 / 1.4 / 1.6), `elite_coop` 0.3 (D-102: 0.5; co-op teams deal less damage per player than solo, so elites fled at the wave timer).
- **Telegraphs:** enemy danger is red with a dashed edge and a fill that grows until impact; lasting zones are red hatching; "stand here" zones are a solid blue-turquoise ring with a hand icon. Minimum warning times: 0.8 s for a targeted impact, 1.2 s for arena-wide attacks, 2.0 s for arena changes; Umfrage shortens them by at most 25 %. Boss telegraphs never fade with **Eigene Effekte**.

**New abilities:**
- **Geschichtslehrer, "Wende um 180 Grad" (rework):** the first reversal comes 4 s into the fight, then every 10 s, with a 1.5 s "3 – 2 – 1" countdown and a 180° arrow over every player. In phase 2 his flying book rings turn around too and come back through the arena. From Umfrage 25 % only one axis flips (left/right or up/down), shown by a big arrow. The reversal lasts 4 s (5 s from 30 %).
- **Sauerländer, "Abstimmung, egal mit wem":** at each phase change and every 20 s after, he walks to an intact wall segment on the side with the fewest holes and holds a vote for 3.0 s (2.2 s at 35 %). The segment glows red and a progress bar shows "Abstimmung läuft …". Around the segment there is **one "Plenum" circle per player** (blue-turquoise). **The vote fails** if enough circles are occupied at the same time: **all circles with 1 or 2 players, players − 1 circles from 3 players on.** It also fails if the players deal 6 % of his max HP during the vote (9 % at 35 %), or if he gets stunned. A failed vote stuns him for 1.5 s ("Keine Mehrheit? Dann halt nächste Woche." — invented). A vote that passes tears the segment open as a **hole that stays until it's repaired in the Späti**, and 4 + 2 × players AfD enemies come straight through it ("Mir doch egal, wer zustimmt." — invented). From 35 % he votes on two neighbouring segments at once.
- **Sauerländer, "Kahlschlag" (from phase 2):** a 90° cone (1.2 s red warning) that deals damage and **removes the players' summons and zones** in it (Infostände, Kleber puddles, Straßenkreide, walls, …), so status and summon builds have to move. Every 14 s (11 s from 25 %, two cones at 35 %).
- **Remigrantin, "Die Brandmauer hält" (rework of phase 2 "Remigration"):** the deportation band only works in front of open wall segments (each hole ± 1 neighbouring segment), 110 px wide (150 px from 25 %; in co-op 110 − 10 × (players − 1) px), and push rings push toward the hole nearest to you. With no hole in the wall she falls back to the old 70 px band along every wall ("Sie findet immer eine Lücke."). So repairing the wall during the run pays off in the final fight; the Antifa-Ortsgruppe repairs here too. Push rings come every 3.5 s (2.6 s at 35 %), with a 2.0 s warning at phase start.

Bug fix that comes with this: the Sauerländer's walk targets and money drops (and the Stadtbild passers-by) still use the old arena coordinates and never reach the right quarter or bottom third; they must use `Arena.INNER`. The Antifa Sitzblockade had the same bug and is fixed with it (D-109).

**Implementation details (D-106 to D-112):** every number lives in `Content.BOSS` (and `hp_mult`, `slow_cap`, `ult_per_phase` in `Content.ENCOUNTERS`), so the balancing round can tune it.
- **One phase system (D-106):** the tempo of the old 50 % rule moves into the phases (×1.0 / ×1.2 / ×1.4 for movement and basic attacks); signature abilities and telegraphs keep real time. The Sylt-Clique shares one phase and one lock on the group's total HP; its phases are "Vorglühen", "Sekt für alle", "Letzte Runde" (invented).
- **Resistance (D-107):** Standfest covers the halved stun plus 10 s (15 s from 30 %). Interruptible casts: Wende countdown, Abstimmung, Kahlschlag, the Remigrantin's Ansturm wind-up and her Abschiebezone warning. A failed vote's 1.5 s stagger is the boss's own and starts no Standfest. The slow cap also limits Antrag gestellt and Streik. New telegraphs shrink with Umfrage by ×1.00 / 0.95 / 0.95 / 0.90 / 0.85 / 0.80.
- **Abstimmung (D-109):** first vote after 20 s or at the first phase change; he hurries there at ×2.5 speed (5 s at most); the segment glows and the Plenum circles (radius 70, 230 px in front of the wall, 160 px apart) appear when he sets off; the vote starts when he arrives. No other attacks while he votes. AfD enemies spawn behind the hole and come through it.
- **Kahlschlag (D-110):** 90° cone, 380 px, at his current target, 1.5× contact damage; removes every summon a player owns and the zones Kleber, Sitzblockade, Brandmauer-Ziegel, Straßenkreide (not the Oma, not the turbines). He stands still during the warning.
- **Die Brandmauer hält (D-111):** neighbours count only on the same wall; phase-2 push rings shove each player toward the hole nearest to them; the band stays into phase 3.
- **Cast display (D-108, D-112):** the boss bar shows the running cast and its progress ("Abstimmung läuft …"); a stun shows "UNTERBROCHEN"; the Pressekonferenz shows a banner with the phase name **above the boss bar, at the bottom**, for as long as it lasts (D-158: it used to sit at the top of the arena and covered the boss walking to the middle; it replaces the small gold "Pressekonferenz" label there); Standfest shows a press-spokesperson shield over the unit. Snapshot version 4 carries it (networking.md §6.1).

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
- **Slurs are never shown** (D-156): a slur in a real quote, above all the N-word, is replaced by asterisks with the mark `[N-Wort zensiert]` inside the quote text, so the mark shows on every card, screen and Album page (e.g. `afd-maier-02`). Otherwise the quote is dropped.
- **Source data:** `research/zitate_de.json`, selection in `research/auswahl.json`. The game reads and ships only the generated `research/zitate_spiel.json` (curated, verified quotes; D-159).

## 16. Co-op (1–4 players)

| Mechanic | Rule |
|---|---|
| **Solidaritätszuschlag** | Reviving a downed player costs the helper 10 % of their max HP (5 % with Erste-Hilfe-Kurs). The revived player returns with 40 % HP |
| **Downed hint** | While you are down, the HUD says "Kurz durchatmen – die anderen holen dich zurück!". **Solo** (only one player left in the run) there is nobody to revive you: going down ends the run ("Vertagt.", or the boss wave restarts with Boss-Wiederholung; Zweiter Wahlgang catches the hit before you go down at all). The hint then says "Solidarität braucht mindestens zwei. Nächster Anlauf!", and the downed character lies there without the revive ring, the green cross and "Hilf mir hoch!" (D-157). **Co-op, everyone down** (the run is over, "Vertagt."): nobody is left to help either, so the hint says "Alle am Boden. Nächstes Mal stehen wir zusammen wieder auf!" and the revive markers disappear as well |
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

### Reichensteuer (co-op only)
Whoever collects far more Pfand in a wave than the others (e.g. thanks to Pfandradar) gives some of it away at the end of the wave. Exact rules: docs/specs/balancing.md §5a.
- Only Pfand **picked up** in that wave counts (not wave income).
- Taxed is only the part above **+50 % over the average of the players poorer than you**, at **50 / 60 / 70 %** for 2 / 3 / 4 players.
- The money goes to the **poorest first**. Givers always keep at least 10 % more than every receiver and never fall below anyone who was poorer. Under 5 Pfand of excess nothing happens.
- Examples, 4 players: 300 / 100 / 100 / 100 → 195 / 135 / 135 / 135; 300 / 300 / 100 / 100 → 223 / 223 / 177 / 177.
- The Späti shows what you paid or received; the end screen shows the totals.

### Koalitionsvertrag (vote before waves 4, 8, 12, 16)
Offers **3 options drawn at random** from the pool below; the result applies for **4 waves** (`Content.VERTRAG`, worse options have a higher "badness"). Six more since D-155 (marked ✚), drawn like the others:

| Option | Badness | Effect | Background |
|---|---|---|---|
| Digitalpakt | 0 | nothing happens | |
| ✚ Klimageld | 0 | nothing during the contract; when it ends, a 50 % chance (one roll for the whole team) that every player gets +30 Pfand × the price factor of the next Späti (D-150). A bubble says "ausgezahlt" or "verschoben" | coalition agreement 2021, never paid out |
| Tempolimit | 1 | players −10 Deutschlandticket, enemies 15 % slower | |
| ✚ Cannabis-Legalisierung | 1 | +5 Krankenschein, −10 Akkord | CanG, 1 April 2024 |
| ✚ 9-Euro-Ticket | 1 | +20 Deutschlandticket, enemies 10 % faster | June–August 2022 |
| Mindestlohn | 2 | +3 Nebenjob for all, enemies +10 % HP | |
| Bürokratieabbau | 2 | +25 Vernetzung, one Späti offer fewer | |
| ✚ Wehrdienst per Los | 2 | at every wave start one present player is drawn (solo: always you): +20 Wut, −20 Deutschlandticket for that wave. A bubble "Eingezogen!" marks them | Wehrdienstgesetz 2025, the dispute over drawing lots |
| Aufrüstung | 3 | +20 Wut for players, enemies +20 % damage | |
| ✚ Maskendeals | 3 | +5 Kündigungsschutz, Späti prices +20 % | 2020/21, commissions for Union MPs |
| ✚ Rente mit 70 | 3 | +10 Akkord, −10 Solidarität | debate 2023–2025 |
| Schuldenbremse | 4 | Späti prices −15 %, no regeneration | |
| Sanktionen | 5 | income halved, 30 % fewer Pfand drops | |

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
- **Difficulty = Umfrage levels:** 10% → 15% → 20% → 25% → 30% → 35%, each step harder (docs/specs/balancing.md §3). **All levels can be picked from the start**; the menu records the highest one beaten. 35 % should be hardly beatable.
- **Boss-Wiederholung (host option in the lobby, off by default):** if the team dies in a wave with an elite or boss (5, 10, 15, 20), that wave starts over instead of ending the run (docs/specs/balancing.md §8).
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
- 12 weapons, 69 items in the shop pool (green/blue/purple/red; 12 red)
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
| **Geräusche der Mitspieler:innen** | volume of the sounds your teammates cause: shots, hits, Pfand (default 50 %, 0 % = off; [audio spec](specs/audio.md) §5). Waves, level-ups and downs are always heard |
| **Zielauswahl** | Nächste:r Gegner:in (default) / Meiste Lebenspunkte / Wenigste Lebenspunkte |
| **Fenstermodus** | Vollbild / Maximiertes Fenster / Fenster (default) |
| **Sprechblasen** | opacity (default 70 %), *aus* |
| **Eigene Effekte** | opacity of everything the players' side draws except the characters themselves (default 100 %, min 20 %) |

**Eigene Effekte** keeps the screen readable in big fights, so enemy projectiles stand out:
- **Fades:** the players' projectiles (incl. Mietspiegel orbiters), their zones (Kleber, Straßenkreide, Brandmauer-Ziegel, Kartoffelbrei marker and splat, Normenkontrolle stamp, Farbklecks, Sitzblockade), all summons, the weapons drawn around the characters, attack effects (swooshes, Scheinwerfer beam, Unterschriften line, Trillerpfeife waves), the Stadtbild followers and ultimate visuals (shouts, Critical-Mass ghost riders, Tarifrunde glow, paper storm).
- **Never fades:** the characters, their ground ring, names and status labels; enemies, enemy projectiles and enemy zones; explosions (they can't be told apart from enemy bombs); pickups; damage numbers; HUD.
- It applies to every player's effects, not only your own, because teammates' effects clutter the screen just as much. It's a local view setting: each player picks their own, and nothing changes for the others.
- The minimum is 20 %, so you always still see where your Kleber puddle or Infostand is.

The main menu also has a **Bug melden** button that opens the GitHub bug-report form.

After a crash or a lost connection during a co-op run, the main menu shows a green **"Zurück ins Spiel"** button on top. It brings you back into the same run as the same character, as long as that run is still going (networking.md §7.5).

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
| Lobby areas | LB / RB jump between Einstellungen (Organisation, Umfrage, Boss-Wiederholung), Charaktere (your selected card) and the bottom row (Bereit, else Los; D-124) | — |

- **Every menu, dialog and the Späti are navigable with focus:** there's a visible focus frame, focus never gets lost, and the first sensible button gets focus.
- **Directions mean directions:** right moves to the control on the right, down to the one below, and so on.
- **In the Späti, the D-pad, left stick and arrow keys stay inside the current section.** At the edge of a section, focus stays where it is. Only LB / RB change the section.
- **Focus stays where you were when an action removes the focused control** (buy, sell, combine, discard):
  - After a buy, focus goes to the next offer you can still buy. From the last offer it wraps to the first.
  - With no buyable offer left, focus goes to Neu würfeln. Otherwise it goes to the first control of the same section. It never jumps to the header (Statistik) (D-126).
- **The level-up options are one row:** left / right walk the options in order and never stop on the reroll below them. Down goes to the reroll; up from the reroll goes back to the option you came from (D-123).
- **The character grid in the lobby is read like text:**
  - Right on the last card of a row goes to the first card of the next row.
  - Left on the first card of a row goes to the last card of the previous row.
  - Up and down move by one row.
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

### Sound effects
Retro synth sounds rendered by `tools/gen_sfx.py` (our own work, D-040), mixed as in the [audio spec](specs/audio.md) (D-151):
- **Loudness tiers:** routine sounds (shots, hits) are quiet, short and capped; rewards and alerts are louder and never cut off.
- **Pfand streak:** quick pickups climb a pentatonic scale.
- **Audible hits and crits.**
- **Ka-ching by tier:** red has a full arpeggio.
- **Your own sounds first:** teammates' sounds are quieter, with their own option.

Reward sounds play only for real gains, never for losses.
