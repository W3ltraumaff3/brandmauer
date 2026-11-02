# Boss-Ideen: schwerere, eigenständige Elite- und Bosskämpfe

Stand: 2026-11-02. Diagnose der vier Encounters (Sylt-Clique, Geschichtslehrer, Sauerländer, Remigrantin) aus Code (`src/sim/sim.gd`, `src/data/content.gd`) und den Bot-Läufen in `balance/runs/v0.3.0-beta/`, dazu 17 neue Fähigkeiten, Regeln für Ultimates gegen Bosse, Umfrage-Stufen und eine Umsetzungs-Shortlist. Nichts davon ist Spec. Was übernommen wird, kommt zuerst ins GDD §14, nach balancing.md §7 und in decisions.md.

## Hinweise

- **Spielertest (Auftrag):** Die Bosse sind auch auf Umfrage 35 % zu leicht. Gespielt wurde solo, und dort sind die normalen Wellen auf 35 % schon hart. **Alle Vorschläge wirken deshalb nur auf Encounter-Einheiten, nicht auf die Wellen.** Mehr Boss-HP ist laut Nutzer:in erlaubt, als Hebel neben den Mechaniken.
- **Datenbasis:** `confirm.jsonl` (152 Läufe, aktuelle Werte für Nahkampf, Fernkampf, Krit und Tank) und `status3.jsonl` (72 Läufe, aktuelle Werte für Status und Beschwörung), jeweils Umfrage 10 % / 20 %. Auf 35 % gibt es keine Bossdaten, weil alle Bots vor Welle 10 sterben. Die Werte für 35 % unten sind deshalb gerechnet, nicht gemessen. Ausgewertet mit `tools/balance_report.py` und einem Hilfsskript (`boss_times.py` im Scratchpad).
- **Aufwand:** **S** = ein Nachmittag (bestehende Bausteine neu kombiniert), **M** = neuer Hazard- oder Gegnertyp plus Zeichnung, **L** = neues System (Snapshot-Format, Bot-Verhalten).
- **Netzwerk (networking.md):** Der Host simuliert alles. Clients bekommen den `ViewState` als Snapshot (Hazards: Typ, Position, Radius, Lebensanteil; Boss: `enc`, `hp`, `phase`, `shield`) und Events (`say`, `sfx`, `wende`, `exit` …) über den zuverlässigen Kanal. Neue Typ-IDs werden nur **angehängt** (`HAZARD_ORDER`, `ENEMY_ORDER`, `PROJ_ORDER`). Feldänderungen brauchen `Snapshot.VERSION` 4 und die Protokollversion.
- **Content (content-guidelines.md):** Bosse sind Parodien mit erfundenem Namen und werden "abgesetzt", nicht getötet. **Keine Phase beschwört oder zeigt die Gruppen, die der Boss beleidigt.** Adds sind Gegenstände oder Institutionen des Bosses (Schulbuch, Briefkasten, Wahlurne) oder die normalen Gegner aus dem Spiel, die als Folge seiner Politik kommen. Echte Zitate nur als `verifiziert`-ID, und nie als Sprechblase im Kampf (GDD §15). Sprechblasen im Kampf sind **erfunden** und hier so markiert.

## 1. Diagnose

### 1.1 Kampfdauer gegen das Ziel

Ziel laut balancing.md §1: Elites 20–40 s, Endboss 60–120 s, bei jeder Spielerzahl.

Median der Kill-Zeit nach Build (Build-Bots, solo und 4 Spieler:innen gemischt, Umfrage 10 % / 20 %; *n* = getötet/Kämpfe):

| Build | Welle 5 Sylt-Clique | Welle 10 Geschichtslehrer | Welle 15 Sauerländer | Welle 20 Remigrantin |
|---|---|---|---|---|
| Fernkampf (status3) | 18 s (20/24) | **10 s** (19/19) | **10 s** (15/15) | **12 s** (15/15) |
| Krit (confirm) | 16 s (16/16) | 13 s (12/14) | 12 s (7/7) | **14 s** (6/6) |
| Beschwörung (status3) | 23 s (19/24) | 11 s (16/17) | 14 s (16/16) | 28 s (16/16) |
| Status (status3) | 18 s (23/23) | 15 s (8/8) | 20 s (1/2) | 33 s (1/1) |
| Nahkampf (confirm) | 16 s (14/15) | 13 s (13/14) | 19 s (8/14) | 239 s (2/14) |
| Tank (confirm) | 23 s (13/14) | 20 s (5/13) | nie (0/10) | nie (0/10) |
| Prioritäts-Bots ohne Build, unsterblich | 15–26 s | 15–27 s | **nie** (0/8) | 52 s solo, 326 s zu viert |

- **Starke Builds (Fernkampf, Krit, Beschwörung) erledigen den Endboss in 12–28 s, also 4–10× zu schnell. Die Elites ab Welle 10 fallen in 10–14 s, 2–3× zu schnell.** Die Werte in balancing.md ("Endboss 85–190 s") stammen von den Prioritäts-Bots ohne Build-Logik, die deutlich schwächer spielen.
- **Menschen sind noch schneller:** Der Bot benutzt **nie ein Ultimate** (`balance_sim.gd` ruft es nicht auf), kollidiert mit Telegraphen und stellt die Zielauswahl nicht um. Ein Mensch mit gutem Build liegt also eher unter den 10–14 s.
- **Die Spanne zwischen Builds ist riesig:** Gegen den Endboss machen Fernkampf-Bots ~1.700–2.100 Schaden/s pro Spieler:in, Nahkampf und Tank 500–700. Reines HP-Tuning trifft also nie alle Builds: 4× HP brächte Fernkampf auf 50 s, aber Nahkampf auf 15 min. **Deshalb braucht es zeitgebundene Mechaniken (Phasen-Sperren, Übergänge, Adds), die eine Mindestdauer setzen, und HP erst obendrauf.**
- Ausreißer: Gegen den Sauerländer schaffen es die unsterblichen Prioritäts-Bots nie (0/8). Ursache ist das Sondervermögen, siehe 1.6.

### 1.2 HP heute (gerechnet aus `spawn_enemy`)

HP = Basis × Umfrage-HP (1 + 0,15·L) × Koop-Faktor (0,6 + 0,45·(Spieler − 1)) × Wellenwachstum (`elite_wave_exp` 0,6) [× 0,9 beim Endboss]. Das Wellenwachstum beträgt 1,00 / 1,62 / 2,42 / 3,39 für die Wellen 5 / 10 / 15 / 20.

| Encounter | U 10 % solo | U 20 % solo | **U 35 % solo** | U 35 % 4 Spieler:innen | Schaden/s, den ein Fernkampf-Build in der Welle davor macht (solo) |
|---|---|---|---|---|---|
| Sylt-Clique (4 Personen zusammen) | 624 | 811 | **1.092** | 3.549 | ~30–40 |
| Geschichtslehrer | 1.944 | 2.527 | **3.402** | 11.057 | ~200–270 |
| Sauerländer | 5.814 | 7.558 | **10.174** | 33.067 | ~600–1.050 |
| Remigrantin (+25 % Schild in Phase 3) | 14.900 | 19.350 | **26.045** | 84.645 | ~1.400–2.100 |

- **Umfrage 35 % gibt Bossen nur +35 % HP gegenüber 20 %** (1,75 statt 1,30). Ein Fernkampf-Build braucht für die Remigrantin auf 35 % also etwa 13–18 s statt 10–14 s. Umfrage verändert heute **nur Zahlen, keine Mechanik**.
- **Koop:** Pro Kopf haben Bosse zu viert 0,49 der Solo-HP (1,95 / 4) gegenüber 0,6 solo, also gut 20 % weniger. Die Bots brauchten zu viert trotzdem länger, weil sie klumpen und die Zusatzgegner auf sich ziehen (Spawnrate ×2,65 bei 4 Spieler:innen).

### 1.3 Mechanik-Inventar und wie viel davon man überhaupt sieht

Phasen über `_boss_phase` bei 66 % / 33 % HP. Zusätzlich gilt ab 50 % HP für alle Encounter-Einheiten "Jetzt reicht's aber!": KI-Tempo ×1,4.

