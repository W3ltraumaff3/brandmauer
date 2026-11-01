# -*- coding: utf-8 -*-
import json, os, sys
from collections import Counter, OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
SP = os.path.join(HERE, "data")
sys.path.insert(0, HERE)
from merz_data import MERZ, MERZ_FALSCH, MERZ_UNVERIFIZIERT
import copy
from pruefung import apply, NEW_MERZ

OUT = os.path.dirname(HERE)
os.makedirs(OUT, exist_ok=True)

FIELDS = ["id", "sprecher", "partei", "rolle_damals", "zitat", "datum", "kontext", "quellen",
          "status", "kategorien", "kurz", "notizen"]
CATS = ["Migration", "Sozialstaat/Arbeit", "Wirtschaft/Kapital", "Klima", "Gender/Familie",
        "Geschichte/NS-Relativierung", "Demokratie/Medien", "Europa", "Sonstiges/Absurd"]


def load(p):
    with open(os.path.join(SP, p), encoding="utf-8") as f:
        return json.load(f)


union = load("union/union_quotes.json")
afd = load("afd/afd_quotes.json")
ux = load("union/union_extra.json")
ax = load("afd/afd_extra.json")


def norm(q):
    q = dict(q)
    if q.get("typ") == "kontext" and not q["notizen"].startswith("KONTEXT-EINTRAG"):
        q["notizen"] = "KONTEXT-EINTRAG (kein Politikerzitat für Sprechblasen; für Album/Ladebildschirm-Infotext). " + q["notizen"]
    out = OrderedDict((k, q[k]) for k in FIELDS)
    assert out["status"] in ("verifiziert", "sinngemäß", "umstritten", "unverifiziert"), q["id"]
    assert all(c in CATS for c in out["kategorien"]), (q["id"], out["kategorien"])
    assert isinstance(out["kurz"], bool)
    return out


ALL = [norm(copy.deepcopy(q)) for q in MERZ + NEW_MERZ + union + afd]
CHECK_ROWS = []
apply(ALL, CHECK_ROWS)
ALL = [norm(q) for q in ALL]
ids = [q["id"] for q in ALL]
assert len(ids) == len(set(ids)), [i for i, c in Counter(ids).items() if c > 1]

with open(os.path.join(OUT, "zitate_de.json"), "w", encoding="utf-8") as f:
    json.dump(ALL, f, ensure_ascii=False, indent=2)

FALSCH = MERZ_FALSCH + ux["falschzitate"] + ax["falschzitate"]
UNVER = MERZ_UNVERIFIZIERT + ux["unverifiziert"] + ax["unverifiziert"]

# ---------------- Markdown ----------------
PERSON_ORDER = [
    ("Friedrich Merz", "CDU", "Bundeskanzler seit 6. Mai 2025, CDU-Bundesvorsitzender"),
    ("Markus Söder", "CSU", "Bayerischer Ministerpräsident, CSU-Vorsitzender"),
    ("Carsten Linnemann", "CDU", "Laut Berichten seit Juli 2026 Bundesgesundheitsminister; zuvor CDU-Generalsekretär (2023–2026)"),
    ("Jens Spahn", "CDU", "MdB; bis 18.07.2026 Vorsitzender der CDU/CSU-Bundestagsfraktion (Nachfolger: Thorsten Frei). Rücktrittsanlass ist privat – im Spiel nicht thematisieren"),
    ("Alexander Dobrindt", "CSU", "Bundesminister des Innern seit Mai 2025"),
    ("Julia Klöckner", "CDU", "Präsidentin des Deutschen Bundestages seit März 2025"),
    ("Philipp Amthor", "CDU", "Staatsminister beim Bundeskanzler (seit 29.07.2026, laut bundesregierung.de)"),
    ("Hubert Aiwanger", "Freie Wähler", "Bayerischer Wirtschaftsminister, stv. Ministerpräsident, FW-Bundesvorsitzender (Stand 11/2026 nicht gesondert geprüft)"),
    ("Katherina Reiche", "CDU", "Bundesministerin für Wirtschaft und Energie seit Mai 2025 (Stand 11/2026 nicht gesondert geprüft)"),
    ("Andreas Scheuer", "CSU", "Ehem. CSU-Generalsekretär und Bundesverkehrsminister; aktuelle Funktion nicht geprüft"),
    ("Alice Weidel", "AfD", "Co-Bundesvorsitzende (bestätigt Erfurt, Juli 2026) und Co-Vorsitzende der AfD-Bundestagsfraktion"),
    ("Björn Höcke", "AfD", "Landessprecher der AfD Thüringen, Fraktionsvorsitzender im Thüringer Landtag; rechtskräftig verurteilt wegen Verwendens der SA-Losung (BGH 2025)"),
    ("Alexander Gauland", "AfD", "MdB, Ehrenvorsitzender der AfD und der Bundestagsfraktion"),
    ("Tino Chrupalla", "AfD", "Co-Bundesvorsitzender und Co-Vorsitzender der AfD-Bundestagsfraktion"),
    ("Beatrix von Storch", "AfD", "MdB, stellvertretende Vorsitzende der AfD-Bundestagsfraktion"),
    ("Maximilian Krah", "AfD", "MdB seit 2025; nicht mehr im AfD-Bundesvorstand/EU-Parlament"),
]
known = {p[0] for p in PERSON_ORDER}
others = []
def grp(q):
    return "Björn Höcke" if q["sprecher"].startswith("Verwaltungsgericht Meiningen") else q["sprecher"]


