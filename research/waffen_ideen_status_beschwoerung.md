# Waffen-Ideen: Status (Ziviler Ungehorsam) und Beschwörung (Ehrenamt)

Stand: 2026-11-02. 13 Konzepte (6 Status, 6 Beschwörung, 1 Hybrid) plus 3 neue Statuseffekte für "Brandmauer". Ergänzt [waffen_ideen.md](waffen_ideen.md); was nicht belegt werden konnte, steht unter "Nachprüfen". Reine Recherche: GDD, `decisions.md` und Code sind unverändert.

## Ausgangslage

- **Bestand (23 Waffen):** Fernkampf 8, Nahkampf 7, Status 5 (Tofu, Farbbeutel, Kleber, Normenkontrolle, Straßenkreide), Beschwörung 3 (Infostand, Brandmauer-Ziegel, Weißer Overall).
- **Was Status heute kann:** Gift (Tofu, Kompost-Ausbreitung beim Tod), Slow (Farbbeutel, Kleber), Zonen-DoT (Kleber, Kreide), verzögerter Burst (Normenkontrolle). Betäubung gibt es nur über Handarbeit-Waffen (Trillerpfeife, Bierkiste), "enthüllt" (+Krit) nur über Durchschlagskraft (Scheinwerfer).
  - **Lücken:** keine Fähigkeitssperre, kein Debuff, der allen im Team nützt, kein Abwehr-Werkzeug (Status-Builds sterben früh), kein DoT, der mit der Gegnerdichte wächst, keine Kontrolle über die Laufrichtung.
- **Was Beschwörung heute kann:** stationärer Schütze (Infostand), statische Linie (Ziegel), Einmal-Schwarm (Overall).
  - **Lücken:** nichts, das Gegner auf sich zieht (Köder/Tank), nichts, das heilt, kein Begleiter, der mitläuft, keine Linie, die sich mit den Spieler:innen bewegt, kein Aufbau-Effekt (wird mit der Zeit stärker).
- **Balancing-Befund (balancing.md, v0.3.0):** Status ist für Bots der schwächste Build (1/12 Siege bei Umfrage 10 %), Beschwörung der stärkste (10/12). Daraus folgt:
  - **Neue Status-Waffen** brauchen mehr direkten Schaden oder Überlebens-Nutzen. Reine DoT-Waffen allein helfen nicht, auch wegen des Reichsbürgers (D-079).
  - **Neue Beschwörungen** sollen **Nutzen statt roher DPS** bringen (Köder, Heilung, Mobilität, Co-op-Linie). Tier-I-DPS bleibt bei oder unter dem Infostand.

## Hinweise

- **Basis:** Werte sind Startvorschläge auf der Skala von `Content.WEAPONS`: Tofu 3 + 5 Gift/s für 3 s bei 1,0 s, Kleber 4/s bei 2,2 s, Normenkontrolle 45 bei 4,5 s, Infostand 4 pro Flugblatt alle 0,6 s für 10 s (max 2), Overall 3 × 6 bei 4,0 s. Stufe II–IV wie üblich ×1,67 / ×2,67 / ×4,3. Skalierungsfaktor 0,6–1,0, Preis 20–28. Balancing steht aus.
- **Aufwand:**
  - **S:** bestehender `kind` mit neuen Parametern, wenige Zeilen.
  - **M:** neuer `kind` oder neuer Statuseffekt mit Hooks in mehreren Stellen.
  - **L:** greift in Gegner-KI oder Zielwahl ein oder bringt neue Wechselwirkungen zwischen Gegnern und Beschwörungen.
- **Netz (gilt für alle):** Alles läuft auf dem Host (networking.md §5), Clients zeichnen nur den `ViewState`.
  - **Neue Typen** gehören ans Ende von `SUMMON_ORDER`, `HAZARD_ORDER` und `PROJ_ORDER`, sonst verschieben sich die Netz-IDs.
  - **`ViewState.e_flags` ist voll:** ein Byte, alle 8 Bits belegt (ELITE, POISONED, SLOWED, WINDUP, PARKED, SHIELDED, BUFFED, HIT). Jeder neue sichtbare Status braucht ein zweites Flag-Byte pro Gegner, bei 200 Gegnern +200 B pro Snapshot (ca. +4 %), plus Protokoll-Bump.
  - **Budget:** max. 64 Beschwörungen pro Snapshot (networking.md §6).
- **Text:** Namen und Flavor sind Übersetzungs-Keys (`i18n/content.csv`), Flavor sind **erfundene Satire-Zeilen** und dürfen nicht wie echte Zitate aussehen (Content-Guidelines §4). Echte Zitate erscheinen nur auf Karten und im Album, mit ID aus `research/zitate_de.json` (nur `verifiziert`).
- **Reichsbürger (D-079):** Er ist immun gegen alle Statuseffekte, auch gegen die neuen, aber jede Waffe macht ihm Schaden. Darum hat jede Status-Waffe unten einen direkten oder Zonen-Schadensanteil.

## Neue Statuseffekte

Drei Effekte, je mit einem klaren, lesbaren Symbol über dem Gegner. Elites und Bosse reagieren abgeschwächt (wie bei der Betäubung, die Elites heute ganz ignorieren).