| Encounter | Mechaniken heute | Takt | Wie oft sie bei 10–14 s Kampfdauer feuern |
|---|---|---|---|
| Sylt-Clique | Verfolgen; Champagner-Lob (Markierung 1,0 s, Radius 50); Buff, solange mindestens 2 innerhalb von 160 px stehen (Tempo ×1,2, Kontakt ×1,5, Champagner ×1,4) | Lob alle 2,5–3,3 s | ~6 Lobs. Der Buff lässt sich nicht brechen: Elites sind immun gegen Rückstoß |
| Geschichtslehrer | Verfolgen; Bücherring (10/12/14 Bücher); **Wende** (4 s Steuerung umgekehrt, Ansage 1,5 s vorher) | Ring alle 3,0/2,5/2,0 s; Wende alle 12 s | **Die erste Wende kommt nach 12 s, also in etwa der Hälfte der Kämpfe gar nicht.** Seine Signatur verpufft |
| Sauerländer | P1 Bierdeckel-Fächer (5); P2 Sondervermögen (8 Scheine alle 4 s; jeder liegengebliebene heilt 1,5 %); P3 Zirkuszelt (3 abprallende Bälle) | P1 1,6 s, P2 2,4 s, P3 3 s | **Jede Phase dauert ~3–4 s:** 2 Fächer, 1 Geldregen, 1 Ballsalve |
| Remigrantin | P1 Ansturm (0,7 s Ansage, 0,6 s Sprint ×4 Tempo), reißt Windräder um (Deckung), Flügel-Fächer (3); P2 Abschiebezone (70-px-Band an allen 4 Wänden) + Druckring alle 3,5 s; P3 Schild 25 % + Chalet oben + Goldbarren-Fächer (5) alle 1,2 s + Druckring alle 6 s | s. links | **Etwa 1 Ansturm, 1 Druckring, 1–2 Ringe im Schild.** Sechs Mechaniken, aber jede nur einmal sichtbar |

**Fazit:** Die Bosse haben brauchbare Ideen. Sie sterben nur, bevor diese wirken, und alle Phasen gehen in einem Burst unter.

### 1.4 Druck auf die Spieler:innen: Kann man sie aussitzen?

Treffergröße auf 35 %: Basis × 1,5 × (1 + 0,03·(Welle − 1)).

| Quelle | Treffer (roh) | Zum Vergleich: normale Gegner in Welle 19 auf 35 % |
|---|---|---|
| Lehrer Kontakt / Buch | 19 / 11 | Besorgte:r Bürger:in 13, Reichsbürger 27 |
| Sauerländer Kontakt / Bierdeckel / Ball | 26 / 15 / 18 | Porsche-SUV 33, Privatjet 27 |
| Remigrantin Kontakt / Flügel / Goldbarren / Druckring / Abschiebezone | 33 / 20 / 16 / 10 / 13 pro s | |

- **Boss-Treffer sind nicht größer als die von späten normalen Gegnern.**
- **Unverwundbarkeit nach Treffer (`IFRAMES` 0,5 s) deckelt jedes Muster auf 2 Treffer pro Sekunde.** Viele Projektile (Bücherring, 5er-Fächer) erhöhen den Schaden also nicht, nur die Chance auf einen Treffer.
- **Bosse sind langsam** (70–90 gegen 220+ der Spieler:innen), **zielen ohne Vorhalt auf die nächste Person** und haben kaum Flächenangriffe. Wer quer läuft, weicht allem aus. Sicher treffen nur der Druckring (10 Schaden) und das Abschiebe-Band.
- **Gemessen:** Fernkampf- und Status-Bots verlieren gegen den Endboss 0,1–0,3× ihrer Max-HP (status3), Beschwörung zu viert 0,3–0,7×. Die Bots weichen keiner Ansage aus, ein Mensch nimmt also noch weniger. **Aussitzen ist nicht einmal nötig, weil der Boss kaum trifft.** Ein Tank-Build könnte stehenbleiben: 26 Rüstung machen aus 33 nur 12, das sind 24 Schaden/s bei Dauerkontakt, gegen bis zu 10 HP/s Lebensraub plus Regeneration.
- **Koop:** Jeder Angriff zielt auf **die nächste** Person (`_target_player` → `_nearest_player`). Zu viert steht also eine Person unter Druck, die anderen drei schießen ungestört.

### 1.5 Ultimates gegen Bosse

Jedes Ultimate gibt es einmal pro Welle, im Endboss-Kampf also genau einmal. Die Bots nutzen keine, die Kill-Zeiten oben sind also **ohne** Ultimates gemessen. *D* = Schaden/s des Teams, *T* = Kampfdauer.

| Ultimate (Figur) | Wirkung auf Bosse heute | Spart Kampfzeit | Anteil bei 12 s / bei 75 s | Bewertung |
|---|---|---|---|---|
| **Fragen Sie mal uns** (Töchter) | Nur Sauerländer (und Anzüge): **2 s betäubt + 6 s doppelter Schaden** | 6 s | Sauerländer 11 s → **~5 s**; bei 40 s noch −15 % | **Stärkster Boss-Killer.** Die Töchter werden erst durch den Sieg über den Sauerländer freigeschaltet und löschen ihn danach praktisch mit einer Taste |
| **Tarifrunde** (Gewerkschaft) | +50 % Schaden für alle Spieler:innen und Beschwörungen, 8 s | 4 s | −33 % / −5 % | stark. Zu viert mit mehreren Gewerkschafter:innen 8 s je Person **hintereinander** (Effekt wird neu gesetzt, nicht addiert) → bis 32 s +50 % |
| **Critical Mass** (Lastenrad) | 5,4 s unverwundbar + Rammschaden (klein) | 0 (Überleben) | **halber Kampf unverwundbar** / 7 % | defensiv sehr stark bei kurzen Kämpfen |
| **Flashmob** (Stadtbild) | 2 s betäubt (die Elite-Ausnahme gilt nur für Waffen-Stun, nicht für Ultimates), Schaden (20 + 5·Mitläufer:innen) × Wut: klein | 0 | 2 s keine Angriffe | ok, unterbricht Muster |
| **Straßenblockade** (Klimakleber:in) | Bosse 6 s um **85 % verlangsamt**, 2–3 überlappende Pfützen treffen (D-101) | ~0 | Ansturm der Remigrantin wird harmlos | Verlangsamung hat bei Bossen keine Obergrenze |
| **Antrag gestellt** (Bürgergeld) | 60 % langsamer, 6 s, nur Bewegung (Timer laufen weiter) | 0 | defensiv | ok |
| Urlaubsantrag, Kaffee und Kuchen, Schwarzer Block | 4 s unverwundbar und stehen / volle Heilung + Wiederbelebung / 6 Genoss:innen mit wenig Schaden | 0 | | defensiv, ok |
| *Streik* (Organisation Gewerkschaft, kein Ultimate) | **Genau in den Wellen 5/10/15/20 verfügbar** (`n % 5 == 0`): 5 s, Elites mit halbem Tempo | 0 | | ok, aber zufällig genau auf Boss-Wellen gelegt |

Schadens-Ultimates sind also **nicht** das Problem; deren direkter Schaden ist klein. Das Problem sind **Multiplikatoren** (×2, +50 %) und **Kontrolle** (Betäubung, 85 % Verlangsamung, unverwundbar) in Kämpfen, die nur 10–15 s dauern. Eine Ultimate-Wirkung von 4–6 s wiegt bei 12 s Kampf ein Drittel bis die Hälfte, bei 75 s nur noch 5–8 %. **Die wichtigste Ultimate-Regel ist deshalb die längere Kampfdauer, dazu ein paar Boss-Regeln (§4).**

Ein Status-Detail dazu: Verlangsamung durch Waffen wirkt **voll** auf Bosse (Kleber 70 %), auch auf den Ansturm der Remigrantin (`spd × 4` mit verlangsamtem `spd`). Status-Builds entschärfen bewegliche Bosse damit nebenbei.

