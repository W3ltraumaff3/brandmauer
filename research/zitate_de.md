# Zitat-Recherche: Union, Merz & AfD

Recherche für Ladebildschirme, Boss-Intros, Sprechblasen und das Zitat-Album. Stand: 1. November 2026. Maschinenlesbare Fassung: `zitate_de.json` (gleiche IDs).

## Überblick

- **140 Einträge** in der JSON: 129 `verifiziert`, 4 `umstritten`, 2 `sinngemäß`, 5 `unverifiziert` (nicht verwenden). **135 sind verwendbar**, davon 80 mit `kurz: ja` (Sprechblasen-tauglich).
- **26** häufig falsch zitierte Sätze mit korrekter Fassung und **52** nicht verwendbare (unverifizierte) Zitate am Ende des Dokuments.
- Primärquellen wurden wo immer möglich genutzt: Bundestags-Plenarprotokolle 19/32, 19/155, 20/209, 21/3, 21/15, 21/17 (Text per `pdftotext` aus den amtlichen PDFs), Gerichtsentscheidungen (VG Köln 13 K 326/21, BGH 3 StR 484/24 und 519/24, LG Hamburg 324 O 103/20).

### Statusdefinitionen

- `verifiziert`: Wortlaut aus Primärquelle (Protokoll, Urteil, eigener Post) oder aus zwei unabhängigen reputablen Quellen. **Ausnahme, offen markiert:** Einträge mit dem Vermerk `EINZELQUELLE (…, hoch)` stammen aus *einer* Quelle mit hoher Reputation (dpa, epd, ZDF über die eigene Sendung) und geben ein direktes Zitat in Anführungszeichen wieder; ein Zweitbeleg ließ sich nicht finden. Siehe „Einzelquellen-Prüfung“.
- `umstritten`: Nur noch, wenn **Wortlaut oder Zuschreibung** tatsächlich strittig sind. Nach der Regel „Gesagt ist gesagt“ bleiben Zitate mit späterer Entschuldigung oder Relativierung `verifiziert`; die Entschuldigung steht in den Notizen.
- `unverifiziert`: Bei der Einzelquellen-Prüfung nicht bestätigt und Wortlaut oder Zuschreibung unsicher. **Nicht im Spiel verwenden.** Diese Einträge stehen nur in der JSON (zur Nachverfolgung) und im Abschnitt „Unverifiziert“ am Ende.
- `sinngemäß`: Nur Paraphrase oder Fragment gesichert. Im Spiel nicht als wörtliches Zitat in Anführungszeichen setzen.
- Übersetzte Zitate (Weidel/Musk auf Englisch, Krah/La Repubblica auf Italienisch) sind als dpa-Übersetzung gekennzeichnet. Im Spiel mit „(übersetzt)“ markieren.

### Einzelquellen-Prüfung (Nachtrag 11/2026)

Alle Einträge, die zuvor nur auf einer Quelle beruhten, wurden erneut geprüft. Regel: bestätigt durch eine zweite unabhängige reputable Quelle oder die Primärquelle → `verifiziert`, Flag entfernt. Nicht bestätigt, aber direktes Zitat aus einer Quelle mit hoher Reputation (dpa, epd, ZDF, Gerichtsurteil) → bleibt `verifiziert` mit Vermerk. Nicht bestätigt bei mittlerer oder niedriger Reputation oder unsicherem Wortlaut bzw. unsicherer Zuschreibung → `unverifiziert`, weggelassen. Reputation: hoch = Agentur (dpa/epd/AFP/APA), öffentlich-rechtlicher Rundfunk, Gerichtsurteil; mittel = Regional- oder Fachpresse, Einzelportale; niedrig = Parteimaterial, Blogs, Aggregatoren.

| id | Sprecher | Zitat (kurz) | Ursprungsquelle (Reputation) | Ergebnis |
|---|---|---|---|---|
| `merz-11` | Friedrich Merz | „Ich werde mich durch Worte wie Sozialabbau und Kahlschlag und was d…“ | zdfheute (ZDF) (hoch) | bestätigt durch AFP (web.de) |
| `merz-27` | Friedrich Merz | „Wir sind nicht im Krieg, aber wir sind auch nicht mehr im Frieden.“ | Berliner Zeitung (mittel) | bestätigt durch zdfheute (29.09.2025, Ständehaus-Treff Düsseldorf) |
| `merz-33` | Friedrich Merz | „Wir sind alle zutiefst schockiert. Wir haben es in dieser Form so n…“ | Apotheke Adhoc (Fachpresse) (mittel) | bestätigt durch dpa via euronews und news.at |
| `merz-35` | Friedrich Merz | „Wir schauen nicht jeden Tag auf die Umfragen, wir sind auf einem ri…“ | euronews (mittel) | WEGGELASSEN: kein zweiter Beleg; Stuttgarter Zeitung und ZDF berichten über die Rede ohne diesen Satz |
| `merz-36` | Friedrich Merz | „Wer meint, diesen Leuten seine Stimme geben zu müssen, der hat in d…“ | euronews; dpa-Paraphrase (mittel) | WEGGELASSEN: Wortlaut und Bezug unklar; die zuvor zitierte Stuttgarter Zeitung enthält den Satz nicht |
| `soeder-03` | Markus Söder | „Der Hauptkonkurrent um Platz eins sind die Grünen. Sie müssen wir s…“ | Abendzeitung München (dpa) (hoch) | nicht bestätigt; behalten als dpa-Einzelquelle (direktes Zitat). Datum nicht doppelt geprüft |
| `soeder-04` | Markus Söder | „Die Grünen haben die Philosophie, zu verbieten und umzuerziehen.“ | Schwäbische Zeitung (dpa) (hoch) | nicht bestätigt; dpa-Text selbst geprüft, behalten als dpa-Einzelquelle |
| `soeder-07` | Markus Söder | „Wir haben in Bayern auf unseren Brezeln mehr Salz als in Berlin auf…“ | Berliner Zeitung (mittel) | WEGGELASSEN: kein Zweitbeleg; Nordkurier-Bericht zur selben Rede enthält den Satz nicht |
| `soeder-08` | Markus Söder | „Wir lassen uns nicht vorschreiben, was wir reden, was wir denken. I…“ | Der Standard (nur Bildunterschrift) (mittel) | WEGGELASSEN: nur in einer Bildunterschrift; Nordkurier zur selben Rede ohne den Satz, Zuordnung zu Söder (vs. Generalsekretär Huber) nicht gesichert |
| `linnemann-03` | Carsten Linnemann | „Die Statistik legt nahe, dass eine sechsstellige Zahl von Personen …“ | epd (Fragment) (hoch) | bestätigt durch AFP (Stuttgarter Zeitung); Zitat auf den vollständigen Satz erweitert |
| `linnemann-05` | Carsten Linnemann | „Ich finde, zehn Krankenkassen in Deutschland reichen“ | Apotheken Umschau (mittel) | bestätigt durch zdfheute und Ärzteblatt (ntv 'Frühstart', 14.04.2026) |
| `spahn-04` | Jens Spahn | „In der Not ist Haben wichtiger als Brauchen. Das war eine Jahrhunde…“ | Ärzteblatt (hoch) | bestätigt durch Pharmazeutische Zeitung (und DocCheck) |
| `dobrindt-03` | Alexander Dobrindt | „Deswegen bleibe ich dabei: Wir müssen verhindern, dass eine Klima-R…“ | Berliner Zeitung (mittel) | WEGGELASSEN: Satz nicht bestätigt (dpa/Berliner Zeitung 2022 nur indirekt); Begriff 'Klima-RAF' selbst ist belegt |
| `dobrindt-04` | Alexander Dobrindt | „Wir halten […] an den Zurückweisungen fest.“ | epd (hoch) | bestätigt durch zdfheute – dort mit Auslassung, deshalb Zitat mit '[…]' |
| `kloeckner-02` | Julia Klöckner | „Ich meine: Klar kann sich Kirche auch zu Tempo 130 äußern, aber daf…“ | epd (hoch) | nicht unabhängig bestätigt (nur englische Wiedergabe bei Brussels Signal); behalten als epd-Einzelquelle |
| `amthor-01` | Philipp Amthor | „Ich bin nicht käuflich“ | web.de (dpa) (hoch) | nicht unabhängig bestätigt (t-online/turi2 nur Paraphrase); behalten als dpa-Einzelquelle |
| `amthor-03` | Philipp Amthor | „Das war mein größter politischer Fehler.“ | zdfheute (ZDF) (hoch) | nicht unabhängig bestätigt; behalten (ZDF berichtet über eigene Sendung, hoch) |
| `amthor-04` | Philipp Amthor | „Ich bringe das mal ein bisschen überspitzt auf die Formel 'Lieber 1…“ | zdfheute (ZDF) (hoch) | nicht unabhängig bestätigt; behalten (ZDF berichtet über eigene Sendung, hoch) |
| `aiwanger-02` | Hubert Aiwanger | „Ich hab die Nase voll, wenn man in der Früh aufsteht, die Zeitung a…“ | Schwäbische Zeitung (dpa) (hoch) | nicht bestätigt; dpa-Text selbst geprüft, behalten als dpa-Einzelquelle |
| `aiwanger-03` | Hubert Aiwanger | „Morgen ruft die AfD dazu auf, in Lederhose aufs Oktoberfest zu gehe…“ | inFranken (dpa) (hoch) | erste Satzhälfte bestätigt durch Nordkurier (dpa); behalten |
| `reiche-02` | Katherina Reiche | „Wir müssen mehr und länger arbeiten“ | Nordkurier (dpa) (hoch) | bestätigt durch zdfheute (26.07.2025) |
| `petry-01` | Frauke Petry | „[…] notfalls auch von der Schusswaffe Gebrauch machen. So steht es …“ | SPD-Zitatesammlung (Interview-Abschrift) (niedrig) | Kern bestätigt durch APA/dpa und epd; Zitat auf den bestätigten Teil gekürzt |
| `hoecke-07` | Björn Höcke | „Wenn alle Stricke reißen, ziehen wir uns wie einst die tapfer-fröhl…“ | Urteil VG Köln 13 K 326/21 (hoch) | behalten: Gerichtsurteil zitiert wörtlich aus der BfV-Belegsammlung (primärnah) |
| `hoecke-08` | Björn Höcke | „Unsere Jugend haben die böswilligen Gutmenschen in den Kindergärten…“ | Urteil VG Köln 13 K 326/21 (hoch) | behalten: Gerichtsurteil (primärnah) |
| `krah-04` | Maximilian Krah | „Deutsche Sprache nicht mehr erforderlich, um deutsche Staatsbürger …“ | Urteil VG Köln 13 K 326/21 (hoch) | behalten: Gerichtsurteil (primärnah) |

Zusätzlich neu aufgenommen: `merz-39` („Denn wir sind die Kraft, die Deutschland stabil auf Kurs hält.“, CSU-Parteitag 24.10.2026, bestätigt durch Stuttgarter Zeitung und euronews) als Ersatz für das weggelassene `merz-35`.

**Status-Umstellung nach „Gesagt ist gesagt“:** `merz-06`, `merz-23`, `merz-25`, `linnemann-03`, `aiwanger-04`, `weidel-05`, `hoecke-01`, `gauland-01`, `gauland-05`, `storch-02`, `petry-01` → `verifiziert`. Weiter `umstritten` (Wortlaut oder Zuschreibung strittig): `kloeckner-03`, `gauland-03`, `poggenburg-01`, `helferich-01`.

### Anzahl pro Person

| Person | Partei | verwendbar | davon verifiziert | kurz | unverifiziert (weggelassen) |
|---|---|---|---|---|---|
| Friedrich Merz | CDU | 39 | 37 | 22 | 2 |
| Markus Söder | CSU | 6 | 6 | 6 | 2 |
| Carsten Linnemann | CDU | 5 | 5 | 1 | 0 |
| Jens Spahn | CDU | 5 | 5 | 3 | 0 |
| Alexander Dobrindt | CSU | 3 | 3 | 2 | 1 |
| Julia Klöckner | CDU | 3 | 2 | 2 | 0 |
| Philipp Amthor | CDU | 4 | 4 | 4 | 0 |
| Hubert Aiwanger | Freie Wähler | 6 | 6 | 1 | 0 |
| Katherina Reiche | CDU | 2 | 2 | 1 | 0 |
| Andreas Scheuer | CSU | 1 | 1 | 0 | 0 |
| Alice Weidel | AfD | 10 | 10 | 7 | 0 |
| Björn Höcke | AfD | 11 | 11 | 5 | 0 |
| Alexander Gauland | AfD | 7 | 6 | 5 | 0 |
| Tino Chrupalla | AfD | 4 | 4 | 4 | 0 |
| Beatrix von Storch | AfD | 4 | 4 | 2 | 0 |
| Maximilian Krah | AfD | 4 | 4 | 2 | 0 |
| Stephan Brandner | AfD | 2 | 2 | 2 | 0 |
| André Poggenburg | AfD | 1 | 0 | 0 | 0 |
| Frauke Petry | AfD | 2 | 2 | 1 | 0 |
| Jens Maier | AfD | 2 | 2 | 1 | 0 |
| Gottfried Curio | AfD | 1 | 1 | 0 | 0 |
| Matthias Helferich | AfD | 1 | 0 | 1 | 0 |
| Ulrich Thomas (gemeinsam mit Lars-Jörn Zimmer) | CDU | 1 | 1 | 1 | 0 |
| Hans-Georg Maaßen | CDU | 1 | 1 | 1 | 0 |
| Saskia Ludwig | CDU | 1 | 1 | 0 | 0 |
| Alexander Räuscher | früher CDU | 2 | 2 | 1 | 0 |
| Clara von Nathusius | CDU | 1 | 1 | 1 | 0 |
| Horst Seehofer | CSU | 2 | 2 | 2 | 0 |
| Ulrich Siegmund | AfD | 2 | 2 | 1 | 0 |
| Marc Vallendar | AfD | 1 | 1 | 1 | 0 |
| CDU/CSU-Bundestagsfraktion (unterzeichnet von Friedrich Merz und Alexander Dobrindt) | CDU/CSU | 1 | 1 | 0 | 0 |

### Die 15 besten Highlights fürs Spiel

| # | Sprecher | Zitat | Datum | Warum |
|---|---|---|---|---|
| 1 | Friedrich Merz | „Eine richtige Entscheidung wird nicht dadurch falsch, dass die Falschen zustimmen. Sie bleibt richtig.“ | 2025-01-29 | Primärquelle Plenarprotokoll; perfekt für den AfD-Abstimmungs-Boss (`merz-12`) |
| 2 | Friedrich Merz | „Der Bundestag ist ja nun kein Zirkuszelt.“ | 2025-07-01 | kurz, absurd, sofort verständlich (`merz-17`) |
| 3 | Friedrich Merz | „Fragen Sie mal Ihre Töchter“ | 2025-10-20 | Kernformel überall identisch belegt (`merz-02`) |
| 4 | Friedrich Merz | „Ich will es einfach an die Adresse dieser Fraktion hier rechts sagen und an Ihre, Herr Gauland: Das war Ihr Fliegenschiss, von dem Sie vor Jahr und Tag gesprochen haben.“ | 2025-01-29 | Merz zitiert Gauland falsch, AfD korrigiert ihn – Dialog-Szene mit brandner-01 (`merz-14`) |
| 5 | Friedrich Merz | „Mit Vier-Tage-Woche und Work-Life-Balance werden wir den Wohlstand dieses Landes nicht erhalten können“ | 2025-05-13 | Arbeitsmoral-Gegner, Bürgergeld-Level (`merz-09`) |
| 6 | Friedrich Merz | „Also, ich würde mich zu der gehobenen Mittelschicht zählen.“ | 2018-11-14 | Millionär als 'gehobene Mittelschicht' – BlackRock-Boss-Intro (`merz-21`) |
| 7 | Friedrich Merz | „Aber halbieren kann man sie“ | 2018-11-14 | 2018 angekündigt, 2026 AfD in Sachsen-Anhalt über 40 % – Ladebildschirm mit Faktenzeile (`merz-24`) |
| 8 | Friedrich Merz | „Das ist die Drecksarbeit, die Israel macht für uns alle.“ | 2025-06-17 | kurz, aber Kontext (Moderatorin brachte das Wort ein) im Album nennen (`merz-16`) |
| 9 | Friedrich Merz | „Aufgeben ist für mich keine Option.“ | 2026-09-07 | Game-Over-/Respawn-Spruch (`merz-34`) |
| 10 | Friedrich Merz | „Ich suche in diesem Deutschen Bundestag keine anderen Mehrheiten als die in der demokratischen Mitte unseres Parlaments. […] Und wenn es hier heute eine solche Mehrheit gegeben hat, dann bedaure ich das.“ | 2025-01-29 | 'Bedauern' wenige Stunden nach merz-12 – Kombi im Album (`merz-13`) |
| 11 | Alice Weidel | „Nieder mit diesen Windmühlen der Schande!“ | 2025-01-11 | Windkraft-Boss; Wortlaut sicher, spätere Einschränkung im Album nennen (`weidel-05`) |
| 12 | Alice Weidel | „Und ich muss Ihnen ganz ehrlich sagen, wenn es dann Remigration heißen soll, dann heißt es eben Remigration.“ | 2025-01-11 | Parteitag Riesa, wörtlich belegt (`weidel-04`) |
| 13 | Alexander Gauland | „Wir werden sie jagen! […] und wir werden uns unser Land und unser Volk zurückholen!“ | 2017-09-24 | kurze Fassung 'Wir werden sie jagen.' verwenden (`gauland-04`) |
| 14 | Tino Chrupalla | „Mir hat er nichts getan. Ich sehe keine Gefahr für Deutschland aktuell durch Russland.“ | 2025-11-11 | Putin-Verharmlosung, wörtlich belegt (`chrupalla-01`) |
| 15 | Jens Spahn | „[…] dass wir nämlich miteinander in ein paar Monaten wahrscheinlich viel werden verzeihen müssen“ | 2020-04-22 | Plenarprotokoll statt geglätteter Buchtitel-Fassung (`spahn-02`) |

### Rechtliche Leitplanken (Kurzfassung)

- Zitate nur im dokumentierten Wortlaut verwenden. Kürzungen mit „[…]“ kennzeichnen und nicht sinnentstellend schneiden. Wo die Notizen eine „Kurzform fürs Spiel“ nennen, ist diese geprüft.
- **Höcke/„Faschist“:** Höcke im Spiel als Faschisten zu bezeichnen ist als eigene Meinungsäußerung zulässig. Nur nicht schreiben „ein Gericht hat Höcke als Faschisten eingestuft“. Das LG Hamburg hat diese Behauptung 2020 per einstweiliger Verfügung untersagt. Zulässig ist z. B.: „Das VG Meiningen entschied 2019, dass Demonstranten Höcke in diesem Kontext ‚Faschist‘ nennen durften.“ Siehe `hoecke-10`.
- **Höcke/SA-Losung:** Zwei Verurteilungen (LG Halle, 14.05. und 01.07.2024), seit den BGH-Beschlüssen vom 20.08.2025 rechtskräftig. Die Parole selbst ist nach § 86a StGB strafbewehrt. Im Spiel nur dokumentarisch (Album/Infotext) zeigen, nicht als Sprechblasen-Ruf einer Figur.
- **Aiwanger/Flugblatt:** Nicht als Verfasser darstellen; sein Bruder Helmut hat die Autorschaft erklärt.
- **Privatpersonen** (z. B. die Kinderärztin im RTL-Gespräch mit Merz, `merz-32`) weder namentlich noch bildlich darstellen. Spahns Rücktrittsanlass (Juli 2026) ist privat und sollte nicht thematisiert werden.
- **Entschuldigungen und Relativierungen** (Sozialtourismus, Vogelschiss, Boateng, Windmühlen, Stadtbild-Selbstkritik) gehören ins Album neben das Zitat.
- Satire über reale Politiker ist durch Kunst- und Meinungsfreiheit weit geschützt. Das gilt aber nicht für erfundene Zitate in Anführungszeichen. Wer satirische Fantasie-Sätze schreibt, sollte sie optisch klar von den echten Zitaten trennen (z. B. eigene Schriftart, kein Quellenverweis).

## Friedrich Merz (CDU)

*Aktuell (11/2026): Bundeskanzler seit 6. Mai 2025, CDU-Bundesvorsitzender.*

### Migration

#### `merz-38` – „(nur Begriff gesichert) – 'freiheitliche deutsche Leitkultur'“

- **Sprecher:** Friedrich Merz (CDU), damals: Vorsitzender der CDU/CSU-Bundestagsfraktion
- **Datum:** 2000-10
- **Kontext:** Interview mit der Rheinischen Post (Oktober 2000) und Welt-Gastbeitrag 'Einwanderung und Identität' (25.10.2000): Zuwanderer sollten sich einer 'gewachsenen freiheitlichen deutschen Leitkultur' anpassen; löste die Leitkultur-Debatte aus.
- **Status:** `sinngemäß` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.wsws.org/de/articles/2000/11/leit-n21.html> · <https://en.wikipedia.org/wiki/Leitkultur>
- **Notizen:** Begriff stammt ursprünglich vom Politologen Bassam Tibi (1998). Merz' vollständiger Originalsatz wurde nicht verifiziert – nur den Begriff in Anführungszeichen verwenden. Quellenlage dünn (WSWS ist parteiisch; Originalinterview nicht online gefunden). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-06` – „Wir erleben mittlerweile einen Sozialtourismus dieser Flüchtlinge: nach Deutschland, zurück in die Ukraine, nach Deutschland, zurück in die Ukraine.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender und Vorsitzender der CDU/CSU-Bundestagsfraktion (Oppositionsführer)
- **Datum:** 2022-09-26
- **Kontext:** Interview bei Bild TV über Geflüchtete aus der Ukraine, die zwischen Deutschland und der Ukraine pendelten.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://www.schwaebische.de/politik/merz-bedauert-sozialtourismus-vorwurf-gegen-ukrainer-13293> · <https://web.de/magazine/politik/angeblicher-sozialtourismus-ukraine-fluechtlingen-merz-bedauert-wortwahl-37330500> · <https://www.t-online.de/nachrichten/ukraine/id_100058708/-sozialtourismus-russisches-medium-greift-merz-aussagen-auf.html>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; Entschuldigung vom 27.09.2022 siehe Notizen/merz-07. Die Wiederholung 'nach Deutschland, zurück in die Ukraine' laut Schwäbischer (dpa); sicherste Kurzform: 'Wir erleben mittlerweile einen Sozialtourismus dieser Flüchtlinge' (wortgleich bei web.de/dpa). ENTSCHULDIGT (siehe merz-07): Am 27.09.2022 schrieb Merz auf Twitter: 'Ich bedaure die Verwendung des Wortes „Sozialtourismus“.' Weder Bundesarbeitsministerium noch Bundesagentur für Arbeit hatten Belege für das beschriebene Phänomen; russische Staatsmedien griffen die Aussage auf (t-online). Im Spiel nur mit Hinweis auf die Entschuldigung verwenden. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-07` – „Wenn meine Wortwahl als verletzend empfunden wird, dann bitte ich dafür in aller Form um Entschuldigung.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender und Vorsitzender der CDU/CSU-Bundestagsfraktion (Oppositionsführer)
- **Datum:** 2022-09-27
- **Kontext:** Tweet am Tag nach dem Bild-TV-Interview (merz-06), nach scharfer Kritik u. a. von Innenministerin Faeser.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sonstiges/Absurd · **kurz:** nein
- **Quellen:** <https://www.schwaebische.de/politik/merz-bedauert-sozialtourismus-vorwurf-gegen-ukrainer-13293> · <https://web.de/magazine/politik/angeblicher-sozialtourismus-ukraine-fluechtlingen-merz-bedauert-wortwahl-37330500>
- **Notizen:** Im selben Thread: 'Ich bedaure die Verwendung des Wortes „Sozialtourismus“.' Kommentatoren kritisierten die Wenn-dann-Form als 'Nonpology'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-05` – „Und dann wollen sie diese Kinder zur Ordnung rufen und die Folge ist, dass die Väter in den Schulen erscheinen und sich das verbitten. Insbesondere, wenn es sich um Lehrerinnen handelt, dass sie ihre Söhne, die kleinen Paschas, da mal etwas zurechtweisen.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender und Vorsitzender der CDU/CSU-Bundestagsfraktion (Oppositionsführer)
- **Datum:** 2023-01-10
- **Kontext:** ZDF-Talkshow 'Markus Lanz' nach den Berliner Silvesterkrawallen 2022/23, über Probleme an Schulen mit Kindern aus Migrantenfamilien.
- **Status:** `verifiziert` · **Kategorien:** Migration, Gender/Familie · **kurz:** nein
- **Quellen:** <https://www.berliner-zeitung.de/article/merz-verteidigt-umstrittene-kleine-paschas-aeusserung-306694> · <https://www.news4teachers.de/2023/01/merz-nennt-migrantenkinder-paschas-und-loest-damit-eine-hitzige-debatte-aus/>
- **Notizen:** Kurzform fürs Spiel: '…ihre Söhne, die kleinen Paschas…'. Keine Entschuldigung; im ZDF-Morgenmagazin verteidigte er sich: 'Wir haben in Schulen erhebliche Probleme.' Datum: Sendung am Dienstag, 10.01.2023 (aus Berichtsdaten erschlossen). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-08` – „Die werden doch wahnsinnig, die Leute, wenn die sehen, dass 300.000 Asylbewerber abgelehnt sind, nicht ausreisen, die vollen Leistungen bekommen, die volle Heilfürsorge bekommen. Die sitzen beim Arzt und lassen sich die Zähne neu machen, und die deutschen Bürger nebendran kriegen keine Termine.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender und Vorsitzender der CDU/CSU-Bundestagsfraktion (Oppositionsführer)
- **Datum:** 2023-09-27
- **Kontext:** Talkshow des Senders Welt (Mittwochabend) zur Migrationspolitik.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://www.zm-online.de/artikel/2023/zm-2023-20/pauschalaussagen-bei-komplexen-lagen-sind-problematisch> · <https://taz.de/Asyl-Aussage-von-CDU-Chef/!5963129/> · <https://correctiv.org/faktencheck/2023/10/05/nein-zahnarztbesuche-von-gefluechteten-kosteten-2022-keine-690-millionen-euro/>
- **Notizen:** Kurzform: 'Die sitzen beim Arzt und lassen sich die Zähne neu machen.' Faktenlage: Abgelehnte Asylbewerber haben in den ersten 18 Monaten nur eingeschränkten Leistungsanspruch; die Zahl 300.000 bezieht sich auf alle Ausreisepflichtigen, die meisten davon geduldet. Bundeszahnärztekammer: 'keinen Zusammenhang' mit Terminknappheit. Merz sah 'keinen Grund' für eine Entschuldigung. Die taz datiert die Sendung auf Donnerstag, 28.09.; die Mehrzahl der Berichte nennt Mittwoch, 27.09.2023. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-01` – „[…] aber wir haben natürlich immer im Stadtbild noch dieses Problem“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-10-14
- **Kontext:** Pressekonferenz beim Antrittsbesuch in Brandenburg (Potsdam), auf die Frage eines Journalisten nach den hohen AfD-Umfragewerten und Merz' früherem Ziel, die AfD zu halbieren.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.stuttgarter-zeitung.de/politik/friedrich-merz-stadtbild-aussage-wortlaut-mhsd-79036257.html> · <https://www.berliner-zeitung.de/news/ich-habe-gar-nichts-zurueckzunehmen-bundeskanzler-merz-verteidigt-stadtbild-aussage-li.10001647> · <https://www.zdfheute.de/politik/deutschland/merz-stadtbild-selbstkritik-100.html>
- **Notizen:** Vollständige Passage (Stuttgarter Zeitung, Wortlaut nach Video): 'Bei der Migration sind wir sehr weit. Wir haben in dieser Bundesregierung die Zahlen August 24, August 25 im Vergleich um 60 % nach unten gebracht, aber wir haben natürlich immer im Stadtbild noch dieses Problem, und deswegen ist der Bundesinnenminister ja auch dabei, jetzt in sehr großem Umfang Rückführungen zu ermöglichen und durchzuführen. Das muss beibehalten werden, das ist in der Koalition verabredet.' Für Sprechblasen: '…im Stadtbild noch dieses Problem…' (mit Auslassungszeichen). Folge: bundesweite Proteste, Petition 'Wir sind die Töchter'. Merz legte die Aussage später auf ausreisepflichtige Migranten ohne Arbeit aus und nannte Migranten laut zdfheute-Überschrift einen 'unverzichtbaren Bestandteil' (https://www.zdfheute.de/politik/deutschland/merz-stadtbild-migration-konkretisiert-100.html). Siehe merz-02 bis merz-04. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender. VERIFIKATION 11/2026: Auf das gesicherte Fragment gekürzt. Der Rest des Satzes ist in den Quellen uneinheitlich (Stuttgarter Zeitung nach Video: 'in sehr großem Umfang Rückführungen', zdfheute und andere: 'in sehr großem Umfang auch Rückführungen'); ohne Video nicht entscheidbar.

#### `merz-02` – „Fragen Sie mal Ihre Töchter“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-10-20
- **Kontext:** Pressekonferenz in Berlin nach der CDU-Präsidiumsklausur, auf die Nachfrage, was er mit dem 'Problem im Stadtbild' gemeint habe.
- **Status:** `verifiziert` · **Kategorien:** Migration, Gender/Familie · **kurz:** ja
- **Quellen:** <https://taz.de/Stadtbild-Debatte/!6119202/> · <https://www.stuttgarter-zeitung.de/politik/friedrich-merz-aussage-toechter-mhsd-79225479.html> · <https://www.nordkurier.de/politik/merz-zu-stadtbild-aeusserung-ich-habe-gar-nichts-zurueckzunehmen-4025387>
- **Notizen:** Der Folgesatz ist in leicht abweichenden Fassungen überliefert: 'Ich vermute, Sie kriegen eine ziemlich klare und deutliche Antwort' (dpa/Nordkurier) bzw. '…was ich damit gemeint haben könnte. Vermutlich bekommen Sie eine ziemlich klare und deutliche Antwort' (Stuttgarter Zeitung). Nur die Kernformel 'Fragen Sie mal Ihre Töchter' ist überall identisch – im Spiel nur diese verwenden. Reaktion: Petition 'Wir sind die Töchter' (>100.000 Unterschriften binnen eines Tages, zdfheute). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-03` – „Ich habe gar nichts zurückzunehmen.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-10-20
- **Kontext:** Dieselbe Pressekonferenz; Merz verteidigte die Stadtbild-Aussage ausdrücklich.
- **Status:** `verifiziert` · **Kategorien:** Migration, Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.nordkurier.de/politik/merz-zu-stadtbild-aeusserung-ich-habe-gar-nichts-zurueckzunehmen-4025387> · <https://www.stuttgarter-zeitung.de/politik/friedrich-merz-stadtbild-aussage-wortlaut-mhsd-79036257.html> · <https://www.berliner-zeitung.de/news/ich-habe-gar-nichts-zurueckzunehmen-bundeskanzler-merz-verteidigt-stadtbild-aussage-li.10001647>
- **Notizen:** Fortsetzung: 'Im Gegenteil: Ich unterstreiche es nochmal' (dpa) bzw. '…ich unterstreiche es noch einmal' (Stuttgarter Zeitung). Siehe Selbstkritik merz-04. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-04` – „Ich hätte vielleicht früher sagen sollen, was ich konkret damit meine. […] Das würde ich heute anders machen.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-12-08
- **Kontext:** ARD-Bürgersendung 'Arena' in Niederkassel (NRW), Frage zur Stadtbild-Aussage.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/merz-stadtbild-selbstkritik-100.html> · <https://www.tagesspiegel.de/politik/das-wurde-ich-heute-anders-machen-merz-zeigt-sich-in-stadtbild-debatte-selbstkritisch-15032265.html>
- **Notizen:** Teil-Walk-back zu merz-01/merz-03: Er bedauerte das späte Konkretisieren, nicht die Aussage selbst. Ob beide Sätze unmittelbar aufeinander folgten, ist nicht gesichert – daher '[…]'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

### Sozialstaat/Arbeit

#### `merz-09` – „Mit Vier-Tage-Woche und Work-Life-Balance werden wir den Wohlstand dieses Landes nicht erhalten können“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-05-13
- **Kontext:** Rede beim Wirtschaftstag des CDU-Wirtschaftsrats in Berlin, eine Woche nach seiner Wahl zum Kanzler; Forderung, 'wieder mehr und vor allem effizienter' zu arbeiten.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit, Wirtschaft/Kapital · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/2324747> · <https://www.heidelberg24.de/politik-und-wirtschaft/merz-sagt-der-work-life-balance-den-kampf-an-spd-stellt-sich-dagegen-zr-94151697.html> · <https://eufactcheck.eu/factcheck/mostly-false-we-need-to-work-more-and-more-efficiently-again/>
- **Notizen:** Variante: '…den Wohlstand unseres Landes…' (Ippen-Medien) – dpa/Berliner Zeitung: 'dieses Landes'. EUfactcheck bewertete die damit verbundene Behauptung, in Deutschland werde zu wenig gearbeitet, als 'mostly false'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-10` – „Der Sozialstaat, wie wir ihn heute haben, ist mit dem, was wir volkswirtschaftlich leisten, nicht mehr finanzierbar.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-08-23
- **Kontext:** Rede auf dem Landesparteitag der CDU Niedersachsen in Osnabrück; Auftakt zum angekündigten 'Herbst der Reformen' (Bürgergeld-Umbau).
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/merz-cdu-spd-debatte-sozialstaat-100.html> · <https://www.schwaebische.de/politik/sozialstaat-nicht-mehr-finanzierbar-koalition-ringt-um-reformen-3865567> · <https://www.zdfheute.de/politik/sozialstaat-debatte-unbezahlbar-merz-kritik-100.html>
- **Notizen:** ZDF-Faktencheck: Der Anteil der Sozialausgaben am Bundeshaushalt ist relativ gesehen zurückgegangen. FALSCHZITAT-WARNUNG: 'Wir können uns den Sozialstaat nicht mehr leisten' ist eine Überschrift (u. a. WSWS), nicht sein Wortlaut. SPD-Generalsekretär Klüssendorf nannte den Satz ein 'Pflichtelement einer CDU-Parteitagsrede'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-11` – „Ich werde mich durch Worte wie Sozialabbau und Kahlschlag und was da alles kommt, nicht irritieren lassen.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-08-23
- **Kontext:** Selbe Rede in Osnabrück, als Vorwegnahme der Kritik an der Bürgergeld-Reform.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/merz-cdu-spd-debatte-sozialstaat-100.html> · <https://web.de/magazine/politik/inland/merz-kuendigt-harte-debatte-spd-sozialstaatsreformen-41307416>
- **Notizen:** Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-30` – „Das sind fast drei Wochen, in denen die Menschen in Deutschland aus Krankheitsgründen nicht arbeiten. […] Ist das wirklich richtig? Ist das wirklich notwendig?“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2026-01-17
- **Kontext:** Wahlkampfveranstaltung zur Landtagswahl Baden-Württemberg in Bad Rappenau; Kritik am Krankenstand und an der telefonischen Krankschreibung ('Heute immer noch?').
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** ja
- **Quellen:** <https://www.lto.de/recht/nachrichten/n/zu-viele-krankheitstage-telefonische-au-arbeitszeitgesetz-merz-kritik> · <https://www.zdfheute.de/politik/deutschland/krankmeldung-krankenstand-merz-kritik-100.html> · <https://www.pharmazeutische-zeitung.de/merz-kritisiert-fehltage-wegen-krankheit-161982/>
- **Notizen:** Kurzform fürs Spiel: 'Ist das wirklich richtig? Ist das wirklich notwendig?' Die Zahl '14,5 Krankheitstage' stammt aus Statistiken/Medien, nicht aus seinem Wortlaut. Ob zwischen beiden Teilen weiterer Text lag, ist nicht gesichert – daher '[…]'. KBV gab ihm recht, SPD/Grüne/Linke kritisierten. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-40` – „Lifestyle und Vier-Tage-Woche. Alles schön, kann man alles machen“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler und CDU-Bundesvorsitzender
- **Datum:** 2026-02-18
- **Kontext:** Rede beim Politischen Aschermittwoch der CDU in Trier, kurz vor dem CDU-Parteitag, mitten im Streit um den Antrag des CDU-Wirtschaftsflügels 'Kein Rechtsanspruch auf Lifestyle-Teilzeit'. Merz forderte einen Mentalitätswechsel und mehr Leistungsbereitschaft; weiter im Text: 'Aber wenn wir unseren Wohlstand erhalten wollen, dann müssen wir jetzt alle mal zusammen ins Rad packen.'
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/merz-mentalitaetswechsel-politischer-aschermittwoch-100.html> · <https://www.handelsblatt.com/politik/deutschland/vor-cdu-parteitag-zusammen-ins-rad-packen-merz-fordert-mentalitaetswechsel/100201501.html> · <https://www.tagesspiegel.de/politik/mussen-zusammen-ins-rad-packen-merz-fordert-mentalitatswechsel-zu-mehr-leistungsbereitschaft-15267745.html> · <https://www.lessentiel.lu/de/story/deutschland-merz-teilt-gegen-lifestyle-teilzeit-aus-103509284>
- **Notizen:** Wortlaut in vier Medien identisch (zdfheute/dpa, Handelsblatt, Tagesspiegel, L'essentiel/dpa). WICHTIG: Merz sagt hier NICHT das Wort 'Teilzeit'; der Bezug zur 'Lifestyle-Teilzeit'-Debatte (Antrag des Wirtschaftsflügels, Januar/Februar 2026) stammt aus der Berichterstattung (L'essentiel-Titel 'Merz teilt in Trier gegen Lifestyle-Teilzeit aus'). Ein wörtliches Merz-Zitat mit 'Teilzeit' wurde in keiner Quelle gefunden. Weitere Zitate derselben Rede: 'wenn unsere Eltern mit dieser Mentalität an die Arbeit gegangen wären, die wir heute zum Teil sehen' (Fragment), 'Nicht mit Zwang, nicht mit Druck, nicht mit neuen Gesetzen, sondern einfach mit Fröhlichkeit an der Arbeit.' Verwandt: merz-09 (Wirtschaftstag Mai 2025).

#### `merz-31` – „Die gesetzliche Rentenversicherung allein wird allenfalls noch die Basisabsicherung sein für das Alter.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2026-04-20
- **Kontext:** Rede beim Empfang zum 75-jährigen Bestehen des Bundesverbands deutscher Banken in Berlin.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit, Wirtschaft/Kapital · **kurz:** nein
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/merz-basisrente-cdu-sozialfluegel-ig-metall-bas-100.html> · <https://www.t-online.de/nachrichten/deutschland/id_101221404/merz-gesetzliche-rente-wird-nur-noch-basisabsicherung-sein.html> · <https://www.stuttgarter-zeitung.de/wirtschaft/merz-rente-basisabsicherung-mhsd-78829447.html>
- **Notizen:** Wortlaut nach dpa; ZDF bestätigt das Kernfragment 'allenfalls noch die Basisabsicherung sein für das Alter'. Abweichende Fassung der DRV Westfalen ('allenfalls eine Basisabsicherung leisten') ist nicht der Wortlaut. Halber Walk-back über Dritte: SPD-Chefin Bas nach Gespräch mit Merz: 'Er hat das so nicht sagen wollen.' Kritik von CDA-Chef Radtke, IG Metall drohte mit Protesten. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-32` – „Wir geben über 500 Milliarden Euro für unser Gesundheitssystem aus und da sind Sie als Teil dieses Gesundheitssystems auch Nutznießer. Sie als Ärztin, Sie könnten ohne dieses Gesundheitssystem nicht leben.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2026-08-27
- **Kontext:** RTL-Sendung 'Am Tisch mit Friedrich Merz', im Streit mit einer Kinderärztin über das GKV-Spargesetz.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit, Wirtschaft/Kapital · **kurz:** nein
- **Quellen:** <https://www.stuttgarter-zeitung.de/politik/interview-mit-kinderaerztin-bei-rtl-die-nutzniesser-aussage-von-merz-im-wortlaut-79429061.html> · <https://www.aerzteblatt.de/news/debatte-um-nutzniesser-aussagen-von-merz-496b48a0-c9ea-4805-9a0a-d456a0a736d9> · <https://hessenschau.de/gesellschaft/nutzniesser-debatte-video-von-darmstaedter-kinderklinik-geht-viral-v1,nutzniesser-video-kinderkliniken-100.html>
- **Notizen:** Ausstrahlungsdatum laut einer Quelle 27.08.2026 (nicht doppelt geprüft). Vor dem Satz sagte Merz: 'Wir haben die ärztlichen Budgets in den letzten 10 Jahren in Deutschland um 40% erhöht.' PERSÖNLICHKEITSRECHT: Die Ärztin ist eine Privatperson – im Spiel weder Namen noch Abbild verwenden. Kurzform: '…da sind Sie als Teil dieses Gesundheitssystems auch Nutznießer.' Folgen: Proteste von Ärzteverbänden, Demo vor dem Reichstag. Keine Rücknahme bekannt. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

