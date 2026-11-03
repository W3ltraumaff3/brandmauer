"""Test area selection (docs/specs/ci-cd.md §2a, tools/affected_tests.py)."""

import importlib.util
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location("affected_tests", ROOT / "tools" / "affected_tests.py")
affected = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(affected)


class AffectedTests(unittest.TestCase):
    def setUp(self):
        self.cfg = affected.load_map()

    def sel(self, *paths):
        return affected.select(list(paths), self.cfg)

    def test_docs_only_runs_nothing(self):
        s = self.sel("docs/GDD.md", "README.md", "balance/runs/x.jsonl", "research/boss_ideen.md")
        self.assertFalse(s["all"])
        self.assertFalse(any(s["checks"].values()))

    def test_ui_change_runs_ui_only(self):
        s = self.sel("src/ui/lobby.gd")
        self.assertEqual(s["areas"], {"ui"})
        self.assertTrue(s["checks"]["godot"])
        self.assertTrue(s["checks"]["spaeti_layout"])
        self.assertFalse(s["checks"]["net_smoke"])
        self.assertEqual(affected.godot_args(s), ["areas=ui"])

    def test_longest_match_wins(self):
        self.assertEqual(self.sel("src/sim/view_state.gd")["areas"], {"sim", "net", "view"})
        self.assertEqual(self.sel("research/zitate_de.json")["areas"], {"quotes", "content"})
        # D-159: the game file and the export filters are checked by the quote tests.
        self.assertEqual(self.sel("research/zitate_spiel.json")["areas"], {"quotes", "content"})
        self.assertEqual(self.sel("export_presets.cfg")["areas"], {"quotes"})

    def test_unknown_path_runs_everything(self):
        s = self.sel("src/newfolder/thing.gd")
        self.assertTrue(s["all"])
        self.assertTrue(all(s["checks"].values()))
        self.assertEqual(affected.godot_args(s), [])

    def test_infrastructure_runs_everything(self):
        for p in ("project.godot", "tests/godot/run_tests.gd", "tests/test_areas.json", ".github/workflows/ci.yml"):
            self.assertTrue(self.sel(p)["all"], p)

    def test_changed_test_file_runs_itself(self):
        s = self.sel("tests/godot/test_ui_nav.gd", "tests/godot/test_summon_aoe.gd.uid")
        self.assertFalse(s["all"])
        self.assertEqual(s["files"], {"test_ui_nav.gd", "test_summon_aoe.gd"})
        self.assertTrue(s["checks"]["godot"])
        self.assertEqual(affected.godot_args(s), ["files=test_summon_aoe.gd,test_ui_nav.gd"])

    def test_every_game_script_has_an_area(self):
        # New source folders must be added to the map deliberately (an unknown
        # path still runs everything, but that should not be the normal case).
        for p in sorted((ROOT / "src").rglob("*.gd")):
            rel = p.relative_to(ROOT).as_posix()
            kind, _ = affected.classify(rel, self.cfg)
            if kind == "all":
                self.assertTrue(any(affected._matches(rel, k) for k in self.cfg["all"]), rel)
            else:
                self.assertEqual(kind, "areas", rel)

    def test_every_godot_test_declares_known_areas(self):
        known = set(self.cfg["checks"]["godot"])
        for p in sorted((ROOT / "tests" / "godot").glob("test_*.gd")):
            if p.name == "test_case.gd":
                continue
            m = re.search(r"^const AREAS := \[(.*)\]", p.read_text(encoding="utf-8"), re.M)
            self.assertIsNotNone(m, "%s declares no AREAS" % p.name)
            areas = set(re.findall(r'"(\w+)"', m.group(1)))
            self.assertTrue(areas, p.name)
            self.assertLessEqual(areas, known, p.name)


if __name__ == "__main__":
    unittest.main()