for q in ALL:
    if grp(q) not in known and grp(q) not in others:
        others.append(grp(q))

HIGHLIGHTS = [
    ("merz-12", "Primärquelle Plenarprotokoll; perfekt für den AfD-Abstimmungs-Boss"),
    ("merz-17", "kurz, absurd, sofort verständlich"),
    ("merz-02", "Kernformel überall identisch belegt"),
    ("merz-14", "Merz zitiert Gauland falsch, AfD korrigiert ihn – Dialog-Szene mit brandner-01"),
    ("merz-09", "Arbeitsmoral-Gegner, Bürgergeld-Level"),
    ("merz-21", "Millionär als 'gehobene Mittelschicht' – BlackRock-Boss-Intro"),
    ("merz-24", "2018 angekündigt, 2026 AfD in Sachsen-Anhalt über 40 % – Ladebildschirm mit Faktenzeile"),
    ("merz-16", "kurz, aber Kontext (Moderatorin brachte das Wort ein) im Album nennen"),
    ("merz-34", "Game-Over-/Respawn-Spruch"),
    ("merz-13", "'Bedauern' wenige Stunden nach merz-12 – Kombi im Album"),
    ("weidel-05", "Windkraft-Boss; Wortlaut sicher, spätere Einschränkung im Album nennen"),
    ("weidel-04", "Parteitag Riesa, wörtlich belegt"),
    ("gauland-04", "kurze Fassung 'Wir werden sie jagen.' verwenden"),
    ("chrupalla-01", "Putin-Verharmlosung, wörtlich belegt"),
    ("spahn-02", "Plenarprotokoll statt geglätteter Buchtitel-Fassung"),
]
byid = {q["id"]: q for q in ALL}
for h, _ in HIGHLIGHTS:
    assert h in byid and byid[h]["status"] == "verifiziert", h


def md_escape(s):
    return s.replace("|", "\\|")


