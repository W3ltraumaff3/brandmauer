"""Validates the quote data against the content guidelines (docs/specs/content-guidelines.md §4):
research/zitate_de.json (all research) and the game file research/zitate_spiel.json (D-159)."""
import fnmatch
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUOTES = ROOT / "research" / "zitate_de.json"
GAME_QUOTES = ROOT / "research" / "zitate_spiel.json"
SELECTION = ROOT / "research" / "auswahl.json"
EXPORT_PRESETS = ROOT / "export_presets.cfg"
GAME_FILE = "research/zitate_spiel.json"
# The fields the game reads (src/data/quotes.gd FIELDS, architecture.md "Quotes"), in this order.
GAME_FIELDS = ["id", "sprecher", "partei", "rolle_damals", "zitat", "datum", "kontext", "kontext_kurz",
               "quellen", "verwendung"]

FIELDS = {"id", "sprecher", "partei", "rolle_damals", "zitat", "datum", "kontext",
          "quellen", "status", "kategorien", "kurz", "notizen", "kontext_kurz"}
STATUSES = {"verifiziert", "sinngemäß", "umstritten", "unverifiziert"}
CATEGORIES = {"Migration", "Sozialstaat/Arbeit", "Wirtschaft/Kapital", "Klima", "Gender/Familie",
              "Geschichte/NS-Relativierung", "Demokratie/Medien", "Europa", "Sonstiges/Absurd"}
DATE = re.compile(r"\d{4}(-\d{2}(-\d{2})?)?")
URL = re.compile(r"https?://\S+")

# Content guidelines §4 (D-156): slurs are never shown. The N-word in any spelling
# (also split by -, ., _ or with 3 for e), and its English forms. Censored text
# replaces the whole word with asterisks and carries "zensiert".
_SEP = r"[-._]?"
N_WORD = re.compile(_SEP.join(["n", "[e3]", "g", "[e3]", "r"]) + "|n[i1]gg|n[e3]gr[o0]", re.IGNORECASE)
# Other ethnic or antisemitic slurs that must not reach players (verifiziert quotes).
SLURS = re.compile("|".join([
    "zigeuner", "kanake", "kanacke", "kümmelhändler", "kameltreiber", "schlitzaug",
    r"\bbimbo", "mohrenkopf", "judensau", "saujude", r"\bitzig\b", r"\bkikes?\b",
]), re.IGNORECASE)
CENSORED = re.compile(r"\*{3,}")
# Everything in the repo that holds quote text or our own player-facing text.
SCANNED = ["research/*.json", "research/scripts/data/**/*.json", "research/scripts/*.py", "research/*.md",
           "i18n/*.csv"]
SHOWN_FIELDS = ("sprecher", "partei", "rolle_damals", "zitat", "datum", "kontext", "kontext_kurz", "quellen")


class QuoteDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.quotes = json.loads(QUOTES.read_text(encoding="utf-8"))

    def test_fields_complete(self):
        for q in self.quotes:
            with self.subTest(id=q.get("id")):
                self.assertEqual(set(q), FIELDS)

    def test_ids_unique(self):
        ids = [q["id"] for q in self.quotes]
        self.assertEqual(len(ids), len(set(ids)))

    def test_status_known(self):
        for q in self.quotes:
            with self.subTest(id=q["id"]):
                self.assertIn(q["status"], STATUSES)

    def test_categories_known(self):
        for q in self.quotes:
            with self.subTest(id=q["id"]):
                self.assertTrue(q["kategorien"])
                self.assertLessEqual(set(q["kategorien"]), CATEGORIES)

    def test_date_format(self):
        for q in self.quotes:
            with self.subTest(id=q["id"]):
                self.assertRegex(q["datum"], DATE)

    def test_verified_quotes_have_sources(self):
        for q in self.quotes:
            if q["status"] != "verifiziert":
                continue
            with self.subTest(id=q["id"]):
                self.assertTrue(q["zitat"].strip())
                self.assertTrue(q["quellen"])
                for url in q["quellen"]:
                    self.assertRegex(url, URL)

    def test_kurz_is_bool(self):
        for q in self.quotes:
            with self.subTest(id=q["id"]):
                self.assertIsInstance(q["kurz"], bool)

    def test_no_n_word_anywhere(self):
        """D-156: the N-word appears nowhere, not in quotes, notes, URLs or source data."""
        for pattern in SCANNED:
            for path in sorted(ROOT.glob(pattern)):
                for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                    with self.subTest(file=str(path.relative_to(ROOT)), line=n):
                        self.assertIsNone(N_WORD.search(line))

    def test_no_slurs_in_shown_fields(self):
        """D-156: no slur reaches the player through a playable (verifiziert) quote."""
        for q in self.quotes:
            if q["status"] != "verifiziert":
                continue
            for field in SHOWN_FIELDS:
                value = q[field] if isinstance(q[field], str) else " ".join(q[field])
                with self.subTest(id=q["id"], field=field):
                    self.assertIsNone(N_WORD.search(value))
                    self.assertIsNone(SLURS.search(value))

    def test_censored_quotes_are_marked(self):
        """D-156: a censored quote says so in the quote text itself, so every screen shows the mark."""
        for q in self.quotes:
            if CENSORED.search(q["zitat"]):
                with self.subTest(id=q["id"]):
                    self.assertIn("zensiert]", q["zitat"])