### Wirtschaft/Kapital

#### `merz-37` – „(kein gesicherter Wortlaut) – Steuererklärung 'auf einem Bierdeckel'“

- **Sprecher:** Friedrich Merz (CDU), damals: Stellvertretender Vorsitzender der CDU/CSU-Bundestagsfraktion (Finanzpolitik)
- **Datum:** 2003-12
- **Kontext:** Merz' Steuerkonzept (Stufentarif 12/24/36 %, Abbau von Ausnahmen) wurde auf dem CDU-Parteitag in Leipzig im Dezember 2003 beschlossen und nie umgesetzt; populär wurde das Bild, die Steuererklärung solle auf einen Bierdeckel passen.
- **Status:** `sinngemäß` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** nein
- **Quellen:** <https://www.leinetal24.de/welt/friedrich-merz-cdu-steuererklaerung-bierdeckel-duesseldorf-rechnung-fehler-staendehaus-zr-90030444.html> · <https://www.bluewin.ch/de/news/merz-steuer-bierdeckel-in-der-vierer-fernsehdebatte-2562979.html>
- **Notizen:** NUR ALS KONZEPT/BILD verwenden ('Bierdeckel-Steuer'), nicht als Zitat in Anführungszeichen – ein wörtlicher Originalsatz von 2003 wurde nicht gefunden. Merz räumte 2020 laut Ippen-Bericht ein, die Rechnung auf dem ausgestellten Bierdeckel sei 'falsch' (nur Einzelquelle). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-20` – „Ich liege jedenfalls nicht darunter.“

- **Sprecher:** Friedrich Merz (CDU), damals: Aufsichtsratsvorsitzender von BlackRock Deutschland; Kandidat für den CDU-Vorsitz (ohne Mandat)
- **Datum:** 2018-11-14
- **Kontext:** Bild-Interview während seiner ersten Kandidatur um den CDU-Vorsitz, Antwort auf die Frage, ob er Millionär sei.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.horizont.net/marketing/nachrichten/friedrich-merz-so-disst-sixt-den-selbst-ernannten-mittelschichtler-171317> · <https://www.thestar.com.my/news/world/2018/11/18/i-earn-around-a-million-euros-german-conservative-merz-tells-bild>
- **Notizen:** Datum: Interview Mitte November 2018 (genauer Tag nicht gesichert). Später gab er gegenüber Bild am Sonntag ein Bruttoeinkommen von rund einer Million Euro pro Jahr an (Reuters). Siehe merz-21. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-21` – „Also, ich würde mich zu der gehobenen Mittelschicht zählen.“

- **Sprecher:** Friedrich Merz (CDU), damals: Aufsichtsratsvorsitzender von BlackRock Deutschland; Kandidat für den CDU-Vorsitz (ohne Mandat)
- **Datum:** 2018-11-14
- **Kontext:** Selbes Bild-Interview, auf die Frage, ob er sich zur Oberschicht zähle.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.horizont.net/marketing/nachrichten/friedrich-merz-so-disst-sixt-den-selbst-ernannten-mittelschichtler-171317> · <https://uk.news.yahoo.com/despite-admitting-earns-1m-merkel-171214123.html>
- **Notizen:** Begründung im selben Kontext: 'Für mich ist die gesellschaftliche Mitte nicht eine rein ökonomische Größe.' (nur Sekundärquellen). Sixt reagierte mit Spott-Werbung (Horizont). Merz ist Hobbypilot mit eigenem Flugzeug (Flug zur Lindner-Hochzeit nach Sylt 2022) – dazu kein gesichertes wörtliches Zitat recherchiert. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-26` – „Angesichts der Bedrohungen unserer Freiheit und des Friedens auf unserem Kontinent muss jetzt auch für unsere Verteidigung gelten: Whatever it takes.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Vorsitzender und Unionsfraktionschef; Wahlsieger der Bundestagswahl, Sondierungen mit der SPD
- **Datum:** 2025-03-04
- **Kontext:** Pressestatement nach der Einigung mit der SPD auf ein Finanzpaket (Ausnahme von der Schuldenbremse für Verteidigung, 500-Mrd.-Sondervermögen Infrastruktur), beschlossen noch vom alten Bundestag.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Europa · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/merz-schulden-kehrtwende-finanzpolitik-100.html> · <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_100621342/sondervermoegen-deutschland-oeffnet-endlich-die-geldschleusen.html> · <https://www.spacewar.com/afp/250304234205.mzqgrkei.html>
- **Notizen:** Anspielung auf EZB-Chef Mario Draghi (2012). Kehrtwende: Im Wahlkampf hatte die Union die Schuldenbremse verteidigt; Ende Februar 2025 hatte Merz eine Reform in 'naher Zukunft' noch ausgeschlossen (laut Sekundärberichten). Kurzform: '…gelten: Whatever it takes.' Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

### Klima

#### `merz-18` – „Selbst wenn wir alle zusammen morgen in Deutschland klimaneutral wären, würde keine einzige Naturkatastrophe auf dieser Welt weniger geschehen, würde kein einziger Waldbrand weniger geschehen, würde keine einzige Überschwemmung in Texas weniger geschehen.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-07-09
- **Kontext:** Regierungsbefragung im Bundestag; Merz bekannte sich zum Klimaziel 2045, relativierte aber den deutschen Beitrag ('ungefähr 2 Prozent des Problems').
- **Status:** `verifiziert` · **Kategorien:** Klima · **kurz:** nein
- **Quellen:** <https://dserver.bundestag.de/btp/21/21017.pdf> · <https://www.bundestag.de/dokumente/textarchiv/2025/kw28-de-regierungsbefragung-1094170> · <https://www.heidelberg24.de/politik-und-wirtschaft/dagegen-immer-mehr-hitzetote-durch-klimawandel-was-tut-die-merz-regierung-zr-93825822.html>
- **Notizen:** PRIMÄRQUELLE: Plenarprotokoll 21/17. ABWEICHUNG: Presseberichte zitieren 'keine einzige Klimakatastrophe auf der Welt weniger' bzw. 'morgen am Tag klimaneutral' – das amtliche Protokoll sagt 'Naturkatastrophe auf dieser Welt'. Im Spiel die Protokollfassung verwenden. Zwischenruf Britta Haßelmann (Grüne): 'Also doch relativieren!' Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-19` – „Wer von euch würde denn gerne hierbleiben? Da hat keiner die Hand gehoben“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-11-13
- **Kontext:** Rede beim Handelskongress in Berlin nach seiner Rückkehr von der Weltklimakonferenz COP30 in Belém (Brasilien); er berichtete, er habe mitgereiste Journalisten so gefragt, und betonte, Deutschland sei 'eines der schönsten Länder der Welt'.
- **Status:** `verifiziert` · **Kategorien:** Klima, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/merz-brasilien-belem-lula-klimakonferenz-100.html> · <https://web.de/magazine/politik/merz-loest-empoerung-brasilien-41602516> · <https://www.zdfheute.de/politik/merz-lula-brasilien-cop30-klimakonferenz-100.html> · <https://www.bundesregierung.de/breg-de/aktuelles/rede-kanzler-handelskongress-2393818>
- **Notizen:** Genaues Rededatum nicht gesichert (Mitte November 2025, berichtet bis 17.11.). Varianten: 'gerne'/'gern'. Belémer Bürgermeister: 'unglücklich, arrogant und voreingenommen'; Präsident Lula empfahl Merz, in Belém tanzen zu gehen. Keine Entschuldigung; beim G20 in Johannesburg versöhnten sich beide ('Nächstes Mal gehen wir zusammen tanzen', t-online). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender. VERIFIKATION 11/2026: Rede beim Handelskongress am 13.11.2025, Wortlaut laut Bundesregierung-Transkript. Brasilien-Reise, aber keine Stadt (nicht 'Belém') nennen.

### Gender/Familie

#### `merz-23` – „Die sexuelle Orientierung geht die Öffentlichkeit nichts an, solange sich das im Rahmen der Gesetze bewegt und solange es nicht Kinder betrifft. An der Stelle ist für mich allerdings eine absolute Grenze erreicht.“

- **Sprecher:** Friedrich Merz (CDU), damals: Kandidat für den CDU-Vorsitz (ohne Mandat)
- **Datum:** 2020-09-20
- **Kontext:** Bild-Videointerview auf die Frage, ob er Vorbehalte gegen einen homosexuellen Bundeskanzler hätte; er antwortete zunächst 'Nein'.
- **Status:** `verifiziert` · **Kategorien:** Gender/Familie · **kurz:** nein
- **Quellen:** <https://www.t-online.de/nachrichten/id_88611374/frage-nach-schwulem-bundeskanzler-cdu-politiker-merz-reagiert-auf-shitstorm.html> · <https://web.de/magazine/politik/friedrich-merz-schwule-naehe-paedophilen-35118882> · <https://orf.at/stories/3182824/>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; Merz bestreitet die Deutung (Gleichsetzung), nicht den Satz. Kritiker warfen ihm vor, Homosexualität in die Nähe von Pädophilie zu rücken. Merz und sein Sprecher nannten das einen 'bösartig konstruierten Zusammenhang' bzw. 'bösartig und schlicht falsch'; die Aussage gelte für Heterosexuelle wie Homosexuelle. Er bedauerte später, missverstanden worden zu sein (ORF). Im Spiel nicht so verkürzen, dass ein Gleichsetzungsvorwurf als Merz' Aussage erscheint. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-22` – „Mit jeder gegenderten Nachrichtensendung gehen ein paar hundert Stimmen mehr zur AfD.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender und Vorsitzender der CDU/CSU-Bundestagsfraktion (Oppositionsführer)
- **Datum:** 2023-06-03
- **Kontext:** Newsletter 'MerzMail' angesichts eines AfD-Umfragehochs (19 %); Merz machte Grüne, eine 'engstirnige Meinungselite' und Medien mitverantwortlich.
- **Status:** `verifiziert` · **Kategorien:** Gender/Familie, Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://web.de/magazine/politik/merz-gendersprache-erstarken-afd-mitverantwortlich-38285992> · <https://www.berliner-zeitung.de/article/355487> · <https://www.turi2.de/?p=4027357>
- **Notizen:** Datum: 'am Samstag' laut Bericht vom 04.06.2023 → 03.06.2023 (erschlossen). DJV nannte die Aussagen 'politisch wirr'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-17` – „Der Bundestag ist ja nun kein Zirkuszelt.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-07-01
- **Kontext:** ARD-Talkshow 'Maischberger'; Merz verteidigte die Entscheidung von Bundestagspräsidentin Klöckner, zum Berliner CSD keine Regenbogenfahne auf dem Reichstag zu hissen.
- **Status:** `verifiziert` · **Kategorien:** Gender/Familie, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/bundestag-ist-kein-zirkuszelt-merz-aeussert-sich-zu-pride-flagge-am-csd-2338234> · <https://www.zdfheute.de/politik/merz-regenbogenfahne-bundestag-zirkuszelt-100.html> · <https://dserver.bundestag.de/btp/21/21017.pdf>
- **Notizen:** Satzfortsetzung nur indirekt überliefert (auf das man beliebig Fahnen hisse). Sendetermin Dienstag 01.07.2025, Berichte ab 02.07. Breite Kritik (LSVD: 'Entgleisung'; SPD-Vize Zorn: 'sehr unglückliche Aussage'). In der Regierungsbefragung am 09.07.2025 hielt ihm Die Linke den Satz vor (Plenarprotokoll 21/17); Merz: 'Ich weise entschieden zurück, was Sie mir hier gerade persönlich unterstellen.' FALSCHZITAT-WARNUNG: Der Satz wird gelegentlich Klöckner zugeschrieben – er stammt von Merz. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

### Geschichte/NS-Relativierung

#### `merz-14` – „Ich will es einfach an die Adresse dieser Fraktion hier rechts sagen und an Ihre, Herr Gauland: Das war Ihr Fliegenschiss, von dem Sie vor Jahr und Tag gesprochen haben.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender, Unionsfraktionschef und Kanzlerkandidat der Union (Oppositionsführer)
- **Datum:** 2025-01-29
- **Kontext:** Einstieg seiner Bundestagsrede, mit Bezug auf die Holocaust-Gedenkstunde am selben Tag (Rede des Überlebenden Roman Schwarzman).
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung, Sonstiges/Absurd · **kurz:** nein
- **Quellen:** <https://dserver.bundestag.de/btp/20/20209.pdf>
- **Notizen:** PRIMÄRQUELLE: Plenarprotokoll 20/209, S. 27038 C. FALSCHZITAT IM ORIGINAL: Gauland hatte 2018 'Vogelschiss' gesagt, nicht 'Fliegenschiss'. Zwischenrufe laut Protokoll: Stephan Brandner [AfD]: 'Er hat nicht „Fliegenschiss“ gesagt! Herr Gauland hat nie „Fliegenschiss“ gesagt! Ihre Rede ist ein Fliegenschiss!' – Tino Chrupalla [AfD]: 'Sie wissen nicht mal, was er gesagt hat!' (siehe brandner-01, gauland-01). Ideal für eine Dialog-Szene. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

### Demokratie/Medien

#### `merz-24` – „Aber halbieren kann man sie“

- **Sprecher:** Friedrich Merz (CDU), damals: Aufsichtsratsvorsitzender von BlackRock Deutschland; Kandidat für den CDU-Vorsitz (ohne Mandat)
- **Datum:** 2018-11-14
- **Kontext:** Bild-Interview im Rennen um den CDU-Vorsitz über die AfD; zuvor räumte er ein, man bekomme sie kurzfristig nicht weg, da sie in allen Parlamenten sitze.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.nau.ch/politik/international/friedrich-merz-will-afd-in-deutschland-halbieren-65455256> · <https://www.stuttgarter-zeitung.de/politik/friedrich-merz-stadtbild-aussage-wortlaut-mhsd-79036257.html> · <https://web.de/magazine/politik/inland/wegregieren-spur-41278016>
- **Notizen:** Wortlaut nach dpa (nau.ch, 14.11.2018); die Überschrift 'Merz will AfD halbieren' ist redaktionell. Satirischer Kontext (Fakten): AfD 2017 12,6 %, Bundestagswahl 2025 20,8 %; Landtagswahl Sachsen-Anhalt 06.09.2026 AfD stärkste Kraft mit über 40 % (vorläufige Zahlen schwanken je nach Quelle zwischen 43,8 und 44,5 %). Laut Berichten nahm Merz das Halbierungsziel als Kanzler faktisch zurück (nicht wörtlich geprüft). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-25` – „Das haben wir doch zu akzeptieren. […] Und natürlich muss in den Kommunalparlamenten dann auch nach Wegen gesucht werden, wie man gemeinsam die Stadt, das Land, den Landkreis gestaltet.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender und Vorsitzender der CDU/CSU-Bundestagsfraktion (Oppositionsführer)
- **Datum:** 2023-07-23
- **Kontext:** ZDF-Sommerinterview, nach der Wahl eines AfD-Landrats in Sonneberg und eines AfD-Bürgermeisters in Raguhn-Jeßnitz.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_100212494/afd-mit-diesem-interview-bringt-friedrich-merz-die-cdu-gegen-sich-auf.html> · <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_100212602/zusammenarbeit-mit-der-afd-merz-relativiert-umstrittene-aeusserung.html> · <https://www.srf.ch/news/international/brandmauer-zur-afd-cdu-chef-sorgt-mit-aussage-zur-afd-fuer-viel-kritik>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; Walk-back am Folgetag siehe Notizen. WALK-BACK am Folgetag nach Kritik aus CDU und CSU (Söder: keine Zusammenarbeit 'egal auf welcher politischen Ebene'): Merz erklärte, es werde auch auf kommunaler Ebene keine Zusammenarbeit mit der AfD geben; das Wort 'Zusammenarbeit' habe er nicht verwendet. Im ARD-Sommerinterview (27.08.2023) bekräftigte er die Abgrenzung auch für Kommunalvertretungen. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-12` – „Eine richtige Entscheidung wird nicht dadurch falsch, dass die Falschen zustimmen. Sie bleibt richtig.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender, Unionsfraktionschef und Kanzlerkandidat der Union (Oppositionsführer)
- **Datum:** 2025-01-29
- **Kontext:** Bundestagsrede in der Debatte zur Regierungserklärung von Kanzler Scholz nach dem Messerangriff von Aschaffenburg, vor der Abstimmung über den Unions-Entschließungsantrag zur Migration, der dann mit Stimmen der AfD angenommen wurde (348:344).
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Migration · **kurz:** ja
- **Quellen:** <https://dserver.bundestag.de/btp/20/20209.pdf> · <https://www.perlentaucher.de/9punkt/2025-01-31.html>
- **Notizen:** PRIMÄRQUELLE: Plenarprotokoll 20/209, Rede Merz (ab S. 27038 C). Unmittelbar davor: 'Um es deutlich zu sagen:'. Im Protokoll folgt Beifall nur von CDU/CSU und FDP. Erster Bundestagsbeschluss mit ausschlaggebenden AfD-Stimmen; Angela Merkel kritisierte das öffentlich. Siehe merz-13 (Bedauern nach der Abstimmung). Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-13` – „Ich suche in diesem Deutschen Bundestag keine anderen Mehrheiten als die in der demokratischen Mitte unseres Parlaments. […] Und wenn es hier heute eine solche Mehrheit gegeben hat, dann bedaure ich das.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender, Unionsfraktionschef und Kanzlerkandidat der Union (Oppositionsführer)
- **Datum:** 2025-01-29
- **Kontext:** Erklärung im Bundestag unmittelbar nach der Annahme des Unions-Antrags mit AfD-Stimmen.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://dserver.bundestag.de/btp/20/20209.pdf>
- **Notizen:** PRIMÄRQUELLE: Plenarprotokoll 20/209, S. 27081 D – 27082 B. Protokollvermerk direkt nach dem ersten Satz: '(Beifall bei der CDU/CSU sowie des Abg. Stephan Brandner [AfD] – Lachen bei Abgeordneten der SPD, des BÜNDNISSES 90/DIE GRÜNEN und der Linken – Felix Banaszak [BÜNDNIS 90/DIE GRÜNEN]: Sie haben eine andere bekommen gerade!)'. Die Kombination mit merz-12 (wenige Stunden zuvor) ist satirisch ergiebig, beide sind wörtlich gesichert. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-15` – „Sie sind doch nicht der oberste Notar dieser Republik, Sie sind der Bundeskanzler der Bundesrepublik Deutschland.“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender, Unionsfraktionschef und Kanzlerkandidat der Union (Oppositionsführer)
- **Datum:** 2025-01-29
- **Kontext:** Selbe Bundestagsrede, an Kanzler Scholz gerichtet, der auf die Rechtslage (EU-Recht, Grundgesetz) verwiesen hatte.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Sonstiges/Absurd · **kurz:** nein
- **Quellen:** <https://dserver.bundestag.de/btp/20/20209.pdf>
- **Notizen:** PRIMÄRQUELLE: Plenarprotokoll 20/209, S. 27039 D. Vorlage für Ironie: Seit Mai 2025 ist Merz selbst Kanzler. Kurzform: 'Sie sind doch nicht der oberste Notar dieser Republik'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-28` – „Links ist vorbei. Es gibt keine linke Mehrheit und keine linke Politik mehr in Deutschland“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender, Unionsfraktionschef und Kanzlerkandidat der Union (Oppositionsführer)
- **Datum:** 2025-02-22
- **Kontext:** Wahlkampfabschluss der Union in München am Vorabend der Bundestagswahl.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/friedrich-merz-rede-zu-linke-und-gruene-spinner-kritik-an-cdu-kanzlerkandidat-2301250> · <https://www.leinetal24.de/welt/gruene-und-linke-spinner-merz-rede-vor-bundestagswahl-verstoerend-zr-93587623.html>
- **Notizen:** Kurzform: 'Links ist vorbei.' Ironie: Er regiert seit Mai 2025 mit der SPD; bei der Kanzlerwahl am 06.05.2025 fiel er im ersten Wahlgang durch. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-29` – „nicht für irgendwelche grünen und linken Spinner auf dieser Welt“