L = []
A = L.append
A("# Zitat-Recherche: Union, Merz & AfD")
A("")
A("Recherche für Ladebildschirme, Boss-Intros, Sprechblasen und das Zitat-Album. Stand: 1. November 2026. Maschinenlesbare Fassung: `zitate_de.json` (gleiche IDs).")
A("")
A("## Überblick")
A("")
st = Counter(q["status"] for q in ALL)
USABLE = [q for q in ALL if q["status"] != "unverifiziert"]
A(f"- **{len(ALL)} Einträge** in der JSON: {st['verifiziert']} `verifiziert`, {st['umstritten']} `umstritten`, {st['sinngemäß']} `sinngemäß`, {st['unverifiziert']} `unverifiziert` (nicht verwenden). **{len(USABLE)} sind verwendbar**, davon {sum(q['kurz'] for q in USABLE)} mit `kurz: ja` (Sprechblasen-tauglich).")
A(f"- **{len(FALSCH)}** häufig falsch zitierte Sätze mit korrekter Fassung und **{len(UNVER)}** nicht verwendbare (unverifizierte) Zitate am Ende des Dokuments.")
A("- Primärquellen wurden wo immer möglich genutzt: Bundestags-Plenarprotokolle 19/32, 19/155, 20/209, 21/3, 21/15, 21/17 (Text per `pdftotext` aus den amtlichen PDFs), Gerichtsentscheidungen (VG Köln 13 K 326/21, BGH 3 StR 484/24 und 519/24, LG Hamburg 324 O 103/20).")
A("")
A("### Statusdefinitionen")
A("")
A("- `verifiziert`: Wortlaut aus Primärquelle (Protokoll, Urteil, eigener Post) oder aus zwei unabhängigen reputablen Quellen. **Ausnahme, offen markiert:** Einträge mit dem Vermerk `EINZELQUELLE (…, hoch)` stammen aus *einer* Quelle mit hoher Reputation (dpa, epd, ZDF über die eigene Sendung) und geben ein direktes Zitat in Anführungszeichen wieder; ein Zweitbeleg ließ sich nicht finden. Siehe „Einzelquellen-Prüfung“.")
A("- `umstritten`: Nur noch, wenn **Wortlaut oder Zuschreibung** tatsächlich strittig sind. Nach der Regel „Gesagt ist gesagt“ bleiben Zitate mit späterer Entschuldigung oder Relativierung `verifiziert`; die Entschuldigung steht in den Notizen.")
A("- `unverifiziert`: Bei der Einzelquellen-Prüfung nicht bestätigt und Wortlaut oder Zuschreibung unsicher. **Nicht im Spiel verwenden.** Diese Einträge stehen nur in der JSON (zur Nachverfolgung) und im Abschnitt „Unverifiziert“ am Ende.")
A("- `sinngemäß`: Nur Paraphrase oder Fragment gesichert. Im Spiel nicht als wörtliches Zitat in Anführungszeichen setzen.")
A("- Übersetzte Zitate (Weidel/Musk auf Englisch, Krah/La Repubblica auf Italienisch) sind als dpa-Übersetzung gekennzeichnet. Im Spiel mit „(übersetzt)“ markieren.")
A("")
A("### Einzelquellen-Prüfung (Nachtrag 11/2026)")
A("")
A("Alle Einträge, die zuvor nur auf einer Quelle beruhten, wurden erneut geprüft. Regel: bestätigt durch eine zweite unabhängige reputable Quelle oder die Primärquelle → `verifiziert`, Flag entfernt. Nicht bestätigt, aber direktes Zitat aus einer Quelle mit hoher Reputation (dpa, epd, ZDF, Gerichtsurteil) → bleibt `verifiziert` mit Vermerk. Nicht bestätigt bei mittlerer oder niedriger Reputation oder unsicherem Wortlaut bzw. unsicherer Zuschreibung → `unverifiziert`, weggelassen. Reputation: hoch = Agentur (dpa/epd/AFP/APA), öffentlich-rechtlicher Rundfunk, Gerichtsurteil; mittel = Regional- oder Fachpresse, Einzelportale; niedrig = Parteimaterial, Blogs, Aggregatoren.")
A("")
A("| id | Sprecher | Zitat (kurz) | Ursprungsquelle (Reputation) | Ergebnis |")
A("|---|---|---|---|---|")
for qid, spr, z, src, rating, res in CHECK_ROWS:
    zs = z if len(z) <= 70 else z[:67] + "…"
    A(f"| `{qid}` | {spr} | „{md_escape(zs)}“ | {md_escape(src)} ({rating}) | {md_escape(res)} |")
A("")
A("Zusätzlich neu aufgenommen: `merz-39` („Denn wir sind die Kraft, die Deutschland stabil auf Kurs hält.“, CSU-Parteitag 24.10.2026, bestätigt durch Stuttgarter Zeitung und euronews) als Ersatz für das weggelassene `merz-35`.")
A("")
A("**Status-Umstellung nach „Gesagt ist gesagt“:** " + ", ".join(f"`{i}`" for i in __import__("pruefung").REKLASS) + " → `verifiziert`. Weiter `umstritten` (Wortlaut oder Zuschreibung strittig): " + ", ".join(f"`{i}`" for i in __import__("pruefung").BLEIBT_UMSTRITTEN) + ".")
A("")
A("### Anzahl pro Person")
A("")
A("| Person | Partei | verwendbar | davon verifiziert | kurz | unverifiziert (weggelassen) |")
A("|---|---|---|---|---|---|")
order_names = [p[0] for p in PERSON_ORDER] + others
for n in order_names:
    qs = [q for q in ALL if grp(q) == n]
    if not qs:
        continue
    us = [q for q in qs if q["status"] != "unverifiziert"]
    A(f"| {n} | {qs[0]['partei']} | {len(us)} | {sum(q['status']=='verifiziert' for q in us)} | {sum(q['kurz'] for q in us)} | {len(qs)-len(us)} |")
A("")
A("### Die 15 besten Highlights fürs Spiel")
A("")
A("| # | Sprecher | Zitat | Datum | Warum |")
A("|---|---|---|---|---|")
for i, (h, why) in enumerate(HIGHLIGHTS, 1):
    q = byid[h]
    A(f"| {i} | {q['sprecher']} | „{md_escape(q['zitat'])}“ | {q['datum']} | {md_escape(why)} (`{h}`) |")
