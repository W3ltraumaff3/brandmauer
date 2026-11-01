# Waffen-Ideen aus der deutschen Protestkultur 2016-2026

Stand: 2026-11-01. 14 Konzepte (19 gesammelt, 5 zusammengelegt oder gestrichen, siehe unten) für "Brandmauer". Recherche per Websuche; was nicht belegt werden konnte, steht unter "Nachprüfen".

## Hinweise

- **Basis:** Werte sind Startvorschläge auf der Skala von GDD §11 (Gendersternchen 6 Schaden / 1,0 s, Döner 12 / 0,9 s, Stricknadeln 3 / 0,35 s, Kleber 2 / 2,2 s). Schaden und Cooldown gelten für Stufe I; Stufe II-IV wie bei den bestehenden Waffen ca. x1,6 / x2,5 / x4. Balancing steht aus.
- **Kinds:** `shot`, `cone`, `orbit`, `puddle`, `turret` existieren. **Neue, einfache Verhalten** sind fett markiert:
  - **lob**: Wurfbogen auf eine Zielmarkierung am Boden, Einschlag nach Verzögerung, reiner Flächenschaden (kein Treffer auf dem Weg, kein Status).
  - **linewall**: setzt ein Wandsegment (Linie) vor den Spieler; Gegner in Kontakt nehmen Tick-Schaden und werden gebremst.
  - **reflect**: Kegel, der gegnerische Projektile umdreht (Besitzer wechselt zum Spieler) - "return to sender".
  - **chain**: Treffer springt auf bis zu N weitere Gegner im Radius R.
  - **fan**: Fächer aus N Schüssen, kurze Reichweite.
  - **mark**: markiert einen Gegner; nach T s oder bei Tod gibt es Bonusschaden bzw. erhöhten Schaden.
  - **trail**: legt beim Laufen Pfützen hinter dem Spieler ab (Variante von `puddle`).
  - **swarm**: N Mini-Begleiter, die je einen Gegner anlaufen und beim Treffer verschwinden.
  - **dash**: Begleiter läuft in einer Linie durch Gegner und zurück.
  - **aura**: ortsfester Stand mit Puls-Radius (Variante von `turret` ohne Projektil).
- **Content:** Alle Ziele sind Mächtige, Institutionen oder Konzerne. Keine Waffe zielt auf Betroffene (Content-Guidelines §4).
- **Zusammengelegt / gestrichen (zu wenig Abstand zu Bestehendem oder zu anderen neuen Waffen):**
  - **W8 Seifenblasen:** gestrichen. Langsamer Schuss, überschneidet sich mit Tofu/Stricknadeln, dazu kein Beleg.
  - **W9 Konfetti-Kanone:** gestrichen. Kegel mit Status ist Megafon/Farbbeutel zu ähnlich; die Kontrollrolle übernimmt die Trillerpfeife (Betäubung). Der "Zirkuszelt"-Gag bleibt als Referenz R8 beim Fahnenmast.
  - **W13 Mülltonnendeckel:** in W3 Regenschirm aufgegangen (beides Blockieren am Körper, Orbit gibt es schon als Mietspiegel).
  - **W15 Farbfeuerlöscher:** gestrichen. Markieren macht jetzt allein die Normenkontrolle (Einzelziel); Flächen-Farbe ist der Farbbeutel; zudem heikel (Kulturgut).
  - **W17 Lichtermeer:** in Mietspiegel-Rolle (Orbit) enthalten, daher gestrichen; Referenz R15 bleibt als Flavor-Quelle für spätere Item-Ideen.
  - W10 Fahnenmast (Heil-Aura) und W14 Baumhaus (Köder-Turm) bleiben getrennt, weil sie unterschiedliche Achsen besetzen (Support vs. Tank/Taunt).
