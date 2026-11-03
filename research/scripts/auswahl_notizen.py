# -*- coding: utf-8 -*-
"""Hand-kept notes for the selection view research/auswahl.md (D-159).

Only ids, reasons and prose live here, never quote texts: build_all.py takes the
quotes from the source data and the selection from research/auswahl.json.
"""

TITEL = "Auswahl: Die drastischsten verifizierten Zitate (Fassung 2, nach D-044)"

UEBERBLICK = (
    "Ausgewählt wurde nach Drastik und Verständlichkeit. NS-/Holocaust-Relativierung und Rassismus stehen auf "
    "Startbildschirm, Ladebildschirm, Boss-Rufen und Sprechblasen, nicht nur im Album. Quellenwahrheit: nur "
    "`verifiziert`, Fragment- und Übersetzungsvorbehalte aus `verifikation.md` bleiben bestehen (Kennzeichnung im "
    "Spiel: \"(übersetzt)\" bei krah-01 und weidel-03; Fragmente nur als Fragment: hoecke-06, weidel-06, weidel-10, "
    "cdu-maassen-01, csu-seehofer-02, merz-29)."
)

# Targets per use (shown next to the generated counts).
VORGABEN = {
    "boss_ruf": "Maximum 4",
    "sprechblase": "Ziel 3",
    "ladebildschirm": "Vorgabe 25–40",
    "startbildschirm": "Vorgabe 8–12; auf Nutzerwunsch eins mehr mit `weidel-01` und `merz-01`",
}

HINWEISE = [
    "`sprechblase:hinterbaenkler`: **zwei Ausnahmen von der Längenregel**: `spahn-03` (19 Wörter, vom Nutzer "
    "ausdrücklich verlangt, beginnt mit \"[…]\", also Fragment) und `cdu-ludwig-01` (16 Wörter, nicht als `kurz` "
    "markiert). Ohne Ausnahmen bleiben 10.",
    "Rassistische Union-Zitate sind für Sprechblasen **zu lang** (`scheuer-01` 22 Wörter, `linnemann-01` 23, "
    "`merz-05` 40). Sie stehen deshalb als Boss-Rufe des Sauerländers und auf dem Ladebildschirm, `scheuer-01` auch "
    "auf dem Startbildschirm. Die Hinterbänkler-Blasen sind überwiegend Brandmauer-/AfD-Kooperationszitate plus "
    "Migrationsrhetorik (`soeder-01`, `csu-seehofer-01`, `dobrindt-02`, `merz-19`).",
    "`startbildschirm`: Grenze etwa 230 Zeichen; `hoecke-01` hat 241 Zeichen (knapp darüber, nicht kürzbar, weil "
    "nichts verkürzt werden darf). Alle anderen liegen bei höchstens 230.",
    "**Charakter-Zitate auf dem Startbildschirm:** Der Nutzer erlaubt, dass Zitate, auf denen eine Freischalt-Figur "
    "beruht, auch auf dem Startbildschirm stehen. Aufgenommen: `weidel-01` (171 Zeichen) und `merz-01` (67 Zeichen), "
    "jeweils zusätzlich zur Karte. `merz-05` hat 255 Zeichen, liegt über der Grenze und darf nicht gekürzt werden; es "
    "bleibt Boss-Ruf und Ladebildschirm. Die übrigen Karten-Zitate (`merz-02`, `merz-06`, `merz-08`, `linnemann-03`, "
    "`dobrindt-01`, `merz-29`) bleiben nur auf der Karte (Content-Guidelines §1).",
    "`freischalt_karte:oma` (`cdu-fraktion-01`, Kleine Anfrage der CDU/CSU-Fraktion, Drucksache 20/15035), "
    "`freischalt_karte:teilzeit` (`merz-40`) und `freischalt_karte:antifa` (`merz-41`) sind echte Vorlagen. "
    "Vorbehalt Teilzeit: Merz sagt in Trier nicht das Wort \"Teilzeit\"; ein wörtliches Merz-Zitat mit \"Teilzeit\" "
    "ist nicht belegt (nur die Wirtschaftsflügel-Forderung \"Lifestyle-Teilzeit\"). Vorbehalt Oma: "
    "Fraktionsdokument, kein Einzelsprecher; Merz und Dobrindt unterzeichnen.",
    "`boss_ruf:eidgenossin`: Für Phase 3 (Steuerparadies) steht `weidel-09` (Erbschaftsteuer, AfD-Pressemitteilung "
    "2016). Reserve: `weidel-10` (Schweizer Wohnsitz, RTL-Quadrell 2025), nur Album, weil die vier Ruf-Plätze "
    "vergeben sind.",
    "`sprechblase:telegram_onkel`, `identitaerer_hipster`, `immobilienerbe`: genau 4, also über dem Ziel von 3, aber "
    "ohne Reserve.",
]

