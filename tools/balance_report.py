"""Summarises tools/balance_matrix.sh output (docs/specs/balancing.md).

    python tools/balance_report.py <runs.jsonl>

Mortal runs: win rate and median wave per player count x Umfrage.
Immortal runs: per wave the damage taken (share of max HP), kill speed, boss
kill times and what a greedy shopper could buy.
"""
import json
import statistics
import sys
from collections import defaultdict


def load(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.startswith("{")]


def mortal(runs):
    cells = defaultdict(list)
    for r in runs:
        cells[(r["players"], r["umfrage"])].append(r)
    umfragen = sorted({u for _, u in cells})
    print("Mortal bots: wins/runs, median wave reached (21 = won)")
    print("players " + "".join(f"  U{u:<10}" for u in umfragen))
    for n in sorted({n for n, _ in cells}):
        row = f"{n:>7} "
        for u in umfragen:
            rs = cells.get((n, u), [])
            if not rs:
                row += " " * 13
                continue
            wins = sum(1 for r in rs if r["won"])
            med = statistics.median(21 if r["won"] else r["wave"] for r in rs)
            row += f"  {wins}/{len(rs)} w{med:<6g}"
        print(row)
    deaths = defaultdict(int)
    for r in runs:
        if not r["won"]:
            deaths[r["wave"]] += 1
    print("Deaths per wave:", dict(sorted(deaths.items())))


def immortal(runs):
    by = defaultdict(lambda: defaultdict(list))
    for r in runs:
        for w in r["waves"]:
            by[(r["players"], r["umfrage"])][w["wave"]].append(w)
    for key in sorted(by):
        n, u = key
        print(f"\nImmortal bots, {n} player(s), Umfrage {u}: per wave (medians)")
        print(" wave  taken(xHP)  dps/player  enemies  boss_kill  shop: pfand  bought  levelups  left")
        for wave in sorted(by[key]):
            ws = by[key][wave]
            med = lambda k: statistics.median(float(x.get(k, 0)) for x in ws)
            sh = [x["shop"] for x in ws if "shop" in x]
            smed = (lambda k: statistics.median(float(x[k]) for x in sh)) if sh else (lambda k: float("nan"))
            kills = [x["enc_kill"] for x in ws if "enc_kill" in x]
            boss = f"{statistics.median(kills):>6.1f}s" if kills else ("  never" if any("enc" in x for x in ws) else "       ")
            print(f" {wave:>4}  {med('taken'):>9.2f}  {med('dps'):>10.1f}  {med('enemies_max'):>7.0f}  {boss:>9}"
                  f"  {smed('pfand_in'):>11.0f}  {smed('bought'):>6.1f}  {smed('levelups'):>8.1f}  {smed('pfand_left'):>4.0f}")


def _effects(title, rows, min_n=8, top=None):
    """rows: list of (key, outcome) per player-run; prints mean outcome with vs. without."""
    allv = [o for _, o in rows]
    by = defaultdict(list)
    for k, o in rows:
        by[k].append(o)
    print(f"\n{title}: mean wave reached (21 = won) with it vs. overall {statistics.mean(allv):.2f}  (n = player-runs)")
    out = []
    for k, vs in by.items():
        if len(vs) >= min_n:
            out.append((statistics.mean(vs) - statistics.mean(allv), k, len(vs), sum(1 for v in vs if v >= 21) / len(vs)))
    out.sort(reverse=True)
    shown = out if top is None or len(out) <= 2 * top else out[:top] + [None] + out[-top:]
    for row in shown:
        if row is None:
            print("   ...")
            continue
        d, k, n, wr = row
        print(f"  {d:+6.2f}  win {wr:4.0%}  n={n:<4} {k}")


def components(runs):
    """Randomised-bot runs: which characters, items, weapons and level-up stats go with
    better or worse outcomes (players of a run share its outcome)."""
    chars, items, weapons, picks = [], [], [], []
    eff = defaultdict(lambda: [0, 0])   # weapon id -> [damage, Pfand spent]
    for r in runs:
        outcome = 21 if r["won"] else r["wave"]
        for p in r["final"]:
            chars.append((p["char"], outcome))
            for it in set(p["items"]):
                items.append((it, outcome))
            for w in set(x.split(":")[0] for x in p["weapons"]):
                weapons.append((w, outcome))
            for st in set(x.split(":")[0] for x in p.get("picks", [])):
                picks.append((st, outcome))
            for wid, spent in p.get("spent", {}).items():
                if wid in p.get("weapon_dmg", {}):
                    eff[wid][0] += p["weapon_dmg"][wid]
                    eff[wid][1] += spent
    _effects("Characters", chars, min_n=4)
    _effects("Items (owned at the end)", items, top=12)
    _effects("Weapons (owned at the end)", weapons)
    _effects("Level-up stats (picked at least once)", picks)
    print("\nWeapon damage per Pfand spent (bought weapons, all runs):")
    for wid, (dmg, spent) in sorted(eff.items(), key=lambda kv: -kv[1][0] / max(1, kv[1][1])):
        print(f"  {dmg / max(1, spent):8.1f}  ({dmg} dmg / {spent} Pfand)  {wid}")


def builds(runs):
    """Human-like build bots: win rate and median wave per build x Umfrage."""
    cells = defaultdict(list)
    for r in runs:
        cells[(r["build"], r["umfrage"])].append(21 if r["won"] else r["wave"])
    umfragen = sorted({u for _, u in cells})
    print("\nBuild bots: wins/runs, median wave (21 = won)")
    print("build   " + "".join(f"  U{u:<10}" for u in umfragen))
    for b in sorted({b for b, _ in cells}):
        row = f"{b:<7} "
        for u in umfragen:
            vs = cells.get((b, u), [])
            row += f"  {sum(1 for v in vs if v >= 21)}/{len(vs)} w{statistics.median(vs):<6g}" if vs else " " * 13
        print(row)
    components(runs)


def main():
    runs = load(sys.argv[1])
    bld = [r for r in runs if r.get("build") and not r.get("immortal")]
    if bld:
        builds(bld)
    runs = [r for r in runs if not r.get("build")]
    rnd = [r for r in runs if r.get("random")]
    m = [r for r in runs if not r.get("immortal") and not r.get("random")]
    im = [r for r in runs if r.get("immortal")]
    if m:
        mortal(m)
    if im:
        immortal(im)
    if rnd:
        mortal([r for r in rnd if not r.get("immortal")])
        components([r for r in rnd if not r.get("immortal")])


if __name__ == "__main__":
    main()
