#!/usr/bin/env python3
"""Pick the tests a change touches (docs/specs/ci-cd.md §2a).

    python tools/affected_tests.py               # what would run for this branch + working tree
    python tools/affected_tests.py --run         # import and run it
    python tools/affected_tests.py --all --run   # the full suite
    python tools/affected_tests.py --base <sha> --github-output   # CI on a PR

Changed paths come from `git diff --name-only <base>` (default base: the merge
base with origin/main) plus untracked files. tests/test_areas.json maps paths to
areas; a path matching nothing runs everything.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP_FILE = ROOT / "tests" / "test_areas.json"
TEST_DIR = "tests/godot/"


def load_map() -> dict:
    return json.loads(MAP_FILE.read_text(encoding="utf-8"))


def _matches(path: str, key: str) -> bool:
    if "*" in key:
        return fnmatch.fnmatch(path, key)
    return path == key or (key.endswith("/") and path.startswith(key))


def classify(path: str, cfg: dict) -> tuple[str, object]:
    """("all", None) | ("skip", None) | ("file", "test_x.gd") | ("areas", [..])."""
    path = path.replace("\\", "/").removesuffix(".uid")
    name = path.removeprefix(TEST_DIR)
    if path.startswith(TEST_DIR) and "/" not in name and name.startswith("test_") \
            and name.endswith(".gd") and name != "test_case.gd":
        return "file", name
    if any(_matches(path, k) for k in cfg["all"]):
        return "all", None
    # Patterns (*.md) first, then the longest prefix or exact path.
    for k in cfg["skip"]:
        if "*" in k and _matches(path, k):
            return "skip", None
    best, best_len = None, -1
    for k in cfg["skip"]:
        if "*" not in k and _matches(path, k) and len(k) > best_len:
            best, best_len = ("skip", None), len(k)
    for k, areas in cfg["areas"].items():
        if _matches(path, k) and len(k) > best_len:
            best, best_len = ("areas", list(areas)), len(k)
    return best if best is not None else ("all", None)


def select(paths: list[str], cfg: dict, run_all: bool = False) -> dict:
    sel = {"all": run_all, "areas": set(), "files": set(), "why": []}
    for p in paths:
        kind, val = classify(p, cfg)
        if kind == "all":
            if not sel["all"]:
                sel["why"].append("%s -> everything" % p)
            sel["all"] = True
        elif kind == "file":
            sel["files"].add(val)
        elif kind == "areas":
            sel["areas"].update(val)
    checks = {}
    for check, areas in cfg["checks"].items():
        checks[check] = sel["all"] or bool(sel["areas"] & set(areas)) \
            or (check == "godot" and bool(sel["files"]))
    sel["checks"] = checks
    return sel


def godot_args(sel: dict) -> list[str]:
    if sel["all"]:
        return []
    out = []
    if sel["areas"]:
        out.append("areas=" + ",".join(sorted(sel["areas"])))
    if sel["files"]:
        out.append("files=" + ",".join(sorted(sel["files"])))
    return out


def _git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


def changed_paths(base: str | None) -> list[str] | None:
    """Changed + untracked paths, or None if no base could be found (run everything)."""
    if base is None:
        for ref in ("origin/main", "main"):
            try:
                base = _git("merge-base", ref, "HEAD").strip()
                break
            except subprocess.CalledProcessError:
                continue
    if not base:
        return None
    paths = _git("diff", "--name-only", base).splitlines()
    paths += _git("ls-files", "--others", "--exclude-standard").splitlines()
    return sorted({p for p in paths if p})


def find_godot() -> str | None:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    for c in ("godot", "godot4", "Godot_v4.7.2-stable_linux.x86_64"):
        if shutil.which(c):
            return shutil.which(c)
    home = Path.home()
    for c in (home / "godot" / "godot",
              home / "Downloads" / "Godot_v4.7.2-stable_win64.exe" / "Godot_v4.7.2-stable_win64_console.exe",
              home / "Downloads" / "Godot_v4.7.2-stable_win64_console.exe",
              Path("/Applications/Godot.app/Contents/MacOS/Godot")):
        if c.exists():
            return str(c)
    return None


def run(sel: dict) -> int:
    checks = sel["checks"]
    failed = 0
    if checks["godot"] or checks["spaeti_layout"]:
        godot = find_godot()
        if godot is None:
            print("Godot 4.7.2 not found. Set GODOT=/path/to/godot.", file=sys.stderr)
            return 2
        base = [godot, "--headless", "--path", str(ROOT)]
        subprocess.run(base + ["--import"], capture_output=True)
        steps = []
        if checks["godot"]:
            extra = godot_args(sel)
            steps.append(base + ["-s", "res://tests/godot/run_tests.gd"] + (["--"] + extra if extra else []))
        if checks["spaeti_layout"]:
            steps.append(base + ["-s", "res://tools/spaeti_layout_check.gd"])
        for cmd in steps:
            print("\n$ " + " ".join(cmd[1:]), flush=True)
            failed += subprocess.run(cmd).returncode != 0
    if checks["quotes"]:
        print("\n$ python -m unittest discover -s tests", flush=True)
        failed += subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "tests"], cwd=ROOT).returncode != 0
    if checks["net_smoke"]:
        print("\nnote: net is affected; CI runs tools/net_smoke.sh (GODOT=... bash tools/net_smoke.sh)")
    if "ui" in sel["areas"] or sel["all"]:
        print("note: ui is affected; tools/gamepad_nav_check.gd needs a window (not in CI)")
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", help="git ref to compare against (default: merge base with origin/main)")
    ap.add_argument("--all", action="store_true", help="select everything")
    ap.add_argument("--files", nargs="*", help="use these changed paths instead of git")
    ap.add_argument("--github-output", action="store_true", help="write the selection to $GITHUB_OUTPUT")
    ap.add_argument("--run", action="store_true", help="run the selected tests and checks")
    a = ap.parse_args()

    cfg = load_map()
    paths = a.files if a.files is not None else ([] if a.all else changed_paths(a.base))
    if paths is None:
        print("no merge base found -> everything")
        paths, a.all = [], True
    sel = select(paths, cfg, a.all)

    what = "everything" if sel["all"] else ", ".join(sorted(sel["areas"])) or "no area"
    print("changed: %d path(s); areas: %s" % (len(paths), what))
    for w in sel["why"][:5]:
        print("  " + w)
    if sel["files"]:
        print("test files: " + ", ".join(sorted(sel["files"])))
    print("checks: " + ", ".join("%s=%s" % (k, "yes" if v else "no") for k, v in sel["checks"].items()))

    if a.github_output:
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as out:
            out.write("godot_args=%s\n" % " ".join(godot_args(sel)))
            for k, v in sel["checks"].items():
                out.write("%s=%s\n" % (k, "true" if v else "false"))
            out.write("summary=%s\n" % what)
    return run(sel) if a.run else 0


if __name__ == "__main__":
    sys.exit(main())