### 1.6 Fehler und Auffälligkeiten (nicht Teil dieses Auftrags, aber gefunden)

- **Sauerländer nutzt die alte Arena (vor D-082):** In P1 wählt er Ziele in x 200–1400, y 220–800, und die Scheine fallen in x 150–1450, y 200–900. Die Innenarena ist aber x 102–1802, y 102–1122. Er läuft nie in das rechte Viertel und das untere Drittel. Dasselbe Muster haben die Passant:innen von Stadtbild (100–1500 / 200–900). GDD §5a verlangt Positionen relativ zur Arenamitte. Der Fix braucht einen Regressionstest (CLAUDE.local.md).
- **Sondervermögen ist ein reiner Schadenscheck:** 8 Scheine alle 4 s (mit ×1,4 Tempo ab 50 % HP alle 2,9 s), jeder liegengebliebene heilt 1,5 % Max-HP. Das sind bis zu ~4 %/s. Bots sammeln kaum (nur wenn sonst nichts los ist) und schaffen ihn nie. Menschen sammeln nebenbei und merken nichts. Das ist eine Ja/Nein-Probe, keine Mechanik.
- **Zwei Phasensysteme laufen nebeneinander:** Phasen bei 66/33 % und das Tempo ab 50 %. Für Spieler:innen ist das nicht lesbar (die HUD-Punkte zeigen 3 Phasen, das Tempo nicht).
- **Elites sind immun gegen Rückstoß:** Gut für Bosse, aber bei der Sylt-Clique kann niemand den Gruppen-Buff brechen.
- **Doku:** balancing.md §7 verweist für "Unique multi-phase bosses" auf open-questions.md, dort fehlt der Eintrag.

### 1.7 Zusammenfassung: Tuning und fehlende Mechanik getrennt

| Ursache | Art | Hebel |
|---|---|---|
| HP an schwachen Prioritäts-Bots kalibriert; starke Builds sind 3–4× schneller | Tuning | Boss-HP-Faktor nur für Encounter, an Umfrage gekoppelt (§6, §7) |
| Umfrage skaliert Bosse nur über HP und Schaden (35 % = +35 % gegenüber 20 %) | Tuning + Design | eigene Boss-Stufen pro Umfrage (§6) |
| Phasen lassen sich wegbursten; Signaturen (Wende, Abstimmung) feuern nicht | **Mechanik** | Phasen-Sperre + Übergang (B2) |
| Wenig Flächen- oder Zwangsdruck; zielt nur auf die nächste Person; kleine Treffer gegen das 0,5-s-Limit | **Mechanik** | wenige, große, angesagte Angriffe; Ziele reihum (B4); Arena-Veränderung (§5) |
| Ultimates wiegen in 12-s-Kämpfen ein Drittel bis die Hälfte | beides | längere Kämpfe + Boss-Regeln für Kontrolle und Multiplikatoren (§4) |
| Status- und Beschwörungs-Builds müssen sich nie bewegen | **Mechanik** | Angriffe gegen Klumpen und Pfützen (§5) |

## 2. Gemeinsame Bausteine

Die Fähigkeiten in §3 verweisen auf diese Bausteine. Einmal gebaut, nutzen sie alle Bosse.

| # | Baustein | Was | Aufwand | Netz |
|---|---|---|---|---|
| **B1** | **Ausrichtung für Hazards** | Ein Winkel-Byte `h_ang` pro Hazard (wie bei Projektilen, TAU/256). Damit gehen Linien, Kegel und Pfeile als **ein** Hazard statt als Kette aus Kreisen (die 64er-Grenze reicht dann) | M | `Snapshot.VERSION` 4, +1 Byte pro Hazard (max. 64 B) |
| **B2** | **Phasen-Sperre und Übergang** | Schaden kann eine Phasengrenze (66/33 %) nicht überspringen; Überschuss verfällt. Beim Wechsel 2,0–2,5 s "Pressekonferenz": unverwundbar (goldener Rand, `EF_SHIELDED`), läuft zur Mitte, Banner mit Phasenname, entfernt Betäubung und Verlangsamung, pausiert laufende Verwundbarkeit (wird nicht verbraucht). Das Tempo ab 50 % wird zum Teil von Phase 2 (ein System statt zwei) | S | Event `["boss_phase", enc, phase]` für Banner und Ton; `boss.phase` existiert |
| **B3** | **Zauber-Anzeige** | `boss.cast` (Fähigkeits-ID, u8) und `boss.cast_t` (Fortschritt, u8) im Boss-Block: Die HUD-Leiste zeigt den Namen des laufenden Angriffs und einen Balken, z. B. "Abstimmung läuft …" | S | +2 Byte im Boss-Block (VERSION 4, zusammen mit B1) |
| **B4** | **Ziele reihum** | Bossangriffe zielen nicht immer auf die nächste Person, sondern reihum auf lebende Spieler:innen (Liste nach ID, Zeiger `e.data["next_target"]`). "Pro Person"-Fähigkeiten erzeugen je eine Instanz | S | keins |
| **B5** | **Encounter-Adds** | Stationäre Objekte mit HP (`faction: "elite"`, `ai: "add"`, gehören zum Encounter, zählen nicht für den Sieg). Typen: `schulbuch`, `wahlurne`, `briefkasten` | M | neue `ENEMY_ORDER`-Einträge (angehängt) |
| **B6** | **Boss-Resistenz** | Betäubung auf Bossen ×0,5, danach 10 s "Standfest" (immun gegen Betäubung, Symbol am Boss); Verlangsamung aus allen Quellen höchstens 40 %; Betäubung **bricht einen laufenden Zauber ab** (B3). Details in §4 | S | Flag-Bit für "Standfest" in `e_flags2` (Bit 6 ist frei) |
| **B7** | **Telegraph-Standard** | Gegnerische Gefahr: Rot (0,85/0,15/0,1), gestrichelter Rand, Füllung wächst bis zum Einschlag (wie `lob_marker`). Bleibende Zonen: rote Schraffur (wie Abschiebezone). "Hier hinstellen": blau-türkiser, durchgezogener Ring mit Handsymbol. Zusätzlich zur Farbe immer eine Form (Kreuz = Einschlag, Pfeil = Stoß, Schraffur = bleibt). Eigene Effekte bleiben über D-086 abschwächbar; Boss-Telegraphe nie | S je Typ | – |
| **B8** | **Mindest-Ansagezeiten** | gezielter Einschlag ≥ 0,8 s; großflächig oder durch die ganze Arena ≥ 1,2 s; Arena-Veränderung ≥ 2,0 s. Umfrage verkürzt um höchstens 25 %, nie unter 0,6 / 1,0 / 1,5 s | – | – |

## 3. Encounters

Format pro Fähigkeit: **Satire** (wen sie trifft und warum das lustig ist) · **Telegraph** · **Konter** · **Skalierung** (Umfrage L = 0..5, Spielerzahl n) · **Technik** · **Content**.

### 3.1 Sylt-Clique (Welle 5, Stufe 1 "leicht")

Ziel: 20–30 s; **die Clique bringt die Telegraph-Sprache bei**. Mit 1–2 Waffen in Welle 5 darf sie nicht unfair sein. Heute gibt es Champagner-Lobs und den Gruppen-Buff. Phasen: keine eigenen; jede Person ab 50 % HP schneller.

**S1 Absperrband (VIP-Bereich).**
- **Satire:** Abgesperrte Partyzone, "Privatgelände", Türsteherlogik der Reichen. Die Spieler:innen crashen die Party.
- **Ablauf:** Alle 14 s spannen sie ein Absperrband um einen Kreis (Radius 170) und stellen sich hinein. Drinnen haben sie 60 % Schadensreduktion und heilen 1 %/s ("Häppchen"). **Steht eine Spielerin drin**, entfällt beides ("Party gecrasht", erfundene Blase: "Wer hat die denn reingelassen?!").
- **Telegraph:** 1,5 s vorher ein rot-weißer Bandring auf dem Boden, danach durchgezogen. "Hier hinstellen"-Ring nach B7.
- **Konter:** reingehen. Fernkampf-Kiter müssen kurz nah ran.
- **Skalierung:** ab L3 alle 11 s; ab L5 nehmen Spieler:innen drinnen 2 Schaden/s ("Türsteher"). Koop: Radius 170 + 20·(n − 1); es reicht eine Person drin.
- **Technik:** neuer Hazard `vip_zone` (Kreis), Prüfung "Spieler:in drin" wie Mietzone; Schadensreduktion in `_damage_enemy`. **M.** Netz: neuer Hazardtyp.
- **Content:** ✔ trifft Exklusivität und Reichtum. Keine Gruppe außer der Clique zu sehen.

