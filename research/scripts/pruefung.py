# -*- coding: utf-8 -*-
"""Einzelquellen-Prüfung und neue Statusregeln (Nachtrag 2026-11-01)."""
import re

NEW_MERZ = [dict(
    id="merz-39", sprecher="Friedrich Merz", partei="CDU",
    rolle_damals="Bundeskanzler (seit 6. Mai 2025) und CDU-Bundesvorsitzender",
    zitat="Denn wir sind die Kraft, die Deutschland stabil auf Kurs hält.",
    datum="2026-10-24",
    kontext="Rede auf dem CSU-Parteitag in München, sechs Wochen nach der verlorenen Landtagswahl in Sachsen-Anhalt; die Union lag in Umfragen hinter der AfD.",
    quellen=["https://www.stuttgarter-zeitung.de/politik/csu-parteitag-in-muenchen-merz-fordert-zukunftsmut-und-offenheit-gegenueber-ki-79606641.html",
             "https://de.euronews.com/2026/10/24/schauen-nicht-auf-umfragen-merz-csu-parteitag"],
    status="verifiziert", kategorien=["Demokratie/Medien", "Sonstiges/Absurd"], kurz=True,
    notizen="Ersetzt den nicht bestätigten Umfragen-Satz (merz-35). Fortsetzung laut Stuttgarter Zeitung: 'Wir sind diejenigen, mit denen Deutschland stark und sicher bleibt, auch im Angesicht der Gefahren von innen und von außen.' euronews ohne 'Denn'. Stand 11/2026: Bundeskanzler und CDU-Bundesvorsitzender.")]

HIGH = "hoch"
MID = "mittel"
LOW = "niedrig"

