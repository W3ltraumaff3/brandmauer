# Verifikation der Zitate (Stand 1. November 2026)

Geprüft wurden alle 59 Ids aus `auswahl.json` sowie die 12 zusätzlich gewünschten Ids (zusammen 71). Methode: Abgleich mit Primärquellen, wo abrufbar (Bundestags-Plenarprotokolle 19/32, 19/155, 20/209, 21/15, 21/17, Urteil VG Köln 13 K 326/21, Transkript der Bundesregierung), sonst mit mindestens zwei Pressequellen. Ehrlicher Vorbehalt: Videos und Audio waren nicht auswertbar. "ok" heißt also bei Pressezitaten: Wortlaut stimmt mit den Quellen überein, ohne Abgleich am Originalton.

Korrekturen stehen in `scripts/pruefung.py` (`KORREKTUREN`), der Kurzkontext in `scripts/kontext_kurz.py`; `zitate_de.*` wurde nur per Build erzeugt.

## hoecke-02: Urteil

Der Wortlaut "Wir brauchen nichts anderes als erinnerungspolitische Wende um 180 Grad!" ist richtig, **ein "eine" gehört nicht hinein**. Drei unabhängige Transkripte der Dresdner Rede vom 17.01.2017 stimmen überein: Tagesspiegel-Dokumentation (https://www.tagesspiegel.de/politik/19273518.html), brightsblog-Transkript (https://brightsblog.wordpress.com/2017/01/19/transkript-hoecke-dresden-rede-17-1-2017/) und geschichte-und-politik.info (https://www.geschichte-und-politik.info/politik/aktuell/brandrede/redeanalyse.html, Transkript eines YouTube-Mitschnitts). Später in der Rede sagt er "diese erinnerungspolitische Wende um 180 Grad". Das "eine" steht nur in Überschrift und Anmoderation des Tagesspiegel ("Wir brauchen eine erinnerungspolitische Wende um 180 Grad", "hat ... eine ... gefordert"). Das Zitat bleibt unverändert; der Notiz wurde das Ergebnis hinzugefügt. Grenze: das Video selbst wurde nicht abgehört; die drei Transkripte sind aber unabhängig voneinander entstanden.

## Korrekturen

- **merz-01**: alt: "[…] aber wir haben natürlich immer im Stadtbild noch dieses Problem, und deswegen ist der Bundesinnenminister ja auch dabei, jetzt in sehr großem Umfang Rückführungen zu ermöglichen und durchzuführen." → neu: "[…] aber wir haben natürlich immer im Stadtbild noch dieses Problem" (Stuttgarter Zeitung nach Video hat "in sehr großem Umfang Rückführungen", zdfheute u. a. "in sehr großem Umfang auch Rückführungen"; ohne Video nicht entscheidbar, das Fragment ist in allen Quellen gleich).
- **merz-19**: Datum "2025-11" → "2025-11-13" (Bundesregierung, Rede beim Handelskongress). Wortlaut bestätigt. Keine Stadt (nicht "Belém") nennen.
- **weidel-03**: alt: "Er war ein Kommunist und sah sich selbst als Sozialisten." → neu: "Er war dieser kommunistische, sozialistische Typ. Punkt." (dpa-Übersetzung, Jüdische Allgemeine und Stuttgarter Zeitung; die alte Fassung steht nur in der Jüdischen Allgemeinen). Bleibt Übersetzung des englischen Gesprächs, "(übersetzt)" kennzeichnen.
- **gauland-04**: alt: "Wir werden sie jagen. […] Wir werden uns unser Land und unser Volk zurückholen." → neu: "Wir werden sie jagen! […] und wir werden uns unser Land und unser Volk zurückholen!" (Buchauszug; näher am Original). Kurzform fürs Spiel bleibt "Wir werden sie jagen."
- **Metadaten ohne Änderung des Zitats**: merz-33 (Kontext: AfD "über 40 %" statt "knapp unter absoluter Mehrheit"), petry-01 (Kontext: unbelegte Angabe "Flüchtling am Zaun" entfernt), spahn-01 (Kontext: Funke/Berliner Morgenpost nicht bestätigt, entfernt), soeder-02 (Quelle perlentaucher ergänzt).

## Neu unverifiziert

Keine. Siehe unten "Mit Vorbehalt" für Fälle, die schwächer belegt sind als der Status vermuten lässt.

## Mit Vorbehalt (Status bleibt `verifiziert`)

- **merz-08**: Zahn-Satz in mehreren Quellen gesichert; die Mitte ("die vollen Leistungen bekommen, die volle Heilfürsorge bekommen") nur in der bestehenden Notiz, vom Prüfer nicht wortgenau gegen Video bestätigt. Datum 27.09. (taz nennt 28.09.).
- **merz-06**: Die Wiederholung "nach Deutschland, zurück in die Ukraine, nach Deutschland, …" wurde in dieser Runde nicht erneut abgerufen (Kurzform bis "Flüchtlinge" bestätigt, Schwäbische/dpa).
- **merz-30**: "[…]" zwischen den Satzteilen ist laut LTO womöglich unnötig (Teile direkt benachbart); bleibt als vorsichtige Auslassung. Datum 17.01.2026 nicht eigens bestätigt (LTO vom 19.01.).
- **merz-26**: Datum 04.03.2025 nicht belegt, Mittelteil nur über zdfheute-Fragmente.
- **merz-29**: nur als Fragment verwenden.
- **hoecke-06**: nur als Fragment verwenden; vollständiger Satz nicht gefunden.
- **weidel-06**: nur als Fragment "rot lackierte Nazis" (taz schreibt mit Bindestrich).
- **chrupalla-01**: zweiter Satz bei zdfheute abweichend formuliert; sicherste Kurzform "Mir hat er nichts getan."
- **soeder-02**: Pressekonferenz/Video nicht eingesehen; ganzer Satz bei bpb und perlentaucher.
- **scheuer-01**: Datum 15.09.2016 nur erschlossen ("am Donnerstag", epd vom 19.09.2016, Presseclub Regensburg); Wortlaut nur bei epd (zwei Abdrucke). Einzelquelle.
- **amthor-01**, **amthor-04**, **soeder-04**: Einzelquelle (dpa bzw. ZDF), wie in den Notizen vermerkt.
- **krah-01**: deutsche Übersetzung des italienischen Originals (La Repubblica). "(übersetzt)" kennzeichnen.
- **hoecke-10**: Satz stammt vom VG Meiningen, nicht von Höcke.
- **hoecke-04**, **hoecke-06**, **hoecke-07**, **maier-01**: Buch bzw. BfV-Gutachten nicht selbst eingesehen; Wortlaut aus Urteil VG Köln und DIMR-Gutachten.
- **krah-03**: Zeichensetzung variiert zwischen Medien; Wortlaut identisch.
- **spahn-03**: Bild-Original nicht gesehen; zdfheute-Wiedergabe, "[…]" am Anfang ehrlich.
- **gauland-05**: dpa schreibt "Deutschtürkin", Daten "Deutsch-Türkin"; nur Schreibweise.

## Ergebnis je Zitat

Alle übrigen Ids: **ok** (Wortlaut stimmt mit den genannten Quellen überein). Primärquelle Plenarprotokoll: merz-12, merz-14, merz-15, merz-18, spahn-02, brandner-01, storch-04, weidel-01, weidel-02. Gerichtsurteil: hoecke-07, maier-01, hoecke-10.

| id | Ergebnis |
|---|---|
| merz-01 | korrigiert (gekürzt, siehe oben) |
| merz-02 | ok ("dann fragen Sie mal Ihre Töchter, was ich damit gemeint haben könnte"; Satzanfang großgeschrieben) |
| merz-03 | ok |
| merz-05 | ok (Berliner Zeitung; Sendedatum 10.01.2023 erschlossen) |
| merz-06 | ok, mit Vorbehalt |
| merz-08 | ok, mit Vorbehalt |
| merz-09, 10 | ok |
| merz-12, 14, 15 | ok (Plenarprotokoll 20/209) |
| merz-16, 17 | ok |
| merz-18 | ok (Plenarprotokoll 21/17) |
| merz-19 | korrigiert (Datum) |
| merz-21, 24, 28, 32, 33 | ok |
| merz-26, 29, 30 | ok, mit Vorbehalt |
| soeder-02 | ok, mit Vorbehalt |
| soeder-04, 05, 06 | ok |
| linnemann-01, 03, 05 | ok |
| spahn-01 | ok (Kontext korrigiert) |
| spahn-02 | ok (Plenarprotokoll 19/155) |
| spahn-03, 04, 05 | ok |
| dobrindt-01, 02 | ok |
| kloeckner-01 | ok |
| amthor-01, 04 | ok (Einzelquelle) |
| aiwanger-01 | ok |
| scheuer-01 | ok (Datum erschlossen, Einzelquelle) |
| weidel-01, 02 | ok (Plenarprotokoll 19/32) |
| weidel-03 | korrigiert |
| weidel-04, 05, 07, 08 | ok |
| weidel-06 | ok, nur als Fragment |
| hoecke-01, 03, 04, 07, 09 | ok |
| hoecke-02 | ok (unverändert, siehe Urteil oben) |
| hoecke-06 | ok, nur als Fragment |
| hoecke-10 | ok (Gerichtszitat) |
| gauland-01 | ok |
| gauland-04 | korrigiert |
| gauland-05 | ok |
| chrupalla-01 | ok, mit Vorbehalt |
| chrupalla-04 | ok (Antwort "Heinrich Heine" nach Nachfrage zum Lieblingsdichter; Sendetermin nicht ermittelt) |
| storch-01, 02 | ok |
| storch-04 | ok (Plenarprotokoll 21/15) |
| krah-01 | ok (Übersetzung) |
| krah-03 | ok |
| brandner-01 | ok (Plenarprotokoll 20/209) |
| petry-01 | ok (Kontext korrigiert) |
| maier-01 | ok |

## Kontext (Task B)

`kontext_kurz` steht jetzt bei allen 121 Einträgen (höchstens 90 Zeichen). Quelle: `scripts/kontext_kurz.py`, Feld in `build_all.py` und im `FIELDS`-Set von `tests/test_quotes.py`. Bei nicht verwendbaren Einträgen (`unverifiziert`) steht der Zusatz "nicht bestätigt, nicht verwenden". chrupalla-04: Er konnte zuerst kein Lieblingsgedicht nennen und antwortete nach Nachfrage zum Lieblingsdichter "Heinrich Heine"; die Quellen rahmen das unterschiedlich, daher steht im Kurzkontext nur die Frage, nicht die Wertung.