**S2 Sektdusche.**
- **Satire:** Champagner als Waffe der Gelangweilten.
- **Ablauf:** Der Lob (gibt es schon) hinterlässt eine Sektlache (Radius 55, 4 s), die Spieler:innen um 30 % bremst.
- **Telegraph:** wie heute (`lob_marker` 1,0 s), danach eine goldgelbe Pfütze mit Bläschen.
- **Konter:** nicht in den Pfützen kämpfen.
- **Skalierung:** Lache ab L2 5 s, ab L4 Radius 70.
- **Technik:** neuer Hazard `sektlache`; in `_step_players` eine Tempo-Strafe. Gegner-Hazards bremsen Spieler:innen bisher nicht, deshalb ein Feld `p.slow_t`. **S–M.**
- **Content:** ✔.

**S3 Rückstoß erlaubt.**
- Die vier Personen sind keine Bosse: Rückstoß wirkt auf sie mit ×0,5 (`knock > 0 and not e.elite` → Ausnahme für `ai == "sylt"`). Dann kann man den Gruppen-Buff gezielt auseinanderprügeln.
- **S**, Tuning.

**S4 Polonaise** (optional, ab L3).
- **Satire:** die Party zieht durch die Arena.
- **Ablauf:** Alle 18 s bilden die vier eine Kette (Folge der Ersten), 5 s lang, die durch die Arena schlängelt; Kontakt trifft.
- **Telegraph:** Die Erste ruft "Polonaise!" (erfunden), Notenspur am Boden 1,0 s voraus.
- **Konter:** quer zur Kette ausweichen; ein Treffer auf die Mittlere bricht die Kette.
- **Technik:** Folge-KI über `_move_toward` auf das vorherige Mitglied. **S.**
- **Content:** ✔. Kein Gesang, keine Parole aus dem echten Video; das "Döp dödö döp" bleibt die einzige Anspielung.

### 3.2 Der Geschichtslehrer (Höcke-Parodie, Welle 10, Stufe 2)

Ziel: 25–40 s. Intro-Karte `hoecke-02` ("erinnerungspolitische Wende um 180 Grad"). **Thema: Alles, was er tut, dreht sich um 180 Grad, und er schreibt die Geschichte um.**

- P1 "Unterricht" (100–66 %): Bücherring + Tafelbild
- P2 "Wende" (66–33 %): Wende-Zyklus + umkehrende Bücher + Nachsitzen
- P3 "Neuauflage" (33–0 %): Geschichte umschreiben + alles davor schneller

**G1 Wende um 180 Grad (Umbau der bestehenden Fähigkeit).**
- **Satire:** Er will die Erinnerungskultur umdrehen. Im Spiel dreht er nur eure Steuerung um, und das Ergebnis ist Chaos.
- **Ablauf:**
  - Die erste Wende kommt **4 s nach Kampfbeginn**, dann alle 10 s.
  - In P2 dreht sich bei der Wende auch jeder fliegende Bücherring um und kommt zurück durch die Arena (zweite Welle von außen).
  - Ab L3 "Teilwende": nur eine Achse kippt (links/rechts **oder** oben/unten); ein großer Pfeil zeigt welche.
- **Telegraph:** 1,5 s Countdown "3 – 2 – 1" mit einem "180°"-Pfeil über jeder Spielfigur (das HUD-Overlay `wende` gibt es schon); die Bücher blinken vor der Umkehr.
- **Konter:** während der Ansage in eine sichere Richtung laufen oder stehen bleiben.
- **Skalierung:** Dauer 4 s; 5 s ab L4. Koop: trifft alle (wie heute).
- **Technik:** Timer ändern, `pr.vel = -pr.vel` für eigene Bücher, Event `["wende", dauer, achse]`. **S.** Netz: ein Event-Parameter mehr.
- **Content:** ✔. Keine NS-Symbolik, kein Denkmal im Bild.

**G2 Tafelbild.**
- **Satire:** Der Oberlehrer diktiert, und wer im Weg steht, wird angestrichen.
- **Ablauf:** Er zieht 2 / 3 / 4 Kreidestriche (je nach Phase) quer durch die Arena, jeweils von einem Wandsegment zum gegenüberliegenden. 0,5 s nach der Ansage schlägt der Strich ein (1,0× Schaden) und **wischt Straßenkreide der Spieler:innen weg**.
- **Telegraph:** 1,2 s dünne, gestrichelte Kreidelinie (weiß auf dunkelgrüner Bahn, 30 px breit), dann ein dicker Strich mit Staubwolke.
- **Konter:** von der Linie treten; Linien kreuzen sich, die Schnittpunkte sind gefährlich.
- **Skalierung:** ab L2 nacheinander statt gleichzeitig ("Unterstreichung"); Koop: 1 Linie zusätzlich je Person, eine davon durch jede Spielfigur (B4).
- **Technik:** neuer Hazard `kreidestrich` mit Winkel (B1), Länge im Radius-Feld. Treffer = Abstand Punkt–Linie. **M.**
- **Content:** ✔. Auf der Tafel nur Kritzel ("Lehrplan", Pfeile), keine Inhalte.

**G3 Nachsitzen.**
- **Satire:** Autoritärer Lehrer bestraft die, die Abstand zu ihm halten.
- **Ablauf:** Die Person, die am **weitesten** von ihm weg ist, bekommt einen Kreidekreis (Radius 110) um sich. 4 s lang kostet jedes Übertreten des Rands 1,0× Schaden ("Schwänzen", erfunden). Dazu lobt er 2 Bücher in den Kreis.
- **Telegraph:** 1,0 s gestrichelter Kreis, der sich zuzieht, dann durchgezogen mit Uhr.
- **Konter:** im Kreis ausweichen; Fernkampf-Kiter können nicht mehr weglaufen.
- **Skalierung:** ab L4 Radius 90; Koop: ab 3 Spieler:innen die zwei am weitesten entfernten.
- **Technik:** neuer Hazard `nachsitzen`; Prüfung "Rand überschritten" wie beim Abschiebe-Band. **M.**
- **Content:** ✔.

**G4 Geschichte umschreiben (P3, Signatur).**
- **Satire:** Geschichtsrevisionismus wörtlich: Er schreibt seine eigene Vergangenheit um. Die Fakten der Spieler:innen stehen dagegen.
- **Ablauf:**
  - Alle 12 s stellt er ein Add **Schulbuch "Neuauflage"** an eine zufällige Wand (HP 6 % seiner Max-HP) und merkt sich seine aktuellen HP.
  - Steht das Buch nach 6 s noch, **springt er auf diesen HP-Stand zurück** (heilt den Schaden seitdem, höchstens 15 % Max-HP; 25 % ab L5). Erfundene Blase: "Das stand so nie im Lehrplan."
  - Wird es zerstört, ist er 2 s betäubt ("Quellenangabe fehlt").
- **Telegraph:** Ein Kreideband verbindet ihn mit dem Buch; das Buch hat einen Countdown-Ring (Hazard, dessen Lebensanteil der Countdown ist).
- **Konter:** Ziel wechseln (Zielauswahl "geringste HP" oder hinlaufen); Beschwörungen und Zonen an der Wand helfen.
- **Skalierung:** Countdown 6 s, ab L3 5 s; Koop: Buch-HP wachsen mit den Boss-HP (über n).
- **Technik:** B5 (Add `schulbuch`) + Countdown-Hazard `countdown` (Ring, `life` = Restzeit); HP-Merker in `e.data`. **M.** Netz: neuer Gegner- und Hazardtyp, kein neues Feld.
- **Content:** ✔. Das Buch zeigt nur "Neuauflage", keine Inhalte, keine Symbole, kein Gedenkort.