# id -> (Originalquelle, Rating, Ergebnis, patch-dict)
CHECKS = [
    ("merz-11", "zdfheute (ZDF)", HIGH, "bestätigt durch AFP (web.de)",
     dict(add=["https://web.de/magazine/politik/inland/merz-kuendigt-harte-debatte-spd-sozialstaatsreformen-41307416"], unflag=True)),
    ("merz-27", "Berliner Zeitung", MID, "bestätigt durch zdfheute (29.09.2025, Ständehaus-Treff Düsseldorf)",
     dict(add=["https://www.zdfheute.de/politik/ausland/merz-frieden-bedrohung-russland-100.html"],
          drop=["https://www.zdfheute.de/briefing/merz-ukraine-nahost-prosor-solingen-zdfheute-update-100.html"],
          note="Datum und Ort durch ZDF bestätigt (Montag, 29.09.2025, 'Ständehaus Treff' der Rheinischen Post). Laut ZDF hatte sich Merz in der Woche davor schon fast wortgleich geäußert.",
          notes_sub=[("Datum erschlossen ('zu Wochenbeginn' vor dem 01.10.2025). ", "")])),
    ("merz-33", "Apotheke Adhoc (Fachpresse)", MID, "bestätigt durch dpa via euronews und news.at",
     dict(add=["https://de.euronews.com/2026/09/07/merz-wahlschlappe-wird-konsequenzen-haben",
               "https://www.news.at/politik/merz-wegen-wahl-in-sachsen-anhalt-zutiefst-schockiert"], unflag=True)),
    ("merz-35", "euronews", MID, "WEGGELASSEN: kein zweiter Beleg; Stuttgarter Zeitung und ZDF berichten über die Rede ohne diesen Satz",
     dict(status="unverifiziert", unflag=True, note="Nicht bestätigt: Stuttgarter Zeitung (Volltext-Bericht der Rede) und zdfheute enthalten den Satz nicht. Stattdessen merz-39 verwenden.")),
    ("merz-36", "euronews; dpa-Paraphrase", MID, "WEGGELASSEN: Wortlaut und Bezug unklar; die zuvor zitierte Stuttgarter Zeitung enthält den Satz nicht",
     dict(status="unverifiziert",
          drop=["https://www.stuttgarter-zeitung.de/politik/csu-parteitag-in-muenchen-merz-fordert-zukunftsmut-und-offenheit-gegenueber-ki-79606641.html"],
          note="Korrektur: Der Stuttgarter-Zeitung-Bericht enthält diese Passage nicht (Quelle entfernt). Nur euronews; Wortlaut und Bezug ('diesen Leuten') nicht gesichert.",
          notes_sub=[("Wortlaut weicht ab: euronews wie oben; Stuttgarter Zeitung (dpa) indirekt '…habe in der Partei nichts mehr zu suchen'. ", "")])),
    ("soeder-03", "Abendzeitung München (dpa)", HIGH, "nicht bestätigt; behalten als dpa-Einzelquelle (direktes Zitat). Datum nicht doppelt geprüft",
     dict(flag="EINZELQUELLE (dpa, hoch): direktes Zitat, kein Zweitbeleg gefunden; Datum nicht doppelt geprüft.")),
    ("soeder-04", "Schwäbische Zeitung (dpa)", HIGH, "nicht bestätigt; dpa-Text selbst geprüft, behalten als dpa-Einzelquelle",
     dict(flag="EINZELQUELLE (dpa, hoch): dpa-Text selbst geprüft (Schwäbische, 10.06.2023); der parallele dpa-Text bei inFranken enthält den Satz nicht.")),
    ("soeder-07", "Berliner Zeitung", MID, "WEGGELASSEN: kein Zweitbeleg; Nordkurier-Bericht zur selben Rede enthält den Satz nicht",
     dict(status="unverifiziert", note="Nicht bestätigt: Nur Berliner Zeitung (Überschrift weicht vom Fließtext ab); Nordkurier und Der Standard zur selben Rede ohne diesen Satz.")),
    ("soeder-08", "Der Standard (nur Bildunterschrift)", MID, "WEGGELASSEN: nur in einer Bildunterschrift; Nordkurier zur selben Rede ohne den Satz, Zuordnung zu Söder (vs. Generalsekretär Huber) nicht gesichert",
     dict(status="unverifiziert", note="Nicht bestätigt: Der Satz steht bei Der Standard nur in einer Bildunterschrift; Zuordnung zu Söder nicht abgesichert.")),
    ("linnemann-03", "epd (Fragment)", HIGH, "bestätigt durch AFP (Stuttgarter Zeitung); Zitat auf den vollständigen Satz erweitert",
     dict(add=["https://www.stuttgarter-zeitung.de/politik/berlin-linnemann-will-mehr-als-100000-menschen-buergergeld-streichen-78907034.html"],
          zitat="Die Statistik legt nahe, dass eine sechsstellige Zahl von Personen grundsätzlich nicht bereit ist, eine Arbeit anzunehmen",
          datum="2024-07-28", unflag=True,
          notes_sub=[("Nur als Satzfragment wörtlich belegt (Einzelquelle epd). ", "Vollständiger Satz laut AFP (Stuttgarter Zeitung, 28.07.2024); Fragment auch bei epd. ")])),
    ("linnemann-05", "Apotheken Umschau", MID, "bestätigt durch zdfheute und Ärzteblatt (ntv 'Frühstart', 14.04.2026)",
     dict(add=["https://www.zdfheute.de/politik/deutschland/linnemann-forderung-krankenkasse-reform-verwaltung-100.html",
               "https://www.aerzteblatt.de/news/rubriken/politik/cdu-generalsekretar-linnemann-zehn-krankenkassen-reichen-1ab52b8a-c004-4117-812b-aa0f46fcf940"],
          datum="2026-04-14", unflag=True,
          notes_sub=[("Einzelquelle (Apotheken Umschau, die n-tv zitiert); Original nicht geprüft. ", "Sendung: ntv 'Frühstart' (Dienstag, 14.04.2026 laut zdfheute-Bericht vom 16.04.). ")])),
    ("spahn-04", "Ärzteblatt", HIGH, "bestätigt durch Pharmazeutische Zeitung (und DocCheck)",
     dict(add=["https://www.pharmazeutische-zeitung.de/spahn-verteidigt-masken-deals-und-gesteht-fehler-ein-156628/",
               "https://www.doccheck.com/de/detail/articles/51153-news-bites-deals-hinter-vorgehaltener-maske"],
          unflag=True, note="Variante: Nordkurier gibt eine kürzere Fassung 'Haben ist besser als brauchen' wieder – nicht verwenden.")),
    ("dobrindt-03", "Berliner Zeitung", MID, "WEGGELASSEN: Satz nicht bestätigt (dpa/Berliner Zeitung 2022 nur indirekt); Begriff 'Klima-RAF' selbst ist belegt",
     dict(status="unverifiziert", note="Nicht bestätigt: Der vollständige Satz steht nur in einer Quelle. Gesichert (Volksstimme/dpa, Berliner Zeitung 17.11.2022, LTO) ist nur, dass Dobrindt im November 2022 forderte, die Entstehung einer 'Klima-RAF' zu verhindern (indirekte Rede). Den Begriff 'Klima-RAF' im Spiel nur als Schlagwort, nicht als Satzzitat verwenden.")),
    ("dobrindt-04", "epd", HIGH, "bestätigt durch zdfheute – dort mit Auslassung, deshalb Zitat mit '[…]'",
     dict(add=["https://www.zdfheute.de/politik/deutschland/grenzkontrolle-zurueckweisung-asyl-urteil-rechtswidrig-100.html"],
          zitat="Wir halten […] an den Zurückweisungen fest.", unflag=True,
          note="zdfheute zitiert 'Wir halten (…) an den Zurückweisungen fest.' und weiter: 'Wir sehen, dass die Rechtsgrundlage gegeben ist und werden deswegen weiter so verfahren, ganz unabhängig von dieser Einzelfallentscheidung.'")),
    ("kloeckner-02", "epd", HIGH, "nicht unabhängig bestätigt (nur englische Wiedergabe bei Brussels Signal); behalten als epd-Einzelquelle",
     dict(flag="EINZELQUELLE (epd, hoch): wortgleiche englische Wiedergabe bei Brussels Signal; Bild-am-Sonntag-Original nicht eingesehen.",
          add=["https://brusselssignal.eu/2025/04/church-should-stay-out-of-politics-focus-on-life-and-death-german-parliament-president"])),
    ("amthor-01", "web.de (dpa)", HIGH, "nicht unabhängig bestätigt (t-online/turi2 nur Paraphrase); behalten als dpa-Einzelquelle",
     dict(flag="EINZELQUELLE (dpa, hoch): andere Medien geben 'nicht käuflich' nur als Paraphrase wieder.")),
    ("amthor-03", "zdfheute (ZDF)", HIGH, "nicht unabhängig bestätigt; behalten (ZDF berichtet über eigene Sendung, hoch)",
     dict(flag="EINZELQUELLE (ZDF über eigene Sendung, hoch).")),
    ("amthor-04", "zdfheute (ZDF)", HIGH, "nicht unabhängig bestätigt; behalten (ZDF berichtet über eigene Sendung, hoch)",
     dict(flag="EINZELQUELLE (ZDF über eigene Sendung, hoch).")),
    ("aiwanger-02", "Schwäbische Zeitung (dpa)", HIGH, "nicht bestätigt; dpa-Text selbst geprüft, behalten als dpa-Einzelquelle",
     dict(flag="EINZELQUELLE (dpa, hoch): Wortlaut im dpa-Text (Schwäbische, 10.06.2023) selbst geprüft; andere Berichte ohne diesen Satz.")),
    ("aiwanger-03", "inFranken (dpa)", HIGH, "erste Satzhälfte bestätigt durch Nordkurier (dpa); behalten",
     dict(add=["https://www.nordkurier.de/politik/aiwanger-kontert-kritik-lasse-mich-nicht-mundtot-machen-1681945"],
          flag="Quelle: dpa (inFranken vollständig, Nordkurier bestätigt 'Morgen ruft die AfD dazu auf, in Lederhose aufs Oktoberfest zu gehen'); beide Abdrucke derselben dpa-Meldung.")),
    ("reiche-02", "Nordkurier (dpa)", HIGH, "bestätigt durch zdfheute (26.07.2025)",
     dict(add=["https://www.zdfheute.de/politik/deutschland/arbeiten-rente-katharina-reiche-100.html"], unflag=True,
          notes_sub=[("In Anführungszeichen nur bei Nordkurier (dpa); bei epd nur als Überschrift – faktisch Einzelquelle. ", "Wörtlich bei dpa (Nordkurier) und zdfheute. ")])),
    ("petry-01", "SPD-Zitatesammlung (Interview-Abschrift)", LOW, "Kern bestätigt durch APA/dpa und epd; Zitat auf den bestätigten Teil gekürzt",
     dict(zitat="[…] notfalls auch von der Schusswaffe Gebrauch machen. So steht es im Gesetz.",
          drop=["https://politicalbeauty.de/unsere-nazis/Zypries_Zitatesammlung.pdf"],
          note="Der vollständige Satz ('Er muss den illegalen Grenzübertritt verhindern, …') steht nur in einer Interview-Abschrift einer Partei-Zitatesammlung und wird deshalb nicht verwendet. 'So steht es im Gesetz.' wörtlich bei epd; 'notfalls auch von der Schusswaffe Gebrauch machen' bei APA/dpa.")),
    ("hoecke-07", "Urteil VG Köln 13 K 326/21", HIGH, "behalten: Gerichtsurteil zitiert wörtlich aus der BfV-Belegsammlung (primärnah)",
     dict(flag="Quelle: Gerichtsurteil (primärnah, hoch); Buch selbst nicht eingesehen.")),
    ("hoecke-08", "Urteil VG Köln 13 K 326/21", HIGH, "behalten: Gerichtsurteil (primärnah)",
     dict(flag="Quelle: Gerichtsurteil (primärnah, hoch).")),
    ("krah-04", "Urteil VG Köln 13 K 326/21", HIGH, "behalten: Gerichtsurteil (primärnah)",
     dict(flag="Quelle: Gerichtsurteil (primärnah, hoch); Plattform des Posts unbekannt.")),
]

