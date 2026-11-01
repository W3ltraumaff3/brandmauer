"""Validates research/zitate_de.json against the content guidelines (docs/specs/content-guidelines.md §4)."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUOTES = ROOT / "research" / "zitate_de.json"

FIELDS = {"id", "sprecher", "partei", "rolle_damals", "zitat", "datum", "kontext",
          "quellen", "status", "kategorien", "kurz", "notizen"}
STATUSES = {"verifiziert", "sinngemäß", "umstritten", "unverifiziert"}
CATEGORIES = {"Migration", "Sozialstaat/Arbeit", "Wirtschaft/Kapital", "Klima", "Gender/Familie",
              "Geschichte/NS-Relativierung", "Demokratie/Medien", "Europa", "Sonstiges/Absurd"}
DATE = re.compile(r"\d{4}(-\d{2}(-\d{2})?)?")
URL = re.compile(r"https?://\S+")


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


if __name__ == "__main__":
    unittest.main()