### 3.3 Der Sauerländer (Merz-Parodie, Welle 15, Stufe 3 "schwer")

Ziel: 30–45 s. Intro-Karte `merz-12` ("Eine richtige Entscheidung wird nicht dadurch falsch, dass die Falschen zustimmen").

- P1 "Bierdeckel" (100–66 %)
- P2 "Sondervermögen" (66–33 %)
- P3 "Zirkuszelt" (33–0 %)

Querschnitt: **Abstimmung** (in jeder Phase) und **Kahlschlag** (ab P2). Dazu der Fehler-Fix aus 1.6: alle Positionen relativ zu `Arena.INNER`.

**M1 Abstimmung, egal mit wem (Signatur, nutzt die Brandmauer).**
- **Satire:** 29.01.2025: Er holt sich eine Mehrheit mit AfD-Stimmen und reißt damit seine eigene Brandmauer ein (`merz-12`, `merz-13`; Ereignis belegt in `waffen_ideen.md` R4).
- **Ablauf:**
  - Beim Phasenwechsel und danach alle 20 s geht er zu dem intakten Wandsegment auf der Seite mit den **wenigsten** Löchern und stimmt 3,0 s lang ab.
  - **Gegenstimmen:** Machen die Spieler:innen in dieser Zeit 6 % seiner Max-HP Schaden **oder** steht jemand im "Plenum"-Kreis vor dem Segment (Radius 120), scheitert die Abstimmung. Dann ist er 1,5 s betäubt (erfunden: "Keine Mehrheit? Dann halt nächste Woche.").
  - Geht sie durch, wird das Segment zum **Loch, das bleibt, bis es im Späti repariert wird**, und sofort kommen 4 + 2·n AfD-Gegner durch (erfunden: "Mir doch egal, wer zustimmt.").
- **Telegraph:** Das Segment glüht rot; ein Balken auf dem Segment und in der Boss-Leiste (B3, "Abstimmung läuft …"); der Plenum-Kreis ist blau-türkis (B7). Eine Wahlurne steht neben ihm.
- **Konter:** Schaden bündeln oder hinlaufen; Betäubungs-Ultimates brechen ab (B6).
- **Skalierung:** Abstimmzeit 3,0 → 2,2 s (L0 → L5), Schwelle 6 → 9 %; ab L5 zwei Segmente nebeneinander. Koop: Plenum braucht ab 3 Spieler:innen 2 Personen.
- **Technik:** Logik wie `_ai_voter` (`wall[seg] = false`, `Arena.seg_inner`), Spawn über `_staging_spawn_pos` an dem Loch. **M.** Netz: die Wandmaske gibt es schon; Telegraph als Hazard `abstimmung` (Lebensanteil = Fortschritt) + B3.
- **Content:** ✔ trifft ihn. Die AfD-Gegner sind die normalen Gegner des Spiels, keine beleidigte Gruppe.

**M2 Bierdeckel-Bumerang (P1).**
- **Satire:** Steuererklärung auf dem Bierdeckel, die Steuerreform, die immer wiederkommt.
- **Ablauf:** Der 5er-Fächer fliegt 300 px und **kehrt zu ihm zurück**; ab L3 zwei Fächer versetzt.
- **Telegraph:** Er hebt 0,6 s den Arm (Wind-up-Flag `EF_WINDUP`); Deckel drehen sich sichtbar.
- **Konter:** zweimal ausweichen; nicht hinter ihm stehen.
- **Technik:** `boomerang` gibt es für Spieler-Projektile; für Gegner zurück zur Position des Bosses. **S.**
- **Content:** ✔. Nachprüfen: Bierdeckel-Konzept 2003 (siehe unten).

**M3 Sondervermögen: Whatever it takes (Umbau P2).**
- **Satire:** Er bricht seine eigene Schuldenbremse (`merz-26` "Whatever it takes"); die Spieler:innen verteilen das Geld um.
- **Ablauf:**
  - Beim Eintritt in P2 legt er sich eine **Schuldenbremse** als goldenen Ketten-Schild an (20 % Max-HP).
  - Alle 4 s fallen 6 + 2·n Scheine, **über alle vier Quadranten verteilt**.
  - Jeder aufgesammelte Schein schlägt 2 % aus dem Schild und gibt 1 Pfand (Umverteilung).
  - Liegengebliebene Scheine (3 s) **füllen den Schild** um je 1 %, statt ihn zu heilen.
- **Telegraph:** Scheine fallen mit Schatten 0,5 s vorher; der Schild ist in der Boss-Leiste golden (gibt es schon).
- **Konter:** sammeln gehen. Auch Nahkampf, Tank und Status haben eine Aufgabe; Geschütz-Builds müssen sich bewegen.
- **Skalierung:** Liegezeit 3,0 → 2,2 s (L5).
- **Technik:** Schild, Pickup und Scheine gibt es; Haken beim Aufsammeln (`t_geld`), Heilung → Schild. **S–M.**
- **Content:** ✔. Kein Geldsack, keine Karikatur im Sinne von §2; Scheine und eine Kette.

**M4 Kahlschlag (ab P2, Anti-Klump).**
- **Satire:** "Ich werde mich durch Worte wie Sozialabbau und Kahlschlag … nicht irritieren lassen" (`merz-11`). Hier räumt er ab, was die Leute aufgebaut haben.
- **Ablauf:** Alle 14 s ein 120°-Kegel (Reichweite 380) in Richtung der **dichtesten Gruppe aus Beschwörungen und Zonen** der Spieler:innen (oder auf eine Person, wenn es keine gibt). Er löscht alle Zonen der Spieler:innen (Kleber, Kreide, Ziegel, Sitzblockade) und Beschwörungen (Infostand, Pappkamerad, Lauti …) im Kegel und macht 1,5× Schaden an Spieler:innen.
- **Telegraph:** 1,2 s roter Kegel, der sich füllt; er holt mit einem riesigen Stempel "GENEHMIGT"/"GESTRICHEN" aus. Erfunden: "Das nennt man Reform."
- **Konter:** Beschwörungen und Zonen verteilen; nach dem Schlag neu setzen; aus dem Kegel laufen.
- **Skalierung:** ab L3 alle 11 s; ab L5 zwei Kegel hintereinander (der zweite 0,8 s später, 60° versetzt). Koop: zielt reihum auf die Gruppe jeder Person (B4).
- **Technik:** neuer Hazard `kahlschlag` (Kegel, B1); Beschwörungen haben `alive`, Hazards werden gefiltert. **M.**
- **Content:** ✔ trifft Sozialabbau. Die Satire richtet sich gegen ihn, nicht gegen Bürgergeld-Beziehende.

**M5 Zirkuszelt: Manege (P3).**
- **Satire:** "Der Bundestag ist ja nun kein Zirkuszelt" (`merz-17`, zur Regenbogenflagge). Ausgerechnet er wird zum Zirkusdirektor.
- **Ablauf:**
  - Zu den abprallenden Bällen (gibt es) kommen 3 Bälle, die ihn auf Radius 150 umkreisen ("Jonglage"), ab L3 fünf in zwei gegenläufigen Ringen. Nahkampf muss den Eintritt timen.
  - Ab L4 setzt das Zirkuszelt 4 Zeltstangen als Lob-Einschläge an die Wände.
- **Telegraph:** Die Bälle sind sichtbar; die Zeltstangen kommen als `lob_marker` 1,2 s vorher.
- **Konter:** Lücken in der Jonglage; Abstand.
- **Technik:** kreisende Projektile (Position je Frame relativ zum Boss setzen) **S**; Zeltstangen nutzen `_lob` **S**.
- **Content:** ✔. **Die Regenbogenfahne ist nie die Waffe.** Wenn sie auftaucht, dann als Antwort (z. B. an den Wänden nach seinem Abgang), nie als Witz über queere Menschen.

### 3.4 Die Remigrantin (Weidel-Parodie, Welle 20, Endboss)