- **Achsen der Abgrenzung:** Einzelziel vs. Gruppe, Burst vs. Dauer, nah vs. weit, Kontrolle (Slow, Knockback, Betäubung) vs. Schaden, Feuermuster (Fächer, Kette, Bogen, Linie, Zone), Takt (sehr schnell vs. sehr langsam und schwer). Die Spalte "Rolle / Unterschied" nennt pro Waffe die wichtigste Abgrenzung.
- **Änderung nach Rücksprache:** Kartoffelbrei ist reiner Flächenschaden ohne Slow und ohne Klebeeffekt, damit es sich klar vom Farbbeutel (direkter Schuss, Splash plus Slow) abhebt.

## Tabelle

Skalierung: Handarbeit = melee, Durchschlagskraft = ranged, Ziviler Ungehorsam = status, Ehrenamt = summon.

| # | Name | Kind | Skalierung | Schaden I | CD (s) | Reichweite | Spezialeffekt | Flavor | Ref | Passt zu | Rolle / Unterschied |
|---|---|---|---|---|---|---|---|---|---|---|---|
| W1 | Kartoffelbrei | **lob** | Durchschlagskraft 1,0 | 18 (Burst) | 3,0 | 340 | Zielmarkierung am Boden, Einschlag nach 0,8 s, großer Radius 110, kein Slow, kein Status | Bitte Abstand zu Gemälden halten. Zu Lobbyist:innen nicht. | R1 | Klimakleber, Lastenrad, Fernkampf | Einzelschuss-Burst auf Gruppe, weit, langsam und schwer; Zielmarkierung, reiner Flächenschaden ohne Kontrolle (Farbbeutel: direkter Schuss + Slow). |
| W2 | Trillerpfeife | cone (360°, Betäubung) | Handarbeit 0,6 | 4 | 2,0 | 150 | Betäubt alle Gegner im Kreis 0,6 s statt Knockback | Ein Pfiff, und die Vorstände hören plötzlich zu. | R2 | Gewerkschaft, Nahkampf | Nahbereich-Kontrolle: Betäubung statt Knockback, 360°, kaum Schaden (Transparent: Schaden + Knockback; Megafon: Kegel vorne). |
| W3 | Regenschirm | **reflect** (cone 180°) | Handarbeit 0,7 | 8 | 1,2 | 100 | Dreht Gegnerprojektile im Kegel um und macht sie zu Spieler-Schüssen | Gegen Regen, Hetze und Querschläger: Oma hat vorgesorgt. | R3 | Oma, Tank-Build | Defensiv-Nahkampf: dreht Projektile um, einzige Waffe gegen Fernkämpfer; mittlere Schadensrate. |
| W4 | Brandmauer-Ziegel | **linewall** | Ehrenamt 1,0 | 3 (Tick 0,5 s) | 4,0 | 220 (Wand 140 breit) | Wand 6 s, bremst Gegner um 0,4, max 2 | Wenn Politiker:innen sie einreißen, mauern wir halt nach. | R4 | Gewerkschaft, Antifa, Summon | Zonen-Kontrolle als Linie: blockierende Wand quer zum Gegnerstrom, setzt Position (Kleber: runde Pfütze, nur Slow). |
| W5 | Normenkontrolle | **mark** | Ziviler Ungehorsam 1,0 | 30 (Detonation) | 4,5 | 360 | Markiert den stärksten Gegner; nach 3 s "nichtig erklärt" (Burst), bei Tod früher | Erst Mietendeckel, dann Karlsruhe: Nichtig erklärt wird heute der Gegner. | R5 | Bürgergeld, Boss-Killer | Einzelziel, extrem langsam und schwer: verzögerter Burst auf den stärksten Gegner, Boss-Killer. |
| W6 | Unterschriftenliste | **chain** | Durchschlagskraft 0,9 | 5 | 1,4 | 260 | Springt auf 3 weitere Gegner (Radius 120), -20 % pro Sprung | Eine Million Ja-Stimmen, und der Senat prüft noch. Wir springen weiter. | R6 | Stadtbild, Schwarm-Gegner | Viele Gegner in Reihe: Kettenblitz mit sinkendem Schaden, mittlere Rate (Gendersternchen: Bounce nur zurück zum Ziel). |
| W7 | Kreide | **trail** (puddle) | Ziviler Ungehorsam 0,8 | 1 (Tick 0,5 s) | 0,8 | 30 (Spur) | Spur hinter dem Spieler, Slow 0,5, 4 s | Kreidemalen ist kein Verbrechen. Regen und Ordnungsamt waschen es ab. | R7 | Lastenrad (Laufwaffe) | Bewegungsgebunden: Spur hinter dem Spieler, Kiter-Werkzeug; Schaden gering (Kleber: geworfener Ort, Spieler steht). |
| W10 | Fahnenmast | **aura** (turret) | Ehrenamt 0,8 | 3 (Puls 1 s) | 6,0 | 120 (Radius) | Steht 12 s, Puls schadet Gegnern und heilt Spieler im Radius 1 HP, max 1 | Hängt sie nicht auf? Dann hissen wir sie selbst. | R8 | Alle, Support | Support-Aura: heilt und tickt, kein Zielen, Begleiter statt Angriff (Infostand: schießt Flugblätter). |
| W11 | Wasserwerfer | cone (schmal, Dauerstrahl) | Durchschlagskraft 0,6 | 3 | 0,25 | 280 (Arc 20°) | Knockback 100 pro Treffer, hält Gegner auf Abstand | Wasser marsch, diesmal in die richtige Richtung. | R9 | Klimakleber, Kiter | Dauerstrahl: sehr schnell, sehr wenig Schaden pro Treffer, Abstandshalter; Kontrolle statt Schaden (Megafon: einzelner Stoß). |
| W12 | Rider | **dash** | Ehrenamt 1,0 | 10 | 3,0 | 300 | 1 Kurier:in läuft durch die Gegnerreihe und zurück, max 2 | Zehn Minuten Lieferzeit, null Minuten Schweigen. | R10 | Lastenrad, Gewerkschaft | Summon-Linie: Kurier:in läuft durch die Reihe und zurück, trifft viele auf einer Geraden (Pfandflasche: Boomerang vom Spieler). |
| W14 | Baumhaus | turret (Tank) | Ehrenamt 1,0 | 5 | 6,0 (Feuer 0,9) | 280 | Steht 14 s, deutlich mehr Leben als Infostand, verlangsamt Gegner im Radius 90 | Brandschutz war vorgeschoben. Das Baumhaus bleibt stehen. | R12 | Klimakleber, Summon | Köder-Turm: viel Leben, zieht Gegner auf sich und bremst sie, schadet kaum (Infostand: Glaskanone, die schießt). |
| W16 | Weißer Overall | **swarm** | Ehrenamt 1,0 | 6 pro Overall | 4,0 | 300 | 3 Aktivist:innen rennen je auf einen Gegner zu, 1 Treffer, dann weg | 6.000 in Weiß, und der Bagger steht still. | R14 | Antifa, Summon-Schwarm | Summon-Schwarm: Einmal-Treffer auf mehrere Ziele gleichzeitig, verteilt Schaden breit (Rider: eine Linie, wiederholt). |
| W18 | Enthüllungs-Scheinwerfer | shot (Strahl, Pierce 99) | Durchschlagskraft 1,0 | 14 | 2,2 | 400 | Gerader Strahl, getroffene Gegner sind "enthüllt": +15 % Krit-Chance für 5 s | Hinterzimmer haben keine Fenster. Jetzt haben sie einen Scheinwerfer. | R16 | Töchter, Crit-Build | Instant-Strahl, sehr weit, durchschlägt alles; Debuff statt Wucht (+Krit), Setup für andere Waffen (Pfandflasche: Boomerang). |
| W19 | 9-Euro-Ticket | **fan** | Durchschlagskraft 0,5 | 2 pro Ticket (x9) | 1,5 | 180 | 9 Tickets im 60°-Fächer; ab Welle 4 nur noch 5 (läuft ab) | Neun Tickets, neun Euro, null Verspätung. Ausnahmsweise. | R17 | Sozialtourist, Nahdistanz | Nah-Fächer: neun Treffer auf kurze Distanz, hoher Burst bei Einzelziel, stark abhängig von Nähe (Stricknadeln: Dauerfeuer weit). |