A("")
A("### Rechtliche Leitplanken (Kurzfassung)")
A("")
A("- Zitate nur im dokumentierten Wortlaut verwenden. Kürzungen mit „[…]“ kennzeichnen und nicht sinnentstellend schneiden. Wo die Notizen eine „Kurzform fürs Spiel“ nennen, ist diese geprüft.")
A("- **Höcke/„Faschist“:** Höcke im Spiel als Faschisten zu bezeichnen ist als eigene Meinungsäußerung zulässig. Nur nicht schreiben „ein Gericht hat Höcke als Faschisten eingestuft“. Das LG Hamburg hat diese Behauptung 2020 per einstweiliger Verfügung untersagt. Zulässig ist z. B.: „Das VG Meiningen entschied 2019, dass Demonstranten Höcke in diesem Kontext ‚Faschist‘ nennen durften.“ Siehe `hoecke-10`.")
A("- **Höcke/SA-Losung:** Zwei Verurteilungen (LG Halle, 14.05. und 01.07.2024), seit den BGH-Beschlüssen vom 20.08.2025 rechtskräftig. Die Parole selbst ist nach § 86a StGB strafbewehrt. Im Spiel nur dokumentarisch (Album/Infotext) zeigen, nicht als Sprechblasen-Ruf einer Figur.")
A("- **Aiwanger/Flugblatt:** Nicht als Verfasser darstellen; sein Bruder Helmut hat die Autorschaft erklärt.")
A("- **Privatpersonen** (z. B. die Kinderärztin im RTL-Gespräch mit Merz, `merz-32`) weder namentlich noch bildlich darstellen. Spahns Rücktrittsanlass (Juli 2026) ist privat und sollte nicht thematisiert werden.")
A("- **Entschuldigungen und Relativierungen** (Sozialtourismus, Vogelschiss, Boateng, Windmühlen, Stadtbild-Selbstkritik) gehören ins Album neben das Zitat.")
A("- Satire über reale Politiker ist durch Kunst- und Meinungsfreiheit weit geschützt. Das gilt aber nicht für erfundene Zitate in Anführungszeichen. Wer satirische Fantasie-Sätze schreibt, sollte sie optisch klar von den echten Zitaten trennen (z. B. eigene Schriftart, kein Quellenverweis).")
A("")


def entry(q):
    out = []
    kurz = "ja" if q["kurz"] else "nein"
    out.append(f"#### `{q['id']}` – „{q['zitat']}“")
    out.append("")
    out.append(f"- **Sprecher:** {q['sprecher']} ({q['partei']}), damals: {q['rolle_damals']}")
    out.append(f"- **Datum:** {q['datum']}")
    out.append(f"- **Kontext:** {q['kontext']}")
    out.append(f"- **Status:** `{q['status']}` · **Kategorien:** {', '.join(q['kategorien'])} · **kurz:** {kurz}")
    out.append("- **Quellen:** " + " · ".join(f"<{u}>" for u in q["quellen"]))
    if q["notizen"]:
        out.append(f"- **Notizen:** {q['notizen']}")
    out.append("")
    return out


roles = {p[0]: p[2] for p in PERSON_ORDER}
for n in order_names:
    qs = [q for q in ALL if grp(q) == n]
    if not qs:
        continue
    A(f"## {n} ({qs[0]['partei']})")
    A("")
    if n in roles:
        A(f"*Aktuell (11/2026): {roles[n]}.*")
        A("")
    for c in CATS:
        cq = [q for q in qs if q["kategorien"][0] == c and q["status"] != "unverifiziert"]
        if not cq:
            continue
        A(f"### {c}")
        A("")
        for q in sorted(cq, key=lambda x: x["datum"]):
            L.extend(entry(q))

A("## Häufig falsch zitiert oder falsch zugeschrieben")
A("")
for x in FALSCH:
    A(f"- **{x['sprecher']}**: falsch: „{x['falsch']}“ → **richtig:** „{x['richtig']}“. {x['erklaerung']}" + ("" if not x.get("quellen") else " Quellen: " + " · ".join(f"<{u}>" for u in x["quellen"])))
A("")
A("## Unverifiziert – nicht verwenden")
A("")
A("Diese Sätze kursieren, ließen sich aber nicht wörtlich und zuverlässig belegen. Sie dürfen nicht als Zitat ins Spiel, solange sie nicht am Original geprüft sind.")
A("")
for q in ALL:
    if q["status"] == "unverifiziert":
        A(f"- **{q['sprecher']}** (`{q['id']}`, bei der Einzelquellen-Prüfung weggelassen): „{q['zitat']}“. *Grund:* {q['notizen'].split('PRÜFUNG 11/2026: ')[-1]}")
for x in UNVER:
    A(f"- **{x['sprecher']}**: „{x['zitat']}“. *Grund:* {x['grund']}")
A("")

with open(os.path.join(OUT, "zitate_de.md"), "w", encoding="utf-8") as f:
    f.write("\n".join(L))

print("entries", len(ALL), dict(st), "falsch", len(FALSCH), "unver", len(UNVER))
print(Counter(q["sprecher"] for q in ALL).most_common())