Ziel: 60–120 s. Intro-Karte `weidel-05` ("Nieder mit diesen Windmühlen der Schande!").

- P1 "Windmühlen der Schande" (100–66 %)
- P2 "Remigration" (66–33 %)
- P3 "Steuerparadies" (33–0 %)

Regel aus GDD §14: **Keine Phase beschwört oder zeigt die Gruppen, die sie beleidigt.** Ihre Angriffe treffen nur die Spieler:innen und die Umgebung.

**R1 Ansturm-Kette (P1, Umbau).**
- **Satire:** Don Quijote gegen Windräder, nur dass sie gewinnt und danach im Dunkeln steht.
- **Ablauf:** Statt eines Ansturms alle 3 s eine Kette aus 2 (ab L2) oder 3 (ab L4) Anstürmen, jeder neu ausgerichtet, je 0,7 s Ansage. Ein umgerissenes Windrad **fällt in Ansturmrichtung** und hinterlässt eine Rotorlinie (Kontakt 1,0× Schaden, 3 s).
- **Telegraph:** Pfeilbahn vom Boss in Laufrichtung (B1) während der Ansage; das Windrad kippt 1,0 s sichtbar.
- **Konter:** nicht in der Bahn und nicht hinter dem Windrad stehen. Windräder bleiben Deckung gegen Flügel-Projektile; ob man sich dahinter stellt, ist also eine Abwägung.
- **Skalierung:** Ketten wie oben. Koop: jeder Ansturm zielt reihum (B4). Die Boss-Resistenz (B6) begrenzt Kleber und Straßenblockade auf 40 % Verlangsamung, damit der Ansturm bleibt.
- **Technik:** Zustandsmaschine gibt es; Kettenzähler, Bahn-Hazard `ansturm_bahn` (B1), Rotor-Hazard. **S–M.**
- **Content:** ✔. Die Windmühlen-Rede ist belegt (`weidel-05`).

**R2 Die Brandmauer hält (P2, Umbau Remigration, Signatur).**
- **Satire:** Die Brandmauer ist genau das, was sie draußen hält. Wo die Mauer steht, kommt sie nicht durch; wo die Union Löcher gerissen hat, wird es gefährlich.
- **Ablauf:**
  - Das Abschiebe-Band gilt **nur noch vor offenen Segmenten** (Loch ± 1 Nachbarsegment), dafür breiter: 110 px, ab L3 150 px.
  - Druckringe stoßen in Richtung **des Lochs, das ihr am nächsten ist** (statt zur nächsten Wand).
  - Ohne Loch: das alte 70-px-Band an allen Wänden ("Sie findet immer eine Lücke").
  - **Folge über den ganzen Lauf:** Wer im Späti repariert und JU-Schnösel früh erledigt hat, hat jetzt einen sicheren Rand. Die Antifa-Ortsgruppe repariert auch hier (60 px, 3 s).
- **Telegraph:** rote Schraffur nur vor Löchern (Daten aus der Wandmaske, die es schon gibt); Ringe mit Pfeilen zum Ziel-Loch; 2,0 s Ansage bei Phasenbeginn (B8).
- **Konter:** vor intakten Segmenten kämpfen, Löcher reparieren, Ringe nicht vor einem Loch abfangen.
- **Skalierung:** Druckring alle 3,5 s → 2,6 s (L5). Koop: Startlöcher (eins pro Person) machen es zu viert gefährlicher, also gleicht die Bandbreite aus: 110 − 10·(n − 1) px.
- **Technik:** Prüfung in `t_absch` gegen offene Segmente (`Arena.edge_dist` + Segmentindex). Die Ansicht liest `vs.wall` und zeichnet das Band nur dort. **M.** Netz: **keine Änderung** (Breite im `h_rad` des Abschiebe-Hazards).
- **Content:** ✔ Das Ziel bleibt die Spielerschaft (Aktivist:innen), nicht Migrant:innen. Keine Abschiebe-Bilder (kein Flugzeug, kein Bus, keine Koffer, keine Pässe). Der Begriff stammt von ihr (`weidel-04`).

**R3 Briefkastenfirmen (P3, Umbau Steuerparadies).**
- **Satire:** Strukturkritik an Steueroasen statt an Personen (content-guidelines §2 "Strukturen"). Zum Phasenruf passen `weidel-09` (Erbschaftsteuer gegen Null) und die Reserve `weidel-10` ("Ich zahle hier meine Steuern").
- **Ablauf:**
  - Zum Goldbarren-Schild (gibt es) kommen **4 Briefkästen** (Adds, B5), je einer in einer Ecke.
  - Solange einer steht, lädt der Schild mit 2 %/s Max-HP nach ("Geld fließt ab"); jeder zerstörte senkt das um ein Viertel.
  - Ein zerstörter Briefkasten kommt nach 15 s wieder ("Neue Adresse, gleiche Firma", erfunden).
- **Telegraph:** goldene Linien von jedem Briefkasten zum Chalet, die pulsieren, solange Geld fließt.
- **Konter:** aufteilen (Koop: jede Person eine Ecke), Beschwörungen in Ecken stellen, rotieren.
- **Skalierung:** ab L3 alle 12 s; ab L5 laden die Briefkästen auch einander auf. Koop: HP der Briefkästen wachsen mit n.
- **Technik:** B5, Schild-Nachladen in `_boss_eidgenossin`. **M.**
- **Content:** ✔. Briefkasten mit vielen Firmenschildern. **Kein Geldsack, kein Gierschlund, keine Fäden, nichts aus §2.** Keine Behauptung, sie hinterziehe Steuern: Das Bild ist die Steueroase als Struktur; ihr eigenes Zitat steht daneben.

**R4 Wahlabend (Soft-Enrage, nur Endboss).**
- **Satire:** Hochrechnung läuft, die Stimmung kippt.
- **Ablauf:** Ab 150 s Kampfdauer (120 s ab L4) alle 15 s Tempo +10 % und Druckring-Takt −10 %. HUD: "Hochrechnung: …".
- **Konter:** Schaden machen.
- **Zweck:** Kämpfe können nicht endlos stocken (Tank- und Nahkampf-Builds); Ultimates werden nicht festgehalten.
- **Technik:** **S.**
- **Content:** ✔.

## 4. Ultimates gegen Bosse

Ziel: **Ein Ultimate fühlt sich gegen einen Boss gut an** (sichtbare Reaktion, unterbricht einen Angriff, öffnet ein Fenster), **beendet den Kampf aber nicht.**

1. **Die Kampfdauer ist der wichtigste Hebel.** Bei 60–90 s wiegt ein Ultimate 5–10 % statt 33–55 %. Ein eigener Schadensfaktor für Ultimates gegen Bosse ist **nicht nötig**: Ihr direkter Schaden (Flashmob, Critical Mass, Schwarzer Block) ist klein.
2. **Betäubung (B6):** auf Bossen halb so lang (Flashmob 1 s, Fragen Sie mal uns 1 s), danach **10 s "Standfest"** (ab L4 15 s). Dafür **bricht jede Betäubung einen laufenden Zauber ab** (Abstimmung, Kahlschlag, Ansturm-Kette, Geschichte umschreiben), mit großem "UNTERBROCHEN"-Text. Das ist der Moment, der sich gut anfühlt.
3. **Verlangsamung:** auf Bossen höchstens 40 %, aus jeder Quelle (Kleber, Straßenblockade, Antrag gestellt). Elites der Sylt-Clique bleiben ohne Deckel (Stufe 1).
4. **Fragen Sie mal uns gegen den Sauerländer:** Verwundbarkeit ×1,5 statt ×2 (6 s bleiben), Betäubung nach Regel 2. Das spart 3 s statt 6 s. Der Witz bleibt: Er ist der einzige Boss, den es trifft.
5. **Tarifrunde:** bleibt +50 % / 8 s, ein Teamgefühl, und bei langen Kämpfen ~5 %. Zu viert nicht verketten: Gegen Encounter-Einheiten gilt höchstens eine Tarifrunde pro 20 s (die nächste bufft nur Beschwörungen und Wellen-Gegner). Erst messen, dann entscheiden.
6. **Phasen-Übergänge (B2):** 2–2,5 s unverwundbar; laufende Verwundbarkeit wird pausiert, nicht verbraucht. Wer sein Ultimate in den Übergang feuert, verliert also nur die Kontrolle, nicht den ×1,5-Bonus. **Timing wird eine Fähigkeit, nicht eine Falle.**
7. **Endboss: ein Ultimate pro Phase.** Bei jedem Phasenwechsel der Remigrantin lädt das Ultimate neu (3 Einsätze im Kampf). Das gleicht die längere Kampfdauer aus. Elites (60-s-Wellen) bleiben bei einem pro Welle.
8. **Unverwundbarkeit (Critical Mass 5,4 s, Urlaubsantrag 4 s):** unverändert. Bei langen Kämpfen ist das ein Ausweich-Werkzeug, kein Sieg.
9. **Reaktion zeigen:** Betäubte Bosse taumeln mit Blase (erfunden: "Kein Kommentar!"), verwundbare tragen das Symbol von "Fragen Sie mal uns", "Standfest" zeigt einen Pressesprecher-Schild.