## Referenzen

Alle Fakten per Websuche geprüft (Stand 2026-11-01). Zitate bewusst nur sinngemäß.

**R1 Kartoffelbrei (W1).** 23.10.2022: Zwei Aktivist:innen der Letzten Generation bewerfen Monets "Getreideschober" (französisch "Les Meules", 1890) im Museum Barberini in Potsdam mit Kartoffelbrei. Das Bild war verglast, laut Museum entstand kein Schaden; das Haus schloss kurz und öffnete am 31.10. mit mehr Sicherheit. Quellen: https://www.museum-barberini.de/files/PM_Vorfall_DE.pdf, https://www.berliner-kurier.de/article/nach-kartoffelbrei-attacke-museum-barberini-schliesst-vorerst-280033

**R2 Trillerpfeife (W2).** 27.03.2023: Gemeinsamer bundesweiter Warnstreik von ver.di und EVG ("Megastreik", Motto "Zusammen geht mehr!"), Fernverkehr der Bahn komplett eingestellt, viele Flughäfen bestreikt. Quellen: https://www.deutschebahn.com/resource/blob/10458086/1fd1f377aeaa01f4122e198e68a39cfe/20230326-Download-PI-Streik-data.pdf, https://trans.info/de/mega-streik-333213. Der Pfeifen-Hook ist Bild-Folklore; ein Beleg für genau diese Pfeifen wurde nicht gesucht.