# Regel 1: 'Gesagt ist gesagt' – umstritten nur bei strittigem Wortlaut/Zuschreibung
REKLASS = {
    "merz-06": ("verifiziert", "Wortlaut gesichert; Entschuldigung vom 27.09.2022 siehe Notizen/merz-07."),
    "merz-23": ("verifiziert", "Wortlaut gesichert; Merz bestreitet die Deutung (Gleichsetzung), nicht den Satz."),
    "merz-25": ("verifiziert", "Wortlaut gesichert; Walk-back am Folgetag siehe Notizen."),
    "linnemann-03": ("verifiziert", "Wortlaut gesichert; umstritten ist die Zahl, nicht das Zitat."),
    "aiwanger-04": ("verifiziert", "Wortlaut seiner Erklärung gesichert; strittig ist die Autorschaft des Flugblatts, nicht dieses Zitat."),
    "weidel-05": ("verifiziert", "Wortlaut gesichert; spätere Einschränkung (Reinhardswald) siehe Notizen."),
    "hoecke-01": ("verifiziert", "Wortlaut gesichert; Höckes spätere Umdeutung siehe Notizen."),
    "gauland-01": ("verifiziert", "Wortlaut gesichert; Distanzierung siehe Notizen."),
    "gauland-05": ("verifiziert", "Wortlaut gesichert; Gauland rückte später nur vom Wort 'entsorgen' ab, bestritt es aber nicht."),
    "storch-02": ("verifiziert", "Wortlaut gesichert; spätere Einschränkung siehe storch-03."),
    "petry-01": ("verifiziert", "Bestätigter Teil des Wortlauts; Relativierung vom 01.02.2016 siehe Notizen."),
}
BLEIBT_UMSTRITTEN = {
    "kloeckner-03": "Klöckner bestreitet, die taz mit Nius verglichen zu haben (Zuschreibung strittig; nur Fragment belegt).",
    "gauland-03": "Gauland bestritt zunächst und stellt den Kontext in Frage (vertrauliches Gespräch, Name Boateng von den Journalisten eingebracht) – Zuschreibung teilweise strittig.",
    "poggenburg-01": "Der Wortlaut des letzten Satzes weicht zwischen den Quellen ab.",
    "helferich-01": "Helferich gibt an, eine fremde Zuschreibung ironisch wiedergegeben zu haben – Zuschreibung strittig.",
}