## 5. Vielfaltsregeln für alle Boss-Kits

1. **Jedes Kit enthält vier Klassen:**
   - ein gezielter Ausweich-Angriff
   - eine **Arena-Veränderung über die vier Wände**: Abstimmung (Löcher), Kreidestriche von Wand zu Wand, Band nur vor Löchern, Briefkästen in den Ecken
   - ein **Zielwechsel** (Add, Phasen-Objekt)
   - ein Angriff **gegen Klumpen und Stillstand**: Kahlschlag (Beschwörungen und Zonen), Tafelbild (wischt Kreide weg), Nachsitzen (Kiter), Briefkästen (Geschütze in einer Ecke reichen nicht)
2. **Adds gehören zum Boss, nie zu den Gruppen, die er beleidigt:** Gegenstände (Schulbuch, Wahlurne, Briefkasten) oder die normalen Gegner des Spiels als Folge seiner Politik (AfD-Gegner durch das Loch, das der Sauerländer abgestimmt hat).
3. **Wenige große, angesagte Treffer statt Kugelhagel.** Die 0,5 s Unverwundbarkeit machen Spam wertlos. Boss-Treffer ≥ 1,5× des Kontaktschadens normaler Gegner derselben Welle, dafür immer mit Ansage nach B8.
4. **Unvermeidbarer Schaden ist nur Kratzer** (Druckring ≤ 10 % Max-HP). Alles Größere ist ausweichbar.
5. **Koop ist nicht leichter:** Ziele reihum (B4); "pro Person"-Instanzen (Linien, Kegel, Nachsitzen); "Hier hinstellen"-Mechaniken brauchen ab 3 Personen zwei. Der Schaden pro Treffer skaliert nicht mit n, die Zahl der Instanzen schon.
6. **Ein Phasensystem:** Phasen bei 66/33 % mit Sperre und Übergang (B2); das Tempo-Plus ist Teil der Phasen statt eines zweiten Schalters bei 50 %.
7. **Enrage:** Elites behalten ihr Fluchtende über den Wellentimer (kein Lohn). Der Endboss bekommt "Wahlabend" (R4).
8. **Status- und Beschwörungs-Builds müssen sich bewegen:** Verlangsamung auf Bossen höchstens 40 %; mindestens ein Angriff pro Boss löscht oder verdrängt Zonen und Beschwörungen; Adds stehen verteilt (Ecken, Wände).
9. **Lesbarkeit:** höchstens zwei Muster gleichzeitig bis L2, drei ab L3. Der Name des Zaubers steht in der Boss-Leiste (B3).

## 6. Schwierigkeit pro Umfrage-Stufe (nur Encounter)

Beantwortet für Bosse auch den offenen Punkt "Umfrage difficulty levels: which extra modifier each step adds".

| Stufe | Boss-HP-Faktor (neu, zusätzlich) | Ansagezeit | Gleichzeitige Muster | Neu freigeschaltet |
|---|---|---|---|---|
| 10 % (L0) | ×1,0 | ×1,00 | 2 | Grundkit |
| 15 % (L1) | ×1,15 | ×0,95 | 2 | – |
| 20 % (L2) | ×1,3 | ×0,95 | 2 | Sektlache 5 s; Tafelbild nacheinander; Ansturm-Kette 2 |
| 25 % (L3) | ×1,45 | ×0,90 | 3 | Polonaise; Teilwende; Bierdeckel doppelt; Jonglage 5; Kahlschlag alle 11 s; Band 150 px; Briefkasten alle 12 s |
| 30 % (L4) | ×1,6 | ×0,85 | 3 | Nachsitzen enger; Wende 5 s; Zeltstangen; Ansturm-Kette 3; Standfest 15 s; Übergang 1,5 s; Wahlabend ab 120 s |
| 35 % (L5) | ×1,75 | ×0,80 (Untergrenzen B8) | 3 | **Signatur-Steigerung:** Türsteher im VIP-Bereich; Umschreiben bis 25 %; Abstimmung über 2 Segmente; Doppel-Kahlschlag; Briefkästen laden einander |

Der HP-Faktor kommt **zusätzlich** zu `diff_hp` als neuer Wert `diff_boss_hp` = 0,15 pro Stufe, nur in `spawn_enemy` für `faction == "elite"` mit Encounter. Die Wellen bleiben, wie sie sind.

## 7. Zahlen: HP als Hebel neben der Mechanik

Startwerte, die die Messung (§9) bestätigen muss:

- **Untergrenze durch Mechanik** (geschätzt, Fernkampf-Build):
  - Übergänge 2 × 2–2,5 s
  - Zielwechsel und Laufwege ~15–25 % weniger Schaden auf den Boss
  - verpasste Abstimmungen und Umschreibungen kosten zusätzlich
  - Elites +6–10 s, Endboss +10–20 s gegenüber heute, schon ohne HP-Änderung.
- **HP:** `final_boss_mult` 0,9 → **1,6**; neuer `diff_boss_hp` 0,15/Stufe; Elites Welle 10/15 über einen neuen Faktor pro Encounter `hp_mult` (Lehrer 1,4, Sauerländer 1,6), Sylt-Clique 1,0. Auf 35 % solo ergibt das gegenüber heute:

| Encounter | HP heute (35 %, solo) | HP neu (35 %, solo) | Fernkampf heute | Ziel neu (Fernkampf, mit Mechanik) |
|---|---|---|---|---|
| Sylt-Clique | 1.092 | 1.911 | ~18 s | 25–35 s |
| Geschichtslehrer | 3.402 | 8.335 | ~10 s | 30–40 s |
| Sauerländer | 10.174 | 28.487 | ~10 s | 35–45 s |
| Remigrantin (+Schild) | 26.045 | 81.000 | ~12 s | 60–90 s |

- Auf 10 % wirkt nur `hp_mult` bzw. `final_boss_mult` (`diff_boss_hp` ist dort ×1,0): Lehrer ×1,4, Sauerländer ×1,6, Remigrantin ×1,78 gegenüber heute. Für schwache Builds (Nahkampf, Tank) trifft der Endboss das Wahlabend-Enrage. Dass sie auf 35 % kaum gewinnen, ist gewollt (balancing.md §1: "hardly beatable"). Auf 10–20 % muss die Messung zeigen, dass sie die 180 s schaffen.
- **Koop:** `elite_coop` 0,45 → 0,5, damit die HP pro Person zu viert (0,53) nicht unter solo (0,6) fallen. Die Instanzen pro Person (B4) erledigen den Rest.

## 8. Shortlist (Reihenfolge = Umsetzungsreihenfolge)

**Zuerst die Grundlagen (machen jeden Boss schwerer, kleiner Aufwand):**
1. **B2 Phasen-Sperre und Übergang** (S): kein Wegbursten, Signaturen feuern, Ultimate-Timing.
2. **B6 Boss-Resistenz und Ultimate-Regeln §4** (S): Betäubung halb + Standfest + Abbruch, Verlangsamung ≤ 40 %, Fragen Sie mal uns ×1,5, Endboss ein Ultimate pro Phase.
3. **HP-Hebel §6/§7** (S): `diff_boss_hp`, `final_boss_mult`, `hp_mult` pro Encounter; nur Encounter-Einheiten.
4. **B4 Ziele reihum** (S) und **Fehler-Fix Sauerländer-Koordinaten** (S, mit Regressionstest).