| Effekt | Wirkung | Lesbarkeit | Elites / Bosse | Reichsbürger | Kosten |
|---|---|---|---|---|---|
| **In Bearbeitung** (Fähigkeitssperre) | Gegner läuft und rempelt weiter, nutzt aber **keine Spezialfähigkeit**: JU-Schnösel stimmt nicht ab (Abstimmungs-Timer pausiert), Telegram-Onkel wirft nicht, Lobbyist-Hausausweis gibt keine Rüstung, Immobilienerbe legt keine Mietzone, Golfclub-Vorstand lobbt nicht, Porsche-SUV startet keinen Sturmlauf, Hipster schiebt nicht. Stirbt ein FDP-Jungunternehmer "in Bearbeitung", ist die Gründung "noch in Bearbeitung": keine Startups. | Wartenummer-Zettel über dem Kopf ("Nr. 551") | Fähigkeits-Cooldowns laufen nur halb so schnell, keine volle Sperre | immun | M: ein Flag `silence_t`, Abfrage in ca. 8 KI-Funktionen |
| **Aktenkundig** (stapelbare Verwundbarkeit) | Pro Stapel +5 % Schaden **aus allen Quellen** (max 5 Stapel = +25 %), 5 s, jeder Treffer frischt auf. Hilft dem ganzen Team, das ist der Co-op-Reiz. | Kleiner Aktenstapel, 1–5 Blätter hoch | volle Wirkung (soll Boss-Werkzeug sein) | immun | M: Zähler + Zeit pro Gegner, ein Faktor in `_damage_enemy`, Stapelzahl im Snapshot (3 Bit) |
| **Rolle rückwärts** (Richtungsumkehr) | Gegner läuft **rückwärts** von seinem Ziel weg (70 % Tempo), Blick weiter zum Spieler. Kontaktschaden bleibt (wer reinläuft, wird getroffen). Kein Knockback, also kein Physik-Chaos: Gegner bleiben in Formation und laufen z. B. zurück in Kleber oder Kreide. | Gegner gespiegelt, "↺" über dem Kopf | immun (wie Betäubung) | immun | S–M: Bewegungs-Override vor dem `match e.def["ai"]` in `_step_enemies` |

- **Satire:** "In Bearbeitung" gibt den Gegnern das Amt zurück, das sie Bürgergeld-Empfänger:innen zumuten. "Aktenkundig" ist Transparenz: Lobbyregister, Protokoll, Akte. "Rolle rückwärts" ist die Kehrtwende als Politik-Stil (Schuldenbremse → Sondervermögen; der Sauerländer hat das schon als Bossphase). Die "Wende um 180 Grad" des Geschichtslehrers (hoecke-02) wird bewusst **nicht** als Name benutzt, die gehört dem Boss und hat Gedenk-Kontext.
- **Bewusst nicht vorgeschlagen:**
  - **"Verwirrt"** (zufällige Laufrichtung): schlechter lesbar als "Rolle rückwärts" und vom Kandidaten "Versiffter 68er" (Rauchwolke, GDD §9) besetzt.
  - **"Umerzogen":** Name abgelehnt (Lager-Konnotation). Der Bekehrungs-Effekt läuft unten als waffengebundenes **"Umgestimmt"** (S5).
- **Offene Frage für die Spec:** Soll der Reichsbürger **nicht** immun gegen "Aktenkundig" sein ("erkennt eure Autorität nicht an, liebt aber Papierkram")? Das wäre witzig, bricht aber die einfache Regel "immun gegen alle Status". Empfehlung: immun lassen, Regel einfach halten.

## Tabelle

Skalierung: Ziviler Ungehorsam = status, Ehrenamt = summon.

| # | Name | Kind | Skalierung | Schaden I | CD (s) | Reichweite | Spezialeffekt | Aufwand | Rolle / Unterschied |
|---|---|---|---|---|---|---|---|---|---|
| S1 | Kleine Anfrage | shot (+`silence`) | Ungehorsam 0,9 | 5, Pierce 1 | 1,2 | 360 | "In Bearbeitung" 3 s; zielt bevorzugt auf Gegner mit Fähigkeit | M | Einzige Antwort auf Gegner-Fähigkeiten; schützt die Brandmauer (JU-Schnösel) |
| S2 | Lobbyregister | shot (+`file`) | Ungehorsam 0,7 | 3 | 0,6 | 340 | +1 "Aktenkundig" pro Treffer; bei 5 Stapeln "Offengelegt": 20 Burst, Stapel weg | M | Einzelziel-Aufbau + Team-Verstärker (Normenkontrolle: ein Burst nach Zeit) |
| S3 | Faktencheck | cone 90° (+`reverse`) | Ungehorsam 0,8 | 6 | 1,6 | 170 | "Rolle rückwärts" 1,2 s; löscht Kettenbriefe im Kegel | S–M | Abwehr für den Status-Build: Abstand ohne Knockback, Anti-Projektil |
| S4 | Soli-Sticker | shot (+`spread`) | Ungehorsam 1,0 | 2 + Gift 3/s, 4 s | 0,9 | 320 | Gift springt jede 1 s auf 1 Nachbarn in 50 px über | M | DoT, der mit der Gegnerdichte wächst (Tofu: Einzelziel; Kompost: nur beim Tod) |
| S5 | Aussteiger-Flyer | shot (+`convert`) | Ungehorsam 0,9 | 8 | 2,0 | 340 | AfD-Fraktion (nicht Elite, nicht Reichsbürger) unter 40 % HP: "Umgestimmt" 5 s, kämpft für dich, steigt dann aus | L | Einziger Bekehrungs-Effekt; belohnt das Fertigmachen von AfD-Gegnern |
| S6 | Brennnesseljauche | puddle (`jauche`, +`repel`) | Ungehorsam 1,0 | 5 pro s | 3,0 | 280 (r 70) | 4 s, max 2; drückt Gegner sanft hinaus (120 px/s), Gift, kein Slow | S–M | Zonen-Sperre: Loch kurz zustopfen, Revive decken (Kleber: hält fest, statt zu verdrängen) |
| B1 | Pappkamerad | **decoy** (turret ohne Schuss, mit HP) | Ehrenamt 1,0 | 12 Burst beim Umfallen (r 90) | 7,0 | 220 (Platzieren) | Steht 8 s, zieht Nicht-Elites im Radius 240 auf sich, max 1 | L | Köder/Tank: einzige Beschwörung, die Gegner bindet |
| B2 | Kiezladen | **spawner** (turret + overall) | Ehrenamt 0,8 | 5 pro Nachbar:in | 6,0 | 280 | Steht 10 s, schickt alle 1,2 s eine:n Nachbar:in (1 Treffer), max 1 | M | Dauer-Schwarm von einem festen Punkt (Overall: 3 auf einmal vom Spieler) |
| B3 | Mahnwache | **aura** (turret ohne Schuss) + Aufbau | Ehrenamt 1,0 | 3 pro Puls (1 s, r 110) | 10,0 | — | Steht 20 s, +10 % Schaden pro Puls bis +150 %, max 1 | S | Aufbau-Beschwörung: lohnt Stellung halten (Klimakleber, Gewerkschaft) |
| B4 | Menschenkette | **tether** | Ehrenamt 1,0 | 4 pro 0,5 s | 5,0 | 320 (Kettenlänge) | 6 s: Kette zwischen dir und nächster:m Mitspieler:in (solo: Laternenmast am Wurfpunkt), Kontakt = Schaden + Rückstoß 120 | M | Bewegliche Linie, die Spieler:innen spannen (Ziegel: statisch); Co-op-Teamwork |
| B5 | Demo-Sanis | **follower** | Ehrenamt 1,0 (Heilung) | Heilung 2 pro 3 s | — (bleibt die Welle) | 160 (Heilradius) | 1 Demosanitäter:in folgt dir, heilt die verletzteste Person im Radius; Co-op: Revive daneben +50 % schneller | M | Einzige Heilung als Waffe, Support-Slot |
| B6 | Lauti | **patrol** (genosse-Variante) | Ehrenamt 0,9 | 5 pro Puls (1,2 s, r 90), Knock 80 | 6,0 | 140 (Kreisbahn) | Lautsprecherwagen fährt 10 s im Kreis um dich, max 1 | M | Mobile Beschwörung: begleitet Kiter (alle anderen stehen oder sind Einmal-Treffer) |
| B7 | Kiezchor (Hybrid) | aura (turret) | Ehrenamt 0,6, Ungehorsam 0,6 | 4 pro Puls (2 s, r 150) | 6,0 | — | Steht 8 s, Puls gibt "Rolle rückwärts" 0,8 s, max 1 | S (nach S3) | Brücke zwischen Status- und Summon-Build (Shop-Match ≥ 0,5 für beide) |