VOR_RELEASE = [
    "Einzelquellen gegenprüfen: `scheuer-01` (epd), `afd-vallendar-01` (dpa), alle `cdu-*` und `csu-*`.",
    "Nachrecherche 11/2026 (`scripts/data/neu/kandidaten.json`, alle `cdu-*`, `csu-*` und `afd-*`): keine Fassung "
    "wurde gegen ein Originalvideo oder Plenarprotokoll geprüft, sofern nicht anders vermerkt. Einträge mit "
    "Hinweisen in den Notizen (`zitate_de.md`) vor Release gegenprüfen.",
    "Weitere offene Prüfungen: `verifikation.md` und `docs/open-questions.md`.",
]

RECHERCHE_LUECKEN = [
    "Nachrecherche 11/2026, Zielvorgabe 8–15 je Kategorie: Union 8, AfD 6 verifiziert. Bei der AfD waren viele der "
    "bekanntesten drastischen Zitate schon in `zitate_de.json`; Neufunde brauchten frischen Beleg.",
    "Die meisten Union-Funde sind keine rassistischen Zitate im engeren Sinn, sondern Brandmauer-/AfD-Öffnungsaussagen "
    "und Migrationsrhetorik; für rassistische Union-Zitate fehlen belegte Neufunde mit zwei Quellen (nicht erfunden, "
    "stattdessen offen gelassen).",
    "Siegmund war laut einer italienischen Schlagzeile (Avvenire: 'Ex Cdu') früher CDU-Mitglied – nicht geprüft, "
    "nicht verwenden ohne Beleg.",
    "Die nicht bestätigten Funde dieser Nachrecherche stehen in `scripts/data/neu/unverifiziert.json` und im "
    "Abschnitt „Unverifiziert“ von `zitate_de.md`.",
]

# Change log of the selection (ids only).
AENDERUNGEN = [
    ("Fassung 2 (nach D-044)", [
        "Behalten: 62 → 90. Verworfen: 48 → 34.",
        "Neu aufgenommen (40): `merz-05`, `merz-20`, `merz-23`, `merz-25`, `merz-31`, `soeder-01`, `linnemann-01`, "
        "`spahn-03`, `scheuer-01`, `reiche-01`, `reiche-02`, `weidel-07`, `hoecke-05`, `hoecke-08`, `gauland-02`, "
        "`gauland-05`, `gauland-07`, `chrupalla-02`, `storch-01`, `storch-03`, `krah-02`, `krah-04`, `brandner-02`, "
        "`petry-01`, `maier-01`, `curio-01`, `cdu-thomas-01`, `cdu-maassen-01`, `cdu-ludwig-01`, `cdu-raeuscher-01`, "
        "`cdu-raeuscher-02`, `cdu-nathusius-01`, `csu-seehofer-01`, `csu-seehofer-02`, `afd-hoecke-11`, "
        "`afd-siegmund-01`, `afd-siegmund-02`, `afd-maier-02`, `afd-vallendar-01`, `afd-petry-02`.",
        "Aus der letzten Auswahl herausgefallen (12): `aiwanger-01`, `spahn-05`, `soeder-02`, `merz-03`, `merz-32`, "
        "`soeder-05`, `merz-33`, `merz-26`, `spahn-02`, `chrupalla-04`, `merz-15`, `merz-24`.",
        "Früher verworfene oder nur im Album geführte Gruppen-Zitate (`hoecke-04`, `hoecke-06`, `krah-01`, `merz-05`, "
        "`storch-01`, `weidel-07`, `gauland-05`, `scheuer-01`, `linnemann-01`, `spahn-03`, `petry-01`, `maier-01`) "
        "stehen jetzt prominent (Boss-Ruf, Startbildschirm, Ladebildschirm oder Sprechblase).",
        "NS-/Holocaust-Relativierung wandert vom Album auf den Startbildschirm und in die Boss-Rufe (`hoecke-01`, "
        "`hoecke-09`, `gauland-01`, `gauland-02`, `krah-01`, `weidel-03`). `hoecke-01` ist jetzt Boss-Karte des "
        "Geschichtslehrers statt `hoecke-02`.",
        "Neue Endgegnerin \"Die Remigrantin\": Hauptzitat ist jetzt `weidel-04` statt `weidel-05`.",
        "`sprechblase:hinterbaenkler` ist auf Union-Rassismus/Brandmauer-Angriffe umgestellt (neue `cdu-*`, `csu-*`, "
        "`spahn-03`); `soeder-04` und `soeder-05` wurden aus den Hinterbänkler-Blasen entfernt (`soeder-04` jetzt "
        "Schnösel, `soeder-05` gestrichen).",
        "Neue Verwendung `startbildschirm`: 11 Zitate.",
        "Die 14 Kandidaten der Nachrecherche 11/2026 sind komplett einsortiert; alle sind `verifiziert`.",
    ]),
    ("2026-11-01 (Nachrecherche der vier schwachen Plätze)", [
        "Behalten: 90 → 95 (5 neue verifizierte Zitate: `cdu-fraktion-01`, `merz-40`, `merz-41`, `weidel-09`, "
        "`weidel-10`). Verworfen: weiter 34.",
        "`freischalt_karte:oma`: `cdu-fraktion-01` (Kleine Anfrage der CDU/CSU-Fraktion, Feb 2025) statt `merz-31` "
        "(jetzt Album).",
        "`freischalt_karte:teilzeit`: `merz-40` (Trier, Feb 2026) statt `storch-04` (jetzt Album). Merz sagt "
        "\"Teilzeit\" nicht wörtlich.",
        "`freischalt_karte:antifa`: `merz-41` (München, Antifa und Lübcke, Feb 2025) statt `weidel-06` (Fragment, "
        "jetzt Album).",
        "`boss_ruf:eidgenossin`: `weidel-09` (Erbschaftsteuer) ersetzt `weidel-05` (bleibt Blase `telegram_onkel`). "
        "`weidel-10` nur Album.",
        "`startbildschirm`: 11 → 13, neu `weidel-01` und `merz-01` (Nutzerwunsch, zusätzlich zur Karte). `merz-05` ist "
        "mit 255 Zeichen zu lang und bleibt draußen.",
        "Die Ladebildschirm-Liste bleibt bei 40; die alten Notlösungen kamen deshalb ins Album statt auf den "
        "Ladebildschirm.",
    ]),
    ("2026-11-03 (D-156, D-159)", [
        "`afd-maier-02`: N-Wort im Zitat zensiert (D-156).",
        "Diese Ansicht wird generiert (D-159); die Staging-Dateien `kandidaten_neu.json/.md` sind entfallen.",
    ]),
]