**Dann pro Boss die 2–3 stärksten Fähigkeiten:**

| Rang | Boss | Fähigkeit | Aufwand | Warum |
|---|---|---|---|---|
| 1 | Remigrantin | **R2 Die Brandmauer hält** | M | Titelmechanik im Endboss; Konsequenz über den ganzen Lauf; kein Snapshot-Umbau |
| 2 | Sauerländer | **M1 Abstimmung, egal mit wem** | M | stärkste Satire im Spiel, nutzt Wand und Späti, braucht kein B1 |
| 3 | Geschichtslehrer | **G1 Wende-Umbau** | S | Signatur feuert endlich; Bücher drehen um |
| 4 | Remigrantin | **R3 Briefkastenfirmen** | M | zwingt zum Aufteilen, Koop-Spiel, Strukturkritik |
| 5 | Sauerländer | **M3 Sondervermögen-Umbau** | S–M | ersetzt den Ja/Nein-Schadenscheck, gibt Nahkampf und Tank eine Aufgabe |
| 6 | Geschichtslehrer | **G4 Geschichte umschreiben** | M | Zielwechsel, starke Satire |
| 7 | Remigrantin | **R1 Ansturm-Kette** + **R4 Wahlabend** | S–M | Druck in P1, kein Stillstand im Endkampf |
| 8 | Sauerländer | **M4 Kahlschlag** | M (B1) | zwingt Status und Beschwörung zur Bewegung |
| 9 | Geschichtslehrer | **G2 Tafelbild** | M (B1) | Arena-Linien über alle vier Wände |
| 10 | Sylt-Clique | **S3 Rückstoß** + **S1 Absperrband** | S + M | Buff brechbar; lehrt "Hier hinstellen" |

B1 (Winkel im Snapshot) erst bauen, wenn Rang 8/9 drankommen. Bis dahin reichen Kreis-Hazards, Wandmaske und der Lebensanteil.

## 9. Messplan mit `tools/balance_sim.gd`

Ein anderer Agent baut das Werkzeug gerade aus (`char=`, A/B-Modus). Das hier setzt darauf auf.

**Was der Bot zusätzlich können muss** (sonst misst er die Bosse falsch):
- **Ultimates benutzen:** beim Boss-Spawn bzw. nach Übergängen (`request(peer, "ult")`). Heute nie, deshalb sind alle Kill-Zeiten zu lang.
- **Gegnerischen Telegraphen ausweichen:** Lob-Markierungen, Kegel, Linien, Band (wie Projektile in `_kite`: Abstoßung von Hazards mit `owner == 0`).
- **Ziele wechseln:** Adds (Schulbuch, Briefkasten) und Plenum oder VIP-Kreis aufsuchen, wenn es welche gibt. Einfache Regel: Gibt es ein Encounter-Add mit Countdown, läuft die nächste Person hin.
- **Scheine sammeln** während Sondervermögen.
- Ohne diese Punkte überschätzt der Bot die neuen Mechaniken (er läuft in jede Ansage) und unterschätzt die Ultimates.

**Kennzahlen pro Lauf** (größtenteils vorhanden):
- `enc_kill` und `taken` pro Bosswelle
- `taken_by` pro Quelle: neue Hazard- und Projektiltypen erscheinen automatisch als `hazard:kahlschlag` usw. und liefern **Trefferquote pro Fähigkeit**
- Ultimate-Schaden (`run_stats` Quelle `ult`)
- **neu:** Zeit in Übergängen, abgebrochene Zauber, verpasste Abstimmungen und Umschreibungen

**Läufe:**
1. **Ausgangswert vor Änderungen** (aktuelle Werte, mit Ultimate-Bot):
   `BUILDS="ranged crit summon melee" tools/balance_matrix.sh boss_a.jsonl 6 builds "2 5" immortal`
   (unsterblich, damit Umfrage 35 % überhaupt Welle 20 erreicht; 4 Builds × {1,4} × 2 Stufen × 6 Seeds = 96 Läufe, unsterblich ~3–10× teurer, also ~30–40 min).
2. **Nach jeder Shortlist-Stufe dieselben Seeds** → `boss_b.jsonl`, dann
   `python tools/balance_report.py --ab boss_a.jsonl boss_b.jsonl`: Boss-Kill-Zeiten A → B pro Build × Spielerzahl × Umfrage, Schaden genommen.
3. **Sterbliche Gegenprobe** auf 10 % / 20 %: `tools/balance_matrix.sh boss_m.jsonl 6 builds "0 2"`. Gewinnquoten dürfen auf 10 % kaum sinken (Ziel: Fernkampf und Beschwörung ≥ 75 %), auf 20 % moderat.
4. **Zielwerte:**
   - Endboss 60–120 s für Fernkampf, Krit und Beschwörung auf 20–35 %
   - Elites 20–40 s
   - unsterbliche Bots nehmen im Endkampf ≥ 1,5× Max-HP (heute 0,1–0,7×)
   - zu viert pro Person ±25 % der Solo-Werte bei Kill-Zeit und Schaden
   - Ultimate-Anteil am Boss-Schaden ≤ 10 %
5. **Schneller Zyklus (optional, L):** ein Modus `encounter=<id> wave=<n>`, der direkt in die Bosswelle springt und Ausrüstung aus dem `loadout` eines früheren Laufs lädt, spart ~90 % der Laufzeit pro Bossmessung.

## 10. Content-Prüfung und Nachprüfen

- **Zitate verwendet (alle `verifiziert`):**
  - `hoecke-02` (Intro Lehrer)
  - `merz-11` ("Kahlschlag"), `merz-12` / `merz-13` (Abstimmung 29.01.2025), `merz-17` (Zirkuszelt), `merz-26` ("Whatever it takes")
  - `weidel-04` (Remigration), `weidel-05` (Windmühlen), `weidel-09` (Erbschaftsteuer), `weidel-10` (Steuern, Schweizer Wohnsitz)
  - Im Kampf erscheinen nur erfundene, markierte Blasen.
- **Bewusst nicht verwendet:** `hoecke-09` (SA-Losung; §86a-Nähe, als Mechanik tabu); alle Zitate über Migrant:innen, Kinder, Geflüchtete (`merz-05`, `merz-06`, `weidel-01`, `weidel-02`, `weidel-07`, `linnemann-01`) als Grundlage von Fähigkeiten. Die stehen auf Karten und im Album, die Mechanik antwortet nie mit Bildern dieser Gruppen.
- **Heikel, beim Bau prüfen:**
  - **Remigrantin:** keinerlei Abschiebe-Bildsprache (Flugzeuge, Busse, Koffer, Pässe, Menschen hinter Zäunen); das Band bleibt rote Schraffur.
  - **Steuerparadies:** keine Behauptung von Steuerhinterziehung; Briefkasten und Goldbarren ja, Geldsack und Gierkarikatur nein (§2).
  - **Geschichtslehrer:** keine Gedenkorte, keine NS-Symbole, keine Inhalte auf Tafel oder Buch.
  - **Zirkuszelt:** Regenbogen nie als Angriff.
  - **Sylt:** kein Gesang, keine Parole aus dem Video.
- **Nachprüfen (nicht in `zitate_de.json`, nur als Faktenbezug genutzt):**
  - Bierdeckel-Steuerkonzept (Merz, CDU-Parteitag Leipzig 2003)
  - Höcke als ehemaliger Geschichtslehrer
  - Ort des Sylt-Videos (Pfingsten 2024)
  - Alle drei sind im GDD schon Grundlage. Für neue Flavor-Texte eine Quelle in `research/` ablegen.
- **Gefundene Doku-Lücke:** balancing.md §7 verweist auf einen Eintrag in open-questions.md, den es nicht gibt.