**R3 Regenschirm (W3).** Omas gegen Rechts mit Schirm: Foto 2020 (Berlin, Demo gegen Querdenker). Belegt sind zudem die Lichtermeer-Demos vom 25.01.2025 (Brandenburger Tor) und die Potsdamer Omas (erste Demo 08.02.2025, ca. 250). Quellen: https://www.berliner-zeitung.de/article/tempelhofer-damm-omas-gegen-rechts-rufen-zu-demo-gegen-querdenker-auf-2289581, https://laif.de/en/lichtermeer-gegen-rechts/. Schwach: Ein Schirm bei einer Demo 2025 ist nicht belegt, daher als Bildmotiv nutzen, nicht als Tatsachenbehauptung.

**R4 Brandmauer-Ziegel (W4).** 29.01.2025: Ein Entschließungsantrag der Union zur Migration erhält im Bundestag mit AfD-Stimmen eine Mehrheit (348:344). Am 30.01. und 01.02. Zehntausende bei "Wir sind die Brandmauer"-Demos. Quellen: https://www.zdfheute.de/briefing/migration-debatte-bundestag-brandmauer-zdfheute-update-100.html, https://orf.at/stories/3383436/. Merz nannte "Brandmauer" selbst das falsche Wort.

**R5 Normenkontrolle (W5).** Beschluss vom 25.03.2021, veröffentlicht am 15.04.2021: Das BVerfG erklärt den Berliner Mietendeckel für nichtig (fehlende Gesetzgebungskompetenz des Landes). Geklagt hatten Abgeordnete von CDU/CSU und FDP. Quellen: https://www.beck-aktuell.de/heute-im-recht/rechtsprechung/bverfg-erklaert-berliner-mietendeckel-fuer-nichtig-2021-04-15, https://www.haufe.de/immobilien/wirtschaft-politik/mietendeckel-bundesverfassungsgericht_84342_541090.html. Ziel des Witzes sind die Kläger-Fraktionen, nicht Mieter:innen. Es gibt schon das Item "Mietendeckel", Namensabgrenzung beachten.