Grobe Tier-I-DPS ohne Stats zum Vergleich: Tofu ~8 (Einzelziel), Normenkontrolle ~10 (Einzelziel), Infostand ~13 (2 Stände), Overall ~4,5. S1 ~4 (+Pierce, +Sperre), S2 ~8,5 (Einzelziel, inkl. Burst), S3 ~3,8 (Fläche), S4 ~5 Einzelziel bzw. mehr in dichten Gruppen, B2 ~4,2, B3 3–7,5 (Fläche, steigt), B4 ~8 auf der Linie, B6 ~4,2 (Fläche).

## Konzepte im Detail

### S1 Kleine Anfrage

- **Flavor:** "551 Fragen an die Zivilgesellschaft? Hier kommt Frage 552." Die Union fragte im Februar 2025 per Kleiner Anfrage 551 Mal nach NGOs, 25 Fragen allein zu den Omas gegen Rechts. Im Spiel geht die Anfrage zurück an die Absender:innen. Ziel des Witzes: die Fraktion, die Engagement unter Verdacht stellt, nicht die Verwaltung.
- **Mechanik:** Projektil (Aktendeckel) mit Pierce 1. Treffer gibt "In Bearbeitung" für 3 s. Neue Zielwahl-Option `prefer_ability`: unter den Gegnern in Reichweite zuerst die, deren Fähigkeit gerade läuft oder bald kommt und die noch nicht gesperrt sind (JU-Schnösel an der Mauer zuerst). Sonst gilt die normale Zielauswahl der Spieler:in.
- **Nische:** Bisher kann keine Waffe Gegner-Fähigkeiten verhindern. Sie macht das Brandmauer-Kernspiel (Löcher) für den Status-Build steuerbar.
- **Zahlen:** 5 / 8 / 13 / 21, CD 1,2 s, Reichweite 360, Tempo 500, Pierce 1, Sperre 3 s, Skalierung status 0,9, Preis 24.
- **Items:** Kompost wirkt nicht auf die Sperre, nur ×0,7 auf den direkten Treffer. Sekundenkleber und Klimakleber-Bonus über die Skalierung. Gute Paarung mit dem Antifa-Ortsgruppe-Reparieren.
- **Content:** Echte Bezugsquelle ist **cdu-fraktion-01** (verifiziert, 24.02.2025, Drucksache 20/15035). Das Zitat steht nur auf Karte oder im Album, mit Sprecher, Partei, Datum, `kontext_kurz`. Der Flavor nennt nur die Zahl (Tatsache), kein Wortlaut. Punch up: ja.

### S2 Lobbyregister

- **Flavor:** "Eintragungspflichtig. Jeder Treffer kommt in die Akte." Seit 2022 gibt es das Lobbyregister des Bundestags. Im Spiel wird jeder Treffer protokolliert, bis die Akte voll ist.
- **Mechanik:** Schnelle Aktenblätter. Jeder Treffer +1 "Aktenkundig" (+5 % Schaden aus allen Quellen pro Stapel, max 5, 5 s). Trifft die Waffe einen Gegner mit 5 Stapeln: **"Offengelegt"**, Burst 20 / 33 / 53 / 86 (+ status ×1,0), Stapel zurück auf 0, Sprechblase "Offengelegt!".
  - **Bonus:** Ein Lobbyist mit ≥ 3 Stapeln verliert die Hausausweis-Aura, seine Nachbar:innen bekommen keine Rüstung mehr.
- **Nische:** Aufbau-Schaden auf ein Ziel, der dem **ganzen Team** nützt (+25 %). Scheinwerfer gibt nur Krit-Chance, Normenkontrolle einen einmaligen Burst.
- **Zahlen:** 3 / 5 / 8 / 13, CD 0,6 s, Reichweite 340, Tempo 700, Skalierung status 0,7, Preis 26.
- **Items:** Kompost: Den "Offengelegt"-Burst als Statusschaden zählen (kein ×0,7), sonst bestraft der Status-Build-Gegenstand seine eigene Waffe. Kritische Masse und Entlassungsurkunde profitieren vom +25 %-Fenster. Tarifrunde (+50 %) stapelt multiplikativ: auf Spitzenwerte achten.
- **Content:** Ziel sind Lobbyist:innen als Struktur. Keine Geldsack- oder Aktenkoffer-Optik (Guidelines §2), die Akte ist ein Leitz-Ordner.