def apply(ALL, check_rows):
    byid = {q["id"]: q for q in ALL}
    for qid, src, rating, result, p in CHECKS:
        q = byid[qid]
        n = q["notizen"]
        for a, b in p.get("notes_sub", []):
            assert a in n, (qid, a[:40])
            n = n.replace(a, b)
        if p.get("unflag"):
            n = re.sub(r"EINZELQUELLE:[^–]*– vor Verwendung im Zitat-Album Original \(Video/Transkript\) gegenchecken\. ", "", n)
            n = re.sub(r"Einzelquelle \([^)]*\)[^.;]*[.;] ?", "", n)
            n = n.replace(" – Einzelquelle für diesen Satz", "").replace(" (Einzelquelle für exakt diesen Satz)", "")
        if p.get("flag"):
            n = p["flag"] + " " + re.sub(r"^Einzelquelle \([^)]*\)[,;.]? ?", "", n)
        if p.get("note"):
            n = n + " PRÜFUNG 11/2026: " + p["note"]
        q["notizen"] = n.strip()
        for u in p.get("drop", []):
            if u in q["quellen"]:
                q["quellen"].remove(u)
        for u in p.get("add", []):
            if u not in q["quellen"]:
                q["quellen"].append(u)
        if "zitat" in p:
            q["zitat"] = p["zitat"]
            q["kurz"] = len(p["zitat"].split()) <= 15
        if "datum" in p:
            q["datum"] = p["datum"]
        if "status" in p:
            q["status"] = p["status"]
        check_rows.append((qid, q["sprecher"], q["zitat"], src, rating, result))
    for qid, (st, why) in REKLASS.items():
        q = byid[qid]
        assert q["status"] in ("umstritten", "verifiziert"), qid
        q["status"] = st
        q["notizen"] = f"STATUS 11/2026: von 'umstritten' auf '{st}' umgestellt (Regel 'Gesagt ist gesagt'): {why} " + q["notizen"]
    for qid, why in BLEIBT_UMSTRITTEN.items():
        q = byid[qid]
        assert q["status"] == "umstritten", qid
        q["notizen"] = f"BLEIBT 'umstritten', weil: {why} " + q["notizen"]
    # Regel 2: Höcke/Faschist
    h = byid["hoecke-10"]
    h["notizen"] = ("KLARSTELLUNG 11/2026: Höcke im Spiel als Faschisten zu bezeichnen ist als eigene Meinung (Werturteil) zulässig. "
                    "Nur nie behaupten, ein Gericht habe ihn als Faschisten eingestuft oder festgestellt. ") + h["notizen"]
    for qid, k in KORREKTUREN.items():
        q = byid[qid]
        if "zitat" in k:
            q["zitat"] = k["zitat"]
            q["kurz"] = len(k["zitat"].split()) <= 15
        for f in ("datum", "kontext", "status"):
            if f in k:
                q[f] = k[f]
        for u in k.get("add", []):
            if u not in q["quellen"]:
                q["quellen"].append(u)
        q["notizen"] = (q["notizen"] + " " + k["note"]).strip()
    # Regel 3: Drecksarbeit
    d = byid["merz-16"]
    d["notizen"] = "Ausdrücklich fürs Spiel gewünscht (zeigt seine Haltung); Wortlaut gesichert (ZDF selbst). " + d["notizen"]