def _filters(cfg: str) -> dict:
    """{preset name: (include patterns, exclude patterns)} from export_presets.cfg."""
    out = {}
    for block in re.split(r"^\[preset\.\d+\]\s*$", cfg, flags=re.M)[1:]:
        get = lambda key: re.search(rf'^{key}="([^"]*)"', block, re.M).group(1)
        split = lambda s: [p.strip() for p in s.split(",") if p.strip()]
        out[get("name")] = (split(get("include_filter")), split(get("exclude_filter")))
    return out


class GameFileTest(unittest.TestCase):
    """D-159: the game reads and ships only research/zitate_spiel.json."""

    @classmethod
    def setUpClass(cls):
        cls.research = {q["id"]: q for q in json.loads(QUOTES.read_text(encoding="utf-8"))}
        cls.selection = json.loads(SELECTION.read_text(encoding="utf-8"))
        cls.game = json.loads(GAME_QUOTES.read_text(encoding="utf-8"))

    def test_exactly_the_curated_verified_ids(self):
        curated = [s["id"] for s in self.selection if self.research.get(s["id"], {}).get("status") == "verifiziert"]
        self.assertEqual([q["id"] for q in self.game], curated, "same ids, same order as auswahl.json")
        self.assertEqual(len(curated), len(self.selection), "auswahl.json names only verified quotes")

    def test_nothing_unverified_ships(self):
        for q in self.game:
            with self.subTest(id=q["id"]):
                self.assertEqual(self.research[q["id"]]["status"], "verifiziert")

    def test_only_and_all_fields_the_game_reads(self):
        quotes_gd = (ROOT / "src" / "data" / "quotes.gd").read_text(encoding="utf-8")
        self.assertIn("const FIELDS := " + json.dumps(GAME_FIELDS), quotes_gd, "quotes.gd FIELDS matches")
        self.assertIn('"res://' + GAME_FILE + '"', quotes_gd, "Quotes loads the game file")
        self.assertNotIn("zitate_de.json\"", quotes_gd, "Quotes doesn't load the research file")
        uses = {s["id"]: s["verwendung"] for s in self.selection}
        for q in self.game:
            with self.subTest(id=q["id"]):
                self.assertEqual(list(q), GAME_FIELDS)
                for field in GAME_FIELDS[:-1]:
                    self.assertEqual(q[field], self.research[q["id"]][field], field)
                self.assertEqual(q["verwendung"], uses[q["id"]])
                self.assertTrue(q["zitat"].strip() and q["sprecher"] and q["kontext_kurz"] and q["quellen"])

    def test_no_slurs_in_game_file(self):
        for q in self.game:
            for field in GAME_FIELDS:
                value = q[field] if isinstance(q[field], str) else " ".join(q[field])
                with self.subTest(id=q["id"], field=field):
                    self.assertIsNone(N_WORD.search(value))
                    self.assertIsNone(SLURS.search(value))

    def test_export_ships_only_the_game_file_from_research(self):
        presets = _filters(EXPORT_PRESETS.read_text(encoding="utf-8"))
        self.assertEqual(set(presets), {"Windows Desktop", "Linux", "macOS", "Linux Server"})
        research_json = sorted(str(p.relative_to(ROOT)).replace("\\", "/") for p in (ROOT / "research").glob("*.json"))
        self.assertIn(GAME_FILE, research_json)
        for name, (include, exclude) in presets.items():
            with self.subTest(preset=name):
                self.assertEqual([p for p in include if p.startswith("research")], [GAME_FILE])
                self.assertFalse(any(fnmatch.fnmatch(GAME_FILE, p) for p in exclude), "game file not excluded")
                # all_resources picks up every JSON on its own, so the rest must be excluded.
                for path in research_json:
                    if path != GAME_FILE:
                        self.assertTrue(any(fnmatch.fnmatch(path, p) for p in exclude), path + " must not ship")
                self.assertIn("research/scripts/*", exclude)


if __name__ == "__main__":
    unittest.main()