# Why each verified quote that is not in auswahl.json stays out of the game.
VERWORFEN = {
    "merz-03": "Trotzig, aber ohne Kontext schwach; nicht drastisch.",
    "merz-04": "Selbstkritik zur Stadtbild-Aussage: ein Rückzieher, nicht drastisch.",
    "merz-07": "Entschuldigung zum Sozialtourismus-Zitat; bland, und die Aussage selbst ist schon auf der Karte.",
    "merz-11": "Politsprech ohne Biss.",
    "merz-13": "Merz bedauert die AfD-Mehrheit: entschärft die Pointe von merz-12, deshalb gestrichen.",
    "merz-15": "Insider-Spott, ohne Kontext unverständlich.",
    "merz-22": "Gendern und AfD-Stimmen: nicht drastisch, thematisch redundant.",
    "merz-24": "Braucht den Hintergrund (Ziel, die AfD zu halbieren), Boss-Rufe sind auf vier begrenzt, nicht drastisch.",
    "merz-26": "Bland, nicht drastisch.",
    "merz-27": "Bland.",
    "merz-32": "Lang und unspektakulär (Ärztin als Nutznießerin).",
    "merz-33": "Reaktion auf das AfD-Ergebnis: bland, nicht drastisch.",
    "merz-34": "Bland.",
    "merz-39": "CSU-Parteitag: bland.",
    "soeder-02": "Mäßig, ohne Kontext schwer verständlich.",
    "soeder-03": "Grüne als Hauptkonkurrenz: bland.",
    "soeder-05": "Abgrenzung zur AfD: das Gegenteil der Brandmauer-Pointe, entschärft.",
    "linnemann-02": "Freibad-Gewalt: bland, kein Biss.",
    "linnemann-04": "Bürgergeld-Job-Ablehnung: redundant zu linnemann-03 und merz-10, bland.",
    "spahn-02": "Corona-Rückblick: weniger drastisch, Ladebildschirm auf 40 begrenzt.",
    "spahn-05": "Reichinnek/Honecker: Aufreger, aber nicht drastisch; Ladebildschirm auf 40 begrenzt.",
    "dobrindt-04": "Fragment zu den Zurückweisungen: bland.",
    "kloeckner-02": "Kirchensteuer und Tempo 130: bland.",
    "amthor-02": "Reuig-erklärendes Statement zur Augustus-Affäre: bland, redundant zu amthor-01.",
    "amthor-03": "Bland, redundant zu amthor-01.",
    "aiwanger-01": "Freie Wähler, nicht Union; derber Ausdruck, aber keine NS-Relativierung und kein Rassismus.",
    "aiwanger-02": "Freie Wähler, nicht Union; Gender-Spott ist bland.",
    "aiwanger-03": "Freie Wähler, nicht Union; Lederhosen-Vergleich ohne Biss.",
    "aiwanger-04": "Distanzierung vom Flugblatt: kein drastisches Zitat, entlastet den Sprecher.",
    "aiwanger-05": "Entschuldigung in der Flugblatt-Affäre: bland.",
    "aiwanger-06": "Verteidigung in der Flugblatt-Affäre: lang, erklärungsbedürftig, Freie Wähler, nicht drastisch genug.",
    "gauland-06": "Stolz auf Wehrmachtssoldaten: weniger direkt als gauland-01, -02, -07; Ladebildschirm auf 40 begrenzt.",
    "chrupalla-03": "Ohne Kontext unverständlich, bland.",
    "chrupalla-04": "Pointe nur über die Frage, bland.",
}