# Verifikationsdurchgang 11/2026 (siehe research/verifikation.md): Korrekturen am Wortlaut und an Metadaten.
# id -> dict(zitat=, datum=, kontext=, status=, add=[urls], note=)
KORREKTUREN = {
    "merz-01": dict(
        zitat="[…] aber wir haben natürlich immer im Stadtbild noch dieses Problem",
        note="VERIFIKATION 11/2026: Auf das gesicherte Fragment gekürzt. Der Rest des Satzes ist in den Quellen uneinheitlich "
             "(Stuttgarter Zeitung nach Video: 'in sehr großem Umfang Rückführungen', zdfheute und andere: 'in sehr großem Umfang auch Rückführungen'); ohne Video nicht entscheidbar."),
    "merz-19": dict(
        datum="2025-11-13",
        add=["https://www.bundesregierung.de/breg-de/aktuelles/rede-kanzler-handelskongress-2393818"],
        note="VERIFIKATION 11/2026: Rede beim Handelskongress am 13.11.2025, Wortlaut laut Bundesregierung-Transkript. Brasilien-Reise, aber keine Stadt (nicht 'Belém') nennen."),
    "spahn-01": dict(
        kontext="Äußerung in der Debatte um den Aufnahmestopp für Ausländer bei der Essener Tafel (März 2018); er sagte auch: 'Damit hat jeder das, was er zum Leben braucht.'",
        note="VERIFIKATION 11/2026: Der Wortlaut ist bei Tagesspiegel, Ärzteblatt und t-online belegt; das Medium der ursprünglichen Äußerung (Funke/Berliner Morgenpost?) konnte nicht bestätigt werden, daher nicht genannt."),
    "soeder-02": dict(
        add=["https://www.perlentaucher.de/9punkt/2018-04-25.html"],
        note="VERIFIKATION 11/2026: Ganzer Satz bei bpb (Graf) und perlentaucher wiedergegeben; Originalvideo/Pressekonferenz nicht eingesehen. Begründung laut perlentaucher: 'Bekenntnis zur Identität' und zur 'kulturellen Prägung'."),
    "merz-33": dict(
        kontext="Pressekonferenz im Konrad-Adenauer-Haus am Tag nach der Landtagswahl in Sachsen-Anhalt (AfD stärkste Kraft mit über 40 %, CDU historisches Tief).",
        note="VERIFIKATION 11/2026: Kontext präzisiert; nach apotheke adhoc lag die AfD bei rund 44 %, die CDU bei 17,2 %."),
    "petry-01": dict(
        kontext="Interview mit dem 'Mannheimer Morgen' (Samstagsausgabe, 30.01.2016) zum Umgang der Grenzpolizei mit illegalen Grenzübertritten.",
        note="VERIFIKATION 11/2026: Die frühere Angabe, die Frage habe einem über einen Zaun kletternden Flüchtling gegolten, ist in keiner geprüften Quelle belegt und wurde entfernt. Relativierung von Petry und Meuthen am 01.02.2016 beachten."),
    "hoecke-02": dict(
        note="VERIFIKATION 11/2026: Wortlaut ohne 'eine' bestätigt. Drei voneinander unabhängige Transkripte (Tagesspiegel-Dokumentation, brightsblog-Transkript, geschichte-und-politik.info nach YouTube-Mitschnitt) haben übereinstimmend 'Wir brauchen nichts anderes als erinnerungspolitische Wende um 180 Grad!'; später in der Rede 'diese erinnerungspolitische Wende um 180 Grad'. Das 'eine' stammt aus Überschrift und Anmoderation der Tagesspiegel-Dokumentation, nicht aus der Rede. Das DIMR klammert '[eine]' grammatisch ein. Eine eigene Prüfung am Videoton steht aus."),
    "weidel-03": dict(
        zitat="Er war dieser kommunistische, sozialistische Typ. Punkt.",
        note="VERIFIKATION 11/2026: Zitat ersetzt. Die frühere Fassung 'Er war ein Kommunist und sah sich selbst als Sozialisten.' steht nur in der Jüdischen Allgemeinen; die jetzige dpa-Übersetzung steht in Jüdischer Allgemeiner und Stuttgarter Zeitung. Weiterhin nur Übersetzung aus dem englischen Gespräch ('(übersetzt)' kennzeichnen), kein offizielles Transkript."),
    "weidel-06": dict(
        note="VERIFIKATION 11/2026: taz schreibt 'rot-lackierte Nazis' (mit Bindestrich), Stuttgarter Zeitung und Transkript ohne; Wortlaut sonst gleich. Nur als Fragment verwenden, nicht als Satz."),
    "gauland-04": dict(
        zitat="Wir werden sie jagen! […] und wir werden uns unser Land und unser Volk zurückholen!",
        note="VERIFIKATION 11/2026: Zitat näher am Original gesetzt (Buchauszug: 'Wir werden sie jagen! Wir werden Frau Merkel oder wen auch immer jagen und wir werden uns unser Land und unser Volk zurückholen!'); die Auslassung ersetzt 'Wir werden Frau Merkel oder wen auch immer jagen'. Kurzform fürs Spiel bleibt 'Wir werden sie jagen.'"),
    "chrupalla-01": dict(
        note="VERIFIKATION 11/2026: Satz 1 und 2 wortgleich bei Berliner Zeitung, Berliner Kurier und web.de. zdfheute formuliert den zweiten Satz anders ('Ich sehe aktuell durch Russland keine Gefahr für Deutschland.'), vermutlich Paraphrase. Sicherste Kurzform: 'Mir hat er nichts getan.'"),
}