### S3 Faktencheck

- **Flavor:** "Wirkt nur kurz. Aber es wirkt." Fakten vertreiben Desinformation nicht für immer, für 1,2 Sekunden aber schon. Ziel: die Telegram-Onkel und die Kehrtwenden der Mächtigen.
- **Mechanik:** Kegel 90° nach vorn, kleiner Schaden, "Rolle rückwärts" 1,2 s. Zerstört gegnerische Projektile im Kegel (Kettenbriefe, Golfbälle), wie es die Mietspiegel-Orbits schon tun.
- **Nische:** Der Status-Build hat kein Abwehrwerkzeug und stirbt deshalb früh (balancing.md). Diese Waffe schafft Abstand, ohne Gegner auseinanderzuwerfen, und treibt sie zurück in eigene Zonen (Kleber, Kreide, Jauche). Megafon und Grundgesetz: Knockback; Trillerpfeife: Betäubung, Handarbeit.
- **Zahlen:** 6 / 10 / 16 / 26, CD 1,6 s, Reichweite 170, Bogen 90°, Knock 0, Dauer 1,2 s (Stufe IV 1,6 s), Skalierung status 0,8, Preis 22.
- **Optionaler Gag:** AfD-Gegner, die gerade durch ein Loch gekommen sind, laufen bei "Rolle rückwärts" wieder hinter die Mauer. Lustig, aber aufwendig (Wechsel von `behind`), erst später.
- **Content:** unbedenklich. Ziel sind Falschinformationen und politische Kehrtwenden.

### S4 Soli-Sticker

- **Flavor:** "Laternenmast, Stromkasten, Porsche-Heckscheibe. Hält überall." Sticker-Kultur ist das billigste Protestmittel überhaupt.
- **Mechanik:** Projektil, kleiner Treffer, Gift 3/s für 4 s ("beklebt"). Jede Sekunde gibt ein beklebter Gegner einen Sticker an **einen** unbeklebten Gegner in 50 px weiter. Die Kopie hat volle 4 s, frischt aber den Spender nicht auf.
  - **Deckel:** max. 25 beklebte Gegner pro Besitzer:in, sonst explodiert es in dichten Schwärmen.
- **Nische:** Der einzige DoT, der **mit der Gegnerdichte** skaliert. Er hilft dem Status-Build in späten Wellen gegen Massen. Kompost verbreitet erst beim Tod.
- **Zahlen:** Treffer 2 / 3 / 5 / 8, Gift 3 / 5 / 8 / 13 pro s, CD 0,9 s, Reichweite 320, Skalierung status 1,0 (Gift über `1 + status × 0,1` wie Tofu), Preis 24.
- **Items und Netz:** Kompost: Gift ×2 und Tod-Ausbreitung stapeln sinnvoll, Deckel beachten. Billig fürs Netz: nutzt `EF_POISONED`, kein neues Flag.
- **Content:** Sticker-Motive generisch und eigen (Herz, Regenbogen, "Mieten runter", Fahrrad). **Keine verbotenen Symbole**, auch nicht durchgestrichen. Keine echten Parteilogos.

### S5 Aussteiger-Flyer

- **Flavor:** "Raus ist möglich. Die Nummer steht hinten drauf." Aussteigerprogramme helfen seit 2000 Menschen aus der rechtsextremen Szene. Im Spiel kann ein angeschlagener AfD-Gegner seine Meinung ändern.
- **Mechanik:** Projektil mit normalem Schaden. Trifft es einen Gegner der Fraktion `afd` (nicht Elite, nicht Reichsbürger) und hat der danach ≤ 40 % HP, wird er **"Umgestimmt"** (5 s):
  - Er läuft zum nächsten anderen Gegner und macht dort seinen Kontaktschaden ×3 pro s.
  - Andere Gegner ignorieren ihn, Spieler:innen trifft er nicht.
  - Danach **"steigt er aus":** Er geht ruhig zum nächsten Loch bzw. Rand und verschwindet. Das zählt als Kill der werfenden Person, mit normalem Pfand.
- **Nische:** Bisher kann keine Waffe Gegner die Seite wechseln lassen. Belohnt Fokus auf AfD-Gegner, passt zu Antifa (×1,4 gegen AfD) und Antifa-Ortsgruppe.
- **Zahlen:** 8 / 13 / 21 / 34, CD 2,0 s, Reichweite 340, Schwelle 40 % (Stufe IV 55 %), Skalierung status 0,9, Preis 28.
- **Netz:** neues Flag (Umfärbung).
- **Content:**
  - **Positiv** gegenüber Aussteiger:innen, der Witz geht auf die Ideologie, nicht auf Menschen, die aussteigen.
  - **Kein echter Programmname** (EXIT-Deutschland ist eine echte Initiative: kein Logo, keine Nummer).
  - Nur für die AfD-Fraktion. Für Union und Kapital gilt das Konzept bewusst nicht. Eine mögliche Tooltip-Pointe dazu: "Die Union braucht keinen Ausstieg." Das ist eine eigene Meinungsäußerung und erlaubt (§4), aber Wording vor Release prüfen.
- **Aufwand:** L: Gegner-gegen-Gegner-Kontakt, Ausnahme in der Gegner-Zielwahl, Kill-Zuordnung.

### S6 Brennnesseljauche

- **Flavor:** "Bio-Pflanzenschutz aus dem Kleingarten. Riecht wie die Debatte." Passt zur geplanten Arena Kleingartenanlage.
- **Mechanik:** geworfene Pfütze (Radius 70, 4 s, max 2). Gegner darin bekommen Gift-Tickschaden und werden langsam nach außen gedrückt (120 px/s), kein Slow.
  - **Elites:** nur Schaden.
  - **Reichsbürger:** Schaden und Druck (Druck ist Physik wie Knockback, kein Status), kein Gift-Status.