**R6 Unterschriftenliste (W6).** 26.09.2021: Berliner Volksentscheid "Deutsche Wohnen & Co. enteignen", 1.035.950 Ja (57,6 %), nicht bindend; der Senat setzt eine Expert:innenkommission ein. Quellen: https://en.wikipedia.org/wiki/Deutsche_Wohnen_%26_Co._enteignen, https://www.entwicklungsstadt.de/deutsche-wohnen-enteignen-was-aus-dem-berliner-volksentscheid-wurde/

**R7 Kreide (W7).** Kreidemalen als Protest: Münster ("Kreidemalen ist kein Verbrechen", Demo gegen Polizeigewalt); das VG Sigmaringen kippte ein Kreideverbot der Stadt Ravensburg für eine Klimaaktivistin. Quellen: https://ms-aktuell.de/?p=67647, https://www.schwaebische.de/regional/oberschwaben/ravensburg/ravensburg-muss-parolen-mit-kreide-zulassen-2642683. Jahresangaben fehlten im Suchergebnis, vor Veröffentlichung nachprüfen.

**R8 Fahnenmast (W10), Zirkuszelt-Gag.** Juni 2025: Bundestagspräsidentin Klöckner lässt zum Berliner CSD keine Regenbogenflagge hissen; am 01.07.2025 sagt Merz bei "Maischberger", der Bundestag sei "kein Zirkuszelt". 08.07.2025: Campact hisst eine Regenbogenflagge vor dem Bundestag; 25.07.2025 hisst der Bundesrat sie, die BVG färbt die Station Bundestag ein. Quellen: https://www.zdfheute.de/politik/merz-regenbogenfahne-bundestag-zirkuszelt-100.html, https://www.evangelisch.de/inhalte/245294/08-07-2025/campact-hisst-regenbogenflagge-vor-bundestag, https://www.evangelisch.de/inhalte/245891/25-07-2025/bundesrat-hisst-regenbogenflagge-bvg-faerbt-bundestagsstation-ein. Ein Glitzer- oder Konfetti-Angriff auf Politiker:innen beim CSD wurde NICHT gefunden. Ein Zirkus-/Konfetti-Gag (gestrichene W9) wäre Wortspiel, kein Einzelereignis.

**R9 Wasserwerfer (W11).** 14.01.2023: Großdemo bei Lützerath (laut Veranstaltenden ca. 35.000), die Polizei setzt Wasserwerfer ein; die Räumung begann am 11.01., das OVG NRW hatte sie am 09.01. gebilligt. Quellen: https://www.evangelisch.de/inhalte/210783/14-01-2023/immer-noch-aktivisten-im-tunnel-polizei-raeumt-letztes-haus-luetzerath, https://business-humanrights.org/es/últimas-noticias/germany-residents-and-climate-activists-oppose-planned-eviction-of-a-village-for-coal-mining-by-energy-company-rwe. Die "Umkehr" ist reine Spielidee. Ziel im Spiel ist der Konzernapparat, nicht einzelne Polizist:innen; Flavor neutral halten.

**R10 Rider (W12).** 09.06.2021: Erste Streiks bei Gorillas in Berlin (ca. 50 Fahrer:innen); Betriebsratswahl Ende November 2021 gegen den Willen des Managements; Lieferando-Streiks für einen Tarifvertrag. Quellen: https://taz.de/Streik-bei-Gorillas/!5801411/, https://netzpolitik.org/2021/lieferdienst-gorillas-profit-auf-dem-ruecken-der-fahrerinnen/

**R11 Mülltonnendeckel (W13).** 18.08.2020: Das BVerfG nimmt die Verfassungsbeschwerden der Containern-Studentinnen (Olching, 2018) nicht zur Entscheidung an, Containern bleibt Diebstahl; 2023 schlugen Buschmann und Özdemir Straffreiheit vor (Umsetzung nicht geprüft). Quellen: https://www.beck-aktuell.de/heute-im-recht/rechtsprechung/bverfg-verfassungsbeschwerden-strafbarkeit-containerns-gescheitert-2020-08-18, https://jura-online.de/blog/2023/03/01/reformvorschlag-zur-straflosigkeit-des-containerns/