- **Sprecher:** Friedrich Merz (CDU), damals: CDU-Bundesvorsitzender, Unionsfraktionschef und Kanzlerkandidat der Union (Oppositionsführer)
- **Datum:** 2025-02-22
- **Kontext:** Selbe Rede in München; Merz grenzte seine Politik von 'grünen und linken Spinnern' ab.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Klima · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/friedrich-merz-rede-zu-linke-und-gruene-spinner-kritik-an-cdu-kanzlerkandidat-2301250> · <https://www.leinetal24.de/welt/gruene-und-linke-spinner-merz-rede-vor-bundestagswahl-verstoerend-zr-93587623.html>
- **Notizen:** Nur als Fragment verwenden; der vollständige Satz wurde nicht geprüft. Häufige Verschreibung 'grüne und linke Spinner' – im Original Dativ 'grünen und linken Spinner'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-41` – „Ich frage mal die Ganzen, die da draußen rumlaufen, Antifa und gegen Rechts: Wo waren die denn, als Walter Lübcke in Kassel ermordet worden ist von einem Rechtsradikalen?“

- **Sprecher:** Friedrich Merz (CDU), damals: Kanzlerkandidat der Union und CDU-Bundesvorsitzender
- **Datum:** 2025-02-22
- **Kontext:** Rede beim gemeinsamen Wahlkampfabschluss von CDU und CSU im Münchner Löwenbräukeller, gerichtet an die Demonstranten vor dem Gebäude. Die Familie von Walter Lübcke zeigte sich 'sehr befremdet'; Lübckes Witwe widersprach der Unterstellung, nach dem Mord seien Tausende auf die Straße gegangen.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.nd-aktuell.de/artikel/1189274.wahlkampf-merz-gegen-antifa.html> · <https://www.hessenschau.de/politik/witwe-von-walter-luebcke-kritisiert-friedrich-merz-sehr-befremdet-v4,merz-aeusserung-walter-luebcke-100.html> · <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_100613614/merz-ueber-luebcke-mord-witwe-kritisiert-seine-aussage-scharf.html>
- **Notizen:** Drei Medien (nd, hessenschau, t-online) geben beide Satzteile übereinstimmend wieder; Abweichungen nur in Groß-/Kleinschreibung und Form ('Ganzen'/'ganzen', 'rumlaufen'/'herumlaufen', 'gegen Rechts'/'Gegen Rechts'). Hier die Schreibweise von t-online ('rumlaufen', auch nd). Datum (Samstag, 22.02.2025) aus hessenschau/nd erschlossen (Artikel 23. bis 27.02.2025; Wahl am 23.02.2025). Tagesspiegel soll laut Suchzusammenfassung zudem berichtet haben, Merz habe 'Antifa und gegen rechts' 'Spinner' genannt: nicht selbst geprüft, nicht verwenden. Video/Protokoll nicht eingesehen. Ersetzt weidel-06 (Fragment) als Antifa-Karte.

#### `merz-33` – „Wir sind alle zutiefst schockiert. Wir haben es in dieser Form so nicht erwartet.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2026-09-07
- **Kontext:** Pressekonferenz im Konrad-Adenauer-Haus am Tag nach der Landtagswahl in Sachsen-Anhalt (AfD stärkste Kraft mit über 40 %, CDU historisches Tief).
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.apotheke-adhoc.de/nachrichten/detail/politik/merz-das-ergebnis-hat-uns-schockiert/> · <https://orf.at/stories/3441415/> · <https://de.euronews.com/2026/09/07/merz-wahlschlappe-wird-konsequenzen-haben> · <https://www.news.at/politik/merz-wegen-wahl-in-sachsen-anhalt-zutiefst-schockiert>
- **Notizen:** ORF bestätigt aus derselben PK: 'Das ist die schwerste Wahlniederlage, die die CDU seit Jahren, seit Jahrzehnten auch eingefahren hat' und '…meine Entschlossenheit, den Reformkurs fortzusetzen, ungebrochen.' Weiter: 'Das Grundgesetz gilt auch in Sachsen-Anhalt – auch in einer AfD-geführten Landesregierung'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender. VERIFIKATION 11/2026: Kontext präzisiert; nach apotheke adhoc lag die AfD bei rund 44 %, die CDU bei 17,2 %.

#### `merz-34` – „Aufgeben ist für mich keine Option.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2026-09-07
- **Kontext:** Selbe Pressekonferenz nach der Sachsen-Anhalt-Wahl, auf die Frage nach einem Rücktritt.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/wahl-sachsen-anhalt-cdu-merz-kanzler-kritik-afd-ergebnis-100.html> · <https://www.apotheke-adhoc.de/nachrichten/detail/politik/merz-das-ergebnis-hat-uns-schockiert/>
- **Notizen:** Ebenfalls dort (zdfheute): 'Es gibt in der CDU keine grundsätzlichen Zweifel an der Richtigkeit dieses Kurses'. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

#### `merz-39` – „Denn wir sind die Kraft, die Deutschland stabil auf Kurs hält.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2026-10-24
- **Kontext:** Rede auf dem CSU-Parteitag in München, sechs Wochen nach der verlorenen Landtagswahl in Sachsen-Anhalt; die Union lag in Umfragen hinter der AfD.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.stuttgarter-zeitung.de/politik/csu-parteitag-in-muenchen-merz-fordert-zukunftsmut-und-offenheit-gegenueber-ki-79606641.html> · <https://de.euronews.com/2026/10/24/schauen-nicht-auf-umfragen-merz-csu-parteitag>
- **Notizen:** Ersetzt den nicht bestätigten Umfragen-Satz (merz-35). Fortsetzung laut Stuttgarter Zeitung: 'Wir sind diejenigen, mit denen Deutschland stark und sicher bleibt, auch im Angesicht der Gefahren von innen und von außen.' euronews ohne 'Denn'. Stand 11/2026: Bundeskanzler und CDU-Bundesvorsitzender.

### Europa

#### `merz-27` – „Wir sind nicht im Krieg, aber wir sind auch nicht mehr im Frieden.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-09-29
- **Kontext:** 'Ständehaus-Treff' der Rheinischen Post in Düsseldorf, nach Drohnenüberflügen über Dänemark und Schleswig-Holstein, auf die Frage nach dem Kriegsrisiko.
- **Status:** `verifiziert` · **Kategorien:** Europa, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/peter-maffay-kritisiert-merz-und-pistorius-euphorische-kriegsrhetorik-2360191> · <https://www.zdfheute.de/politik/ausland/merz-frieden-bedrohung-russland-100.html>
- **Notizen:** Wortlaut in allen Quellen identisch. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender. PRÜFUNG 11/2026: Datum und Ort durch ZDF bestätigt (Montag, 29.09.2025, 'Ständehaus Treff' der Rheinischen Post). Laut ZDF hatte sich Merz in der Woche davor schon fast wortgleich geäußert.

### Sonstiges/Absurd

#### `merz-16` – „Das ist die Drecksarbeit, die Israel macht für uns alle.“

- **Sprecher:** Friedrich Merz (CDU), damals: Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender
- **Datum:** 2025-06-17
- **Kontext:** ZDF-Interview am Rande des G7-Gipfels in Kananaskis (Kanada) über die israelischen Angriffe auf iranische Atomanlagen.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd, Europa · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/g7-gipfel-merz-100.html> · <https://www.juedische-allgemeine.de/politik/israel-macht-die-drecksarbeit-fuer-uns/> · <https://www.zdfheute.de/politik/merz-israel-iran-drecksarbeit-reaktionen-100.html>
- **Notizen:** Ausdrücklich fürs Spiel gewünscht (zeigt seine Haltung); Wortlaut gesichert (ZDF selbst). Kontext wichtig: Die Moderatorin Diana Zimmermann hatte das Wort 'Drecksarbeit' in ihrer Frage zuerst verwendet; Merz griff es auf und bedankte sich für den Begriff. Kritik u. a. aus der SPD ('wenig zielführend'); Strafanzeige einer Gruppe um Dieter Hallervorden. Keine Entschuldigung. Stand 11/2026: Bundeskanzler (gewählt am 6. Mai 2025 im zweiten Wahlgang) und CDU-Bundesvorsitzender.

## Markus Söder (CSU)

*Aktuell (11/2026): Bayerischer Ministerpräsident, CSU-Vorsitzender.*

### Migration

#### `soeder-01` – „Der Asyltourismus muss beendet werden“

- **Sprecher:** Markus Söder (CSU), damals: Bayerischer Ministerpräsident
- **Datum:** 2018-06
- **Kontext:** Tweet Mitte Juni 2018 (laut KNA am Donnerstag vor dem 20.06.2018) im Asylstreit der Union um Zurückweisungen an der Grenze. In einem Interview sprach er zudem davon, ein "europäisches Signal setzen, um den Asyltourismus zu beenden".
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://cibedo.de/?p=9478> · <https://www.evangelisch.de/inhalte/150618/18-06-2018/asylstreit-csu-warum-soeder-mit-asyltourismus-fluechtlinge-entmenschlicht> · <https://www.unwortdesjahres.net/wp-content/uploads/2021/06/pressemitteilung_unwort2018.pdf>
- **Notizen:** Wortlaut des Tweets nach KNA (cibedo.de); epd belegt die Variante 'europäisches Signal setzen, um den Asyltourismus zu beenden'. 'Asyltourismus' war 2018 die häufigste Einsendung zum Unwort des Jahres (122x laut Jury-Pressemitteilung), gewählt wurde aber 'Anti-Abschiebe-Industrie'. Walk-back: Laut Junge Freiheit/Tichys Einblick sagte Söder am 11.07.2018 im Landtag, er werde das Wort 'nicht wieder verwenden, wenn es jemanden verletzt' – nicht in Leitmedien/Landtagsprotokoll geprüft (siehe unverifiziert). Aktuell (Stand Nov. 2026): Bayerischer Ministerpräsident und CSU-Vorsitzender.

### Klima

#### `soeder-03` – „Der Hauptkonkurrent um Platz eins sind die Grünen. Sie müssen wir stärker in den Fokus nehmen.“

- **Sprecher:** Markus Söder (CSU), damals: Bayerischer Ministerpräsident und CSU-Vorsitzender
- **Datum:** 2019-11-03
- **Kontext:** Interview-Äußerungen (dpa-Bericht) nach den Landtagswahlen im Osten 2019; Söder forderte zugleich 'Keine einseitige Fixierung nach Rechtsaußen!'.
- **Status:** `verifiziert` · **Kategorien:** Klima, Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.abendzeitung-muenchen.de/bayern/soeder-gruene-sind-gegner-keine-fixierung-auf-rechtsaussen-art-658881>
- **Notizen:** EINZELQUELLE (dpa, hoch): direktes Zitat, kein Zweitbeleg gefunden; Datum nicht doppelt geprüft. Ursprungsmedium dort nicht genannt. ACHTUNG: Die oft kolportierte Formulierung 'Die Grünen sind unser Hauptgegner' ist in den geprüften Quellen NICHT als Söder-Zitat belegt (siehe falschzitate). Aktuell (Stand Nov. 2026): Bayerischer Ministerpräsident und CSU-Vorsitzender.

#### `soeder-04` – „Die Grünen haben die Philosophie, zu verbieten und umzuerziehen.“

- **Sprecher:** Markus Söder (CSU), damals: Bayerischer Ministerpräsident und CSU-Vorsitzender
- **Datum:** 2023-06-10
- **Kontext:** Rede auf der Kundgebung gegen das Heizungsgesetz der Ampel in Erding (u. a. mit Hubert Aiwanger); Söder wandte sich dort auch gegen 'zwanghafte Veganisierung' und 'zwanghaftes Gendern'.
- **Status:** `verifiziert` · **Kategorien:** Klima, Gender/Familie · **kurz:** ja
- **Quellen:** <https://www.schwaebische.de/regional/bayern/soeder-und-aiwanger-heizen-anti-ampel-demo-an-viel-kritik-1678466> · <https://www.infranken.de/bayern/soeder-attackiert-auf-kundgebung-bundesregierung-und-wird-ausgebuht-art-5702694>
- **Notizen:** EINZELQUELLE (dpa, hoch): dpa-Text selbst geprüft (Schwäbische, 10.06.2023); der parallele dpa-Text bei inFranken enthält den Satz nicht. Dieser Satz wörtlich nur in der Schwäbischen (dpa) geprüft; 'zwanghafte Veganisierung'/'zwanghaftes Gendern' zusätzlich bei inFranken. Söder wurde bei der Kundgebung teils ausgebuht. Aktuell (Stand Nov. 2026): Bayerischer Ministerpräsident und CSU-Vorsitzender.

### Demokratie/Medien

#### `soeder-05` – „Die bürgerliche Mitte hat nichts mit AfD, hat nichts mit Anti-Demokraten zu tun“

- **Sprecher:** Markus Söder (CSU), damals: Bayerischer Ministerpräsident und CSU-Vorsitzender
- **Datum:** 2023-06-10
- **Kontext:** Abgrenzung zur AfD auf derselben Erdinger Anti-Heizungsgesetz-Kundgebung, bei der Söder zugleich 'Nein zu diesem Heizungsgesetz' forderte.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Klima · **kurz:** ja
- **Quellen:** <https://www.schwaebische.de/regional/bayern/soeder-und-aiwanger-heizen-anti-ampel-demo-an-viel-kritik-1678466> · <https://www.infranken.de/bayern/soeder-attackiert-auf-kundgebung-bundesregierung-und-wird-ausgebuht-art-5702694>
- **Notizen:** Brandmauer-Linie; in beiden Quellen identisch. Aktuell (Stand Nov. 2026): Bayerischer Ministerpräsident und CSU-Vorsitzender.

### Sonstiges/Absurd

#### `soeder-02` – „Das Kreuz ist nicht ein Zeichen einer Religion“

- **Sprecher:** Markus Söder (CSU), damals: Bayerischer Ministerpräsident
- **Datum:** 2018-04-24
- **Kontext:** Nach dem Kabinettsbeschluss, in allen bayerischen Landesbehörden ein Kreuz im Eingangsbereich aufzuhängen (Kreuzerlass), hängte Söder in der Staatskanzlei demonstrativ ein Kreuz auf.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd, Migration · **kurz:** ja
- **Quellen:** <https://www.bpb.de/shop/zeitschriften/apuz/272097/ein-kreuz/?p=all> · <https://www.taz.de/!5506490/> · <https://www.perlentaucher.de/9punkt/2018-04-25.html>
- **Notizen:** Laut bpb-Essay (F. W. Graf) relativierte Söder die Aussage nach Kritik u. a. aus den Kirchen später. Der BayVGH sah im Erlass einen Verstoß gegen die Neutralitätspflicht, wies die Klagen aber ab; das BVerwG bestätigte die Abweisung (Dez. 2023). Söder sprach danach vom Kreuz als 'Zeichen unserer christlichen und kulturellen Prägung' (nur in Suchzusammenfassung gesehen). Aktuell (Stand Nov. 2026): Bayerischer Ministerpräsident und CSU-Vorsitzender. VERIFIKATION 11/2026: Ganzer Satz bei bpb (Graf) und perlentaucher wiedergegeben; Originalvideo/Pressekonferenz nicht eingesehen. Begründung laut perlentaucher: 'Bekenntnis zur Identität' und zur 'kulturellen Prägung'.

#### `soeder-06` – „Besonders die Rote Heidi, die sozialistische Tiktok-Tante, die Rosa Luxemburg für Arme, liebe Freundinnen und Freunde.“

- **Sprecher:** Markus Söder (CSU), damals: Bayerischer Ministerpräsident und CSU-Vorsitzender
- **Datum:** 2026-02-18
- **Kontext:** Politischer Aschermittwoch der CSU in Passau; Spott über Linken-Fraktionschefin Heidi Reichinnek.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/10019869> · <https://www.nordkurier.de/politik/sozialistische-tiktok-tante-soeder-zieht-ueber-linken-chefin-reichinnek-her-4371240> · <https://www.derstandard.at/story/3000000309099/pfui-pfui-pfui-soeder-warnt-am-aschermittwoch-vor-der-afd>
- **Notizen:** Vollständiger Satz bei Berliner Zeitung; 'rote Heidi' und 'sozialistische Tiktok-Tante' auch bei Nordkurier (dpa). Anschließender Trabi/Audi-Spott ist in den Quellen unterschiedlich formuliert (siehe unverifiziert). Aktuell (Stand Nov. 2026): Bayerischer Ministerpräsident und CSU-Vorsitzender.

## Carsten Linnemann (CDU)

*Aktuell (11/2026): Laut Berichten seit Juli 2026 Bundesgesundheitsminister; zuvor CDU-Generalsekretär (2023–2026).*

### Migration

#### `linnemann-01` – „Um es auf den Punkt zu bringen: Ein Kind, das kaum Deutsch spricht und versteht, hat auf einer Grundschule noch nichts zu suchen.“

- **Sprecher:** Carsten Linnemann (CDU), damals: Stellvertretender Vorsitzender der CDU/CSU-Bundestagsfraktion
- **Datum:** 2019-08-05
- **Kontext:** Interview mit der Rheinischen Post; Linnemann forderte eine verpflichtende Vorschule für Kinder ohne ausreichende Deutschkenntnisse und notfalls eine Zurückstellung der Einschulung, unter Verweis auf 'neue Parallelgesellschaften'.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.evangelisch.de/inhalte/159036/05-08-2019/cdu-politiker-erstklaessler-muessen-gute-deutschkenntnisse-haben> · <https://www.abendzeitung-muenchen.de/politik/debatte-ohne-deutschkenntnisse-kein-grundschulbesuch-art-582068> · <https://taz.de/Grundschul-Forderung-aus-der-CDU/!5611031/>
- **Notizen:** Wortlaut 'spricht und versteht' laut epd und dpa; taz gibt 'spricht oder versteht' wieder (siehe falschzitate). Die Zuspitzung 'Grundschulverbot' ist nicht sein Wortlaut: Er forderte kein Verbot des Grundschulbesuchs (wie dpa zunächst meldete), sondern Vorschulpflicht/Zurückstellung. Breite Kritik von Kultusministern. Aktuell (Stand Nov. 2026): Bundesminister für Gesundheit (Nachfolger von Nina Warken, Kabinettsumbildung Juli 2026); zuvor CDU-Generalsekretär (Juli 2023 – Juli 2026).

#### `linnemann-02` – „Wer mittags im Freibad Menschen angreift, muss abends vor dem Richter sitzen und abgeurteilt werden. Auch am Wochenende.“

- **Sprecher:** Carsten Linnemann (CDU), damals: CDU-Generalsekretär
- **Datum:** 2023-07
- **Kontext:** Interview mit der Bild am Sonntag nach gewalttätigen Vorfällen in Berliner Freibädern; Forderung nach beschleunigten Verfahren.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sonstiges/Absurd · **kurz:** nein
- **Quellen:** <https://www.lto.de/recht/presseschau/p/2023-07-17-linnemann-schnellverfahren-polizeiinspekteur-freispruch-bverfg-laserblitzer>
- **Notizen:** Wortlaut nach LTO-Presseschau vom 17.07.2023 (Interview vom Wochenende davor); in weiteren Berichten (Ippen-Medien, nur in Suche gesehen) übereinstimmend. Juristen kritisierten den Vorschlag als unrealistisch. Aktuell (Stand Nov. 2026): Bundesminister für Gesundheit (Nachfolger von Nina Warken, Kabinettsumbildung Juli 2026); zuvor CDU-Generalsekretär (Juli 2023 – Juli 2026).

### Sozialstaat/Arbeit

#### `linnemann-03` – „Die Statistik legt nahe, dass eine sechsstellige Zahl von Personen grundsätzlich nicht bereit ist, eine Arbeit anzunehmen“

- **Sprecher:** Carsten Linnemann (CDU), damals: CDU-Generalsekretär
- **Datum:** 2024-07-28
- **Kontext:** Gegenüber den Funke-Zeitungen begründete Linnemann seine Forderung, sogenannten Totalverweigerern die Grundsicherung komplett zu streichen.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://www.evangelisch.de/inhalte/232292/29-07-2024/diakonie-chef-linnemanns-zahlen-sind-falsch> · <https://www.stuttgarter-zeitung.de/politik/berlin-linnemann-will-mehr-als-100000-menschen-buergergeld-streichen-78907034.html>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; umstritten ist die Zahl, nicht das Zitat. Vollständiger Satz laut AFP (Stuttgarter Zeitung, 28.07.2024); Fragment auch bei epd. Die Zahl ist umstritten: Diakonie-Präsident Schuch nannte Linnemanns Zahlen falsch. Aktuell (Stand Nov. 2026): Bundesminister für Gesundheit (Nachfolger von Nina Warken, Kabinettsumbildung Juli 2026); zuvor CDU-Generalsekretär (Juli 2023 – Juli 2026).

#### `linnemann-04` – „Wenn jemand nachweislich wiederholt einen zumutbaren Job nicht annimmt, obwohl er offenkundig arbeiten kann, dann muss der Staat davon ausgehen, dass derjenige nicht bedürftig ist. Und dann bekommt er auch kein Bürgergeld mehr.“

- **Sprecher:** Carsten Linnemann (CDU), damals: CDU-Generalsekretär
- **Datum:** 2025-06-08
- **Kontext:** Interview-Äußerung (dpa-Bericht) zur geplanten Bürgergeld-Reform der schwarz-roten Koalition; er forderte, 'wirklich an die Substanz des Systems' zu gehen.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://www.nordkurier.de/politik/spd-kritisiert-linnemanns-harten-buergergeld-kurs-3653255> · <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_100758648/linnemann-fuer-buergergeld-reform-substanz-des-systems-.html>
- **Notizen:** Ursprungsmedium in den geprüften Artikeln nicht genannt (dpa). Ergänzung im selben Interview: 'Niemand kann erwarten, dass Menschen für ihn bezahlen, die jeden Tag arbeiten gehen.' Aktuell (Stand Nov. 2026): Bundesminister für Gesundheit (Nachfolger von Nina Warken, Kabinettsumbildung Juli 2026); zuvor CDU-Generalsekretär (Juli 2023 – Juli 2026).

### Wirtschaft/Kapital

#### `linnemann-05` – „Ich finde, zehn Krankenkassen in Deutschland reichen“

- **Sprecher:** Carsten Linnemann (CDU), damals: CDU-Generalsekretär
- **Datum:** 2026-04-14
- **Kontext:** Laut Apotheken Umschau in einem n-tv-Interview; Linnemann verwies auf 'über 90 Krankenkassen, die in der Regel die gleichen Leistungen anbieten'. Wenige Monate später wurde er selbst Gesundheitsminister.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.apotheken-umschau.de/gesundheitspolitik/carsten-linnemann-bisherige-positionen-des-neue-gesundheitsministers-1562025.html> · <https://www.zdfheute.de/politik/deutschland/linnemann-forderung-krankenkasse-reform-verwaltung-100.html> · <https://www.aerzteblatt.de/news/rubriken/politik/cdu-generalsekretar-linnemann-zehn-krankenkassen-reichen-1ab52b8a-c004-4117-812b-aa0f46fcf940>
- **Notizen:** Sendung: ntv 'Frühstart' (Dienstag, 14.04.2026 laut zdfheute-Bericht vom 16.04.). Die Überschrift 'Zehn Kassen reichen' ist redaktionell, nicht sein Wortlaut. Aktuell (Stand Nov. 2026): Bundesminister für Gesundheit (Nachfolger von Nina Warken, Kabinettsumbildung Juli 2026); zuvor CDU-Generalsekretär (Juli 2023 – Juli 2026).

## Jens Spahn (CDU)

*Aktuell (11/2026): MdB; bis 18.07.2026 Vorsitzender der CDU/CSU-Bundestagsfraktion (Nachfolger: Thorsten Frei). Rücktrittsanlass ist privat – im Spiel nicht thematisieren.*

### Sozialstaat/Arbeit

#### `spahn-01` – „Niemand müsste in Deutschland hungern, wenn es die Tafeln nicht gäbe.“

- **Sprecher:** Jens Spahn (CDU), damals: Designierter Bundesgesundheitsminister (noch Parl. Staatssekretär im Bundesfinanzministerium)
- **Datum:** 2018-03
- **Kontext:** Äußerung in der Debatte um den Aufnahmestopp für Ausländer bei der Essener Tafel (März 2018); er sagte auch: 'Damit hat jeder das, was er zum Leben braucht.'
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/politik/olaf-scholz-weist-spahns-hartz-iv-ausserungen-zuruck-5517976.html> · <https://www.aerzteblatt.de/news/debatte-um-armutsbekaempfung-entbrannt-0e8fb5a0-8932-460c-9203-fe2fb214cca3> · <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_83385430/jens-spahn-rudert-in-hartz-iv-debatte-zurueck-natuerlich-ist-es-schwierig-.html>
- **Notizen:** Das berühmte 'Hartz IV bedeutet nicht Armut' ist in den geprüften Quellen NUR als indirekte Rede belegt ('Hartz IV bedeute nicht Armut, sondern sei die Antwort der Solidargemeinschaft auf Armut') – siehe falschzitate. Walk-back bei n-tv (März 2018): 'Natürlich ist es schwierig, mit so einem kleinen Einkommen umgehen zu müssen, wie es Hartz IV bedeutet.' Aktuell (Stand Nov. 2026): Bundestagsabgeordneter, Mitglied im Haushaltsausschuss; trat am 18.07.2026 als Vorsitzender der CDU/CSU-Fraktion zurück, Nachfolger ist Thorsten Frei. Anlass war eine Debatte um eine private Familienangelegenheit – im Spiel aus Persönlichkeitsrechtsgründen nicht thematisieren. VERIFIKATION 11/2026: Der Wortlaut ist bei Tagesspiegel, Ärzteblatt und t-online belegt; das Medium der ursprünglichen Äußerung (Funke/Berliner Morgenpost?) konnte nicht bestätigt werden, daher nicht genannt.

### Wirtschaft/Kapital

#### `spahn-04` – „In der Not ist Haben wichtiger als Brauchen. Das war eine Jahrhundertkrise und eine Ausnahmesituation.“

- **Sprecher:** Jens Spahn (CDU), damals: Vorsitzender der CDU/CSU-Bundestagsfraktion
- **Datum:** 2025-06
- **Kontext:** Im Podcast Table.Today zur Kritik an seiner Maskenbeschaffung 2020 (Bericht der Sonderermittlerin Margaretha Sudhof).
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.aerzteblatt.de/news/debatte-um-untersuchungsbericht-zu-maskenbeschaffung-4c3a1c63-8238-4e73-8351-2c03b16a11eb> · <https://www.zdfheute.de/politik/deutschland/spahn-corona-masken-bericht-100.html> · <https://www.pharmazeutische-zeitung.de/spahn-verteidigt-masken-deals-und-gesteht-fehler-ein-156628/> · <https://www.doccheck.com/de/detail/articles/51153-news-bites-deals-hinter-vorgehaltener-maske>
- **Notizen:** Wortlaut nach Ärzteblatt (10.06.2025). Im selben Kontext (Ärzteblatt): 'So ein Verfahren würde ich nie wieder machen, kann ich niemandem empfehlen.'; zdfheute (Rheinische Post): 'Ich habe nichts zu verbergen'. Laut Ärzteblatt stellte der Sudhof-Bericht fest, Spahn sei 'gegen den Rat seiner Fachabteilungen' in die Beschaffung eingestiegen. Aktuell (Stand Nov. 2026): Bundestagsabgeordneter, Mitglied im Haushaltsausschuss; trat am 18.07.2026 als Vorsitzender der CDU/CSU-Fraktion zurück, Nachfolger ist Thorsten Frei. Anlass war eine Debatte um eine private Familienangelegenheit – im Spiel aus Persönlichkeitsrechtsgründen nicht thematisieren. PRÜFUNG 11/2026: Variante: Nordkurier gibt eine kürzere Fassung 'Haben ist besser als brauchen' wieder – nicht verwenden.

### Demokratie/Medien

#### `spahn-03` – „[…] mit der AfD als Oppositionspartei so umzugehen in den Verfahren und Abläufen wie mit jeder anderen Oppositionspartei auch“

- **Sprecher:** Jens Spahn (CDU), damals: Stellvertretender Vorsitzender der CDU/CSU-Bundestagsfraktion
- **Datum:** 2025-04-12
- **Kontext:** Interview mit der Bild-Zeitung nach der Bundestagswahl, u. a. zur Frage von Ausschussvorsitzen für die AfD.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/spahn-cdu-afd-umgang-kritik-100.html>
- **Notizen:** Satzanfang laut weiteren Berichten (Nordkurier, Schwäbische; nur in Suche gesehen): 'Da würde ich uns einfach empfehlen, …'. Scharfe Kritik von SPD, Grünen, Linken; Spahn verteidigte sich bei 'Markus Lanz' (April 2025) und betonte, das Wort 'Normalisierung' nicht verwendet zu haben. Ab Mai 2025 Fraktionsvorsitzender. Aktuell (Stand Nov. 2026): Bundestagsabgeordneter, Mitglied im Haushaltsausschuss; trat am 18.07.2026 als Vorsitzender der CDU/CSU-Fraktion zurück, Nachfolger ist Thorsten Frei. Anlass war eine Debatte um eine private Familienangelegenheit – im Spiel aus Persönlichkeitsrechtsgründen nicht thematisieren.

#### `spahn-05` – „Ich kann euch sagen, Tattoos, TikTok: Am Ende wird es mit Genossin Reichinnek nicht besser als mit Genosse Honecker.“

- **Sprecher:** Jens Spahn (CDU), damals: Vorsitzender der CDU/CSU-Bundestagsfraktion
- **Datum:** 2026-02-21
- **Kontext:** Rede auf dem CDU-Bundesparteitag in Stuttgart mit Absage an eine Zusammenarbeit mit AfD und Linken; die Linke nannte er eine 'krude Mischung (...) aus alter SED und neuer Hamas'.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://www.nordkurier.de/politik/cdu-mann-spahn-am-ende-wird-es-mit-genossin-reichinnek-nicht-besser-als-mit-genosse-honecker-4378574> · <https://www.blick.ch/ausland/judenhasser-mischung-aus-sed-und-hamas-spahn-schimpft-auf-parteitag-ueber-die-linke-und-afd-id21716341.html>
- **Notizen:** Schreibweise 'TikTok' (Nordkurier) bzw. 'Tiktok' (Blick), beide dpa. Zur AfD in derselben Rede: 'Das ist Vetternwirtschaft, Verrat am Vaterland, Verrat am Steuerzahler. Mit der Truppe ist kein Staat zu machen.' Aktuell (Stand Nov. 2026): Bundestagsabgeordneter, Mitglied im Haushaltsausschuss; trat am 18.07.2026 als Vorsitzender der CDU/CSU-Fraktion zurück, Nachfolger ist Thorsten Frei. Anlass war eine Debatte um eine private Familienangelegenheit – im Spiel aus Persönlichkeitsrechtsgründen nicht thematisieren.

### Sonstiges/Absurd

#### `spahn-02` – „[…] dass wir nämlich miteinander in ein paar Monaten wahrscheinlich viel werden verzeihen müssen“

- **Sprecher:** Jens Spahn (CDU), damals: Bundesminister für Gesundheit
- **Datum:** 2020-04-22
- **Kontext:** Regierungsbefragung im Bundestag in der ersten Corona-Welle (Plenarprotokoll 19/155, S. 19211); er bezog es ausdrücklich 'auch gerade zur Maske und anderem'.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://dserver.bundestag.de/btp/19/19155.pdf> · <https://www.aerzteblatt.de/nachrichten/112192/Spahn-wirbt-um-Verstaendnis-fuer-schwierige-Entscheidungen-in-der-Coronakrise>
- **Notizen:** Wortlaut aus dem Plenarprotokoll (Primärquelle). Satzanfang: 'Bei etwas anderem bin ich ausdrücklich Ihrer Meinung – das will ich auch grundsätzlich zu anderen Debatten, etwa auch gerade zur Maske und anderem, sagen –, dass wir nämlich …'. Protokoll vermerkt '(Lachen bei Abgeordneten der LINKEN)'. Die geläufige Fassung 'Wir werden einander viel verzeihen müssen' ist sein Buchtitel (2022), nicht der Bundestagswortlaut. Aktuell (Stand Nov. 2026): Bundestagsabgeordneter, Mitglied im Haushaltsausschuss; trat am 18.07.2026 als Vorsitzender der CDU/CSU-Fraktion zurück, Nachfolger ist Thorsten Frei. Anlass war eine Debatte um eine private Familienangelegenheit – im Spiel aus Persönlichkeitsrechtsgründen nicht thematisieren.

## Alexander Dobrindt (CSU)

*Aktuell (11/2026): Bundesminister des Innern seit Mai 2025.*

### Migration

#### `dobrindt-01` – „Es ist nicht akzeptabel, dass durch eine aggressive Anti-Abschiebe-Industrie bewusst die Bemühungen des Rechtsstaates sabotiert und eine weitere Gefährdung der Öffentlichkeit provoziert wird.“

- **Sprecher:** Alexander Dobrindt (CSU), damals: Vorsitzender der CSU-Landesgruppe im Bundestag
- **Datum:** 2018-05-06
- **Kontext:** Interview mit der Bild am Sonntag; gemeint waren Anwälte und Initiativen, die mit Klagen Abschiebungen verhindern.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.tagesspiegel.de/politik/csu-landesgruppenchef-dobrindt-beklagt-eine-anti-abschiebe-industrie/21248990.html> · <https://www.t-online.de/nachrichten/deutschland/id_83725718/alexander-dobrindt-beklagt-anti-abschiebe-industrie-.html> · <https://www.unwortdesjahres.net/wp-content/uploads/2021/06/pressemitteilung_unwort2018.pdf>
- **Notizen:** 'Anti-Abschiebe-Industrie' wurde Unwort des Jahres 2018 (Jury: 'offensichtlicher Kampfbegriff'). Kritik u. a. von Deutschem Anwaltverein und Bundesrechtsanwaltskammer. Kurzform 'Rechtsstaat sabotiert' ist kein Wortlaut. Aktuell (Stand Nov. 2026): Bundesminister des Innern (seit Mai 2025).

#### `dobrindt-04` – „Wir halten […] an den Zurückweisungen fest.“

- **Sprecher:** Alexander Dobrindt (CSU), damals: Bundesminister des Innern
- **Datum:** 2025-06-02
- **Kontext:** Reaktion auf den Eilbeschluss des Verwaltungsgerichts Berlin, der die Zurückweisung dreier Somalier an der deutsch-polnischen Grenze für rechtswidrig erklärte.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.evangelisch.de/inhalte/243956/02-06-2025/gerichtsbeschluss-zurueckweisungen-grenzen-war-rechtswidrig> · <https://www.heidelberg24.de/politik-und-wirtschaft/hinter-grenze-rechtswidrig-gericht-abweisung-asylsuchender-zr-93765332.html> · <https://www.zdfheute.de/politik/deutschland/grenzkontrolle-zurueckweisung-asyl-urteil-rechtswidrig-100.html>
- **Notizen:** Wortlaut nach epd. Ippen-Medien zitieren zusätzlich 'Die Macht des Faktischen wirkt längst …' (Zuschreibung nicht eindeutig, siehe unverifiziert). Laut LTO (Suchergebnis) erklärte eine weitere Kammer des VG Berlin im Mai 2026 erneut eine Zurückweisung für rechtswidrig. Aktuell (Stand Nov. 2026): Bundesminister des Innern (seit Mai 2025). PRÜFUNG 11/2026: zdfheute zitiert 'Wir halten (…) an den Zurückweisungen fest.' und weiter: 'Wir sehen, dass die Rechtsgrundlage gegeben ist und werden deswegen weiter so verfahren, ganz unabhängig von dieser Einzelfallentscheidung.'

### Demokratie/Medien

#### `dobrindt-02` – „Auf die linke Revolution der Eliten folgt eine konservative Revolution der Bürger.“

- **Sprecher:** Alexander Dobrindt (CSU), damals: Vorsitzender der CSU-Landesgruppe im Bundestag
- **Datum:** 2018-01-04
- **Kontext:** Gastbeitrag in der 'Welt' ('Für eine bürgerliche Wende') vor der CSU-Klausur in Seeon; Fortsetzung laut Tagesspiegel: 'Wir unterstützen diese Revolution und sind ihre Stimme in der Politik.'
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/politik/csu-landesgruppenchef-dobrindt-will-konservative-revolution-unterstuetzen/20812904.html> · <https://www.t-online.de/nachrichten/deutschland/parteien/id_82993442/vor-csu-klausurtagung-dobrindt-fordert-konservative-revolution-.html>
- **Notizen:** Kritiker verwiesen auf die Begriffsgeschichte der 'Konservativen Revolution' (antidemokratische Strömung der Weimarer Zeit). Welt-Original nicht selbst eingesehen; Wortlaut in Tagesspiegel und t-online identisch. Datum des Gastbeitrags laut Sekundärquellen 4.1.2018 (teils 1.1. genannt). Aktuell (Stand Nov. 2026): Bundesminister des Innern (seit Mai 2025).

## Julia Klöckner (CDU)

*Aktuell (11/2026): Präsidentin des Deutschen Bundestages seit März 2025.*

### Wirtschaft/Kapital

#### `kloeckner-01` – „An die Hatespeaker, weil ich mit Nestlé gesprochen habe: Mal eigene Forderungen #Zuckerreduktion nachlesen!“

- **Sprecher:** Julia Klöckner (CDU), damals: Bundesministerin für Ernährung und Landwirtschaft
- **Datum:** 2019-06-04
- **Kontext:** Tweet nach Kritik an einem vom Ministerium verbreiteten Video, in dem Klöckner gemeinsam mit dem Nestlé-Deutschlandchef die Reduktion von Zucker, Fett und Salz lobte.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.horizont.net/marketing/nachrichten/wegen-werbevideo-fuer-nestl-empoerungswelle-im-internet-gegen-ministerin-kloeckner-175319> · <https://www.t-online.de/nachrichten/deutschland/gesellschaft/id_85876504/julia-kloeckner-loest-mit-nestle-video-shitstorm-aus-schleichwerbung-.html> · <https://www.aerzteblatt.de/themen/ernaehrung/empoerungswelle-gegen-bundeslandwirtschaftsministerin-2c02cb72-0143-4862-9072-c198618fbfc1>
- **Notizen:** Volltext nach Horizont; 'Hatespeaker' auch bei t-online und Ärzteblatt. Weiterer Tweet (Horizont): 'Erst unterstellen, dass nichts geschieht. Dann durchdrehen, wenn man was erreicht'. Die Medienanstalt Berlin-Brandenburg wertete das Video später nicht als Schleichwerbung. Aktuell (Stand Nov. 2026): Präsidentin des Deutschen Bundestages (seit März 2025).

### Demokratie/Medien

#### `kloeckner-03` – „sich beide nicht so sehr unähnlich, in ihren Vorgehensweisen“

- **Sprecher:** Julia Klöckner (CDU), damals: Präsidentin des Deutschen Bundestages
- **Datum:** 2025-08
- **Kontext:** Rede beim Sommerfest der CDU Koblenz auf dem Firmengelände von Frank Gotthardt, einem Hauptgeldgeber des Portals Nius; bezogen auf Nius und die taz.
- **Status:** `umstritten` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/news/julia-kloeckner-vergleicht-nius-mit-der-taz-nach-teilnahme-an-cdu-fest-li.2350119> · <https://www.heidelberg24.de/politik-und-wirtschaft/kloeckner-wegen-nius-unter-druck-macht-mich-betroffen-zr-93896762.html> · <https://taz.de/Kloeckner-vs-taz/!t6108339/>
- **Notizen:** BLEIBT 'umstritten', weil: Klöckner bestreitet, die taz mit Nius verglichen zu haben (Zuschreibung strittig; nur Fragment belegt). Nur Satzfragment wörtlich belegt (Berliner Zeitung 18.08.2025; heidelberg24 'nicht so sehr unähnlich'). Klöckner bestritt später, die taz mit Nius verglichen zu haben (taz-Kommentar 18.09.2025: es gebe Aufnahmen der Rede). Kritik u. a. vom DJV; Linke forderte Rücktritt. Im Spiel nur als Fragment mit Kontext verwenden. Aktuell (Stand Nov. 2026): Präsidentin des Deutschen Bundestages (seit März 2025).

### Sonstiges/Absurd

#### `kloeckner-02` – „Ich meine: Klar kann sich Kirche auch zu Tempo 130 äußern, aber dafür zahle ich jetzt nicht unbedingt Kirchensteuer.“

- **Sprecher:** Julia Klöckner (CDU), damals: Präsidentin des Deutschen Bundestages
- **Datum:** 2025-04-20
- **Kontext:** Osterinterview mit Bild am Sonntag über Kirchenaustritte; eine Kirche, die wie eine NGO zu tagespolitischen Fragen Stellung nehme, werde 'leider auch austauschbar'.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd, Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.evangelisch.de/inhalte/241992/20-04-2025/bundestagspraesidentin-kloeckner-kirche-muss-sinn-stiften> · <https://www.tichyseinblick.de/meinungen/gruene-erfinden-aussagen-von-julia-kloeckner/> · <https://brusselssignal.eu/2025/04/church-should-stay-out-of-politics-focus-on-life-and-death-german-parliament-president>
- **Notizen:** EINZELQUELLE (epd, hoch): wortgleiche englische Wiedergabe bei Brussels Signal; Bild-am-Sonntag-Original nicht eingesehen. Wortlaut nach epd (Einzelquelle für den Satz; Tichys Einblick bestätigt das Interview, nennt es 'BILD'). Kritiker warfen ihr vor, der Kirche einen 'Maulkorb' verpassen zu wollen – das sagte sie nicht; im Interview heißt es 'da kann man alles sicherlich tun und machen'. Im Mai 2026 wiederholte sie, Kirche müsse mehr als eine NGO sein. Aktuell (Stand Nov. 2026): Präsidentin des Deutschen Bundestages (seit März 2025).

## Philipp Amthor (CDU)

*Aktuell (11/2026): Staatsminister beim Bundeskanzler (seit 29.07.2026, laut bundesregierung.de).*

### Wirtschaft/Kapital

#### `amthor-01` – „Ich bin nicht käuflich“

- **Sprecher:** Philipp Amthor (CDU), damals: Bundestagsabgeordneter (Mecklenburg-Vorpommern)
- **Datum:** 2020-06
- **Kontext:** dpa-Interview nach Spiegel-Enthüllungen über seinen Lobbyeinsatz beim Bundeswirtschaftsministerium für das US-Start-up Augustus Intelligence, von dem er einen Direktorenposten und Aktienoptionen erhalten hatte.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital · **kurz:** ja
- **Quellen:** <https://web.de/magazine/politik/philipp-amthor-kritischem-bericht-konsequenzen-34786954>
- **Notizen:** EINZELQUELLE (dpa, hoch): andere Medien geben 'nicht käuflich' nur als Paraphrase wieder. WICHTIG: Die Generalstaatsanwaltschaft Berlin leitete mangels Anfangsverdachts kein Ermittlungsverfahren wegen Bestechlichkeit ein (LTO, nur in Suche gesehen: https://www.lto.de/recht/nachrichten/n/gsta-berlin-leitet-kein-ermittlungsverfahren-gegen-philipp-amthor-wegen-bestechlichkeit-ein). Amthor beendete die Nebentätigkeit und gab die Optionen nach eigenen Angaben zurück. Aktuell (Stand Nov. 2026): Staatsminister beim Bundeskanzler für Bund-Länder-Zusammenarbeit (seit 29.07.2026, laut bundesregierung.de); 2025–2026 Parlamentarischer Staatssekretär im Bundesministerium für Digitales und Staatsmodernisierung.

#### `amthor-02` – „Gleichwohl habe ich mich politisch angreifbar gemacht und kann die Kritik nachvollziehen. Es war ein Fehler“

- **Sprecher:** Philipp Amthor (CDU), damals: Bundestagsabgeordneter (Mecklenburg-Vorpommern)
- **Datum:** 2020-06
- **Kontext:** Facebook-Erklärung zur Augustus-Intelligence-Affäre; dazu: 'Dieses Kapitel ist mir eine Lehre.'
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital · **kurz:** ja
- **Quellen:** <https://web.de/magazine/politik/philipp-amthor-kritischem-bericht-konsequenzen-34786954> · <https://orf.at/stories/3169831/>
- **Notizen:** Volltext nach dpa/web.de (15.06.2020); 'Fehler' auch bei ORF. Er zog sich zudem aus dem Amri-Untersuchungsausschuss zurück. Aktuell (Stand Nov. 2026): Staatsminister beim Bundeskanzler für Bund-Länder-Zusammenarbeit (seit 29.07.2026, laut bundesregierung.de); 2025–2026 Parlamentarischer Staatssekretär im Bundesministerium für Digitales und Staatsmodernisierung.

#### `amthor-03` – „Das war mein größter politischer Fehler.“

- **Sprecher:** Philipp Amthor (CDU), damals: Bundestagsabgeordneter, Unterhändler in den Koalitionsgesprächen 2025
- **Datum:** 2025-04-01
- **Kontext:** Bei 'Markus Lanz' zur Augustus-Intelligence-Affäre, die 2020 über eine Anfrage nach dem Informationsfreiheitsgesetz (IFG) bekannt geworden war – im Gespräch über Unionspläne zum IFG.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/markus-lanz-philipp-amthor-informationsfreiheitsgesetz-100.html>
- **Notizen:** EINZELQUELLE (ZDF über eigene Sendung, hoch). In derselben Sendung: 'Das Informationsfreiheitsgesetz und dessen Reform ist kein Schwerpunkt für die Staatsmodernisierung in Deutschland.' Aktuell (Stand Nov. 2026): Staatsminister beim Bundeskanzler für Bund-Länder-Zusammenarbeit (seit 29.07.2026, laut bundesregierung.de); 2025–2026 Parlamentarischer Staatssekretär im Bundesministerium für Digitales und Staatsmodernisierung.

#### `amthor-04` – „Ich bringe das mal ein bisschen überspitzt auf die Formel 'Lieber 10 Prozent von X, als 20 Prozent von nix'.“

- **Sprecher:** Philipp Amthor (CDU), damals: Bundestagsabgeordneter, Unterhändler in den Koalitionsgesprächen 2025
- **Datum:** 2025-04-01
- **Kontext:** Bei 'Markus Lanz' als Argument gegen Steuererhöhungen ('für das Steueraufkommen in Deutschland wäre es absolutes Gift, jetzt die Steuern zu erhöhen').
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/markus-lanz-philipp-amthor-informationsfreiheitsgesetz-100.html>
- **Notizen:** EINZELQUELLE (ZDF über eigene Sendung, hoch). Aktuell (Stand Nov. 2026): Staatsminister beim Bundeskanzler für Bund-Länder-Zusammenarbeit (seit 29.07.2026, laut bundesregierung.de); 2025–2026 Parlamentarischer Staatssekretär im Bundesministerium für Digitales und Staatsmodernisierung.

## Hubert Aiwanger (Freie Wähler)

*Aktuell (11/2026): Bayerischer Wirtschaftsminister, stv. Ministerpräsident, FW-Bundesvorsitzender (Stand 11/2026 nicht gesondert geprüft).*

### Gender/Familie

#### `aiwanger-02` – „Ich hab die Nase voll, wenn man in der Früh aufsteht, die Zeitung aufschlägt oder das Radio einschaltet, und es kommt nur links-grüner Gender-Gaga auf uns zu“

- **Sprecher:** Hubert Aiwanger (Freie Wähler), damals: Bayerischer Wirtschaftsminister und stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler
- **Datum:** 2023-06-10
- **Kontext:** Ebenfalls Erdinger Kundgebung gegen das Heizungsgesetz; er schimpfte dort auch über 'Berliner Chaoten'.
- **Status:** `verifiziert` · **Kategorien:** Gender/Familie, Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.schwaebische.de/regional/bayern/soeder-und-aiwanger-heizen-anti-ampel-demo-an-viel-kritik-1678466>
- **Notizen:** EINZELQUELLE (dpa, hoch): Wortlaut im dpa-Text (Schwäbische, 10.06.2023) selbst geprüft; andere Berichte ohne diesen Satz. Aktuell (Stand Nov. 2026, nicht gesondert geprüft): Bayerischer Staatsminister für Wirtschaft, Landesentwicklung und Energie, stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler.

### Geschichte/NS-Relativierung

#### `aiwanger-04` – „Ich habe das fragliche Papier nicht verfasst und erachte den Inhalt als ekelhaft und menschenverachtend.“

- **Sprecher:** Hubert Aiwanger (Freie Wähler), damals: Bayerischer Wirtschaftsminister und stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler
- **Datum:** 2023-08-26
- **Kontext:** Schriftliche Stellungnahme, nachdem die Süddeutsche Zeitung über ein antisemitisches Flugblatt aus seiner Schulzeit berichtet hatte, das in seiner Schultasche gefunden worden war. Er ergänzte: 'Der Verfasser des Papiers ist mir bekannt, er wird sich selbst erklären.'
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://www.evangelisch.de/inhalte/220113/26-08-2023/wende-im-fall-aiwanger-bruder-bekennt-sich-zu-flugblatt> · <https://www.evangelisch.de/inhalte/220298/31-08-2023/aiwanger-weist-antisemitismus-vorwuerfe-erneut-von-sich>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut seiner Erklärung gesichert; strittig ist die Autorschaft des Flugblatts, nicht dieses Zitat. Kurz darauf erklärte sein Bruder Helmut Aiwanger: 'Ich bin der Verfasser dieses in der Presse wiedergegebenen Flugblatts.' Hubert Aiwanger räumte ein, bei ihm seien 'ein oder wenige Exemplare' in der Schultasche gefunden worden; ob er Exemplare weitergegeben habe, sei ihm 'heute nicht mehr erinnerlich'. Status 'umstritten' bezieht sich auf die öffentlich strittige Autorschaft, nicht auf den Wortlaut – im Spiel Hubert Aiwanger NICHT als Verfasser darstellen. Aktuell (Stand Nov. 2026, nicht gesondert geprüft): Bayerischer Staatsminister für Wirtschaft, Landesentwicklung und Energie, stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler.

#### `aiwanger-05` – „Ich bereue zutiefst, wenn ich durch mein Verhalten in Bezug auf das in Rede stehende Pamphlet oder weitere Vorwürfe gegen mich aus der Jugendzeit Gefühle verletzt habe“

- **Sprecher:** Hubert Aiwanger (Freie Wähler), damals: Bayerischer Wirtschaftsminister und stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler
- **Datum:** 2023-08-31
- **Kontext:** Pressestatement ohne Fragen in der Flugblatt-Affäre; Entschuldigung 'zuvorderst allen Opfern des NS-Regimes', verbunden mit dem Vorwurf einer 'politischen Kampagne' und Ablehnung eines Rücktritts.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://www.schwaebische.de/politik/aiwanger-bittet-um-entschuldigung-kein-ruecktritt-1869633> · <https://www.evangelisch.de/inhalte/220298/31-08-2023/aiwanger-weist-antisemitismus-vorwuerfe-erneut-von-sich>
- **Notizen:** Wortlaut nach Schwäbischer (dpa). Im selben Statement: 'Ich kann mich nicht erinnern, jemals einen Hitlergruß gezeigt zu haben.' (epd: '… je einen Hitlergruß …' – Variante beachten). Laut Berichten nannte Zentralrat-Präsident Schuster die Entschuldigung überfällig und nicht ausreichend; das Internationale Auschwitz Komitee sah keine echte Entschuldigung. Aktuell (Stand Nov. 2026, nicht gesondert geprüft): Bayerischer Staatsminister für Wirtschaft, Landesentwicklung und Energie, stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler.

#### `aiwanger-06` – „In meinen Augen wird hier die Schoah zu parteipolitischen Zwecken missbraucht“

- **Sprecher:** Hubert Aiwanger (Freie Wähler), damals: Bayerischer Wirtschaftsminister und stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler
- **Datum:** 2023-08-31
- **Kontext:** Interview mit der 'Welt' in der Flugblatt-Affäre, in dem er den Vorwurf einer Kampagne gegen ihn erneuerte.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung, Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.schwaebische.de/politik/aiwanger-bittet-um-entschuldigung-kein-ruecktritt-1869633> · <https://www.evangelisch.de/inhalte/220317/01-09-2023/antisemitismusbeauftragter-klein-aiwanger-schadet-der-erinnerungskultur>
- **Notizen:** Wörtlich in der Schwäbischen (dpa) geprüft; epd-Artikel nur in Suche gesehen. Schreibweise teils 'Schoa' (Jüdische Allgemeine). Antisemitismusbeauftragter Felix Klein: Aiwanger schade der Erinnerungskultur. Ebenfalls belegt: 'Ich habe den Eindruck, ich soll politisch und persönlich fertig gemacht werden.' Aktuell (Stand Nov. 2026, nicht gesondert geprüft): Bayerischer Staatsminister für Wirtschaft, Landesentwicklung und Energie, stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler.

### Demokratie/Medien

#### `aiwanger-01` – „Jetzt ist der Punkt erreicht, wo endlich die schweigende große Mehrheit dieses Landes sich die Demokratie wieder zurückholen muss und denen in Berlin sagen: Ihr habt's wohl den Arsch offen da oben“

- **Sprecher:** Hubert Aiwanger (Freie Wähler), damals: Bayerischer Wirtschaftsminister und stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler
- **Datum:** 2023-06-10
- **Kontext:** Rede auf der Kundgebung gegen das Heizungsgesetz der Ampel-Regierung in Erding, bei der auch Markus Söder sprach.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Klima · **kurz:** nein
- **Quellen:** <https://www.schwaebische.de/regional/bayern/soeder-und-aiwanger-heizen-anti-ampel-demo-an-viel-kritik-1678466> · <https://www.abendzeitung-muenchen.de/bayern/gruene-fordern-per-landtagsantrag-die-entlassung-von-aiwanger-art-907719> · <https://www.infranken.de/bayern/muenchen-aiwanger-wegen-vermeintlicher-rhetorik-der-afd-in-kritik-csu-geht-auf-distanz-art-5703602>
- **Notizen:** Vollständiger Satz nach Schwäbischer (dpa); Kernformel 'die schweigende große Mehrheit dieses Landes' auch bei AZ und inFranken. Das Landtagsprotokoll gibt die Stelle laut Suchergebnis als 'den A... offen' wieder. CSU nannte die Wortwahl 'leider unangemessen' (inFranken-Überschrift), Grüne forderten per Landtagsantrag seine Entlassung; Kritiker sahen AfD-Rhetorik. Aiwanger danach: 'Ich stehe zu diesem Satz.' Aktuell (Stand Nov. 2026, nicht gesondert geprüft): Bayerischer Staatsminister für Wirtschaft, Landesentwicklung und Energie, stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler.

### Sonstiges/Absurd

#### `aiwanger-03` – „Morgen ruft die AfD dazu auf, in Lederhose aufs Oktoberfest zu gehen, dann dürfte niemand mehr in Lederhose aufs Oktoberfest gehen - oder was?“

- **Sprecher:** Hubert Aiwanger (Freie Wähler), damals: Bayerischer Wirtschaftsminister und stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler
- **Datum:** 2023-06-12
- **Kontext:** Gegenüber dpa in München zur Verteidigung gegen den Vorwurf, seine Erdinger Formulierung ähnele AfD-Rhetorik; zuvor: 'Nur weil irgendwann mal ein AfD-ler etwas Ähnliches gesagt hat, ist das noch lange kein Tabu-Satz für jeden anderen.'
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd, Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.infranken.de/bayern/muenchen-aiwanger-wegen-vermeintlicher-rhetorik-der-afd-in-kritik-csu-geht-auf-distanz-art-5703602> · <https://www.abendzeitung-muenchen.de/bayern/gruene-fordern-per-landtagsantrag-die-entlassung-von-aiwanger-art-907719> · <https://www.nordkurier.de/politik/aiwanger-kontert-kritik-lasse-mich-nicht-mundtot-machen-1681945>
- **Notizen:** Quelle: dpa (inFranken vollständig, Nordkurier bestätigt 'Morgen ruft die AfD dazu auf, in Lederhose aufs Oktoberfest zu gehen'); beide Abdrucke derselben dpa-Meldung. Lederhosen-Satz wörtlich nur bei inFranken (dpa); der AfD-ler-Satz auch bei AZ (dort 'etwas ähnliches' kleingeschrieben). Aktuell (Stand Nov. 2026, nicht gesondert geprüft): Bayerischer Staatsminister für Wirtschaft, Landesentwicklung und Energie, stellvertretender Ministerpräsident, Bundesvorsitzender der Freien Wähler.

## Katherina Reiche (CDU)

*Aktuell (11/2026): Bundesministerin für Wirtschaft und Energie seit Mai 2025 (Stand 11/2026 nicht gesondert geprüft).*

### Sozialstaat/Arbeit

#### `reiche-01` – „Der demografische Wandel und die weiter steigende Lebenserwartung machen es unumgänglich: Die Lebensarbeitszeit muss steigen.“

- **Sprecher:** Katherina Reiche (CDU), damals: Bundesministerin für Wirtschaft und Energie
- **Datum:** 2025-07-26
- **Kontext:** Interview mit der Frankfurter Allgemeinen Zeitung; sie verwies darauf, die Deutschen arbeiteten im internationalen Vergleich wenig.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit, Wirtschaft/Kapital · **kurz:** nein
- **Quellen:** <https://www.evangelisch.de/inhalte/245910/25-07-2025/ministerin-reiche-wir-muessen-mehr-und-laenger-arbeiten> · <https://www.nordkurier.de/politik/kann-auf-dauer-nicht-gut-gehen-wirtschaftsministerin-reiche-mit-radikaler-forderung-an-rentner-3788833>
- **Notizen:** Schreibweise 'demografisch' (epd) bzw. 'demographisch' (dpa/Nordkurier). Kritik von SPD, DGB und CDA ('Fehlbesetzung'); Arbeitgeberpräsident Dulger lobte 'Klartext'. Aktuelle Funktion (Nov. 2026) nicht gesondert geprüft.

#### `reiche-02` – „Wir müssen mehr und länger arbeiten“

- **Sprecher:** Katherina Reiche (CDU), damals: Bundesministerin für Wirtschaft und Energie
- **Datum:** 2025-07-26
- **Kontext:** FAZ-Interview zur Lebensarbeitszeit; dazu der Satz, es könne auf Dauer nicht gut gehen, 'dass wir nur zwei Drittel unseres Erwachsenenlebens arbeiten und ein Drittel in Rente verbringen'.
- **Status:** `verifiziert` · **Kategorien:** Sozialstaat/Arbeit · **kurz:** ja
- **Quellen:** <https://www.nordkurier.de/politik/kann-auf-dauer-nicht-gut-gehen-wirtschaftsministerin-reiche-mit-radikaler-forderung-an-rentner-3788833> · <https://www.evangelisch.de/inhalte/245910/25-07-2025/ministerin-reiche-wir-muessen-mehr-und-laenger-arbeiten> · <https://www.zdfheute.de/politik/deutschland/arbeiten-rente-katharina-reiche-100.html>
- **Notizen:** Wörtlich bei dpa (Nordkurier) und zdfheute. Der Zwei-Drittel-Satz differiert: dpa 'Es kann jedenfalls auf Dauer nicht gut gehen …', epd ohne 'jedenfalls' – Variante kennzeichnen.

## Andreas Scheuer (CSU)

*Aktuell (11/2026): Ehem. CSU-Generalsekretär und Bundesverkehrsminister; aktuelle Funktion nicht geprüft.*

### Migration

#### `scheuer-01` – „Das Schlimmste ist ein fußballspielender, ministrierender Senegalese. Der ist drei Jahre hier - als Wirtschaftsflüchtling -, den kriegen wir nie wieder los.“

- **Sprecher:** Andreas Scheuer (CSU), damals: CSU-Generalsekretär
- **Datum:** 2016-09-15
- **Kontext:** Beim Regensburger Presseclub zu Schwierigkeiten bei Abschiebungen abgelehnter Asylbewerber.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sonstiges/Absurd · **kurz:** nein
- **Quellen:** <https://www.evangelisch.de/inhalte/138468/19-09-2016/csu-generalsekretaer-scheuer-stoesst-mit-aussage-zu-fluechtlingen-bei-kirchen-auf-ablehnung> · <https://www.evangelisch.de/inhalte/138465/19-09-2016/bedford-strohm-entsetzt-ueber-csu-aussage>
- **Notizen:** Datum: 'Donnerstag' vor dem 19.09.2016 = 15.09.2016 (erschlossen). Scheuer nannte den Satz danach 'eine bewusste Zuspitzung'. Scharfe Kritik der Kirchen (Bischof Hofmann: 'Wo bleibt hier noch das Christliche?'; EKD-Ratsvorsitzender Bedford-Strohm entsetzt). Beide Quellen epd. Später Bundesverkehrsminister (2018–2021, Pkw-Maut); aktuelle Funktion nicht geprüft.

## Alice Weidel (AfD)

*Aktuell (11/2026): Co-Bundesvorsitzende (bestätigt Erfurt, Juli 2026) und Co-Vorsitzende der AfD-Bundestagsfraktion.*

### Migration

#### `weidel-07` – „Das Jahr beginnt mit dem Zensurgesetz und der Unterwerfung unserer Behörden vor den importierten, marodierenden, grapschenden, prügelnden, Messer stechenden Migrantenmobs, an die wir uns gefälligst gewöhnen sollen.“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Vorsitzende der AfD-Bundestagsfraktion
- **Datum:** 2018-01-01
- **Kontext:** Social-Media-Beitrag zu Neujahr 2018, nachdem Twitter Beatrix von Storch wegen ihres Tweets über die Kölner Polizei gesperrt hatte (siehe storch-01).
- **Status:** `verifiziert` · **Kategorien:** Migration, Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_82980164/twitter-sperrt-beatrix-von-storchs-profil-wegen-hass-nachricht.html> · <https://de.euronews.com/2018/01/01/rassismus-und-hetze-auf-twitter-afd-vize-von-storch-angezeigt>
- **Notizen:** Zweiter Satz des Beitrags: 'Die deutsche Polizei kommuniziert mittlerweile auf Arabisch, obwohl die Amtssprache in unserem Land Deutsch ist.' Der parallel abgesetzte Tweet (bei Euronews eingebettet) lautet kürzer: 'Unsere Behörden unterwerfen sich importierten, marodierenden, grapschenden, prügelnden, Messer stechenden Migrantenmobs.' – Versionen nicht vermischen. 'Zensurgesetz' = NetzDG. Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion.

#### `weidel-01` – „Burkas, Kopftuchmädchen, alimentierte Messermänner und sonstige Taugenichtse werden unseren Wohlstand, das Wirtschaftswachstum und vor allem den Sozialstaat nicht sichern.“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Vorsitzende der AfD-Bundestagsfraktion
- **Datum:** 2018-05-16
- **Kontext:** Rede in der Generalaussprache zum Bundeshaushalt 2018 (Einzelplan Bundeskanzleramt), Deutscher Bundestag, 32. Sitzung der 19. Wahlperiode.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sozialstaat/Arbeit · **kurz:** nein
- **Quellen:** <https://dserver.bundestag.de/btp/19/19032.pdf> · <https://www.bundestag.de/dokumente/textarchiv/2018/kw20-de-einspruch-ordnungsruf-555494> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** Wortlaut nach Plenarprotokoll 19/32 (S. 2972); zwischen 'Taugenichtse' und 'werden' steht im Protokoll der Zwischenruf 'Ulli Nissen [SPD]: Was?'. Die Bundestags-Textarchivmeldung schreibt 'Kopftuchmädchen und alimentierte Messermänner' (mit 'und') – maßgeblich ist das Protokoll. Bundestagspräsident Schäuble erteilte einen Ordnungsruf ('Damit diskriminieren Sie alle Frauen, die ein Kopftuch tragen.'); Weidels Einspruch wurde am 17.05.2018 namentlich abgelehnt (549 Nein, 85 Ja, 2 Enthaltungen). Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion.

#### `weidel-02` – „Ihre eingewanderten Goldstücke etwa? Das glauben Sie doch wohl nicht im Ernst.“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Vorsitzende der AfD-Bundestagsfraktion
- **Datum:** 2018-05-16
- **Kontext:** Dieselbe Haushaltsrede; unmittelbar zuvor fragte Weidel, wer künftig für Renten und Pensionen aufkommen solle.
- **Status:** `verifiziert` · **Kategorien:** Migration, Sozialstaat/Arbeit · **kurz:** ja
- **Quellen:** <https://dserver.bundestag.de/btp/19/19032.pdf>
- **Notizen:** Primärquelle Plenarprotokoll 19/32, S. 2973 (A). Kein Ordnungsruf für diesen Satz. Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion.

#### `weidel-04` – „Und ich muss Ihnen ganz ehrlich sagen, wenn es dann Remigration heißen soll, dann heißt es eben Remigration.“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Bundessprecherin der AfD; am selben Tag zur Kanzlerkandidatin gewählt
- **Datum:** 2025-01-11
- **Kontext:** Rede auf dem AfD-Bundesparteitag in Riesa nach ihrer Wahl zur Kanzlerkandidatin; zuvor forderte sie 'Rückführungen im großen Stil'. Der Parteitag nahm den Begriff anschließend ins Wahlprogramm auf.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.stuttgarter-zeitung.de/politik/alice-weidel-auf-afd-parteitag-in-riesa-wenn-das-radikale-schleichend-normal-wird-79030329.html> · <https://taz.de/Remigration-ist-jetzt-Parteiraeson/!6058444/> · <https://taz.de/Weidel-zur-AfD-Kanzlerkandidatin-gewaehlt/!6061592> · <https://gotranscript.com/public/afd-parteitag-in-riesa-weidel-als-kanzlerkandidatin>
- **Notizen:** Vollständiger Satz in Stuttgarter Zeitung und im Transkript (gotranscript); taz zitiert ab 'Wenn es dann ...'. 'Remigration' war 2023 Unwort des Jahres. Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion.

### Wirtschaft/Kapital

#### `weidel-09` – „Eine Steuer, die gegen Null geht, stärkt die Familien, fördert den unternehmerischen Geist, stärkt den Mittelstand und macht nicht zuletzt den Wirtschaftsstandort Deutschland attraktiver.“

- **Sprecher:** Alice Weidel (AfD), damals: AfD-Bundesvorstandsmitglied
- **Datum:** 2016-02-15
- **Kontext:** AfD-Pressemitteilung 'Weidel: Reform der Erbschaftsteuer - Eine historische Chance für eine Abschaffung' (Berlin, 15.02.2016) zur Debatte um die Reform der Erbschaftsteuer. Weidel forderte darin, die Erbschaftsteuer ganz abzuschaffen, weil der Staat 'am erarbeiteten Privateinkommen und -vermögen doppelt verdient'.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital · **kurz:** nein
- **Quellen:** <https://www.afd.de/weidel-reform-der-erbschaftssteuer-eine-historische-chance-fuer-eine-abschaffung/> · <https://www.aktiencheck.de/exklusiv/Artikel-Weidel_AfD_Reform_Erbschaftssteuer_Eine_historische_Chance_fuer_eine_Abschaffung-7021961>
- **Notizen:** Primärquelle: Pressemitteilung auf afd.de, Wortlaut selbst von der Seite abgerufen und im Volltext geprüft. Zweitabdruck bei aktiencheck.de (nur Suchtreffer gesehen, nicht abgerufen). Eigene Erklärung Weidels (Pressemitteilung), keine Rede. Schlusssatz: 'Ich appelliere an die Vernunft aller im Bundestag vertretenen Parteien, diese historische Chance zu nutzen [...] und die Erbschaftsteuer abzuschaffen.' Weidel war 2016 Bundesvorstandsmitglied, noch nicht Parteichefin.

#### `weidel-10` – „Ich zahle hier meine Steuern“

- **Sprecher:** Alice Weidel (AfD), damals: AfD-Bundessprecherin und Kanzlerkandidatin
- **Datum:** 2025-02-16
- **Kontext:** RTL-'Quadrell' (Kampf ums Kanzleramt, u. a. mit Günther Jauch) auf die Frage nach ihrem Wohnsitz in der Schweiz (Einsiedeln, wo ihre Partnerin und die Kinder leben) und ihrer Steuerpflicht. Weidel verwies auf das Doppelbesteuerungsabkommen und gab Überlingen als deutschen Wohnsitz an.
- **Status:** `verifiziert` · **Kategorien:** Wirtschaft/Kapital · **kurz:** ja
- **Quellen:** <https://www.20min.ch/story/kanzlerduell-keine-steuern-alice-weidel-erklaert-ihre-schweizer-wohnsituation-103283171> · <https://politik.watson.de/politik/deutschland/570975740-alice-weidel-bezahlt-sie-in-der-schweiz-doch-steuern> · <https://www.blick.ch/ausland/versteuern-sie-alles-in-deutschland-alice-weidel-in-tv-debatte-wegen-schweiz-wohnsitz-unter-druck-id20598804.html>
- **Notizen:** Drei Medien (20 Minuten, watson, Blick) geben 'Ich zahle hier meine Steuern' wörtlich wieder. Längere Fassungen: 20 Minuten 'Ich zahle hier meine Steuern und bin nur als Fraktions- und Parteivorsitzende in Deutschland unterwegs, ich arbeite hier.'; Blick 'Ich habe meinen Wohnsitz in Deutschland. Ich zahle hier meine Steuern.'; watson zusätzlich 'Das ist völlig normal gemäß dem Doppelbesteuerungsabkommen' und 'Meine Frau ist Schweizerin. Dementsprechend hat sie ihren Wohnsitz in der Schweiz.' (nur watson). Sendung am Sonntag, 16.02.2025 (Artikel vom 17.02.2025). Mehrere Medien (CH Media, nume) berichteten später, sie zahle zumindest auf eine Schweizer Immobilie Steuern; das ist nicht Teil des Zitats. Fragment: ohne Video/Transkript nur der Kernsatz gesichert.

### Klima

#### `weidel-05` – „Nieder mit diesen Windmühlen der Schande!“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Bundessprecherin der AfD; Kanzlerkandidatin
- **Datum:** 2025-01-11
- **Kontext:** Parteitagsrede in Riesa; unmittelbar davor: 'Und ich kann Ihnen sagen, wenn wir am Ruder sind, wir reißen alle Windkraftwerke nieder.'
- **Status:** `verifiziert` · **Kategorien:** Klima · **kurz:** ja
- **Quellen:** <https://www.zdfheute.de/politik/deutschland/weidel-afd-windraeder-reinhardswald-windkraft-kritik-100.html> · <https://taz.de/Weidel-zur-AfD-Kanzlerkandidatin-gewaehlt/!6061592> · <https://taz.de/Remigration-ist-jetzt-Parteiraeson/!6058444/> · <https://gotranscript.com/public/afd-parteitag-in-riesa-weidel-als-kanzlerkandidatin>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; spätere Einschränkung (Reinhardswald) siehe Notizen. Wortlaut gesichert (ZDFheute; taz: 'Wenn wir am Ruder sind: Wir reißen alle Windkraftwerke nieder! Nieder mit diesen Windmühlen der Schande!'). Umstritten wegen späterer Einschränkung: Weidel sagte im ZDF heute journal, gemeint sei v. a. der für Windräder gerodete Reinhardswald in Hessen; Windkraft ohne Subventionen schloss sie nicht grundsätzlich aus (ZDFheute, 13.01.2025). Häufiger Fehler: NICHT 'Windräder der Schande' – es heißt 'Windmühlen der Schande'. Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion.

### Geschichte/NS-Relativierung

#### `weidel-03` – „Er war dieser kommunistische, sozialistische Typ. Punkt.“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Bundessprecherin der AfD und Co-Fraktionsvorsitzende; designierte Kanzlerkandidatin
- **Datum:** 2025-01-09
- **Kontext:** Live-Gespräch (X Space) mit Elon Musk auf dessen Plattform X, auf Englisch geführt; Weidel sprach über Adolf Hitler.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.juedische-allgemeine.de/politik/weidel-im-talk-mit-musk-hitler-war-ein-kommunist> · <https://www.stuttgarter-zeitung.de/panorama/alice-weidel-ueber-hitler-er-war-ein-sozialistischer-kommunistischer-typ-79153160.html> · <https://correctiv.org/faktencheck/2025/01/16/anders-als-von-alice-weidel-behauptet-war-hitler-kein-kommunist/> · <https://newrepublic.com/post/190065/elon-musk-german-far-right-afd-hitler-lies>
- **Notizen:** ACHTUNG ÜBERSETZUNG: Original auf Englisch; die deutsche Fassung ist die dpa-Übersetzung (übereinstimmend in Jüdischer Allgemeiner und Stuttgarter Zeitung). Im Spiel als '(übersetzt)' kennzeichnen. Weitere dpa-übersetzte Sätze: 'Er war dieser kommunistische, sozialistische Typ. Punkt.' und 'Und der größte Erfolg nach dieser schrecklichen Ära in unserer Geschichte war, Adolf Hitler als rechts und konservativ zu bezeichnen.' Englische Wiedergaben variieren je nach Medium (z. B. New Republic: 'He was a Communist socialist guy. Full stop.') – kein offizielles Transkript gefunden. Correctiv bewertete die Behauptung als falsch. Später (RTL/ntv) bekräftigte Weidel: 'Ich bin Ökonomin und für uns ist völlig klar, dass Adolf Hitler ein Linker war' (Stuttgarter Zeitung). Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion. VERIFIKATION 11/2026: Zitat ersetzt. Die frühere Fassung 'Er war ein Kommunist und sah sich selbst als Sozialisten.' steht nur in der Jüdischen Allgemeinen; die jetzige dpa-Übersetzung steht in Jüdischer Allgemeiner und Stuttgarter Zeitung. Weiterhin nur Übersetzung aus dem englischen Gespräch ('(übersetzt)' kennzeichnen), kein offizielles Transkript.

### Demokratie/Medien

#### `weidel-08` – „Denn die politische Korrektheit gehört auf den Müllhaufen der Geschichte.“

- **Sprecher:** Alice Weidel (AfD), damals: Mitglied des AfD-Bundesvorstands; auf dem Parteitag zur Spitzenkandidatin für die Bundestagswahl 2017 gewählt
- **Datum:** 2017-04-23
- **Kontext:** Rede auf dem AfD-Bundesparteitag in Köln; davor: 'Und wir werden uns als Demokraten und Patrioten trotz dessen nicht den Mund verbieten lassen.'
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.lto.de/recht/nachrichten/n/lg-hamburg-324o217-17-alice-weidel-afd-ndr-nazi-schlampe-satire> · <https://www.vice.com/de/article/ein-anwalt-erklart-wie-du-afd-politiker-korrekt-beleidigst/>
- **Notizen:** Datum: Bundesparteitag Köln 22./23.04.2017, Spitzenkandidatenwahl am 23.04. (genauer Redetag nicht separat geprüft). Folge: NDR-'extra 3'-Satire ('Nazi-Schlampe'); LG Hamburg wies Weidels Eilantrag ab (Beschl. v. 11.05.2017, 324 O 217/17), Weidel nahm die Beschwerde zurück. Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion.

#### `weidel-06` – „rot lackierte Nazis“

- **Sprecher:** Alice Weidel (AfD), damals: Co-Bundessprecherin der AfD; Kanzlerkandidatin
- **Datum:** 2025-01-11
- **Kontext:** In der Riesaer Parteitagsrede über die Gegendemonstranten vor der Halle.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://taz.de/Remigration-ist-jetzt-Parteiraeson/!6058444/> · <https://www.stuttgarter-zeitung.de/politik/alice-weidel-auf-afd-parteitag-in-riesa-wenn-das-radikale-schleichend-normal-wird-79030329.html> · <https://taz.de/Weidel-zur-AfD-Kanzlerkandidatin-gewaehlt/!6061592>
- **Notizen:** Nur als Wortfragment belegt (taz, Stuttgarter Zeitung); der vollständige Satz wurde nicht gefunden – im Spiel nur als Fragment in Anführungszeichen verwenden. Stand 11/2026: Co-Bundesvorsitzende der AfD (beim Bundesparteitag Erfurt am 4./5.7.2026 mit 81,3 % bestätigt) und Co-Vorsitzende der AfD-Bundestagsfraktion. VERIFIKATION 11/2026: taz schreibt 'rot-lackierte Nazis' (mit Bindestrich), Stuttgarter Zeitung und Transkript ohne; Wortlaut sonst gleich. Nur als Fragment verwenden, nicht als Satz.

## Björn Höcke (AfD)

*Aktuell (11/2026): Landessprecher der AfD Thüringen, Fraktionsvorsitzender im Thüringer Landtag; rechtskräftig verurteilt wegen Verwendens der SA-Losung (BGH 2025).*

### Migration

#### `hoecke-06` – „lebensbejahende afrikanische Ausbreitungstyp … selbstverneinenden europäischen Platzhaltertyp“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2015-11
- **Kontext:** Vortrag beim rechten 'Institut für Staatspolitik' in Schnellroda (Ende November 2015) über Asyl und Bevölkerungsentwicklung.
- **Status:** `verifiziert` · **Kategorien:** Migration, Gender/Familie · **kurz:** ja
- **Quellen:** <https://www.lto.de/recht/nachrichten/n/bjoern-hoecke-afd-umstrittene-aeusserungen> · <https://web.de/magazine/politik/afd-landeschef-bjoern-hoecke-krassesten-fehltritte-31207182> · <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Notizen:** Nur die beiden Begriffe sind wörtlich belegt (LTO, web.de/dpa); der vollständige Satz wurde nicht verifiziert. Schreibweisen variieren ('Ausbreitungstyp'/'Ausbreitungstypus'). Der AfD-Bundesvorstand rügte Höcke; Strafanzeigen wegen Volksverhetzung u. a. wegen Äußerungen zum afrikanischen 'Reproduktionsüberschuss'. Im Spiel nur als Begriffsfragmente verwenden. Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

#### `hoecke-08` – „Unsere Jugend haben die böswilligen Gutmenschen in den Kindergärten, Schulen und Universitäten zu Schafen gemacht, während sie jetzt dabei sind, die Wölfe ins Land zu lassen.“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2018-06-17
- **Kontext:** Äußerung vom 17.06.2018, vom VG Köln als Beleg dafür angeführt, dass Höcke Geflüchtete pauschal als 'Wölfe' bezeichnet; der Anlass wird im Urteil nicht genannt.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Notizen:** Quelle: Gerichtsurteil (primärnah, hoch). Einzige Quelle: VG-Köln-Urteil (zitiert BfV-Belegsammlung I Bl. 1985, 1996). Nicht verwechseln mit dem häufig zitierten, hier NICHT verifizierten Satz 'Heute lautet die Frage: Schaf oder Wolf ...' (siehe afd_extra.json/unverifiziert). Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

#### `hoecke-04` – „Ja, neben dem Schutz unserer nationalen und europäischen Außengrenzen wird ein großangelegtes Remigrationsprojekt notwendig sein. Und bei dem wird man, so fürchte ich, nicht um eine Politik der 'wohltemperierten Grausamkeit', wie es Peter Sloterdijk nannte, herumkommen. Das heißt, daß sich menschliche Härten und unschöne Szenen nicht immer vermeiden lassen werden.“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2018-07
- **Kontext:** Aus dem Gesprächsband 'Nie zweimal in denselben Fluß' (Interview mit Sebastian Hennig, Manuscriptum 2018), S. 254.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.spiegel.de/politik/deutschland/rechtsextreme-in-der-afd-so-sprechen-fluegel-anfuehrer-hoecke-und-seine-leute-a-98188c22-71b5-4b56-8d0c-a21f4bcef2e1> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf> · <https://taz.de/Studie-zur-AfD/!5939276/> · <https://www.juedische-allgemeine.de/politik/bjoern-hoecke-ist-die-praegendste-figur-fuer-die-afd-ideologie/>
- **Notizen:** Wortlaut nach Spiegel (12.03.2020); DIMR gibt dieselbe Passage mit Seitenangabe S. 254 und Auslassung '[…]' statt 'wie es Peter Sloterdijk nannte'. Alte Rechtschreibung 'daß' wie im Buch. Kurzform fürs Spiel: 'wohltemperierte Grausamkeit' – Begriff von Sloterdijk entlehnt, nicht als Höckes Wortschöpfung darstellen. Erscheinen Juli 2018 laut VG-Meiningen-Zusammenfassung im VG-Köln-Urteil (eine taz-Meldung nennt fälschlich 2019). Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

#### `hoecke-05` – „Auch wenn wir leider ein paar Volksteile verlieren werden, die zu schwach oder nicht willens sind, sich der fortschreitenden Afrikanisierung, Orientalisierung und Islamisierung zu widersetzen.“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2018-07
- **Kontext:** Gesprächsband 'Nie zweimal in denselben Fluß' (2018), laut DIMR S. 255–258; im Kontext eines erhofften 'neuen Kapitels unserer Geschichte'.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf> · <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html> · <https://www.juedische-allgemeine.de/politik/bjoern-hoecke-ist-die-praegendste-figur-fuer-die-afd-ideologie/>
- **Notizen:** Wortgleich im VG-Köln-Urteil (13 K 326/21) und in der DIMR-Analyse. Anschluss im Buch: 'Aber abgesehen von diesem möglichen Aderlaß haben wir Deutschen in der Geschichte nach dramatischen Niedergängen eine außergewöhnliche Renovationskraft gezeigt.' Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

### Geschichte/NS-Relativierung

#### `hoecke-01` – „Wir Deutschen – und ich rede jetzt nicht von euch Patrioten, die sich hier heute versammelt haben – wir Deutschen, also unser Volk, sind das einzige Volk der Welt, das sich ein Denkmal der Schande in das Herz seiner Hauptstadt gepflanzt hat.“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2017-01-17
- **Kontext:** Rede bei den 'Dresdner Gesprächen' der Jungen Alternative im Ballhaus Watzke in Dresden; gemeint war nach allgemeiner Lesart das Holocaust-Mahnmal in Berlin.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://www.tagesspiegel.de/politik/19273518.html> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; Höckes spätere Umdeutung siehe Notizen. Wortlaut gesichert (Tagesspiegel-Volltext vom 19.01.2017; DIMR zitiert die Kernstelle). Verbreitete Kurzfassung ohne Einschub: 'Wir Deutschen, also unser Volk, sind das einzige Volk der Welt, das sich ein Denkmal der Schande in das Herz seiner Hauptstadt gepflanzt hat.' – bei Kürzung den Einschub mit '[…]' markieren. Umstritten: Höcke erklärte später, er habe den Holocaust als Schande bezeichnet, nicht das Mahnmal; die taz und andere halten die Mahnmal-Lesart für eindeutig. Falschzitat-Warnung: Er sagte 'Denkmal der Schande', nicht 'Schandmal'. Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

#### `hoecke-02` – „Wir brauchen nichts anderes als erinnerungspolitische Wende um 180 Grad!“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2017-01-17
- **Kontext:** Dieselbe Dresdner Rede; Kernforderung nach einer Umkehr der deutschen Erinnerungskultur.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/politik/19273518.html> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf> · <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Notizen:** Wortlaut exakt wie Tagesspiegel-Transkript (ohne 'eine'); das DIMR zitiert mit Ergänzung '[eine]'. Eine zweite Stelle derselben Rede: 'Wir brauchen so dringend wie niemals zuvor diese erinnerungspolitische Wende um 180 Grad, liebe Freunde.' Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag. VERIFIKATION 11/2026: Wortlaut ohne 'eine' bestätigt. Drei voneinander unabhängige Transkripte (Tagesspiegel-Dokumentation, brightsblog-Transkript, geschichte-und-politik.info nach YouTube-Mitschnitt) haben übereinstimmend 'Wir brauchen nichts anderes als erinnerungspolitische Wende um 180 Grad!'; später in der Rede 'diese erinnerungspolitische Wende um 180 Grad'. Das 'eine' stammt aus Überschrift und Anmoderation der Tagesspiegel-Dokumentation, nicht aus der Rede. Das DIMR klammert '[eine]' grammatisch ein. Eine eigene Prüfung am Videoton steht aus.

#### `hoecke-03` – „Und diese dämliche Bewältigungspolitik, die lähmt uns heute noch viel mehr als zu Franz Josef Strauß’ Zeiten.“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2017-01-17
- **Kontext:** Dieselbe Dresdner Rede, mit Bezug auf die Aufarbeitung der NS-Zeit.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/politik/19273518.html> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** Tagesspiegel-Volltext; DIMR zitiert gekürzt ('die lähmt uns heute […]'). Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

#### `afd-hoecke-11` – „Bis jetzt ist unsere Geistesverfassung, unser Gemütszustand immer noch der eines total besiegten Volkes.“

- **Sprecher:** Björn Höcke (AfD), damals: AfD-Landes- und Fraktionsvorsitzender in Thüringen
- **Datum:** 2017-01-17
- **Kontext:** Rede bei den 'Dresdner Gesprächen' der Jungen Alternative im Ballhaus Watzke, Dresden - dieselbe Rede, in der er das Holocaust-Mahnmal 'Denkmal der Schande' nannte und eine 'erinnerungspolitische Wende um 180 Grad' forderte.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/politik/19273518.html> · <https://www.tagesspiegel.de/politik/der-totale-hocke-4912966.html>
- **Notizen:** Wortlaut nach Tagesspiegel (abgerufen: 19273518). ACHTUNG Variante: Die Jüdische Allgemeine zitiert laut Suchzusammenfassung 'brutal besiegten' statt 'total besiegten'; 'total' ist durch die Tagesspiegel-Transkription belegt, Original-Video nicht selbst geprüft. Ergänzt hoecke-01 bis -03 (gleiche Rede, anderer Satz). Zweiter Tagesspiegel-Link nur aus Suchtreffer, nicht abgerufen; vor Release am besten Video gegenprüfen.

#### `hoecke-09` – „Alles für Deutschland“

- **Sprecher:** Björn Höcke (AfD), damals: Vorsitzender der AfD-Fraktion im Thüringer Landtag
- **Datum:** 2021-05-29
- **Kontext:** KONTEXT-EINTRAG (Strafurteil): Höcke verwendete die verbotene SA-Losung bei einer Wahlkampfrede in Merseburg (Sachsen-Anhalt). Am 12.12.2023 rief er bei einem AfD-'Stammtisch' in Gera 'Alles für' und forderte das Publikum mit Gesten zur Vervollständigung auf.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.beck-aktuell.de/heute-im-recht/rechtsprechung/bgh-3str48424-3str51924-hoecke-revisionen-sa-parole-2025-09-11> · <https://www.zdfheute.de/politik/deutschland/bjoern-hoecke-afd-urteil-ns-parole-bgh-100.html> · <https://www.evangelisch.de/inhalte/231410/01-07-2024/hoecke-wegen-sa-parole-erneut-verurteilt>
- **Notizen:** KONTEXT-EINTRAG (kein Politikerzitat für Sprechblasen; für Album/Ladebildschirm-Infotext). LG Halle, 14.05.2024: Geldstrafe 100 Tagessätze à 130 € (13.000 €) wegen Verwendens von Kennzeichen verfassungswidriger Organisationen (§ 86a StGB), Fall Merseburg. LG Halle, 01.07.2024: 130 Tagessätze à 130 € (16.900 €), Fall Gera; laut Gerichtssprecher wäre bei Rechtskraft beider Urteile eine Gesamtstrafe zu bilden. BGH verwarf beide Revisionen (Beschlüsse v. 20.08.2025, 3 StR 484/24 und 3 StR 519/24, bekannt 11.09.2025) – Urteile rechtskräftig. Höcke bestritt stets, die Parole gekannt zu haben. Präzision: In Gera sprach er nur 'Alles für' selbst. Den genauen Merseburger Satzzusammenhang nicht verifiziert – nur die Parole selbst verwenden. Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

### Demokratie/Medien

#### `hoecke-10` – „ihr Werturteil nicht aus der Luft gegriffen ist, sondern auf einer überprüfbaren Tatsachengrundlage beruht“

- **Sprecher:** Verwaltungsgericht Meiningen (zu Björn Höcke) (—), damals: Höcke: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2019-09-26
- **Kontext:** KONTEXT-EINTRAG (Gerichtsbeschluss): Im Eilverfahren hob das VG Meiningen eine Auflage der Stadt Eisenach auf, die verbieten sollte, Höcke auf einer Gegendemonstration ('Protest gegen die rassistische AfD, insbesondere gegen den Faschisten Höcke') 'Faschist' zu nennen.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.lto.de/recht/nachrichten/n/vg-meiningen-2-e-jj94-19-me-bjoern-hoecke-faschist-afd-gegendemonstration> · <https://www.lto.de/recht/nachrichten/n/lg-hamburg-324o103-20-einstweilige-verfuegung-aeusserung-hoecke-gerichtlich-zum-faschisten-erklaert> · <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Notizen:** KLARSTELLUNG 11/2026: Höcke im Spiel als Faschisten zu bezeichnen ist als eigene Meinung (Werturteil) zulässig. Nur nie behaupten, ein Gericht habe ihn als Faschisten eingestuft oder festgestellt. KONTEXT-EINTRAG (kein Politikerzitat für Sprechblasen; für Album/Ladebildschirm-Infotext). Das Zitat ist Wortlaut des Beschlusses (über die Demonstranten), nicht Höckes. RECHTLICHE WARNUNG: Das LG Hamburg untersagte am 16.03.2020 (324 O 103/20, einstweilige Verfügung auf Höckes Antrag gegen Sebastian Czaja) die Behauptung, ein Gericht habe Höcke als Faschisten eingestuft – das VG habe nur über die Zulässigkeit einer konkreten Meinungsäußerung in einem konkreten Kontext entschieden. Im Spiel also z. B.: 'Ein Gericht entschied 2019, dass Demonstranten Höcke in diesem Kontext Faschist nennen durften' – NICHT 'Höcke ist gerichtlich festgestellt ein Faschist'. Aktenzeichen bei LTO als '2 E JJ94/19 Me' wiedergegeben (wohl Tippfehler; nicht primär geprüft). Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

### Sonstiges/Absurd

#### `hoecke-07` – „Wenn alle Stricke reißen, ziehen wir uns wie einst die tapfer-fröhlichen Gallier in unsere ländlichen Refugien zurück und die neuen Römer, die in den verwahrlosten Städten residieren, können sich an den teutonischen Asterixen und Obelixen die Zähne ausbeißen!“

- **Sprecher:** Björn Höcke (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Thüringen
- **Datum:** 2018-07
- **Kontext:** Gesprächsband 'Nie zweimal in denselben Fluß' (2018); Höcke beschreibt die 'strategische Option der gallischen Dörfer' als Rückzug, aus dem später eine 'Rückeroberung' werden könne.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd, Migration · **kurz:** nein
- **Quellen:** <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Notizen:** Quelle: Gerichtsurteil (primärnah, hoch); Buch selbst nicht eingesehen. Einzige Quelle, aber Primärcharakter: wörtliche Wiedergabe im Urteil des VG Köln vom 08.03.2022 (13 K 326/21), das aus der BfV-Belegsammlung zitiert; Buch selbst nicht eingesehen. Davor: 'Dann haben wir immer noch die strategische Option der ‚gallischen Dörfer‘.' Stand 11/2026: Landessprecher der AfD Thüringen und Vorsitzender der AfD-Fraktion im Thüringer Landtag.

## Alexander Gauland (AfD)

*Aktuell (11/2026): MdB, Ehrenvorsitzender der AfD und der Bundestagsfraktion.*

### Migration

#### `gauland-03` – „Die Leute finden ihn als Fußballspieler gut. Aber sie wollen einen Boateng nicht als Nachbarn haben.“

- **Sprecher:** Alexander Gauland (AfD), damals: Stellvertretender Bundessprecher der AfD; Fraktionsvorsitzender im Landtag Brandenburg
- **Datum:** 2016-05-29
- **Kontext:** So zitiert von der Frankfurter Allgemeinen Sonntagszeitung (Ausgabe 29.05.2016) aus einem Gespräch mit zwei Redakteuren über den Nationalspieler Jérôme Boateng.
- **Status:** `umstritten` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/sport/boateng-fur-gaulands-aussage-ist-kein-platz-in-diesem-land-6985063.html> · <https://www.evangelisch.de/inhalte/134989/31-05-2016/gauland-rechtfertigt-sich-mail-afd-mitglieder> · <https://www.abendzeitung-muenchen.de/promis/twitter-reaktionen-alle-wollen-boateng-als-nachbarn-art-344179>
- **Notizen:** BLEIBT 'umstritten', weil: Gauland bestritt zunächst und stellt den Kontext in Frage (vertrauliches Gespräch, Name Boateng von den Journalisten eingebracht) – Zuschreibung teilweise strittig. Wortlaut wie von der FAS veröffentlicht, übereinstimmend zitiert. Umstritten: Gauland dementierte zunächst, räumte dann ein, 'Dabei mag das Zitat von der Nachbarschaft gefallen sein'; er nannte es ein vertrauliches Hintergrundgespräch, der Name Boateng sei wohl von den Journalisten gekommen, und die FAS-Überschrift 'Gauland beleidigt Boateng' sei nicht gedeckt. FAS-Redakteur Eckart Lohse widersprach. Im Spiel als 'laut FAS' kennzeichnen. Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021).

#### `gauland-05` – „Das sagt eine Deutsch-Türkin. Ladet sie mal ins Eichsfeld ein und sagt ihr dann, was spezifisch deutsche Kultur ist. Danach kommt sie hier nie wieder her, und wir werden sie dann auch, Gott sei Dank, in Anatolien entsorgen können.“

- **Sprecher:** Alexander Gauland (AfD), damals: Spitzenkandidat der AfD zur Bundestagswahl 2017; stellvertretender Bundessprecher
- **Datum:** 2017-08
- **Kontext:** Wahlkampfrede im thüringischen Eichsfeld (Wochenende vor dem 28.08.2017) über die damalige Integrationsbeauftragte Aydan Özoğuz (SPD), die gesagt hatte, eine spezifisch deutsche Kultur sei jenseits der Sprache nicht identifizierbar.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.leinetal24.de/welt/afd-mann-gauland-will-spd-politikerin-oezoguz-in-tuerkei-entsorgen-zr-8632666.html> · <https://www.tagesspiegel.de/politik/gauland-will-integrationsbeauftragte-ozoguz-in-anatolien-entsorgen-4535902.html> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; Gauland rückte später nur vom Wort 'entsorgen' ab, bestritt es aber nicht. Wortlaut zuerst von der FAZ berichtet; identisch bei dpa (leinetal24) und im DIMR (zitiert Tagesspiegel). leinetal24 schreibt 'Deutschtürkin'. Umstritten: Gauland sagte zunächst, er erinnere sich nicht an das Wort; später, er beharre nicht auf 'entsorgen', es sei 'kein gutes Wort', blieb aber in der Sache dabei. Özoğuz stammt aus Hamburg (Regierungssprecher Seibert). Ein Ermittlungsverfahren wegen Volksverhetzung wurde laut Medienberichten 2018 eingestellt (nicht primär geprüft). Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021).

### Geschichte/NS-Relativierung

#### `gauland-06` – „Wenn die Franzosen zu Recht stolz auf ihren Kaiser sind und die Briten auf Nelson und Churchill, haben wir das Recht, stolz zu sein auf die Leistungen deutscher Soldaten in zwei Weltkriegen.“

- **Sprecher:** Alexander Gauland (AfD), damals: Spitzenkandidat der AfD zur Bundestagswahl 2017; stellvertretender Bundessprecher
- **Datum:** 2017-09-02
- **Kontext:** Rede beim Kyffhäusertreffen des völkischen AfD-'Flügels' am Kyffhäuser-Denkmal (Thüringen); das Video wurde Mitte September bekannt.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://www.berliner-zeitung.de/article/afd-spitzenkandidat-gauland-provoziert-mit-wehrmacht-neubewertung-67933> · <https://www.leinetal24.de/welt/afd-mann-gauland-man-muss-uns-ns-zeit-nicht-mehr-vorhalten-zr-8686062.html> · <https://www.news4teachers.de/2017/09/afd-chef-gauland-fordert-ein-neues-geschichtsbild-fuer-deutschland-wir-haben-das-recht-stolz-zu-sein-auf-die-leistungen-deutscher-soldaten-in-zwei-weltkriegen/> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** Einleitung im Original: 'Und deshalb, liebe Freunde, haben wir auch das Recht, uns nicht nur unser Land, sondern auch unsere Vergangenheit zurückzuholen.' Einige Agenturtexte lassen 'die' vor 'Leistungen' weg. Gauland verteidigte sich später, er bestreite nicht, dass die Wehrmacht in Verbrechen verwickelt gewesen sei. Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021).

#### `gauland-07` – „Man muss uns diese zwölf Jahre jetzt nicht mehr vorhalten. Sie betreffen unsere Identität heute nicht mehr. Und das sprechen wir auch aus.“

- **Sprecher:** Alexander Gauland (AfD), damals: Spitzenkandidat der AfD zur Bundestagswahl 2017; stellvertretender Bundessprecher
- **Datum:** 2017-09-02
- **Kontext:** Dieselbe Kyffhäuser-Rede, mit Bezug auf die NS-Herrschaft 1933–1945.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.leinetal24.de/welt/afd-mann-gauland-man-muss-uns-ns-zeit-nicht-mehr-vorhalten-zr-8686062.html> · <https://www.news4teachers.de/2017/09/afd-chef-gauland-fordert-ein-neues-geschichtsbild-fuer-deutschland-wir-haben-das-recht-stolz-zu-sein-auf-die-leistungen-deutscher-soldaten-in-zwei-weltkriegen/>
- **Notizen:** dpa-Fassung (leinetal24) mit 'jetzt'; news4teachers ohne 'jetzt' ('Man muss uns diese zwölf Jahre nicht mehr vorhalten.') – Abweichung eines Worts; im Zweifel ohne 'jetzt' kürzen oder '[jetzt]' setzen. Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021).

#### `gauland-01` – „Hitler und die Nazis sind nur ein Vogelschiss in über 1000 Jahren erfolgreicher deutscher Geschichte.“

- **Sprecher:** Alexander Gauland (AfD), damals: Bundessprecher (Co-Vorsitzender) der AfD und Co-Vorsitzender der AfD-Bundestagsfraktion
- **Datum:** 2018-06-02
- **Kontext:** Rede beim Bundeskongress der Jungen Alternative im thüringischen Seebach; der Satz folgte auf ein Bekenntnis zur Verantwortung für die NS-Zeit.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/vogelschiss-staatsanwaltschaft-stellt-ermittlungen-wegen-gegen-alexander-gauland-ein-24472> · <https://www.berliner-zeitung.de/article/vogelschiss-aeusserung-gauland-denkt-nicht-an-entschuldigung-29043> · <https://taz.de/Gaulands-Relativierung-der-NS-Zeit/!5510144/> · <https://www.tagesspiegel.de/politik/alexander-gauland-und-der-vogelschiss-3958210.html> · <https://www.tagesspiegel.de/politik/vogelschiss-ausserung-war-politisch-unklug-5524372.html> · <https://dserver.bundestag.de/btp/20/20209.pdf>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; Distanzierung siehe Notizen. Wortlaut gesichert (Berliner Zeitung, taz; taz schreibt '1.000'). Umstritten wegen späterer Distanzierung: Gauland bedauerte 'die entstandene Wirkung', er habe seine 'tiefste Verachtung' ausdrücken wollen; am 09.06.2018 nannte er die Äußerung 'missdeutbar und damit politisch unklug'. Die Staatsanwaltschaft Meiningen stellte Ermittlungen ein (Meinungsfreiheit; Metapher mehrdeutig). FALSCHZITAT-WARNUNG: Es heißt 'Vogelschiss', NICHT 'Fliegenschiss' – Friedrich Merz sagte am 29.01.2025 im Bundestag 'Das war Ihr Fliegenschiss, von dem Sie vor Jahr und Tag gesprochen haben' (Plenarprotokoll 20/209), worauf Stephan Brandner rief: 'Er hat nicht „Fliegenschiss“ gesagt! Herr Gauland hat nie „Fliegenschiss“ gesagt!' Auch die Variante 'in unserer über 1000jährigen Geschichte' (so in einer Sekundärquelle) ist ungenau. Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021).

#### `gauland-02` – „Wir haben eine ruhmreiche Geschichte – und die, liebe Freunde, dauerte länger als die verdammten zwölf Jahre.“

- **Sprecher:** Alexander Gauland (AfD), damals: Bundessprecher (Co-Vorsitzender) der AfD und Co-Vorsitzender der AfD-Bundestagsfraktion
- **Datum:** 2018-06-02
- **Kontext:** Dieselbe Rede in Seebach; vorher: 'Ja, wir bekennen uns zur Verantwortung für die zwölf Jahre' (taz).
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://taz.de/Gaulands-Relativierung-der-NS-Zeit/!5510144/> · <https://www.tagesspiegel.de/politik/alexander-gauland-und-der-vogelschiss-3958210.html>
- **Notizen:** Wortgleich in taz und Tagesspiegel. Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021).

### Demokratie/Medien

#### `gauland-04` – „Wir werden sie jagen! […] und wir werden uns unser Land und unser Volk zurückholen!“

- **Sprecher:** Alexander Gauland (AfD), damals: Spitzenkandidat der AfD zur Bundestagswahl 2017; stellvertretender Bundessprecher
- **Datum:** 2017-09-24
- **Kontext:** Auftritt am Abend der Bundestagswahl 2017 vor Anhängern in Berlin, adressiert an die künftige Bundesregierung.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.spiegel.de/politik/deutschland/afd-alexander-gauland-wir-werden-frau-merkel-jagen-a-1169598.html> · <https://www.heidelberg24.de/politik-und-wirtschaft/bundestagswahl-2017-gauland-kuendigt-an-afd-will-frau-merkel-jagen-zr-8713172.html> · <https://www.revierpassagen.de/46024/jagdszenen-in-deutschland-zum-abend-der-bundestagswahl/20170924_2050> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** 'Wir werden sie jagen' (dpa/heidelberg24, Revierpassagen) und 'Wir werden uns unser Land und unser Volk zurückholen' (DIMR; Spiegel/dpa als 'unser Land und unser Volk zurückholen') mehrfach belegt. Die ausgelassene Mitte lautet nach Tagesspiegel/Buchauszug (nur in Suchergebnissen gesehen, nicht selbst abgerufen) 'Wir werden Frau Merkel oder wen auch immer jagen' – erst nach Prüfung verwenden. Davor sagte er laut Buchauszug sinngemäß, die Regierung könne sich 'warm anziehen'. Sicherste Kurzform: 'Wir werden sie jagen.' Die Spiegel-Überschrift 'Wir werden Frau Merkel jagen' ist eine Verkürzung. Frauke Petry kritisierte die Wortwahl. Stand 11/2026: Mitglied des Bundestages (21. WP, Wahlkreis 161 Chemnitz), Ehrenvorsitzender der AfD (seit 2019) und der AfD-Bundestagsfraktion (seit 2021). VERIFIKATION 11/2026: Zitat näher am Original gesetzt (Buchauszug: 'Wir werden sie jagen! Wir werden Frau Merkel oder wen auch immer jagen und wir werden uns unser Land und unser Volk zurückholen!'); die Auslassung ersetzt 'Wir werden Frau Merkel oder wen auch immer jagen'. Kurzform fürs Spiel bleibt 'Wir werden sie jagen.'

## Tino Chrupalla (AfD)

*Aktuell (11/2026): Co-Bundesvorsitzender und Co-Vorsitzender der AfD-Bundestagsfraktion.*

### Europa

#### `chrupalla-01` – „Mir hat er nichts getan. Ich sehe keine Gefahr für Deutschland aktuell durch Russland.“

- **Sprecher:** Tino Chrupalla (AfD), damals: Co-Bundessprecher der AfD und Co-Vorsitzender der AfD-Bundestagsfraktion
- **Datum:** 2025-11-11
- **Kontext:** ZDF-Talkshow 'Markus Lanz', auf die Frage, was er an Wladimir Putin kritisiere.
- **Status:** `verifiziert` · **Kategorien:** Europa, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/afd-chef-chrupalla-verteidigt-wladimir-putin-keine-gefahr-fuer-deutschland-aktuell-durch-russland-10005205> · <https://www.berliner-kurier.de/article/chrupalla-bei-lanz-10005221> · <https://www.zdfheute.de/politik/deutschland/chrupalla-russland-aussagen-putin-entspannungspolitik-100.html>
- **Notizen:** Wortgleich bei Berliner Zeitung und Berliner Kurier. Die Berliner Zeitung zitiert zusätzlich: 'Putin hat noch nicht mal gedroht, Deutschland mit der Atombombe anzugreifen' (Kurier nur sinngemäß). Varianten in Überschriften – 'Mir hat Putin nichts getan' (Kurier) bzw. 'Putin hat mir persönlich nichts getan' (ZDF-Frageformulierung) – sind NICHT der Wortlaut. Im ZDF-Morgenmagazin (12./13.11.2025) hielt er daran fest: Er bezwecke 'ganz klar eine Entspannungspolitik'. Kritik auch aus der eigenen Partei. Stand 11/2026: Co-Bundesvorsitzender der AfD (Erfurt, 4./5.7.2026 mit ca. 70 % bestätigt) und Co-Vorsitzender der AfD-Bundestagsfraktion; MdB (Görlitz). VERIFIKATION 11/2026: Satz 1 und 2 wortgleich bei Berliner Zeitung, Berliner Kurier und web.de. zdfheute formuliert den zweiten Satz anders ('Ich sehe aktuell durch Russland keine Gefahr für Deutschland.'), vermutlich Paraphrase. Sicherste Kurzform: 'Mir hat er nichts getan.'

#### `chrupalla-02` – „Jeder hat sein Kiesewetter und das ist der Herr Kiesewetter Russlands.“

- **Sprecher:** Tino Chrupalla (AfD), damals: Co-Bundessprecher der AfD und Co-Vorsitzender der AfD-Bundestagsfraktion
- **Datum:** 2025-11-11
- **Kontext:** Bei 'Markus Lanz' über Dmitri Medwedew, den Vizechef des russischen Sicherheitsrats, im Vergleich mit dem CDU-Außenpolitiker Roderich Kiesewetter.
- **Status:** `verifiziert` · **Kategorien:** Europa, Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.berliner-zeitung.de/article/afd-chef-chrupalla-verteidigt-wladimir-putin-keine-gefahr-fuer-deutschland-aktuell-durch-russland-10005205> · <https://www.berliner-kurier.de/article/chrupalla-bei-lanz-10005221>
- **Notizen:** Auf Lanz' Nachfrage ('Im Ernst jetzt?') laut Kurier: 'Warum nicht? Natürlich!' und 'Das ist genauso Propaganda wie Herr Kiesewetter hier!' (Berliner Zeitung kürzer: 'Das ist genauso Propaganda.'). Stand 11/2026: Co-Bundesvorsitzender der AfD (Erfurt, 4./5.7.2026 mit ca. 70 % bestätigt) und Co-Vorsitzender der AfD-Bundestagsfraktion; MdB (Görlitz).

### Sonstiges/Absurd

#### `chrupalla-04` – „Heinrich Heine.“

- **Sprecher:** Tino Chrupalla (AfD), damals: Co-Bundessprecher der AfD; Spitzenkandidat zur Bundestagswahl 2021
- **Datum:** 2021-09
- **Kontext:** Interview mit dem 13-jährigen Kinderreporter Alexander für ZDF 'logo!' vor der Bundestagswahl 2021. Chrupalla hatte mehr deutsche Volkslieder und Gedichte im Unterricht gefordert, konnte aber auf Nachfrage kein Lieblingsgedicht nennen; erst auf die Frage nach dem Lieblingsdichter antwortete er so.
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://www.juedische-allgemeine.de/meinung/ausgerechnet-heine/> · <https://www.yahoo.com/news/far-leader-germany-caught-child-123715421.html> · <https://www.turi2.de/aktuell/lese-tipp-wie-kinderreporter-alexander-afd-mann-chrupalla-aus-dem-konzept-brachte/>
- **Notizen:** Antwort 'Heinrich Heine' belegt durch Jüdische Allgemeine (13.09.2021) und The Independent (via Yahoo, 16.09.2021). Seine stockende Antwort zum Gedicht ist nur in englischer Übersetzung belegt ('My favourite poem is, uh, I have to, I should think about it now, I can't think of any.') – deutschen Originalwortlaut NICHT erfinden. Pointe der Berichterstattung: ausgerechnet Heine, Spötter über deutschen Nationalismus. Genaues Ausstrahlungsdatum nicht geprüft (Clip kursierte ab ca. 11.09.2021). Stand 11/2026: Co-Bundesvorsitzender der AfD (Erfurt, 4./5.7.2026 mit ca. 70 % bestätigt) und Co-Vorsitzender der AfD-Bundestagsfraktion; MdB (Görlitz).

#### `chrupalla-03` – „Davon abgesehen: Die Rolle des Ostbeauftragten hat ohnehin meine Partei, die Alternative für Deutschland, übernommen.“

- **Sprecher:** Tino Chrupalla (AfD), damals: Co-Bundessprecher der AfD und Co-Vorsitzender der AfD-Bundestagsfraktion
- **Datum:** 2025-05-14
- **Kontext:** Bundestagsrede in der Aussprache zur ersten Regierungserklärung von Bundeskanzler Friedrich Merz (Plenarprotokoll 21/3).
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd · **kurz:** ja
- **Quellen:** <https://dserver.bundestag.de/btp/21/21003.pdf>
- **Notizen:** Primärquelle Plenarprotokoll 21/3, S. 104 (A). Kontext: Kritik an der Ernennung einer SPD-Ostbeauftragten. Weitere Zeile derselben Rede: 'Herr Bundeskanzler, haben Sie dann die Größe, sich für günstiges Gas auszusprechen?' (zu Nord Stream). Stand 11/2026: Co-Bundesvorsitzender der AfD (Erfurt, 4./5.7.2026 mit ca. 70 % bestätigt) und Co-Vorsitzender der AfD-Bundestagsfraktion; MdB (Görlitz).

## Beatrix von Storch (AfD)

*Aktuell (11/2026): MdB, stellvertretende Vorsitzende der AfD-Bundestagsfraktion.*

### Migration

#### `storch-02` – „Ja.“

- **Sprecher:** Beatrix von Storch (AfD), damals: Stellvertretende Bundessprecherin der AfD, MdEP, Landesvorsitzende AfD Berlin
- **Datum:** 2016-01-30
- **Kontext:** Antwort auf Facebook auf die Nutzerfrage 'Wollt Ihr etwa Frauen mit Kindern an der grünen Wiese den Zutritt mit Waffengewalt verhindern?' – im Zuge von Frauke Petrys Interview zum Schusswaffengebrauch an der Grenze.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.leinetal24.de/welt/afd-chefin-wuerde-auch-kinder-schiessen-lassen-zr-6082516.html> · <https://www.salzburg24.at/news/welt/afd-fordert-schiessbefehl-an-grenze-art-114035> · <https://www.evangelisch.de/inhalte/131288/01-02-2016/petry-relativiert-forderung-nach-schusswaffen-einsatz-grenze> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Wortlaut gesichert; spätere Einschränkung siehe storch-03. Frage und 'Ja' wortgleich bei dpa (leinetal24) und DIMR (zitiert FAZ). Umstritten, weil später eingeschränkt: Ihr 'Ja' habe sich nur auf Frauen bezogen, nicht auf Kinder (siehe storch-03). Die oft kolportierte Ausrede, sie sei 'mit der Maus abgerutscht', ist NICHT gesichert (siehe afd_extra.json). Datum: Samstag 30.01.2016 laut dpa ('am Samstag'). Stand 11/2026: MdB und stellvertretende Vorsitzende der AfD-Bundestagsfraktion (laut Bundestagsprofil, 21. WP).

#### `storch-03` – „Ich bin grundsätzlich gegen Gewalt gegen Kinder, das umfasst auch den Einsatz von Schusswaffen gegen minderjährige Migranten durch die Polizei.“

- **Sprecher:** Beatrix von Storch (AfD), damals: Stellvertretende Bundessprecherin der AfD, MdEP, Landesvorsitzende AfD Berlin
- **Datum:** 2016-01-31
- **Kontext:** Nachträgliche Klarstellung nach der Kritik an ihrem 'Ja' zum Waffeneinsatz an der Grenze (storch-02).
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.salzburg24.at/news/welt/afd-fordert-schiessbefehl-an-grenze-art-114035> · <https://www.leinetal24.de/welt/afd-chefin-wuerde-auch-kinder-schiessen-lassen-zr-6082516.html>
- **Notizen:** Wortgleich bei APA/dpa (salzburg24) und dpa (leinetal24). Laut dpa begründete sie die Unterscheidung zusätzlich damit, Frauen seien 'anders als Kinder verständig' – diese Zeile ist nur in einer dpa-Fassung gefunden (siehe unverifiziert). Datum: Klarstellung am Sonntagabend 31.01.2016 laut dpa (Zeitpunkt des zitierten Satzes nicht exakt gesichert). Stand 11/2026: MdB und stellvertretende Vorsitzende der AfD-Bundestagsfraktion (laut Bundestagsprofil, 21. WP).

#### `storch-01` – „Was zur Hölle ist in diesem Land los? Wieso twittert eine offizielle Polizeiseite aus NRW auf Arabisch. Meinen Sie, die barbarischen, muslimischen, gruppenvergewaltigenden Männerhorden so zu besänftigen?“

- **Sprecher:** Beatrix von Storch (AfD), damals: MdB, stellvertretende Vorsitzende der AfD-Bundestagsfraktion
- **Datum:** 2017-12-31
- **Kontext:** Tweet am Silvesterabend als Reaktion auf Neujahrsgrüße der Kölner Polizei in mehreren Sprachen, darunter Arabisch.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_82980164/twitter-sperrt-beatrix-von-storchs-profil-wegen-hass-nachricht.html> · <https://www.horizont.net/medien/nachrichten/AfD-Politikerin-Twitter-sperrt-Beatrix-von-Storch-nach-Hass-Tweet-fuer-zwoelf-Stunden-163695> · <https://de.euronews.com/2018/01/01/rassismus-und-hetze-auf-twitter-afd-vize-von-storch-angezeigt>
- **Notizen:** Wortgleich in t-online, Horizont, Euronews (inkl. Punkt statt Fragezeichen nach 'Arabisch'). Twitter sperrte den Account für zwölf Stunden ('Verstoß gegen Regeln über Hass-Inhalte'); die Kölner Polizei erstattete Anzeige wegen Verdachts der Volksverhetzung, dazu mehrere Hundert Strafanzeigen. Ausgang des Verfahrens nicht geprüft. Häufig falsch zitiert als 'barbarische, muslimische, gruppenvergewaltigende Männerhorden' (Nominativ) – im Tweet steht der Akkusativ. Stand 11/2026: MdB und stellvertretende Vorsitzende der AfD-Bundestagsfraktion (laut Bundestagsprofil, 21. WP).

#### `storch-04` – „Rabenmutter!“

- **Sprecher:** Beatrix von Storch (AfD), damals: MdB, stellvertretende Vorsitzende der AfD-Bundestagsfraktion
- **Datum:** 2025-06-27
- **Kontext:** Zwischenruf in der Bundestagsdebatte über die Aussetzung des Familiennachzugs, als die Linken-Abgeordnete Clara Bünger sagte: 'Sagen Sie das mal einer Mutter, die seit vier Jahren auf die Zusammenführung mit ihren Kindern wartet!'
- **Status:** `verifiziert` · **Kategorien:** Migration, Gender/Familie · **kurz:** ja
- **Quellen:** <https://dserver.bundestag.de/btp/21/21015.pdf>
- **Notizen:** Primärquelle Plenarprotokoll 21/15, S. 1365 (B): '(… – Dr. Christian Wirth [AfD]: Wer lässt denn seine Kinder im Stich? – Beatrix von Storch [AfD]: Rabenmutter!)'. Kurz danach rügte Präsidentin Klöckner von Storch für eine abfällige Geste ('Wischer') gegenüber einem Bundesminister. Stand 11/2026: MdB und stellvertretende Vorsitzende der AfD-Bundestagsfraktion (laut Bundestagsprofil, 21. WP).

## Maximilian Krah (AfD)

*Aktuell (11/2026): MdB seit 2025; nicht mehr im AfD-Bundesvorstand/EU-Parlament.*

### Migration

#### `krah-04` – „Deutsche Sprache nicht mehr erforderlich, um deutsche Staatsbürger zu werden. Aber wehe, man unterscheidet das deutsche Volk von der Gemeinschaft der Staatsbürger!“

- **Sprecher:** Maximilian Krah (AfD), damals: MdEP (AfD)
- **Datum:** 2021-11-26
- **Kontext:** Social-Media-Beitrag; vom VG Köln als Beleg für eine Unterscheidung zwischen deutschem Volk und Staatsbürgern angeführt.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Notizen:** Quelle: Gerichtsurteil (primärnah, hoch); Plattform des Posts unbekannt. Einzige Quelle: Urteil VG Köln vom 08.03.2022 (13 K 326/21), zitiert aus Gerichtsakte (Bl. 207 GA). Plattform im Urteil nicht genannt. Stand 11/2026: MdB seit 2025 (Direktmandat Wahlkreis 162 Chemnitzer Umland – Erzgebirgskreis II), AfD-Fraktion; seit 2024 nicht mehr in der AfD-Delegation im EU-Parlament/Bundesvorstand.

### Gender/Familie

#### `krah-03` – „Lass dir nicht einreden, dass du lieb, soft, schwach und links zu sein hast. Echte Männer sind rechts. Echte Männer haben Ideale. Echte Männer sind Patrioten.“

- **Sprecher:** Maximilian Krah (AfD), damals: MdEP; designierter AfD-Spitzenkandidat zur Europawahl 2024
- **Datum:** 2023-07
- **Kontext:** TikTok-Video an junge Männer, eingeleitet mit der Behauptung, jeder dritte junge Mann habe noch nie eine Freundin gehabt.
- **Status:** `verifiziert` · **Kategorien:** Gender/Familie · **kurz:** nein
- **Quellen:** <https://www.t-online.de/nachrichten/deutschland/parteien/id_100367884/afd-tiktok-schraenkt-reichweite-von-maximilian-krah-ein.html> · <https://www.nordkurier.de/politik/dating-tipps-vom-afd-spitzenkandidaten-sorgen-fuer-belustigung-im-netz-1797112>
- **Notizen:** Wortlaut nach t-online; Nordkurier (30.07.2023) gibt den Kern ebenso wieder, mit Anhang 'dann klappt es auch mit der Freundin'. Nordkurier zitiert außerdem: 'Schau keine Pornos, wähl' nicht die Grünen, geh' raus an die frische Luft, steh' zu dir, sei selbstbewusst, guck geradeaus.' (nur eine Quelle). Genaues Veröffentlichungsdatum des Videos nicht ermittelt ('vor einigen Wochen' vor dem 30.07.2023). TikTok schränkte 2024 Krahs Reichweite ein. Stand 11/2026: MdB seit 2025 (Direktmandat Wahlkreis 162 Chemnitzer Umland – Erzgebirgskreis II), AfD-Fraktion; seit 2024 nicht mehr in der AfD-Delegation im EU-Parlament/Bundesvorstand.

### Geschichte/NS-Relativierung

#### `krah-01` – „Ich werde nie sagen, dass jeder, der eine SS-Uniform trug, automatisch ein Verbrecher war.“

- **Sprecher:** Maximilian Krah (AfD), damals: MdEP, AfD-Spitzenkandidat zur Europawahl 2024, Mitglied des AfD-Bundesvorstands
- **Datum:** 2024-05-18
- **Kontext:** Interview mit der italienischen Zeitung 'La Repubblica' im Europawahlkampf.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.juedische-allgemeine.de/politik/eklat-um-ss-aeusserungen-von-maximilian-krah-le-pen-bricht-mit-der-afd/> · <https://www.srf.ch/news/international/aussagen-ueber-ns-zeit-afd-europakandidat-krah-tritt-im-wahlkampf-nicht-mehr-auf>
- **Notizen:** ACHTUNG ÜBERSETZUNG: Interview erschien auf Italienisch; deutsche Fassung = übereinstimmende dpa-Übersetzung (Jüdische Allgemeine, SRF). Einzelne Medien schreiben 'Krimineller' statt 'Verbrecher'. Folgen: Rassemblement National kündigte Bruch mit der AfD an, AfD-Bundesvorstand erteilte Auftrittsverbot (22.05.2024), Krah trat aus dem Bundesvorstand zurück; die ID-Fraktion schloss die AfD-Delegation aus; Krah wurde nicht in die neue AfD-Delegation im EU-Parlament aufgenommen. FALSCHZITAT-WARNUNG: Nicht 'Nicht alle SS-Leute waren Verbrecher' als wörtliches Zitat ausgeben – das ist eine Paraphrase. Stand 11/2026: MdB seit 2025 (Direktmandat Wahlkreis 162 Chemnitzer Umland – Erzgebirgskreis II), AfD-Fraktion; seit 2024 nicht mehr in der AfD-Delegation im EU-Parlament/Bundesvorstand.

#### `krah-02` – „Es gab sicherlich einen hohen Prozentsatz an Kriminellen, aber nicht alle waren kriminell.“

- **Sprecher:** Maximilian Krah (AfD), damals: MdEP, AfD-Spitzenkandidat zur Europawahl 2024, Mitglied des AfD-Bundesvorstands
- **Datum:** 2024-05-18
- **Kontext:** Selbes 'La Repubblica'-Interview, Antwort auf die Frage, ob die SS Kriegsverbrecher gewesen seien.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://www.juedische-allgemeine.de/politik/eklat-um-ss-aeusserungen-von-maximilian-krah-le-pen-bricht-mit-der-afd/> · <https://www.srf.ch/news/international/aussagen-ueber-ns-zeit-afd-europakandidat-krah-tritt-im-wahlkampf-nicht-mehr-auf>
- **Notizen:** dpa-Übersetzung aus dem Italienischen, wortgleich in Jüdischer Allgemeiner und SRF; als '(übersetzt)' kennzeichnen. Die SS wurde in Nürnberg zur verbrecherischen Organisation erklärt. Stand 11/2026: MdB seit 2025 (Direktmandat Wahlkreis 162 Chemnitzer Umland – Erzgebirgskreis II), AfD-Fraktion; seit 2024 nicht mehr in der AfD-Delegation im EU-Parlament/Bundesvorstand.

## Stephan Brandner (AfD)

### Demokratie/Medien

#### `brandner-02` – „Klar, warum der gegen uns sabbert/sabbern muss #Judaslohn“

- **Sprecher:** Stephan Brandner (AfD), damals: MdB, Vorsitzender des Rechtsausschusses des Bundestages
- **Datum:** 2019-10-31
- **Kontext:** Tweet zum Bundesverdienstkreuz für den AfD-kritischen Musiker Udo Lindenberg; Brandner stellte ein Zitat aus einem Zeitungsartikel über die Auszeichnung dazu.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.tagesspiegel.de/politik/parteien-fordern-rucktritt-von-afd-politiker-brandner-6867439.html> · <https://www.juedische-allgemeine.de/politik/brandner-war-nicht-laenger-tragbar/> · <https://www.bundestag.de/webarchiv/presse/hib/2019_11/668082-668082> · <https://taz.de/Abwahl-von-AfD-Politiker-im-Ausschuss-/!5641977/>
- **Notizen:** Tweettext laut Tagesspiegel (nach Handelsblatt, Tweet 'am Donnerstag' = 31.10.2019); Hashtag #Judaslohn mehrfach belegt. Folge: Am 13.11.2019 wurde Brandner als erster Ausschussvorsitzender in der Geschichte des Bundestages abberufen – wegen dieses Tweets und Äußerungen nach dem Anschlag von Halle (hib). Kritik: Spiel mit antisemitischen Ressentiments (u. a. CSU-Politiker Ullrich).

### Sonstiges/Absurd

#### `brandner-01` – „Er hat nicht „Fliegenschiss“ gesagt! Herr Gauland hat nie „Fliegenschiss“ gesagt! Ihre Rede ist ein Fliegenschiss!“

- **Sprecher:** Stephan Brandner (AfD), damals: MdB, stellvertretender Bundessprecher der AfD
- **Datum:** 2025-01-29
- **Kontext:** Zwischenruf im Bundestag, als Friedrich Merz (CDU) Alexander Gauland fälschlich einen 'Fliegenschiss' vorhielt (statt 'Vogelschiss').
- **Status:** `verifiziert` · **Kategorien:** Sonstiges/Absurd, Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://dserver.bundestag.de/btp/20/20209.pdf>
- **Notizen:** Primärquelle Plenarprotokoll 20/209. Im selben Zwischenrufblock: 'Tino Chrupalla [AfD]: Sie wissen nicht mal, was er gesagt hat!' Merz' Satz: 'Ich will es einfach an die Adresse dieser Fraktion hier rechts sagen und an Ihre, Herr Gauland: Das war Ihr Fliegenschiss, von dem Sie vor Jahr und Tag gesprochen haben.' Stand 11/2026: Brandner ist MdB und stellv. Bundesvorsitzender (Wiederwahl 2026 nicht separat geprüft).

## André Poggenburg (AfD)

### Migration

#### `poggenburg-01` – „Diese Kümmelhändler haben selbst einen Völkermord an 1,5 Millionen Armeniern am Arsch, für den sie bis heute keine Verantwortung übernehmen. Und die wollen uns irgendetwas über Geschichte und Heimat erzählen? Die spinnen wohl! Diese Kameltreiber sollen sich dahin scheren, wo sie hingehören. Weit, weit, weit hinter den Bosporus zu ihren Lehmhütten und Vielweibern.“

- **Sprecher:** André Poggenburg (AfD), damals: Landes- und Fraktionsvorsitzender der AfD Sachsen-Anhalt
- **Datum:** 2018-02-14
- **Kontext:** Rede beim Politischen Aschermittwoch der AfD in Nentmannsdorf (Sachsen) gegen die Kritik der Türkischen Gemeinde an einem Heimatministerium.
- **Status:** `umstritten` · **Kategorien:** Migration · **kurz:** nein
- **Quellen:** <https://www.volksstimme.de/sachsen-anhalt/poggenburg-beklagt-stimmungsmache-877649> · <https://jungefreiheit.de/politik/deutschland/2018/politischer-aschermittwoch-der-afd-sorgt-fuer-empoerung/> · <https://www.lto.de/recht/presseschau/p/Volksverhetzung-durch-AfD-LandesvorsitzendenEU-Kommission-ruegt-Facebook-und-TwitterTuerkischer-Ministerpraesident-trifft-Kanzlerin>
- **Notizen:** BLEIBT 'umstritten', weil: Der Wortlaut des letzten Satzes weicht zwischen den Quellen ab. Wortlaut nach Volksstimme; Junge Freiheit mit leicht abweichender Fassung ('sollen sich hinscheren, wo sie hingehören, weit hinter den Bosporus') – Kernbegriffe 'Kümmelhändler', 'Kameltreiber', 'Lehmhütten und Vielweibern' sicher. Kurzform fürs Spiel am besten nur Fragmente. In derselben Rede über Doppelstaatler: 'heimat- und vaterlandsloses Gesindel'. Umstritten: Poggenburg nannte es 'zugespitzte' Aschermittwochs-Satire, er habe 'hart und grob formuliert'; Bundesvorstand rügte ihn, StA Dresden leitete ein Prüfverfahren wegen Volksverhetzung ein (Ausgang nicht geprüft). Rücktritt von Landes- und Fraktionsvorsitz Ende März 2018. Stand 11/2026: kein AfD-Mitglied mehr (Austritt Januar 2019).

## Frauke Petry (AfD)

### Migration

#### `petry-01` – „[…] notfalls auch von der Schusswaffe Gebrauch machen. So steht es im Gesetz.“

- **Sprecher:** Frauke Petry (AfD), damals: Bundessprecherin (Co-Vorsitzende) der AfD, Fraktionsvorsitzende im Sächsischen Landtag
- **Datum:** 2016-01-30
- **Kontext:** Interview mit dem 'Mannheimer Morgen' (Samstagsausgabe, 30.01.2016) zum Umgang der Grenzpolizei mit illegalen Grenzübertritten.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.evangelisch.de/inhalte/131288/01-02-2016/petry-relativiert-forderung-nach-schusswaffen-einsatz-grenze> · <https://www.salzburg24.at/news/welt/afd-fordert-schiessbefehl-an-grenze-art-114035>
- **Notizen:** STATUS 11/2026: von 'umstritten' auf 'verifiziert' umgestellt (Regel 'Gesagt ist gesagt'): Bestätigter Teil des Wortlauts; Relativierung vom 01.02.2016 siehe Notizen. Vollständiger Satz nur in einer Interview-Abschrift (SPD-Zitatesammlung) gefunden; 'notfalls auch von der Schusswaffe Gebrauch machen' und 'So steht es im Gesetz.' bei epd und APA/dpa wörtlich bestätigt. Im selben Interview: 'Kein Polizist will auf einen Flüchtling schießen. Ich will das auch nicht. Aber zur Ultima Ratio gehört der Einsatz von Waffengewalt.' Umstritten, weil relativiert: Petry und Meuthen erklärten am 01.02.2016, die AfD lehne es 'strikt ab, dass auf Menschen geschossen wird, die friedlich Einlass in das Bundesgebiet begehren'. Begriff 'Schießbefehl' stammt aus Medien/Kritik, nicht von Petry. Stand 11/2026: seit 2017 nicht mehr in der AfD; Gründerin des Vereins/der Partei 'Team Freiheit' (2025). PRÜFUNG 11/2026: Der vollständige Satz ('Er muss den illegalen Grenzübertritt verhindern, …') steht nur in einer Interview-Abschrift einer Partei-Zitatesammlung und wird deshalb nicht verwendet. 'So steht es im Gesetz.' wörtlich bei epd; 'notfalls auch von der Schusswaffe Gebrauch machen' bei APA/dpa. VERIFIKATION 11/2026: Die frühere Angabe, die Frage habe einem über einen Zaun kletternden Flüchtling gegolten, ist in keiner geprüften Quelle belegt und wurde entfernt. Relativierung von Petry und Meuthen am 01.02.2016 beachten.

### Geschichte/NS-Relativierung

#### `afd-petry-02` – „Wenn er damit zu tun hat, dass es um das Volk geht, was ist daran per se negativ?“

- **Sprecher:** Frauke Petry (AfD), damals: AfD-Bundesvorsitzende
- **Datum:** 2016-09-11
- **Kontext:** Interview mit der Welt am Sonntag über den Begriff 'völkisch'; sie sagte auch, der Begriff solle 'wieder positiv besetzt' werden.
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://www.vol.at/afd-chefin-will-begriff-voelkisch-positiv-besetzen/4900717> · <https://correctiv.org/ruhr/faktencheck-ruhr/2017/04/21/frauke-petry-und-das-voelkische-was-stimmt>
- **Notizen:** vol.at (Wortlaut abgerufen; Interview WamS 11.09.2016). Correctiv-Faktencheck nur über Suchzusammenfassung bestätigt, nicht abgerufen. Weitere Zitate aus demselben Interview: 'Ich sperre mich dagegen, Wörter zu Unwörtern zu erklären' und '[...] dass dieser Begriff wieder positiv besetzt ist'. Petry sagte laut Correctiv auch, sie benutze den Begriff selbst nicht, ihr missfalle aber seine ausschließlich negative Verwendung - Kontext mitliefern.

## Jens Maier (AfD)

### Migration

#### `maier-01` – „Diese ganze Entwicklung, die jetzt gerade stattfindet, die Herstellung von Mischvölkern, um die nationalen Identitäten auszulöschen und damit die Abgabe der Souveränität an die EU - das ist einfach nicht zu ertragen.“

- **Sprecher:** Jens Maier (AfD), damals: Richter am Landgericht Dresden, AfD-Bundestagskandidat (Sachsen)
- **Datum:** 2017-01-17
- **Kontext:** Rede als Vorredner Björn Höckes bei der JA-Veranstaltung im Dresdner Ballhaus Watzke (siehe hoecke-01).
- **Status:** `verifiziert` · **Kategorien:** Migration, Europa · **kurz:** nein
- **Quellen:** <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html> · <https://www.l-iz.de/melder/wortmelder/2017/01/klaus-bartl-linke-afd-mann-maier-nach-assistenz-fuer-hoecke-als-richter-noch-tragbar-164880> · <https://www.lto.de/recht/hintergruende/h/richter-jens-maier-sachsen-afd-justiz-rueckkehr-aussagen-2017-dresden-slomka-zdf-bundestag-mandat>
- **Notizen:** Vollzitat im VG-Köln-Urteil (aus BfV-Gutachten); 'Herstellung von Mischvölkern' und 'einfach nicht zu ertragen' bei L-IZ/LTO bestätigt. In derselben Rede erklärte er den 'Schuldkult' für 'endgültig beendet' (nur fragmentarisch belegt). Das LG Dresden erteilte 2017 einen Verweis. Maier war 2017–2021 MdB; 2022 Rückkehr in die Justiz untersagt, BGH bestätigte im Oktober 2023 die Versetzung in den vorzeitigen Ruhestand; die Disziplinarklage auf Aberkennung des Ruhegehalts wies das Dienstgericht Leipzig im November 2024 ab (weiterer Verlauf nicht geprüft).

#### `afd-maier-02` – „Dem kleinen Halb***** [N-Wort zensiert] scheint einfach zu wenig Beachtung geschenkt worden zu sein [...]“

- **Sprecher:** Jens Maier (AfD), damals: AfD-Bundestagsabgeordneter, Richter am Landgericht Dresden (beurlaubt)
- **Datum:** 2018-01-02
- **Kontext:** Tweet vom Account Maiers über Noah Becker (Sohn von Boris Becker), nachdem dieser sich beklagt hatte, ständig nur als Sohn gesehen zu werden. Tweet gelöscht; Maier sagte, ein Mitarbeiter habe ihn verfasst.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.lto.de/recht/nachrichten/n/jens-maier-afd-richter-bundestagsabgeordneter-rassistischer-kommentar-noah-becker> · <https://www.vice.com/de/article/jens-maier-urteil-afd-politiker-muss-wegen-rassistischem-tweet-15000-euro-schmerzensgeld-an-noah-becker-zahlen/>
- **Notizen:** Wortlaut nach LTO (abgerufen; dort geht das Zitat noch weiter, der Rest wurde nicht ausgegeben) - deshalb [...] am Ende, Satzende nicht selbst ergänzen. Die anderen Quellen nur über Suchzusammenfassungen gesehen; der Wortlaut ('kleiner Halb…') ist dort einheitlich. Maier sagte, ein Mitarbeiter habe geschrieben -> 'Tweet vom Account des AfD-Abgeordneten' formulieren. Gerichtsfolgen widersprüchlich berichtet: Vice 15.000 EUR Urteil, t-online 7.500 EUR - im Spiel nicht nennen, solange ungeklärt. LTO nennt es 'rassistischen Kommentar'; Gauland und Meuthen kritisierten ihn. ZENSUR (D-156, content-guidelines §4): Im Original steht das N-Wort als Teil des Kompositums 'Halb…'. Es ist durch Sternchen ersetzt und im Zitat mit '[N-Wort zensiert]' markiert; sonst ist der Wortlaut unverändert. Die t-online-Quelle (Artikel id_82996470, 'Tweet geht Meuthen zu weit') ist nicht verlinkt, weil ihre URL das Wort ausschreibt.

## Gottfried Curio (AfD)

### Demokratie/Medien

#### `curio-01` – „Mut und Glück auf, Deutschland. Mut und Glück auf, du Land der Bayern. Setze ein Zeichen für die Beendigung der Herrschaft des Unrechts, setze ein Zeichen an den Iden des März, setzt das Erwachen in Gange, befreit das Land!“

- **Sprecher:** Gottfried Curio (AfD), damals: MdB, innenpolitischer Sprecher der AfD-Bundestagsfraktion
- **Datum:** 2020-02
- **Kontext:** Rede beim Politischen Aschermittwoch der AfD Bayern im Februar 2020, vor den bayerischen Kommunalwahlen am 15. März 2020.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.spiegel.de/politik/deutschland/rechtsextreme-in-der-afd-so-sprechen-fluegel-anfuehrer-hoecke-und-seine-leute-a-98188c22-71b5-4b56-8d0c-a21f4bcef2e1> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** Wortgleich bei Spiegel (12.03.2020) und DIMR. Die 'Iden des März' bezeichnen die Ermordung Caesars (15. März); das DIMR deutet die Passage als Aufruf zu politischem Mord – das ist eine Interpretation, keine gerichtliche Feststellung; Curios eigene Deutung nicht ermittelt (der 15.03.2020 war auch der bayerische Kommunalwahltag). Genaues Datum der Rede nicht geprüft (Aschermittwoch war der 26.02.2020). Stand 11/2026: MdB, AfD-Fraktion.

## Matthias Helferich (AfD)

### Geschichte/NS-Relativierung

#### `helferich-01` – „das freundliche Gesicht des NS“

- **Sprecher:** Matthias Helferich (AfD), damals: AfD-Politiker in Dortmund (Chat von 2017; bekannt geworden 2021 als stellv. NRW-Landesvorsitzender und Bundestagskandidat)
- **Datum:** 2017
- **Kontext:** Kommentar zu einem Foto von sich selbst in einem nicht-öffentlichen Facebook-Chat; die Screenshots veröffentlichte der WDR 2021.
- **Status:** `umstritten` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://taz.de/AfD-Bezuege-zum-Nationalsozialismus/!5790562/> · <https://correctiv.org/aktuelles/afd/2026/07/03/helferich-urteil-gewinn-fuer-das-voelkische-lager-der-afd-in-nrw/> · <https://www.institut-fuer-menschenrechte.de/fileadmin/Redaktion/Publikationen/Analyse_Studie/Analyse_Warum_die_AfD_verboten_werden_koennte.pdf>
- **Notizen:** BLEIBT 'umstritten', weil: Helferich gibt an, eine fremde Zuschreibung ironisch wiedergegeben zu haben – Zuschreibung strittig. Fragment wörtlich belegt (taz, Correctiv). Umstritten: Helferich erklärte, er habe nur die Zuschreibung eines Linken ironisch wiedergegeben; laut taz bestritt er die Aussagen nicht, bestätigte sie aber auch nicht. Das AfD-Bundesschiedsgericht ließ ihn am 26.06.2026 in der Partei (nur sechs Monate Ämtersperre) und wertete diese Äußerung als aus dem Zusammenhang gerissen. Stand 11/2026: MdB (seit 2021), AfD-Mitglied. Nur mit Kontext/Hinweis auf seine Erklärung verwenden.

## Ulrich Thomas (gemeinsam mit Lars-Jörn Zimmer) (CDU)

### Demokratie/Medien

#### `cdu-thomas-01` – „Es muss gelingen, das Soziale wieder mit dem Nationalen zu versöhnen.“

- **Sprecher:** Ulrich Thomas (gemeinsam mit Lars-Jörn Zimmer) (CDU), damals: stellv. CDU-Fraktionsvorsitzender im Landtag von Sachsen-Anhalt (Mitverfasser der 'Denkschrift' mit Lars-Jörn Zimmer)
- **Datum:** 2019-06
- **Kontext:** Aus der achtseitigen 'Denkschrift' der beiden CDU-Fraktionsvizes Thomas und Zimmer, die u. a. forderte, Koalitionen mit der AfD künftig nicht auszuschließen und sich von 'multikulturellen Strömungen linker Parteien und Gruppen' abzugrenzen. CDU-Landeschef Holger Stahlknecht lehnte den Vorstoß ab ('Ich warne davor, die CDU nach rechts zu verrücken').
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien, Migration · **kurz:** ja
- **Quellen:** <https://www.t-online.de/nachrichten/deutschland/id_85958160/cdu-politiker-ueber-koalition-mit-afd-soziales-mit-nationalem-versoehnen-.html> · <https://www.volksstimme.de/sachsen-anhalt/trotz-denkschrift-stahlknecht-sieht-cdu-gut-aufgestellt-986975>
- **Notizen:** Zitiert nach Mitteldeutscher Zeitung (via t-online, Stand 20.06.2019). Volksstimme/dpa (05.07.2019) gibt die Stelle als 'das Soziale mit dem Nationalen zu versöhnen' wieder (Kernfragment identisch, ohne 'wieder' - ob Kürzung der Zeitung oder Abweichung, nicht geklärt). SICHERSTE Sprechblasen-Fassung: Kernfragment 'das Soziale mit dem Nationalen zu versöhnen'. Das Originaldokument der Denkschrift wurde NICHT eingesehen. Zuschreibung an Thomas folgt der MZ (via t-online); das Papier hat zwei Autoren. Weitere Passage laut Volksstimme/dpa: Kampf gegen den 'linken Mainstream aus gesteuertem Gutmenschentum und Klimaverständnis' (nur 1 Quelle, nicht doppelt belegt).

## Hans-Georg Maaßen (CDU)

### Migration

#### `cdu-maassen-01` – „eliminatorischer Rassismus gegen Weiße“

- **Sprecher:** Hans-Georg Maaßen (CDU), damals: CDU-Mitglied (Thüringen, 2021 Bundestagskandidat), ehem. Präsident des Bundesamts für Verfassungsschutz; Werteunion-Umfeld
- **Datum:** 2023-01
- **Kontext:** Twitter-Beitrag Maaßens in der Woche bis 22.01.2023: Die Stoßrichtung der 'treibenden Kräfte im politischen-medialen Raum' sei 'eliminatorischer Rassismus gegen Weiße'. Daraufhin forderte das CDU-Präsidium ihn einstimmig zum Parteiaustritt auf (30.01.2023).
- **Status:** `verifiziert` · **Kategorien:** Migration, Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://taz.de/Antrag-auf-Parteiausschlussverfahren/!5911309/> · <https://www.juedische-allgemeine.de/allgemein/gebrauch-von-sprache-aus-dem-milieu-der-antisemiten-und-verschwoerungsideologen-zutiefst-verstoerend-und-unertraeglich> · <https://www.lto.de/recht/nachrichten/n/cdu-hans-georg-maassen-parteiaustritt-forderung-partei-praesidium-parteiausschlussverfahren/print.html>
- **Notizen:** Nur das Fragment 'eliminatorischer Rassismus gegen Weiße' ist in taz, Jüdischer Allgemeiner und LTO übereinstimmend wörtlich zitiert; voller Tweet-Text und exaktes Tweet-Datum wurden NICHT gefunden (Originaltweet nicht abrufbar). Nur als Fragment verwenden, nicht zum Satz ergänzen. Laut taz verdrehte Maaßen damit einen Begriff des Holocaust-Forschers Daniel Goldhagen; RIAS sah Anklänge an NS-Vernichtungsantisemitismus (Wertungen Dritter, nicht als Tatsache darstellen). Die Interview-Formulierung 'Rassenlehre' NICHT verwenden: taz 'grün-roten Rassenlehre', LTO 'rot-grünen Rassenlehre' -> Wortlaut uneinheitlich. Maaßen war zum Zeitpunkt CDU-Mitglied (Jüdische Allgemeine, 22.01.2023).

## Saskia Ludwig (CDU)

### Demokratie/Medien

#### `cdu-ludwig-01` – „Wenn über 50 Prozent Mitte-Rechts wählen, dann muss es auch eine Mitte-Rechts-Regierung geben für die Bürger.“

- **Sprecher:** Saskia Ludwig (CDU), damals: CDU-Politikerin aus Brandenburg (inzwischen Bundestagsabgeordnete), prominente Gegnerin der 'Brandmauer'
- **Datum:** 2025
- **Kontext:** Interview mit dem Berliner Lokalsender TV.Berlin vor der Bundestagswahl 2025, in dem sie für eine Regierung rechts der Mitte warb. Im August 2025 sorgte sie zudem mit einem Treffen mit Alice Weidel beim MCC-Festival in Ungarn für Streit in der Union.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.zdfheute.de/politik/saskia-ludwig-cdu-afd-weidel-100.html>
- **Notizen:** Einzelquelle, aber ZDF (zitiert TV.Berlin-Interview); exaktes Interviewdatum nicht angegeben (vor Bundestagswahl 23.02.2025). Der Satz nennt die AfD nicht; der AfD-Bezug ist Einordnung des ZDF - nicht als 'Ludwig will AfD-Koalition' ausgeben. NICHT verifiziert: 'Die Brandmauer halte ich für einen politischen Irrweg' (nur heidelberg24, 17.03.2026) und 'höchst undemokratisch' (nur Sekundärbericht).

## Alexander Räuscher (früher CDU)

### Demokratie/Medien

#### `cdu-raeuscher-01` – „Das Wahlergebnis verlangt, dass Herr Siegmund Ministerpräsident wird. Die CDU sollte seine Wahl ermöglichen“

- **Sprecher:** Alexander Räuscher (früher CDU), damals: früherer CDU-Landtagsabgeordneter in Sachsen-Anhalt (nicht mehr im 2026 gewählten Landtag); laut Berichten langjähriger Brandmauer-Gegner
- **Datum:** 2026-10-08
- **Kontext:** Äußerung gegenüber dem Tagesspiegel nach der Landtagswahl in Sachsen-Anhalt (06.09.2026) zur Frage, ob die CDU den AfD-Spitzenkandidaten Ulrich Siegmund im Dezember zum Ministerpräsidenten wählen soll. CDU-Landesvize Marco Tullner lehnte das klar ab.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.volksstimme.de/deutschland-und-welt/deutschland/cdu-landesvize-tullner-wir-sind-keine-afd-hilfstruppe-4335338>
- **Notizen:** dpa-Meldung (Volksstimme, 08.10.2026, 12:55) zitiert den Tagesspiegel; Tagesspiegel-Original nicht selbst abgerufen. Parteistatus: dpa nennt ihn 'früheren CDU-Landtagsabgeordneten' - ob er zum Zeitpunkt noch CDU-Mitglied war, ist nicht belegt; im Album daher 'ehem. CDU-Landtagsabgeordneter' schreiben. Satz endet in der dpa-Fassung ohne Punkt.

#### `cdu-raeuscher-02` – „Ich hätte Bauchschmerzen, Siegmund im Landtag zu wählen, aber ich würde es tun. Da müssen wir jetzt durch“

- **Sprecher:** Alexander Räuscher (früher CDU), damals: früherer CDU-Landtagsabgeordneter in Sachsen-Anhalt
- **Datum:** 2026-10-08
- **Kontext:** Tagesspiegel-Interview nach der Landtagswahl Sachsen-Anhalt 2026, zur möglichen CDU-Wahl des AfD-Spitzenkandidaten Siegmund zum Ministerpräsidenten.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://www.volksstimme.de/deutschland-und-welt/deutschland/cdu-landesvize-tullner-wir-sind-keine-afd-hilfstruppe-4335338>
- **Notizen:** Wie cdu-raeuscher-01: dpa (via Volksstimme), Tagesspiegel-Original nicht selbst gesehen. Kürzer für Sprechblase: 'Ich hätte Bauchschmerzen, [...] aber ich würde es tun.' (mit Auslassungszeichen).

## Clara von Nathusius (CDU)

### Demokratie/Medien

#### `cdu-nathusius-01` – „Ich glaube, dass die Brandmauer ein gescheitertes Projekt ist.“

- **Sprecher:** Clara von Nathusius (CDU), damals: Mitglied im Bundesvorstand der Jungen Union (Schatzmeisterin), ehem. Pressesprecherin bei Kulturstaatsminister Weimer
- **Datum:** 2026-09-13
- **Kontext:** ARD 'Bericht aus Berlin' (Sonntag 13.09.2026) nach der Landtagswahl in Sachsen-Anhalt; sie forderte, die Unvereinbarkeitsbeschlüsse 'in der jetzigen bestehenden Form' abzuschaffen, und schloss Sondierungsgespräche mit der AfD nicht aus.
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** ja
- **Quellen:** <https://www.hessenschau.de/politik/cdu-haelt-an-afd-abgrenzung-fest---doch-das-wort-soll-weg-v1,brandmauerdebatte-cdu-100.html> · <https://www.leinetal24.de/welt/clara-von-nathusius-cdu-fordert-ende-der-brandmauer-und-attackiert-merz-zr-94491000.html>
- **Notizen:** hessenschau (15.09.2026) zitiert wörtlich; zweiter Bericht (Welt-Text via leinetal24, nur über Suchtreffer-Zusammenfassung gesehen, Seite nicht abgerufen) bestätigt 'ein gescheitertes Projekt' und die Sendung. Sendung/Transkript nicht eingesehen. Sehr kurz, sprechblasentauglich.

## Horst Seehofer (CSU)

### Migration

#### `csu-seehofer-02` – „Herrschaft des Unrechts“

- **Sprecher:** Horst Seehofer (CSU), damals: bayerischer Ministerpräsident und CSU-Vorsitzender
- **Datum:** 2016-02-09
- **Kontext:** Seehofer warf der Bundesregierung (Merkel) in der Flüchtlingspolitik eine 'Herrschaft des Unrechts' vor (Interview, Meldungen vom 09./10.02.2016). Es folgte breite Kritik, auch aus der SPD.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.leinetal24.de/welt/seehofer-aeusserungen-herrschaft-unrechts-vergleich-unrechtsstaaten-zr-6112226.html> · <https://web.de/magazine/politik/horst-seehofer-angela-merkels-fluechtlingspolitik-schaden-31345766>
- **Notizen:** Nur das Fragment 'Herrschaft des Unrechts' selbst abgerufen (leinetal24/dpa, Stand 10.02.2016 13:10). Der volle Satz soll laut Sekundärrecherche lauten 'Wir haben im Moment keinen Zustand von Recht und Ordnung. Es ist eine Herrschaft des Unrechts.' (Passauer Neue Presse) - NICHT selbst im Original bestätigt; vor Nutzung des vollen Satzes gegenprüfen. web.de-Seite nicht abgerufen. Als Fragment verwenden. Datum 09.02. vs. 10.02. nicht eindeutig.

#### `csu-seehofer-01` – „Die Migrationsfrage ist die Mutter aller politischen Probleme in diesem Land.“

- **Sprecher:** Horst Seehofer (CSU), damals: Bundesinnenminister und CSU-Vorsitzender
- **Datum:** 2018-09-05
- **Kontext:** Rheinische-Post-Interview, veröffentlicht rund um die Klausur der CSU-Landesgruppe in Neuhardenberg (05./06.09.2018), nach den Ausschreitungen in Chemnitz. Die Kurzform 'Mutter aller Probleme' kam laut Berichten aus dem Teilnehmerkreis der Klausur.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://www.derstandard.at/story/2000086798388/seehofer-nennt-migration-mutter-aller-probleme> · <https://www.evangelisch.de/inhalte/152105/06-09-2018/seehofer-migration-ist-die-mutter-aller-probleme>
- **Notizen:** KORREKTUR der häufigen Kurzfassung 'Migration ist die Mutter aller Probleme': belegt ist als Interviewwortlaut 'Die Migrationsfrage ist die Mutter aller politischen Probleme in diesem Land.' Die Kurzform stammt laut epd aus Teilnehmerkreisen der Klausur (Bild/Welt), nicht aus dem Interview. Datum: Äußerung Mittwoch 05.09.2018 laut epd, Artikel 06.09.2018. Seehofer ist kein Hinterbänkler, passt aber als Parteilinien-Zitat.

## Ulrich Siegmund (AfD)

### Migration

#### `afd-siegmund-02` – „[...] weil wir bei späteren Remigrations- und Abschiebeoffensiven natürlich [...] entsprechende Hilfsmittel brauchen.“

- **Sprecher:** Ulrich Siegmund (AfD), damals: AfD-Spitzenkandidat und Fraktionsvorsitzender im Landtag von Sachsen-Anhalt
- **Datum:** 2026-09-09
- **Kontext:** Pressekonferenz der AfD Sachsen-Anhalt auf die Frage, ob er sich Produktion von Raketen/Drohnen des israelischen Rüstungskonzerns Elbit in Sangerhausen vorstellen könne. Davor: 'Wir verteufeln nicht pauschal die Produktion von Rüstungsgütern'.
- **Status:** `verifiziert` · **Kategorien:** Migration · **kurz:** ja
- **Quellen:** <https://correctiv.org/aktuelles/afd/2026/09/11/siegmund-afd-ruestung-remigration-ueberblick/> · <https://www.nordkurier.de/politik/siegmund-verknuepft-das-thema-remigration-und-aufruestung-brauchen-entsprechende-hilfsmittel-4857470>
- **Notizen:** Zwei Fassungen: Correctiv (nach NTV-Video) 'natürlich auch entsprechende Hilfsmittel', Nordkurier 'natürlich entsprechende Hilfsmittel' -> deshalb Auslassungszeichen; das Wort 'auch' NICHT ins Zitat setzen. Datum: Correctiv-Bildunterschrift 09.09.2026 (Artikel nennt 'Donnerstag', der 09.09.2026 ist aber ein Mittwoch); Tweet dazu 10.09.2026 -> Datum vor Release gegenprüfen. Video nicht selbst gesehen. Folge-Statement über seinen Sprecher: '[...] eine echte Remigrationsoffensive zu ermöglichen' (nur Correctiv).

### Geschichte/NS-Relativierung

#### `afd-siegmund-01` – „Das maße ich mir nicht an zu bewerten, weil ich die gesamte Menschheit nicht aufarbeiten kann [...]“

- **Sprecher:** Ulrich Siegmund (AfD), damals: AfD-Spitzenkandidat und Fraktionsvorsitzender im Landtag von Sachsen-Anhalt
- **Datum:** 2025-11-21
- **Kontext:** Auf die Frage von Gordon Repinski 'Würden Sie auch sagen, das war das schlimmste Menschheitsverbrechen?' (zur NS-Zeit/Holocaust) in einem 45-minütigen Interview-Podcast. Der Zentralrat der Juden warf ihm Relativierung vor ('völlige Schamlosigkeit', Schuster).
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** nein
- **Quellen:** <https://correctiv.org/faktencheck/2025/11/27/zitat-zum-teil-erfunden-was-ulrich-siegmund-zum-holocaust-sagte-und-was-nicht/> · <https://www.juedische-allgemeine.de/politik/voellige-schamlosigkeit-zentralrat-der-juden-kritisiert-afd-spitzenkandidat-fuer-ns-relativierung/>
- **Notizen:** FALSCHZITAT-WARNUNG: Auf X kursierte eine Fassung mit zwei erfundenen Folgesätzen (Stalinismus, Maoismus, Völkermord an Armeniern, 'verurteile den Holocaust ohne Vorbehalt') - laut Correctiv-Faktencheck NICHT gesagt. Belegt (Correctiv, nach Video): 'Das maße ich mir nicht an zu bewerten, weil ich die gesamte Menschheit nicht aufarbeiten kann und aus allen Verbrechen dieser Menschheit natürlich lernen muss, genauso wie aus dieser, wie aus vielen anderen auch.' Davor sagte er, die NS-Zeit müsse 'über die ganze AfD hinweg gleichsam als Tiefpunkt unserer Geschichte natürlich betrachtet werden' - im Album FAIRNESSHALBER mit diesem Kontext zeigen. Interview-Video nicht selbst gesehen (Correctiv transkribiert; Jüdische Allgemeine nennt es 'Politico-Podcast', Correctiv 'Gespräch mit Welt-Journalist Repinski'). Auslassung nach 'kann' ist mit [...] kenntlich gemacht.

## Marc Vallendar (AfD)

### Geschichte/NS-Relativierung

#### `afd-vallendar-01` – „Mag ja sein, dass es Kriegsverbrechen gegeben hat“

- **Sprecher:** Marc Vallendar (AfD), damals: AfD-Abgeordneter im Berliner Abgeordnetenhaus
- **Datum:** 2025-01-27
- **Kontext:** Innenausschuss des Berliner Abgeordnetenhauses am Internationalen Holocaust-Gedenktag, in einem längeren Redebeitrag; Ausschussvorsitzender Dörstelmann (SPD) fragte, ob er sich des Datums bewusst sei. Vallendar korrigierte sich ('Es gab Kriegsverbrechen').
- **Status:** `verifiziert` · **Kategorien:** Geschichte/NS-Relativierung · **kurz:** ja
- **Quellen:** <https://de.nachrichten.yahoo.com/unversch%C3%A4mtheit-holocaust-gedenktag-sorgt-afd-163834618.html>
- **Notizen:** Einzelquelle, aber dpa (via Yahoo Nachrichten). Worauf sich 'Kriegsverbrechen' im Redebeitrag bezog, steht im abgerufenen dpa-Auszug nicht; die Grünen (Franco) warfen ihm vor, den Mord an sechs Millionen Juden zu relativieren (Wertung der Grünen). Selbstkorrektur 'Es gab Kriegsverbrechen.' immer mitnennen. Kein Ausschussprotokoll eingesehen.

## CDU/CSU-Bundestagsfraktion (unterzeichnet von Friedrich Merz und Alexander Dobrindt) (CDU/CSU)

### Demokratie/Medien

#### `cdu-fraktion-01` – „Ein besonders umstrittenes Beispiel ist der Verein „Omas gegen Rechts“, der über das Programm „Demokratie leben!“ Fördermittel erhalten hat.“

- **Sprecher:** CDU/CSU-Bundestagsfraktion (unterzeichnet von Friedrich Merz und Alexander Dobrindt) (CDU/CSU), damals: Fraktion der CDU/CSU im Bundestag (Kleine Anfrage, Drucksache 20/15035, unterzeichnet von Fraktionsvorsitzendem Friedrich Merz und Alexander Dobrindt)
- **Datum:** 2025-02-24
- **Kontext:** Einleitungstext der Kleinen Anfrage 'Politische Neutralität staatlich geförderter Organisationen' (551 Fragen zu NGOs, Drucksache 20/15035, datiert 24.02.2025, unterzeichnet 21.02.2025), kurz nach den Protesten gegen die CDU vor der Bundestagswahl. Allein 25 Fragen (Nr. 45 bis 69) gelten den Omas gegen Rechts, u. a. Nr. 54: 'Werden staatliche Fördergelder, die der Verein Omas gegen Rechts Deutschland e. V. vereinnahmt hat, nach Einschätzung der Bundesregierung für parteipolitische Zwecke zweckentfremdet?'
- **Status:** `verifiziert` · **Kategorien:** Demokratie/Medien · **kurz:** nein
- **Quellen:** <https://dserver.bundestag.de/btd/20/150/2015035.pdf> · <https://www.vorwaerts.de/inland/anfrage-zu-omas-gegen-rechts-die-cdu-hat-uns-damit-viele-probleme-bereitet>
- **Notizen:** Wortlaut direkt aus dem Original (Bundestags-Drucksache 20/15035, S. 2, Text selbst aus dem PDF extrahiert); Vorwärts (14.03.2025) gibt 'besonders umstrittenes Beispiel' ebenfalls wieder. Der Satz geht weiter: 'Während der Verein betont, dass er sich aus Spenden und Mitgliedsbeiträgen finanziere, gehört die staatliche Förderung ebenfalls zu seinen Finanzierungsquellen' (laut Mimikama/Vorwärts erhält der Verein keine staatliche Förderung; Einordnung, nicht Teil des Zitats). Autorschaft: Fraktionsdokument, kein Einzelsprecher; Merz und Dobrindt zeichnen als Fraktionsvorsitzende. Die Bundesregierung ließ laut Presse ca. 251 der 551 Fragen offen (Antwort März 2025).

## Häufig falsch zitiert oder falsch zugeschrieben

- **Friedrich Merz**: falsch: „Selbst wenn wir alle zusammen morgen am Tag klimaneutral wären in Deutschland, würde keine einzige Klimakatastrophe auf der Welt weniger geschehen.“ → **richtig:** „Selbst wenn wir alle zusammen morgen in Deutschland klimaneutral wären, würde keine einzige Naturkatastrophe auf dieser Welt weniger geschehen, würde kein einziger Waldbrand weniger geschehen, würde keine einzige Überschwemmung in Texas weniger geschehen.“. Presseberichte (u. a. dpa) zitieren 'Klimakatastrophe'; das amtliche Plenarprotokoll 21/17 (09.07.2025) verzeichnet 'Naturkatastrophe'. Protokollfassung verwenden (das Protokoll ist redigiert; ein Video-Abgleich wäre ideal). Quellen: <https://dserver.bundestag.de/btp/21/21017.pdf>
- **Friedrich Merz**: falsch: „Wir können uns den Sozialstaat nicht mehr leisten.“ → **richtig:** „Der Sozialstaat, wie wir ihn heute haben, ist mit dem, was wir volkswirtschaftlich leisten, nicht mehr finanzierbar.“. Die Kurzform ist eine Überschrift (u. a. WSWS), nicht sein Wortlaut (Osnabrück, 23.08.2025). Quellen: <https://www.zdfheute.de/politik/deutschland/merz-cdu-spd-debatte-sozialstaat-100.html>
- **Friedrich Merz**: falsch: „Ich will die AfD halbieren.“ → **richtig:** „Aber halbieren kann man sie“. 'Merz will AfD halbieren' ist eine dpa-Überschrift zum Bild-Interview vom 14.11.2018. Eine Twitter-Fassung ('…und die AfD halbieren') ist nur über eine Quelle belegt. Quellen: <https://www.nau.ch/politik/international/friedrich-merz-will-afd-in-deutschland-halbieren-65455256>
- **Friedrich Merz**: falsch: „Ärzte sind Nutznießer des Gesundheitssystems.“ → **richtig:** „Wir geben über 500 Milliarden Euro für unser Gesundheitssystem aus und da sind Sie als Teil dieses Gesundheitssystems auch Nutznießer. Sie als Ärztin, Sie könnten ohne dieses Gesundheitssystem nicht leben.“. Er sprach eine einzelne Ärztin direkt an; die verallgemeinerte Fassung ist eine Zuspitzung der Debatte. Quellen: <https://www.stuttgarter-zeitung.de/politik/interview-mit-kinderaerztin-bei-rtl-die-nutzniesser-aussage-von-merz-im-wortlaut-79429061.html>
- **Friedrich Merz**: falsch: „Die Deutschen sind 14,5 Tage im Jahr krank – das ist zu viel.“ → **richtig:** „Das sind fast drei Wochen, in denen die Menschen in Deutschland aus Krankheitsgründen nicht arbeiten. […] Ist das wirklich richtig? Ist das wirklich notwendig?“. Die Zahl 14,5 stammt aus Statistiken in der Berichterstattung, nicht aus Merz' Wortlaut (Bad Rappenau, 17.01.2026). Quellen: <https://www.lto.de/recht/nachrichten/n/zu-viele-krankheitstage-telefonische-au-arbeitszeitgesetz-merz-kritik>
- **Friedrich Merz**: falsch: „Mit Work-Life-Balance und Vier-Tage-Woche ruiniert ihr den Wohlstand. / '…den Wohlstand unseres Landes…'“ → **richtig:** „Mit Vier-Tage-Woche und Work-Life-Balance werden wir den Wohlstand dieses Landes nicht erhalten können“. dpa/Berliner Zeitung: 'dieses Landes'; Ippen-Medien 'unseres Landes'. Eine längere AFP-Fassung ('…und deswegen müssen wir mehr arbeiten') ist nur über Sekundärzusammenfassungen belegt. Quellen: <https://www.berliner-zeitung.de/article/2324747>
- **Jens Spahn**: falsch: „Hartz IV bedeutet nicht Armut.“ → **richtig:** „Niemand müsste in Deutschland hungern, wenn es die Tafeln nicht gäbe. / Damit hat jeder das, was er zum Leben braucht.“. In allen geprüften Agentur- und Zeitungstexten nur als indirekte Rede ('Hartz IV bedeute nicht Armut, sondern sei die Antwort der Solidargemeinschaft auf Armut'). Original-Interview (Funke/Berliner Morgenpost, März 2018) nicht eingesehen. Im Spiel nur als Paraphrase kennzeichnen. Quellen: <https://www.aerzteblatt.de/news/debatte-um-armutsbekaempfung-entbrannt-0e8fb5a0-8932-460c-9203-fe2fb214cca3> · <https://www.evangelisch.de/inhalte/149112/13-03-2018/jens-spahn-sozialverbaende-hartz-iv-beduerfnisse-unzureichend> · <https://www.t-online.de/nachrichten/deutschland/innenpolitik/id_83385430/jens-spahn-rudert-in-hartz-iv-debatte-zurueck-natuerlich-ist-es-schwierig-.html>
- **Jens Spahn**: falsch: „Wir werden einander viel verzeihen müssen.“ → **richtig:** „[…] dass wir nämlich miteinander in ein paar Monaten wahrscheinlich viel werden verzeihen müssen“. Die geglättete Fassung ist der Titel seines Buchs (2022). Der tatsächliche Bundestagswortlaut (22.04.2020) steht im Plenarprotokoll 19/155, S. 19211. Quellen: <https://dserver.bundestag.de/btp/19/19155.pdf>
- **Carsten Linnemann**: falsch: „Ein Kind, das kaum Deutsch spricht oder versteht, hat auf einer Grundschule noch nichts zu suchen. / 'Linnemann fordert Grundschulverbot'“ → **richtig:** „Um es auf den Punkt zu bringen: Ein Kind, das kaum Deutsch spricht und versteht, hat auf einer Grundschule noch nichts zu suchen.“. epd und dpa geben 'spricht und versteht' wieder, die taz 'oder'. Ein Verbot des Grundschulbesuchs forderte er nicht; er wollte Vorschulpflicht und notfalls spätere Einschulung (dpa hatte zunächst anders gemeldet). Quellen: <https://www.evangelisch.de/inhalte/159036/05-08-2019/cdu-politiker-erstklaessler-muessen-gute-deutschkenntnisse-haben> · <https://www.abendzeitung-muenchen.de/politik/debatte-ohne-deutschkenntnisse-kein-grundschulbesuch-art-582068> · <https://taz.de/Grundschul-Forderung-aus-der-CDU/!5611031/>
- **Markus Söder**: falsch: „Die Grünen sind unser Hauptgegner.“ → **richtig:** „Der Hauptkonkurrent um Platz eins sind die Grünen. Sie müssen wir stärker in den Fokus nehmen.“. 'Hauptgegner' ließ sich in den geprüften Quellen nicht als wörtliches Söder-Zitat belegen (der Begriff taucht in CSU-Kontexten z. B. bei Generalsekretär Blume zur Kommunalwahl auf). Belegt ist 'Hauptkonkurrent' (2019). Nicht ausgeschlossen, dass Söder 'Hauptgegner' anderswo sagte – nur ohne Beleg nicht verwenden. Quellen: <https://www.abendzeitung-muenchen.de/bayern/soeder-gruene-sind-gegner-keine-fixierung-auf-rechtsaussen-art-658881>
- **Julia Klöckner**: falsch: „Der Bundestag ist kein Zirkuszelt. (Klöckner zugeschrieben)“ → **richtig:** „Klöckners Sprecher begründete den CSD-Verzicht der Bundestagsverwaltung mit der 'notwendige[n] politische[n] Neutralität der Verwaltung'. Der Zirkuszelt-Satz wird in Berichten Friedrich Merz zugeschrieben.“. Häufige Verwechslung in der Regenbogenflaggen-Debatte 2025. Merz-Wortlaut hier nicht geprüft (Merz separat recherchiert). Zur Flagge selbst ist kein eigenes wörtliches Klöckner-Zitat in den abgerufenen Quellen belegt (nur Sprecher-Zitate). Quellen: <https://www.zdfheute.de/politik/csd-bundestag-regenbogenfahne-kloeckner-100.html>
- **Julia Klöckner**: falsch: „Klöckner: Die Kirchen sollen sich aus der Politik raushalten / Maulkorb für die Kirchen“ → **richtig:** „Ich meine: Klar kann sich Kirche auch zu Tempo 130 äußern, aber dafür zahle ich jetzt nicht unbedingt Kirchensteuer.“. Im Interview sagt sie ausdrücklich 'da kann man alles sicherlich tun und machen'; die 'Maulkorb'-Zuspitzung stammt von Kritikern. Quellen: <https://www.evangelisch.de/inhalte/241992/20-04-2025/bundestagspraesidentin-kloeckner-kirche-muss-sinn-stiften>
- **Alexander Dobrindt**: falsch: „Die Anti-Abschiebe-Industrie sabotiert den Rechtsstaat.“ → **richtig:** „Es ist nicht akzeptabel, dass durch eine aggressive Anti-Abschiebe-Industrie bewusst die Bemühungen des Rechtsstaates sabotiert und eine weitere Gefährdung der Öffentlichkeit provoziert wird.“. Verkürzte Kurzfassung kursiert; das Original bezieht sich auf 'die Bemühungen des Rechtsstaates'. Quellen: <https://www.tagesspiegel.de/politik/csu-landesgruppenchef-dobrindt-beklagt-eine-anti-abschiebe-industrie/21248990.html>
- **Hubert Aiwanger**: falsch: „Hubert Aiwanger hat das antisemitische Flugblatt geschrieben. (als Tatsache)“ → **richtig:** „Ich habe das fragliche Papier nicht verfasst und erachte den Inhalt als ekelhaft und menschenverachtend. (Hubert Aiwanger) / Ich bin der Verfasser dieses in der Presse wiedergegebenen Flugblatts. (Helmut Aiwanger)“. Keine Zitat-, sondern Tatsachenbehauptung mit hohem Rechtsrisiko: Die Süddeutsche nannte ihn als Verfasser, sein Bruder bekannte sich zur Autorschaft. Im Spiel nicht als Tatsache darstellen. Quellen: <https://www.evangelisch.de/inhalte/220113/26-08-2023/wende-im-fall-aiwanger-bruder-bekennt-sich-zu-flugblatt>
- **Alexander Gauland**: falsch: „Hitler und die Nazis sind nur ein Fliegenschiss in der Geschichte.“ → **richtig:** „Hitler und die Nazis sind nur ein Vogelschiss in über 1000 Jahren erfolgreicher deutscher Geschichte.“. Gauland sagte am 02.06.2018 'Vogelschiss'. Friedrich Merz verwechselte es am 29.01.2025 im Bundestag ('Das war Ihr Fliegenschiss, von dem Sie vor Jahr und Tag gesprochen haben'); Stephan Brandner rief dazwischen: 'Er hat nicht „Fliegenschiss“ gesagt! Herr Gauland hat nie „Fliegenschiss“ gesagt!' Auch die Variante 'in unserer über 1000jährigen Geschichte' ist ungenau. Quellen: <https://dserver.bundestag.de/btp/20/20209.pdf> · <https://taz.de/Gaulands-Relativierung-der-NS-Zeit/!5510144/> · <https://www.berliner-zeitung.de/article/vogelschiss-aeusserung-gauland-denkt-nicht-an-entschuldigung-29043>
- **Björn Höcke**: falsch: „Höcke nannte das Holocaust-Mahnmal ein 'Schandmal'.“ → **richtig:** „… das einzige Volk der Welt, das sich ein Denkmal der Schande in das Herz seiner Hauptstadt gepflanzt hat.“. Der Begriff 'Schandmal' ist eine Verkürzung (u. a. in der Argumentation vor dem VG Meiningen, wiedergegeben im VG-Köln-Urteil). Höcke sagte 'Denkmal der Schande'; er behauptete später, damit den Holocaust gemeint zu haben. Quellen: <https://www.tagesspiegel.de/politik/19273518.html> · <https://nrwe.justiz.nrw.de/ovgs/vg_koeln/j2022/13_K_326_21_Urteil_20220308.html>
- **Björn Höcke (über ihn)**: falsch: „Ein Gericht hat festgestellt / entschieden, dass Höcke ein Faschist ist.“ → **richtig:** „Das VG Meiningen entschied am 26.09.2019 im Eilverfahren, dass Demonstranten Höcke in einem konkreten Versammlungskontext 'Faschist' nennen durften, weil ihr Werturteil 'auf einer überprüfbaren Tatsachengrundlage beruht'.“. Das LG Hamburg untersagte am 16.03.2020 (324 O 103/20) per einstweiliger Verfügung die Behauptung, Höcke sei gerichtlich als Faschist eingestuft worden. Rechtlich heikel – nur korrekt formulieren. Quellen: <https://www.lto.de/recht/nachrichten/n/lg-hamburg-324o103-20-einstweilige-verfuegung-aeusserung-hoecke-gerichtlich-zum-faschisten-erklaert> · <https://www.lto.de/recht/nachrichten/n/vg-meiningen-2-e-jj94-19-me-bjoern-hoecke-faschist-afd-gegendemonstration>
- **Björn Höcke**: falsch: „Höcke rief in Gera 'Alles für Deutschland'.“ → **richtig:** „In Gera (12.12.2023) sagte Höcke nur 'Alles für' und animierte das Publikum mit Gesten, 'Deutschland' zu ergänzen; die vollständige Parole verwendete er in Merseburg (29.05.2021).“. Beide Fälle führten zu rechtskräftigen Verurteilungen (LG Halle 14.05.2024 und 01.07.2024; BGH-Beschlüsse 20.08.2025). Quellen: <https://www.beck-aktuell.de/heute-im-recht/rechtsprechung/bgh-3str48424-3str51924-hoecke-revisionen-sa-parole-2025-09-11>
- **Maximilian Krah**: falsch: „Nicht alle SS-Leute waren Verbrecher.“ → **richtig:** „Ich werde nie sagen, dass jeder, der eine SS-Uniform trug, automatisch ein Verbrecher war. / Es gab sicherlich einen hohen Prozentsatz an Kriminellen, aber nicht alle waren kriminell.“. Die Kurzform ist eine Paraphrase der Medien. Wörtliche (übersetzte) Fassung aus La Repubblica, 18.05.2024, siehe krah-01/krah-02. Original italienisch. Quellen: <https://www.juedische-allgemeine.de/politik/eklat-um-ss-aeusserungen-von-maximilian-krah-le-pen-bricht-mit-der-afd/>
- **Tino Chrupalla**: falsch: „Putin hat mir persönlich nichts getan. / Mir hat Putin nichts getan.“ → **richtig:** „Mir hat er nichts getan. Ich sehe keine Gefahr für Deutschland aktuell durch Russland.“. Die Varianten stammen aus Überschriften bzw. der Frageformulierung im ZDF-Morgenmagazin; bei 'Markus Lanz' (11.11.2025) sagte er 'Mir hat er nichts getan'. Quellen: <https://www.berliner-kurier.de/article/chrupalla-bei-lanz-10005221> · <https://www.zdfheute.de/politik/deutschland/chrupalla-russland-aussagen-putin-entspannungspolitik-100.html>
- **Alice Weidel**: falsch: „Wir reißen alle Windräder der Schande ab.“ → **richtig:** „Und ich kann Ihnen sagen, wenn wir am Ruder sind, wir reißen alle Windkraftwerke nieder. Nieder mit diesen Windmühlen der Schande.“. Es heißt 'Windmühlen der Schande' und 'niederreißen'. Weidel schränkte später ein, gemeint sei v. a. der Reinhardswald. Quellen: <https://www.zdfheute.de/politik/deutschland/weidel-afd-windraeder-reinhardswald-windkraft-kritik-100.html>
- **Alice Weidel**: falsch: „Hitler war Kommunist. (als deutsches Originalzitat Weidels)“ → **richtig:** „Original englisch im X-Space mit Elon Musk (09.01.2025); dpa-Übersetzung: 'Er war ein Kommunist und sah sich selbst als Sozialisten.'“. Deutsche Fassungen sind Übersetzungen; englische Transkripte variieren. Als übersetzt kennzeichnen. Quellen: <https://www.juedische-allgemeine.de/politik/weidel-im-talk-mit-musk-hitler-war-ein-kommunist>
- **Alexander Gauland**: falsch: „Wir werden Frau Merkel jagen.“ → **richtig:** „Wir werden sie jagen. […] Wir werden uns unser Land und unser Volk zurückholen. (Mittelsatz laut Tagesspiegel: 'Wir werden Frau Merkel oder wen auch immer jagen' – nicht selbst geprüft)“. Die verbreitete Kurzform ist eine Spiegel-Überschrift; gemeint war die künftige Bundesregierung, 'wen auch immer'. Quellen: <https://www.spiegel.de/politik/deutschland/afd-alexander-gauland-wir-werden-frau-merkel-jagen-a-1169598.html>
- **Frauke Petry**: falsch: „Petry forderte einen 'Schießbefehl' an der Grenze.“ → **richtig:** „Er muss den illegalen Grenzübertritt verhindern, notfalls auch von der Schusswaffe Gebrauch machen. So steht es im Gesetz.“. 'Schießbefehl' ist ein Medien-/Kritikerbegriff, nicht Petrys Wortlaut. Quellen: <https://www.salzburg24.at/news/welt/afd-fordert-schiessbefehl-an-grenze-art-114035> · <https://www.evangelisch.de/inhalte/131288/01-02-2016/petry-relativiert-forderung-nach-schusswaffen-einsatz-grenze>
- **Beatrix von Storch**: falsch: „Ich bin mit der Maus abgerutscht. (als gesichertes Zitat von Storchs)“ → **richtig:** „Nicht gesichert – siehe unverifiziert.“. Der Spiegel berichtete Anfang 2016, von Storch habe sich parteiintern so gerechtfertigt; sie bestreitet, das so gesagt zu haben, und ließ 2017 den Verlag eines Buchs, das das Zitat enthielt, abmahnen. Quellen: <https://www.turi2.de/aktuell/afd-politikerin-geht-gegen-afd-buch-von-spiegel-journalistin-vor/>
- **Alice Weidel**: falsch: „Kopftuchmädchen und Messermänner (verkürzte Zuordnung als Sammelbegriff für alle Muslime) bzw. 'Burkas, Kopftuchmädchen und alimentierte Messermänner'“ → **richtig:** „Burkas, Kopftuchmädchen, alimentierte Messermänner und sonstige Taugenichtse werden unseren Wohlstand, das Wirtschaftswachstum und vor allem den Sozialstaat nicht sichern.“. Maßgeblich ist das Plenarprotokoll 19/32; die Bundestags-Pressemeldung fügt ein 'und' ein. Quellen: <https://dserver.bundestag.de/btp/19/19032.pdf>

## Unverifiziert – nicht verwenden

Diese Sätze kursieren, ließen sich aber nicht wörtlich und zuverlässig belegen. Sie dürfen nicht als Zitat ins Spiel, solange sie nicht am Original geprüft sind.

- **Friedrich Merz** (`merz-35`, bei der Einzelquellen-Prüfung weggelassen): „Wir schauen nicht jeden Tag auf die Umfragen, wir sind auf einem richtigen Kurs“. *Grund:* Nicht bestätigt: Stuttgarter Zeitung (Volltext-Bericht der Rede) und zdfheute enthalten den Satz nicht. Stattdessen merz-39 verwenden.
- **Friedrich Merz** (`merz-36`, bei der Einzelquellen-Prüfung weggelassen): „Wer meint, diesen Leuten seine Stimme geben zu müssen, der hat in der CDU nichts zu suchen“. *Grund:* Korrektur: Der Stuttgarter-Zeitung-Bericht enthält diese Passage nicht (Quelle entfernt). Nur euronews; Wortlaut und Bezug ('diesen Leuten') nicht gesichert.
- **Markus Söder** (`soeder-07`, bei der Einzelquellen-Prüfung weggelassen): „Wir haben in Bayern auf unseren Brezeln mehr Salz als in Berlin auf den Straßen“. *Grund:* Nicht bestätigt: Nur Berliner Zeitung (Überschrift weicht vom Fließtext ab); Nordkurier und Der Standard zur selben Rede ohne diesen Satz.
- **Markus Söder** (`soeder-08`, bei der Einzelquellen-Prüfung weggelassen): „Wir lassen uns nicht vorschreiben, was wir reden, was wir denken. Ich lasse mir nicht vorschreiben, was ich esse.“. *Grund:* Nicht bestätigt: Der Satz steht bei Der Standard nur in einer Bildunterschrift; Zuordnung zu Söder nicht abgesichert.
- **Alexander Dobrindt** (`dobrindt-03`, bei der Einzelquellen-Prüfung weggelassen): „Deswegen bleibe ich dabei: Wir müssen verhindern, dass eine Klima-RAF entsteht.“. *Grund:* Nicht bestätigt: Der vollständige Satz steht nur in einer Quelle. Gesichert (Volksstimme/dpa, Berliner Zeitung 17.11.2022, LTO) ist nur, dass Dobrindt im November 2022 forderte, die Entstehung einer 'Klima-RAF' zu verhindern (indirekte Rede). Den Begriff 'Klima-RAF' im Spiel nur als Schlagwort, nicht als Satzzitat verwenden.
- **Friedrich Merz**: „Die Antwort ist sehr klar und sehr eindeutig: Nein!“. *Grund:* Angeblich Deutschlandfunk-Interview Mitte November 2024 auf die Frage nach einer Lockerung der Schuldenbremse; nur in einem zdfheute-Artikel zitiert, DLF-Original nicht gefunden. Satirisch wertvoll als Kontrast zu 'Whatever it takes' (merz-26) – vor Verwendung im DLF-Archiv prüfen. Achtung: Im selben Zeitraum äußerte sich Merz auch offen für eine Reform, Kontext also genau klären.
- **Friedrich Merz**: „Ich gucke nicht rechts und nicht links. Ich gucke in diesen Fragen nur geradeaus.“. *Grund:* Nur als Zitat im Mund anderer Redner im Plenarprotokoll 20/209 (29.01.2025) belegt ('Das haben Sie noch bei der Vorstellung des Fünf-Punkte-Plans gesagt'); Original-Pressekonferenz (Januar 2025) nicht geprüft.
- **Friedrich Merz**: „Lifestyle-Teilzeit“. *Grund:* Ippen-Überschrift 'Kanzler Merz wettert gegen Lifestyle-Teilzeit'; der Begriff stammt aus einem Vorstoß des CDU-Wirtschaftsflügels (2026). Ob Merz ihn selbst wörtlich benutzt hat, wurde nicht verifiziert.
- **Friedrich Merz**: „Herbst der Reformen“. *Grund:* Schlagwort ab Juli/August 2025 vielfach Merz zugeschrieben; Erstverwendung nicht gesichert. Belegt ist laut Bundestagsbericht (Sept. 2025): 'Der Herbst der Reformen wird auch nicht die letzte Jahreszeit sein, in der wir das Land zum Besseren verändern' – nur über Suchzusammenfassung gesehen, Protokoll nicht geprüft.
- **Friedrich Merz**: „Die Steuererklärung muss auf einen Bierdeckel passen.“. *Grund:* Kein wörtlicher Originalbeleg (2003) gefunden – nur als Konzept 'Bierdeckel-Steuer' verwenden (siehe merz-37).
- **Friedrich Merz**: „Ich habe einige Journalisten, die mit mir in Brasilien waren, letzte Woche gefragt: …“. *Grund:* Einleitung des Belém-Satzes nur in einer web.de/dpa-Fassung gesehen; ZDF zitiert ab 'Wer von euch würde…'. Nur die ZDF-Fassung (merz-19) verwenden.
- **Markus Söder**: „Für mich persönlich gilt: Ich werde das Wort Asyltourismus nicht wieder verwenden, wenn es jemanden verletzt“. *Grund:* Nur bei Junge Freiheit und Tichys Einblick gefunden (angeblich Bayerischer Landtag, 11.07.2018); Landtagsprotokoll und Leitmedien nicht geprüft. Wäre der wichtigste Walk-back zu soeder-01.
- **Markus Söder**: „Die Bevölkerung versteht das Wort 'Asyltourismus' leider sehr genau“. *Grund:* Angeblich Welt am Sonntag (Juli 2018); nur über Junge Freiheit gefunden.
- **Markus Söder**: „(Bäume umarmen / Klimawende-Zitate 2019)“. *Grund:* Kein wörtliches Söder-Zitat zum Bäume-Umarmen gefunden; 'Söder umarmt Bäume' scheint vor allem Spott/Fremdbeschreibung zu sein.
- **Markus Söder**: „(#söderisst-Posts)“. *Grund:* Kein einzelner Post wörtlich geprüft; stattdessen soeder-08 ('Ich lasse mir nicht vorschreiben, was ich esse') verwenden.
- **Markus Söder**: „Die Reichinnek soll sich lieber in einen Trabi setzen und nicht bayerische Produkte missbrauchen.“. *Grund:* Wortlaut zwischen Der Standard und Berliner Zeitung abweichend (Berliner Zeitung: 'Die soll sich lieber in einen Trabi oder in einen Lada setzen' / 'und nicht bayerische Produkte da missbrauchen').
- **Alexander Dobrindt**: „Die Macht des Faktischen wirkt längst. Die Bundespolizisten werden vor Ort die Probleme lösen.“. *Grund:* Nur Ippen-Medien (heidelberg24/echo24, angeblich gegenüber Bild, Juni 2025); ein anderer (Blog-)Text schreibt die Formel Michael Kretschmer zu. Zuschreibung unklar.
- **Alexander Dobrindt**: „(Original-Formulierung 'Klima-RAF', Bild am Sonntag Nov. 2022)“. *Grund:* Original nicht eingesehen; dpa paraphrasiert nur. Belegt ist die Wiederholung vom April 2023 (dobrindt-03).
- **Julia Klöckner**: „Wir sind der Deutsche Bundestag und bei uns weht eine Fahne: Schwarz-Rot-Gold“. *Grund:* Nur in einer Suchzusammenfassung (angeblich ARD-Interview 2025) aufgetaucht, in keinem abgerufenen Artikel wörtlich gefunden.
- **Julia Klöckner**: „Ich freue mich, dass wir Unterstützung haben für unsere Innovations- und Reduktionsstrategie. Weniger Zucker, weniger Salz und weniger Fett in den Produkten, die die Bürger gerne mögen.“. *Grund:* Nestlé-Video Juni 2019: Wortlaut nur bei t-online gefunden; Video selbst nicht geprüft.
- **Carsten Linnemann**: „(Leitkultur-Zitat)“. *Grund:* Kein wörtliches Linnemann-Zitat zur Leitkultur in reputablen Quellen gefunden.
- **Carsten Linnemann**: „Wenn sie mich jetzt aufgestellt hätten, weiß ich nicht, als Gesundheitsminister, wäre ich wahrscheinlich nicht erfolgreich gewesen.“. *Grund:* Phoenix 2025, nur über Apotheken Umschau (Einzelquelle, 'sie/Sie' unklar). Satirisch reizvoll, da er 2026 Gesundheitsminister wurde – vor Verwendung das Phoenix-Video prüfen.
- **Carsten Linnemann**: „Wir werden auch darüber reden, ob die telefonische Krankschreibung so sinnvoll ist oder ob man nicht sagt, wenn man krank ist, muss man zum Arzt gehen“. *Grund:* August 2025 (CDU-Klausur Rheinland-Pfalz); nur über Apotheken Umschau (zitiert Tagesspiegel) gefunden.
- **Jens Spahn**: „Dieser Sozialismus wird bei der Genossin Reichinnek nicht besser funktionieren, als beim Genossen Honecker“. *Grund:* Angebliche Talkshow-Fassung, nur über Apollo News; belegt ist die Parteitagsfassung (spahn-05).
- **Jens Spahn**: „Da würde ich uns einfach empfehlen, … (Satzanfang zu spahn-03)“. *Grund:* Satzanfang nur in Suchergebnis-Snippets (Nordkurier/Schwäbische) gesehen, nicht selbst abgerufen.
- **Christoph Ploß**: „(Gendern-Zitate)“. *Grund:* Aus Zeitgründen nicht recherchiert.
- **Wolfram Weimer**: „(Zitate als Kulturstaatsminister)“. *Grund:* Aus Zeitgründen nicht recherchiert.
- **Beatrix von Storch**: „Ich bin mit der Maus abgerutscht. / … sie sei 'mit der Maus abgerutscht'“. *Grund:* Nur als indirekte, parteiinterne Rechtfertigung vom Spiegel (2016) bzw. im Buch von Melanie Amann berichtet; von Storch bestreitet die Äußerung und ging 2017 per Abmahnung gegen das Buch vor (turi2). Kein Primärbeleg – rechtlich riskant, nicht als ihr Zitat verwenden.
- **Beatrix von Storch**: „Wer das HALT an unserer Grenze nicht akzeptiert, der ist ein Angreifer. Und gegen Angriffe müssen wir uns verteidigen.“. *Grund:* Nur im DIMR-Bericht (zitiert FAZ, 31.01.2016) gefunden; FAZ-Artikel nicht abrufbar, keine zweite Quelle.
- **Beatrix von Storch**: „Gegen Kinder ist der Schusswaffeneinsatz richtigerweise nicht zulässig. Frauen sind anders als Kinder verständig.“. *Grund:* Nur in einer dpa-Meldung (wortgleich auf Ippen-Portalen leinetal24/heidelberg24/echo24) gefunden; keine unabhängige zweite Quelle.
- **Beatrix von Storch**: „Die Pläne für einen Massenaustausch der Bevölkerung sind längst geschrieben.“. *Grund:* Nur im DIMR-Bericht, dort zitiert nach Pfahl-Traughber (2019); Originaltweet (Mai 2016) nicht eingesehen.
- **Björn Höcke**: „Heute lautet die Frage: Schaf oder Wolf. Und ich, nein, wir entscheiden uns in dieser Lage, Wolf zu sein.“. *Grund:* Nur im DIMR-Bericht, zitiert nach Kraske (2021); Datum dort 'Kyffhäusertreffen Juni 2018'. Keine zweite Quelle gefunden.
- **Björn Höcke**: „Ich will, dass Deutschland nicht nur eine tausendjährige Vergangenheit hat. Ich will, dass Deutschland auch eine tausendjährige Zukunft hat.“. *Grund:* Varianten widersprechen sich: SPD-Zitatesammlung nennt Erfurt/FAZ 16.10.2015, das VG-Köln-Urteil gibt in der Zusammenfassung der Antragsteller eine Magdeburg-Variante wieder ('dass Magdeburg und dass Deutschland …'). Kein gesicherter Wortlaut.
- **Björn Höcke**: „Thüringer! Deutsche! 3.000 Jahre Europa. 1.000 Jahre Deutschland.“. *Grund:* Nur mit 'soll gerufen haben' berichtet (web.de/dpa 2015).
- **Jens Maier**: „Ich erkläre hiermit diesen Schuldkult für beendet, für endgültig beendet.“. *Grund:* Nur Fragmente gesichert ('Schuldkult', 'für endgültig beendet' – L-IZ, LTO); vollständiger Satz variiert zwischen Quellen.
- **Jens Maier**: „Breivik ist aus Verzweiflung heraus zum Massenmörder geworden.“. *Grund:* Laut BfV-Gutachten/Parteiausschlussantrag (LTO); Maier bestreitet die Äußerung, die Videoaufnahme ist verschwunden. Rechtlich riskant.
- **Tino Chrupalla**: „Das will ich ganz klar dementieren. (zur Verwendung des Wortes 'Umvolkung')“. *Grund:* ZDF-Interview mit Theo Koll nach seiner Wahl zum Parteichef (Ende Nov./1.12.2019); wörtlich nur in einem Ippen-Artikel (heidelberg24) gefunden; ZDF-Original nicht mehr abrufbar. Auch 'Habe ihn nicht bewusst gesetzt' nur dort.
- **Alice Weidel**: „Wir schließen alle Gender Studies und schmeißen die Professoren raus.“. *Grund:* Riesa 11.01.2025; wörtlich nur in der taz gefunden (zwei taz-Artikel). Ein Transkript gibt es nur sinngemäß wieder. Für 'verifiziert' fehlt eine unabhängige zweite Quelle.
- **Alexander Gauland**: „Wir versuchen, die Grenzen des Sagbaren auszuweiten. / Und ja, da findet eine Ausweitung der sagbaren Zone statt, und das ist auch beabsichtigt.“. *Grund:* Nur im DIMR-Bericht, zitiert nach 'Frankfurter Allgemeine Woche' (08.06.2018); FAZ nicht abrufbar.
- **Jörg Meuthen (2022 aus der AfD ausgetreten)**: „links-rot-grün verseuchtes 68er-Deutschland“. *Grund:* Stuttgarter Parteitag 30.04.2016; Wortlaut variiert zwischen Quellen ('verseucht' vs. 'versifft', Datum/Parteitag uneinheitlich).
- **Andreas Kalbitz (2020 Mitgliedschaft annulliert)**: „Die AfD ist die letzte evolutionäre Chance für dieses Land. Danach kommt nur noch ‚Helm auf‘.“. *Grund:* Nur via news4teachers, das sich auf 'Welt' beruft (Kyffhäuser 2017); Welt-Artikel nicht abgerufen.
- **Maximilian Krah**: „Schau keine Pornos, wähl' nicht die Grünen, geh' raus an die frische Luft …“. *Grund:* TikTok 2023; nur bei Nordkurier wörtlich gefunden.
- **Björn Höcke**: „Mit der Bombardierung Dresdens und der anderen deutschen Städte wollte man nichts anderes als uns unsere kollektive Identität rauben.“. *Grund:* Nur im Spiegel (12.03.2020, nach Verfassungsschutz) gefunden, ohne genaues Datum/Ort ('2017 in Sachsen').
- **Ulrich Thomas (CDU)**: „Wir sollten eine Koalition jedenfalls nicht ausschließen. / Stand jetzt ist sie nicht möglich, wir wissen aber nicht, wie die Lage in zwei oder fünf Jahren ist.“. *Grund:* MZ via t-online 2019; Einzelquelle
- **Lars-Jörn Zimmer (CDU)**: „CDU-Minderheitsregierung mit AfD-Duldung 'absolut denkbar' (ZDF Berlin direkt, 09.02.2020)“. *Grund:* nur Volksstimme-Bericht, übrige Aussagen indirekte Rede; Wortlaut ('absolut denkbar') nur Fragment
- **Alexander Räuscher (CDU)**: „Sozial wäre wenn alle 'Faulen' knallhart aussortiert werden, um nur echt Bedürftigen zu helfen (Tweet Juli 2023)“. *Grund:* nur Volksstimme
- **Sven Rosomkiewicz (CDU, MdL Sachsen-Anhalt)**: „Dort wurden die linksgrünen 'Ökofaschisten' bei der Landtagswahl 2022 mit 32,5% (!) stärkste Kraft. (Tweet 05.07.2023)“. *Grund:* Volksstimme (zwei Artikel, z. T. dpa) + Junge Freiheit; für Sprechblase nach zweiter unabhängiger Quelle suchen; Entschuldigung: 'über das Ziel hinausgeschossen'
- **Andreas Bühl (CDU Thüringen)**: „Ich finde, das ist ein Kampfbegriff. (zu 'Brandmauer', 15.09.2026)“. *Grund:* nur hessenschau
- **Saskia Ludwig (CDU)**: „Die Brandmauer halte ich für einen politischen Irrweg (17.03.2026)“. *Grund:* nur heidelberg24
- **Sven Schulze (CDU, MP Sachsen-Anhalt)**: „'von Landtagssitzung zu Landtagssitzung' (MDR-Interview Anfang Okt 2026, zur Kooperation mit der AfD)“. *Grund:* nur Correctiv-Fragment
- **Alexander Räuscher / Mario Voigt**: „Voigt (Thüringen) soll im Spiegel die Brandmauer für 'beendet' erklärt haben“. *Grund:* nur exxpress/Apollo News, Wortlaut nicht prüfbar
- **Ulrich Siegmund (AfD)**: „Remigration ist viel mehr als nur eine Abschiebung. / Remigration trifft alle Menschen, die keinen Beitrag leisten wollen. (Phoenix-Interview 2026)“. *Grund:* nur Correctiv, Datum unbekannt
- **Christian Lüth (AfD, Fraktionssprecher)**: „'Wir können die nachher immer noch alle erschießen [...]' (Aufnahme Feb 2020, ProSieben)“. *Grund:* NICHT verwenden: ProSieben nennt es aus Gedächtnisprotokoll rekonstruiert (dpa/Jüdische Allgemeine) - kein wörtlicher Mitschnitt, Wortlaut variiert
- **Jörg Prophet (AfD Thüringen)**: „Gleichsetzung Auschwitz/Dresden laut Buchenwald-Komitee (Jan 2025)“. *Grund:* nur Vorwurf Dritter, Prophets eigener Wortlaut nicht gefunden
- **Wolfgang Gedeon (AfD, 2016)**: „'Zivilreligion des Westens', Neonazis 'Dissidenten' (Buch 'Der grüne Kommunismus')“. *Grund:* Buch nicht eingesehen, nur Sekundärzitate
- **Martin Hohmann (CDU, 2003)**: „Rede 'Gerechtigkeit für Deutschland' (Neuhof, 03.10.2003)“. *Grund:* Volltext nicht gefunden; Aussage notorisch umstritten ('Tätervolk') - nicht empfohlen
- **Maaßen (CDU)**: „'Rassenlehre' (Wallasch-Interview Jan 2023)“. *Grund:* Wortlaut je nach Medium 'grün-rot'/'rot-grün' - umstritten, nicht nutzen