- **Nische:** Zonen-**Sperre** statt Zonen-**Falle**: ein Loch in der Brandmauer kurz zustopfen, eine:n Gefallene:n beim Revive abschirmen, eine Engstelle bauen. Kleber hält Gegner fest, Jauche hält sie draußen.
- **Zahlen:** 5 / 8 / 13 / 21 pro s, CD 3,0 s, Reichweite 280, Skalierung status 1,0, Preis 24.
- **Items:** Kompost ×2 wie Kleber.
- **Balancing-Risiko:** Zwei Pfützen vor dem einzigen Solo-Loch könnten frühe Wellen trivialisieren. Druck deshalb gegen `staging`-Gegner (hinter der Mauer) **nicht** wirken lassen, nur innen.
- **Content-Prüfung:** Eine naheliegende Pointe "Hilft gegen Braunfäule" (Pflanzenkrankheit, braun = Nazi-Farbe) ist eine **Krankheitsmetapher für Menschen**. Nicht §2-verboten (das gilt für Kapitalismus-Codes), aber entmenschlichend. Empfehlung: nicht verwenden, Flavor oben nutzen.

### B1 Pappkamerad

- **Flavor:** "Sie kämpfen gegen einen Pappkameraden. Wie immer." Ein Pappaufsteller der erfundenen "Verbotspartei" mit Schild "Schnitzelverbot!" (Satire-Zeile, kein Zitat). Rechte und konservative Gegner stürzen sich auf den Strohmann, den sie selbst gebaut haben. Satirischer Kontext für das Album: **soeder-04** (verifiziert, 10.06.2023, "Die Grünen haben die Philosophie, zu verbieten und umzuerziehen.").
- **Mechanik:**
  - Platziert einen Aufsteller mit HP (Vorschlag `25 + 15 × Welle + 5 × Ehrenamt`, ×2 mit Ehrenamtskarte). Nicht-Elites im Radius 240, die sonst eine:n Spieler:in jagen würden, laufen ihn an und machen ihm Kontaktschaden.
  - Fällt er um oder läuft er nach 8 s ab, gibt es einen Konfetti-Burst (r 90).
  - Fernkämpfer (Telegram-Onkel, Golfclub) zielen ebenfalls auf ihn.
- **Nische:** Köder/Tank. Das alte Baumhaus (W14 in `waffen_ideen.md`) hatte die Rolle, war aber knapp raus; der Pappkamerad hat den stärkeren Witz.
- **Zahlen:** Burst 12 / 20 / 32 / 52, CD 7,0 s, Platzierreichweite 220, Leben 8 s, max 1, Skalierung summon 1,0, Preis 26.
- **Aufwand:** L. Braucht in `_target_player(e)` eine Ziel-Position statt nur `SimPlayer`, Schaden an Beschwörungen (`SimSummon.hp` gibt es schon für die Windräder) und Rückmeldung im ViewState (HP-Balken).
- **Co-op und Netz:**
  - **Host-simuliert:** Er lenkt Gegner von allen Spieler:innen ab, das ist ein Team-Werkzeug.
  - **Gegner-Zielwahl** bleibt beim Host. Clients sehen nur, wohin Gegner laufen.
  - **Besitzer:in "away":** Der Aufsteller bleibt bis zum Ablauf stehen.
  - **Boss-Wiederholung:** wird wie alle Beschwörungen geräumt.
- **Content-Prüfung:**
  - Der Aufsteller darf **keine echte Person** zeigen (§3: echte Politiker:innen werden nicht körperlich angegriffen). Kein Habeck- oder Lang-Lookalike.
  - Er darf **keine reale Gruppe** zeigen: kein "Gender-Gaga"-Aufsteller (aiwanger-02), weil dann Gegner auf eine queere Figur einprügeln würden. Nur das abstrakte Verbots-Schild.

### B2 Kiezladen

- **Flavor:** "Kaffee 1 Euro, Fahrradwerkstatt dienstags, Widerstand täglich." Läuft er ab, erscheint die Status-Sprechblase "Gekündigt. Eigenbedarf." Ziel: Gewerbe-Verdrängung als Struktur.
- **Mechanik:** stationärer Laden (10 s, max 1). Alle 1,2 s läuft ein:e Nachbar:in los (wie Overall: rennt zum nächsten Ziel, ein Treffer, weg).
- **Nische:** Dauer-Schwarm von einem festen Punkt. Overall ist Burst vom Spieler, Infostand schießt.
- **Zahlen:** 5 / 8 / 13 / 21 pro Nachbar:in, CD 6,0 s, Reichweite 280, Skalierung summon 0,8, Preis 26.
- **Netz:** Bis ca. 3 Läufer:innen gleichzeitig pro Laden, mit 4 Spieler:innen ≤ 16 Einträge, im 64er-Budget.
- **Items:** Achtung, Gewerkschaftsmitglied zählt jede eigene Beschwörung in 220 px (`_allies_near`). Läufer:innen würden den +60 %-Deckel sofort füllen, deshalb Läufer:innen dort nicht mitzählen (siehe "Wechselwirkungen").
- **Content-Prüfung:**
  - **Bewusst kein konkreter Räumungsfall.** Die Räumung der Kiezkneipe "Syndikat" (Berlin-Neukölln, 07.08.2020) ist belegt. Die Berichterstattung stellt aber eine britische Eigentümerfamilie und ein verschleiertes Firmengeflecht in den Mittelpunkt. Das liegt zu nah an §2 ("schattenhafte Strippenzieher", Codes), deshalb nicht verwenden.
  - Kritik bleibt strukturell (Gewerbemiete, Eigenbedarf).

### B3 Mahnwache