**R12 Baumhaus (W14).** Mitte September 2018: Räumung des Hambacher Forsts, 86 Baumhäuser zerstört, Begründung Brandschutz; 09/2021 erklärt das VG Köln die Räumung für rechtswidrig (Brandschutz vorgeschoben), 2023 sah das OVG NRW es anders. Quellen: https://www.lto.de/recht/nachrichten/n/vg-koeln-23k704618-hambacher-forst-hambi-raeumung-bauhaeuser-zu-unrecht-brandschutz, https://www.lto.de/recht/nachrichten/n/ovg-nrw-7a263521-hambach-hambacher-forst-klima-braunkohle-protest-baumhaus-raeumung-polizei. Der Flavor bezieht sich auf das VG-Urteil; das OVG-Gegenurteil nicht verschweigen.

**R13 Farbfeuerlöscher (W15).** 17.09.2023: Die Letzte Generation besprüht das Brandenburger Tor per Feuerlöscher mit oranger Farbe, 14 Festnahmen, Reinigung mindestens 115.000 Euro, im November erneut Farbe. Eine Aktion "Juni 2023" gibt es nicht. Quellen: https://www.evangelisch.de/inhalte/220890/17-09-2023/letzte-generation-besprueht-brandenburger-tor, https://www.berliner-kurier.de/article/reinigung-des-brandenburger-tores-dauert-laenger-als-erwartet-418752. Heikel, weil Kulturgut betroffen; Alternative: nur eine Konzernfassade zeigen.

**R14 Weißer Overall (W16).** Juni 2019: Ende Gelände blockiert im Rheinischen Revier drei Tage lang (über 6.000 Personen), besetzt u.a. Hambach- und Nord-Süd-Bahn; zuvor Bagger-Besetzungen im Februar 2019 in Lausitz und Leipziger Land. Quellen: https://www.l-iz.de/melder/wortmelder/2019/06/Ende-Gelaende-beendet-Massenaktion-Fast-48-Stunden-Blockade-282108, https://www.zfk.de/politik/deutschland/rheinisches-revier-tausende-besetzen-kohle-bahn

**R15 Lichtermeer (W17).** Nach der Correctiv-Recherche vom 10.01.2024 gehen bundesweit Hunderttausende auf die Straße; 25.01.2025 "Lichtermeer gegen Rechts" am Brandenburger Tor. Quellen: https://www.evangelisch.de/inhalte/226646/03-02-2024/zahlreiche-aktionen-deutschland-zehntausende-bei-demonstrationen-gegen-rechts, https://laif.de/en/lichtermeer-gegen-rechts/

**R16 Enthüllungs-Scheinwerfer (W18).** 10.01.2024: Correctiv veröffentlicht "Geheimplan gegen Deutschland" über das Treffen vom 25.11.2023 in Potsdam (AfD-Politiker:innen, Neonazis, Unternehmer; "Remigration"-Plan). Quellen: https://correctiv.org/top-stories/2024/01/10/geheimplan-remigration-vertreibung-afd-rechtsextreme-november-treffen/, https://correctiv.org/aktuelles/neue-rechte/2025/01/15/faq-geheimplan-recherche-correctiv/. Das LG Hamburg wies zwei Klagen ab, die Berufung läuft (laut Correctiv selbst); der Flavor macht bewusst keine Tatsachenbehauptungen über Einzelpersonen.

**R17 9-Euro-Ticket (W19).** Juni bis August 2022: 52 Millionen verkaufte Tickets (VDV-Bilanz vom 29.08.2022), Kosten des Bundes 2,5 Mrd. Euro, ca. 1,8 Mio. t CO2 gespart (VDV-Schätzung). Quellen: https://www.vdv.de/220829-pm-bilanz-9-euro-ticket.pdfx, https://www.horizont.net/marketing/nachrichten/52-millionen-verkaufte-tickets-vdv-bahn-und-bvg-ziehen-bilanz-zum-9-euro-ticket---und-fordern-anschlussloesung-202280. Das Item "9-Euro-Ticket" (B2) existiert schon, daher als Waffe nur das Fächer-Gimmick.