- **Flavor:** "Je länger sie steht, desto heller wird's." Bezug: Lichtermeer gegen Rechts (R15 in `waffen_ideen.md`).
- **Mechanik:** Kerzenkreis an der Spieler-Position, 20 s, max 1. Puls jede Sekunde im Radius 110. Jeder Puls +10 % Schaden, bis +150 % (nach 15 s). Die Kerzen werden sichtbar größer, das zeigt den Aufbau ohne UI.
- **Nische:** Einziger Aufbau-Effekt bei Beschwörungen, belohnt Stellung halten. Passt zu Klimakleber (Stillstand +80 %) und Gewerkschaftsmitglied (Beschwörung in der Nähe +15 %).
- **Zahlen:** 3 / 5 / 8 / 13 pro Puls, CD 10 s, Skalierung summon 1,0, Preis 22.
- **Aufwand:** S: Turret-Variante ohne Projektil, Pulszähler in `SimSummon.cd`. Ersetzt den alten Fahnenmast (W10), dessen Heil-Rolle an B5 geht.
- **Content:** unbedenklich. Keine religiösen Symbole an den Kerzen.

### B4 Menschenkette

- **Flavor:** "Hand in Hand. Und wer durch will, fliegt zurück." Bezug: 03.02.2024, "Wir sind die Brandmauer", Menschenkette um den Bundestag mit über 150.000 Menschen. Der Spieltitel als Beschwörung, in Bewegung.
- **Mechanik:**
  - **Co-op:** Vier Aktivist:innen spannen eine Kette zwischen dir und der nächsten lebenden Mitspieler:in in ≤ 320 px.
  - **Solo, oder niemand nah genug:** Die Kette geht zu einem Laternenmast am Wurfpunkt.
  - Die Kette bewegt sich mit den Endpunkten. Wird sie länger als 320 px, reißt sie und bildet sich neu, sobald es wieder passt.
  - Gegner, die sie berühren, nehmen Schaden und werden zurückgestoßen (120, Elites nur Schaden). Rückstoß ist Physik, wirkt also auch beim Reichsbürger.
- **Nische:** Eine Linie, die **Spieler:innen gemeinsam führen**. Der Ziegel ist statisch und bremst.
- **Zahlen:** 4 / 7 / 11 / 18 pro 0,5 s, CD 5,0 s, Leben 6 s, max 1, Skalierung summon 1,0, Preis 26.
- **Netz:**
  - Die Kette ist kein eigenes Objekt mit Zustand. Der Host berechnet sie jeden Tick aus zwei Positionen und schickt sie wie den Ziegel als 5 Hazard-Segmente; die Clients rechnen nichts nach.
  - **Partner:in away oder down:** Die Kette springt zum Laternenmast.
  - **Rejoin:** nichts Besonderes, alles kommt aus dem Snapshot.
- **Content:** unbedenklich, starker positiver Bezug.

### B5 Demo-Sanis

- **Flavor:** "Pflaster, Wasser, Rettungsdecke. Und niemand bleibt liegen." Demosanitäter:innen sind ehrenamtliche Profis. Sie werden kompetent gezeichnet, nie als Retter:innen von außen (GDD §7: keine Heldenfigur, die rettet; sie sind Teil der eigenen Gruppe).
- **Mechanik:**
  - Ein:e Demosanitäter:in folgt dir (40 px dahinter) für die ganze Welle. Ein zweiter Kauf erhöht über die Stufe, nicht über die Anzahl.
  - Alle 3 s heilt sie die verletzteste lebende Person im Radius 160.
  - **Co-op:** Steht sie neben einer:m Gefallenen, wird der Revive 50 % schneller.
  - Kein Schaden.
- **Nische:** Heilung als Waffe, Support-Slot für Co-op. Kein Bestand deckt das ab, nur Items (Krankenschein) und die Oma-Ult.
- **Zahlen:** Heilung 2 / 3 / 5 / 8 (+ Ehrenamt × 0,3) pro 3 s, Skalierung summon 1,0, Preis 24.
- **Items:**
  - **Ehrenamtskarte** ×2 Heilung.
  - **Robin-Hood-Kostüm** (Krankenschein wirkt nicht) blockiert die Sani-Heilung **nicht**, weil sie kein Krankenschein ist. Bewusst so festlegen.
  - **Statistik:** neue Zeile "geheilt durch Demo-Sanis".
- **Bots:** Der Summon-Bot misst nur Schaden. Der Balancing-Report muss Heilung extra zählen, sonst sieht die Waffe schlecht aus.
- **Netz:**
  - **Follower-Bewegung** läuft auf dem Host.
  - **Besitzer:in "away":** Die Sani bleibt bei der verlassenen Figur stehen und heilt weiter andere.
  - **Clients** sehen sie wie jede Beschwörung im Snapshot.
- **Content:** Namensnähe zum Item "Demosani-Weste" ist gewollt; im Tooltip auseinanderhalten.

### B6 Lauti

- **Flavor:** "Vorne Ska, hinten die Ordner:innen." Der Lautsprecherwagen jeder Demo, im Spiel natürlich mit Ska (passt zur Musik-Richtung, GDD §20).
- **Mechanik:** kleiner Wagen auf einer Kreisbahn (Radius 140) um dich, 10 s, max 1. Alle 1,2 s ein Schallpuls im Radius 90: Schaden plus Knockback 80.
- **Nische:** die einzige Beschwörung, die **mitkommt**. Der Summon-Build kann damit kiten. Mietspiegel ist ein kleiner Nahkampf-Orbit.
- **Zahlen:** 5 / 8 / 13 / 21 pro Puls, CD 6,0 s, Skalierung summon 0,9, Preis 24.
- **Aufwand:** M: `_step_genosse`-Variante mit Kreisbahn um die Besitzer:in.
- **Netz:** Bahn auf dem Host. Besitzer:in away: Der Wagen kreist um die stehende Figur weiter, bis er abläuft.
- **Content:** unbedenklich. Name **"Lauti"** statt "Lautsprecherwagen", weil das Item "Lautsprecherwagen" (+2 Durchschlagskraft, +30 Reichweite) schon so heißt.

### B7 Kiezchor (Hybrid)

- **Flavor:** "Vierstimmig gegen rechts. Die Bässe kommen etwas spät."
- **Mechanik:** Chor für 8 s, Puls alle 2 s im Radius 150: kleiner Schaden plus "Rolle rückwärts" 0,8 s.
- **Nische:** Eine **Brückenwaffe**. Mit Skalierung 0,6 / 0,6 passt sie im Shop zu Status- **und** Summon-Builds (Match ≥ 0,5, balancing.md §5). Der Status-Build bekommt so ein frühes Sicherheitsnetz, ohne den Summon-Build stärker zu machen.
- **Zahlen:** 4 / 7 / 11 / 18, CD 6,0 s, max 1, Preis 22.
- **Aufwand:** S, sobald "Rolle rückwärts" (S3) existiert.
- **Content:** Lieder nur als Bild (Notenblätter), kein Liedtext, keine Musik ohne Lizenz.

## Wechselwirkungen mit Items und Charakteren

- **Ehrenamtskarte (Lücke im Bestand):** `_build_mult` gibt ×2 nur bei `kind == "turret"`. Alle anderen Waffen bekommen ×0,6, **auch Brandmauer-Ziegel und Weißer Overall**, obwohl sie mit Ehrenamt skalieren (`src/sim/sim.gd`, `_build_mult`). Die GDD-Formulierung ("Infostände und Genoss:innen") deckt das zwar, aber die neuen Summon-Kinds würden es verschärfen. Empfehlung:
  - **Regel umstellen:** Spec-Entscheidung "×2 für alle Waffen mit `summon` in `scale`", auch die Lebensdauer ×2 für alle Beschwörungen. Erst danach neue Summon-Waffen bauen.
  - **Testen:** Regressionstest, dass Ziegel und Overall ×2 bekommen.
- **Kompost:** Gift und Pfützen ×2 → Soli-Sticker (Gift) und Brennnesseljauche (Pfütze) ×2. Kontroll-Effekte ("In Bearbeitung", "Rolle rückwärts", "Umgestimmt") bleiben unverändert; der "Offengelegt"-Burst zählt als Statusschaden (kein ×0,7). Optional: Kompost +50 % Dauer auf Kontroll-Effekte, erst nach Messung.
- **Gewerkschaftsmitglied:** `_allies_near` zählt jede eigene Beschwörung in 220 px (+15 % je, max +60 %). Begleiter (Lauti, Demo-Sanis) geben damit dauerhaft +30 %, Kiezladen-Läufer:innen würden den Deckel sofort füllen. Empfehlung: pro Waffe nur eine Beschwörung zählen und kurzlebige Einmal-Läufer:innen (Overall, Kiezladen) nie.
- **Tarifrunde:** Alle neuen Beschwörungs-Schäden laufen über `_team_dmg()` wie Infostand und Overall. Heilung (Demo-Sanis) nicht.
- **Klimakleber:in:** Mahnwache, Jauche und Faktencheck passen zum Stillstand-Spiel. Startet mit Kleber und +3 Ungehorsam, die neuen Waffen geben dem Charakter endlich Abwehr.
- **Antifa-Aktivist:in / Antifa-Ortsgruppe:** Aussteiger-Flyer und Kleine Anfrage (JU-Schnösel stoppen) passen zum Brandmauer-Schutz.
- **Statusimmune Gegner (Reichsbürger):** Alle neuen Statuseffekte prallen ab. Jede Status-Waffe oben hat Treffer- oder Zonenschaden, Jauche, Menschenkette und Lauti schieben ihn physisch.
  - **Nebenbefund:** Die Betäubung von Trillerpfeife und Bierkiste (`_fire`, `"cone"`: `if def.has("stun") and not e.elite`) und die Ult-Betäubungen (Flashmob, "Fragen Sie mal uns") prüfen `immune` **nicht**. Der Reichsbürger lässt sich also betäuben, entgegen GDD §13 und D-079. Vermutlich ein Bug, braucht eine Regressionsprüfung, hier nicht angefasst.

## Abgelehnt oder zusammengelegt

- **Pfandsammler:in als Beschwörung** (sammelt Pfand für dich): Arme Menschen arbeiten für die Spieler:in, das ist Punch-down. Abgelehnt.
- **Gerichtsvollzieher-"Kuckuck"** (Pfändungssiegel gegen den Reichsbürger): Echte Pfändungen treffen meist arme Schuldner:innen, und staatlicher Zwang als Held passt nicht zum Ton. Abgelehnt.
- **Gold-Rettungsdecke** (lenkt Kapital-Gegner mit Gold ab): Gier-Gold-Bildsprache liegt zu nah an §2. Abgelehnt.
- **Glitzer, Seifenblasen, Konfetti-Kanone, Soli-Grill:** bereits abgelehnt (D-080, `waffen_ideen.md`).
- **Tauben-Schwarm:** Tiere mit Ungeziefer-Assoziation ("Ratten der Lüfte"). Abgelehnt.
- **Status "Umerzogen":** Name abgelehnt (Lager-Konnotation). Der Mechanik-Kern lebt als "Umgestimmt" in S5 weiter.
- **"Gender-Gaga"-Pappkamerad:** Gegner würden auf eine queere Figur einprügeln. Nur das Verbots-Schild bleibt.
- **Eingangsstempel** (360°-Puls mit "Aktenkundig"): zu nah an Lobbyregister plus Trillerpfeife. Gestrichen, Lean-Set-Regel (§5).
- **Alte Ideen aus `waffen_ideen.md`:** Fahnenmast (Heil-Aura) geht in Mahnwache (Puls) und Demo-Sanis (Heilung) auf, Baumhaus (Köder) im Pappkamerad, Rider (Linie hin und zurück) wird von Menschenkette und Lauti abgedeckt.

## Referenzen