### Nachprüfen und nicht belegt

- **Seifenblasen (W8, gestrichen):** Keine Quelle zu einem konkreten Demo-Ereignis gefunden.
- **Bollerwagen (1. Mai / Vatertag):** nicht belegt, daher nicht aufgenommen.
- **Klimastreik-Schild:** Termin belegt (20.09.2019, laut Veranstaltenden 1,4 Mio. in Deutschland, ca. 270.000 in Berlin; https://www.evangelisch.de/inhalte/160523/20-09-2019/hunderttausende-demonstranten-fordern-mehr-klimaschutz), das Konzept überschneidet sich aber mit "Transparent" und dem Item "Protestschild", daher nicht aufgenommen.
- **Glitzer-/Konfetti-Attacke auf Politiker:innen:** nicht belegt, deshalb kein Gag, der das behauptet.
- **Adlertreppe/Höcke-Mahnmal (ZPS, 11/2017):** belegt (Nachbau des Holocaust-Mahnmals neben Höckes Wohnhaus), aber wegen des Gedenk-Kontexts nicht als Waffe aufgenommen.
- **Lastenrad-Klingel / Critical Mass:** Das Berliner Mobilitätsgesetz ist belegt (28.06.2018, Volksentscheid Fahrrad, 105.425 Unterschriften in 3,5 Wochen), ein Klingel- oder Critical-Mass-Ereignis nicht.
- **Wasserwerfer-Umkehr, Flugblatt-Kanone, Soli-Kuchen, Plakatwand, Bürgerantrag-Formular:** reine Spielideen ohne Ereignis; Flugblatt gibt es als Infostand-Projektil.

## Top 8

1. **Kartoffelbrei (W1):** Auf ausdrücklichen Wunsch gesetzt. Sofort verständlich, starker Meme-Hook (23.10.2022). `lob` mit Zielmarkierung, 0,8 s Einschlagverzögerung, großem Radius und gutem Burst; reiner Flächenschaden ohne Slow, daher klar vom Farbbeutel getrennt. Der Flavor spielt auf "Abstand zu Gemälden" an.
2. **Brandmauer-Ziegel (W4):** Der Spieltitel als Waffe. Datum belegt (29.01.2025). `linewall` ist neu, einfach und gibt Positionsspiel.
3. **Regenschirm (W3):** `reflect` ("return to sender") ist ein eigener Spielreiz gegen Fernkampf-Gegner und passt zur Oma-Figur.
4. **Enthüllungs-Scheinwerfer (W18):** Starke Referenz (Correctiv 10.01.2024), sauberes Crit-Synergie-Konzept mit den Töchtern, nutzt nur bestehendes Pierce.
5. **Normenkontrolle (W5):** `mark` plus Detonation ist ein guter Boss-Killer, der Witz zielt auf die Kläger-Fraktionen, Datum belegt (15.04.2021).
6. **Weißer Overall (W16):** `swarm` erzeugt ein "Masse"-Gefühl, das zur Gewerkschafts- und Antifa-Fantasie passt; Ende Gelände Juni 2019 ist gut belegt.
7. **Trillerpfeife (W2):** Billigste Umsetzung (Variante von `cone`), klare Stärke (Betäubung), starker Gewerkschafts-Bezug (27.03.2023).
8. **9-Euro-Ticket (W19):** `fan` ist ein trivial zu bauender Schrotflinten-Reiz, und das Ticket ist als Marke bereits bekannt; die Verfallsmechanik passt zum Original.

Knapp raus: Unterschriftenliste (W6, `chain` ist nützlich, der Name schwach) und Baumhaus (W14, gute Taunt-Rolle, braucht Engine-Support für Gegnerziel).