- **R-S1 Kleine Anfrage:** Kleine Anfrage "Politische Neutralität staatlich geförderter Organisationen", CDU/CSU-Fraktion, Drucksache 20/15035, datiert 24.02.2025, 551 Fragen, davon Nr. 45–69 zu den Omas gegen Rechts. Im Spiel nur über **cdu-fraktion-01** (verifiziert, Quellen in `zitate_de.json`).
- **R-S2 Lobbyregister:** Lobbyregistergesetz vom Bundestag am 25.03.2021 beschlossen, in Kraft seit 01.01.2022, Pflicht-Eintragung nach Übergangsfrist ab 01.03.2022, später verschärft. Quellen: https://www.lto.de/recht/kanzleien-unternehmen/k/lobbyregister-gesetz-januar-lobbyrg-interessensvertretung-politik-bundestag-regierung-anmeldung, https://legal.pwc.de/de/news/fachbeitraege/lobbyregistergesetz-in-kraft-getreten
- **R-S5 Aussteigerprogramme:** EXIT-Deutschland, 2000 gegründet von Bernd Wagner und Ingo Hasselbach, erste Ausstiegsinitiative für Rechtsextreme in der Bundesrepublik. Quellen: https://journal-exit.de/wp-content/uploads/2023/03/Ausstieg-aus-dem-Extremismus_krause_wagner_exit_2023.pdf, https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_85964728/initiative-fuer-neonazi-aussteiger-droht-exit-deutschland-jetzt-das-aus-.html. Im Spiel kein Programmname.
- **R-B1 Pappkamerad:** satirischer Kontext soeder-04 (verifiziert, 10.06.2023, Erding). Sonst reine Spielidee.
- **R-B3 Mahnwache:** siehe R15 in `waffen_ideen.md` (Lichtermeer gegen Rechts, 25.01.2025).
- **R-B4 Menschenkette:** 03.02.2024, Bündnis "Hand in Hand", "#WirSindDieBrandmauer", Kundgebung vor dem Reichstag und symbolische Menschenkette um den Bundestag. Angemeldet 100.000, laut Berichten über 150.000. Quellen: https://www.berlin.de/en/news/8696673-5559700-menschenkette-um-reichstag-100000-demons.en.html, https://www.berliner-mieterverein.de/magazin/online/mm0324/3-februar-2024-wir-sind-die-brandmauer-032412b.htm, https://www.evangelisch.de/inhalte/226646/03-02-2024/zahlreiche-aktionen-deutschland-zehntausende-bei-demonstrationen-gegen-rechts

### Nachprüfen und nicht belegt

- **Faktencheck / "Rolle rückwärts":** Die Kehrtwende Schuldenbremse → Sondervermögen (Grundgesetzänderung im März 2025) wurde für dieses Dokument nicht neu per Websuche geprüft. Vor einem Tooltip-Bezug belegen. Der Flavor oben kommt ohne aus.
- **"Heizungs-Stasi"** (rechter Kampfbegriff zum Heizungsgesetz 2023): nicht belegt, darum nicht für den Pappkamerad verwendet.
- **Kiezladen:** Die Syndikat-Räumung (07.08.2020) ist belegt (z. B. https://www.tip-berlin.de/stadtleben/raeumung-syndikat-kiezkneipe-neukoelln-proteste-gentrifizierung-demos/), wird aber wegen §2 bewusst nicht referenziert (siehe B2).
- **Soli-Sticker, Brennnesseljauche, Demo-Sanis, Lauti, Kiezchor:** Alltagsgegenstände ohne Einzelereignis, kein Beleg nötig. Keine Tatsachenbehauptungen im Flavor.

## Shortlist

### Status (Top 4)

1. **Kleine Anfrage (S1):** Füllt die größte Lücke (keine Waffe stoppt Gegner-Fähigkeiten) und hängt direkt am Kernspiel: JU-Schnösel stimmen nicht ab, die Brandmauer hält. Stärkster Real-Bezug mit verifiziertem Zitat (cdu-fraktion-01), der Witz dreht das Instrument um. M.
2. **Faktencheck (S3):** Gibt dem schwächsten Build (1/12) endlich Abwehr: Abstand ohne Knockback-Chaos, löscht Kettenbriefe, treibt Gegner zurück in eigene Zonen. Gut lesbar ("↺"), billig. S–M.
3. **Soli-Sticker (S4):** Billigste Umsetzung (nutzt Gift und `EF_POISONED`, kein neues Netz-Flag), skaliert mit Gegnerdichte, also genau da, wo Status spät abfällt. Starke Kompost-Synergie. M.
4. **Lobbyregister (S2):** Boss-Schaden plus Team-Verstärker (+25 % für alle), guter Co-op-Reiz, klares Ziel (Lobbyismus als Struktur). M.

Knapp raus: **Aussteiger-Flyer** (stärkste Satire-Idee, aber L und Content-heikel im Detail; Kandidat für ein späteres Update) und **Brennnesseljauche** (gut, aber Zonen-Nische nah am Kleber, Risiko beim Loch-Zustopfen).

### Beschwörung (Top 4)

1. **Menschenkette (B4):** Spieltitel-Thema, belegtes Ereignis (03.02.2024), echte Co-op-Mechanik (Spieler:innen spannen die Linie gemeinsam), solo trotzdem spielbar. Eigene Nische gegenüber dem statischen Ziegel. M.
2. **Pappkamerad (B1):** Bester Witz (Strohmann-Kampf) und die fehlende Tank/Köder-Rolle. Nutzen statt DPS, passt zur Vorgabe "Summon nicht stärker machen". L wegen Gegner-Zielwahl.
3. **Demo-Sanis (B5):** Einzige Heilung als Waffe plus Revive-Hilfe; stark für Co-op, kein DPS-Zuwachs für den ohnehin starken Build. M. Braucht Heil-Messung im Balance-Report.
4. **Lauti (B6):** Die erste mobile Beschwörung macht den Summon-Build beim Kiten spielbar; Ska-Gag passt zur Musik. M.

Knapp raus: **Mahnwache** (S, gute Aufbau-Idee, aber reine DPS für den stärksten Build; erste Wahl, falls der Aufwand zählt), **Kiezladen** (DPS plus Gewerkschafts-Zähl-Problem) und **Kiezchor** (lohnt erst nach S3, dann als billige Brückenwaffe).

**Reihenfolge-Empfehlung:** erst Ehrenamtskarte-Regel und Reichsbürger-Stun klären (Spec + Test), dann S3 und S4 (billig, heben den Status-Build), dann S1 und B4, zuletzt B1 (L).
