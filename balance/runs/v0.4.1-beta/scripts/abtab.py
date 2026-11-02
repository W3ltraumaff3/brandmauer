"""abtab.py <dir> [<dir2> ...]: per build, every side vs <build>_base on the same seed/umfrage.
Prints n pairs, wins A/B, mean outcome A/B, paired diff +- SE, B>A/B=A/B<A, the share of B runs
that bought the item and the median buy wave/price, and pairs restricted to runs where A reached
wave 9 (the item could matter)."""
import json, math, os, statistics as st, sys
from collections import defaultdict

def load(path):
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.startswith("{")]

def outcome(r):
    return 21 if r["won"] else r["wave"]

runs = {}
for d in sys.argv[1:]:
    for f in sorted(os.listdir(d)):
        if f.endswith(".jsonl"):
            runs[f[:-6]] = load(os.path.join(d, f))
key = lambda r: (r["umfrage"], r["seed"], r.get("char", ""))
print(f"{'side':<24} {'U':>3} {'n':>3} {'winsA':>5} {'winsB':>5} {'meanA':>6} {'meanB':>6} {'B-A':>6} {'SE':>5}  >  =  <  bought  wave  price   | late n  B-A   SE")
for name in sorted(runs):
    b, side = name.split("_", 1)
    if side == "base" or f"{b}_base" not in runs:
        continue
    base = {key(r): r for r in runs[f"{b}_base"]}
    for ufilter in (None, 0, 2, 5):
        rs = [r for r in runs[name] if key(r) in base and (ufilter is None or r["umfrage"] == ufilter)]
        if not rs:
            continue
        d = [outcome(r) - outcome(base[key(r)]) for r in rs]
        se = st.stdev(d) / math.sqrt(len(d)) if len(d) > 1 else float("nan")
        item = (rs[0].get("buy") or [""])[0].split(":")[0]
        bw = [bb for r in rs for p in r["final"] for bb in p.get("buys", []) if bb[1] == item]
        late = [(r, base[key(r)]) for r in rs if outcome(base[key(r)]) >= 9]
        dl = [outcome(x) - outcome(y) for x, y in late]
        sel = st.stdev(dl) / math.sqrt(len(dl)) if len(dl) > 1 else float("nan")
        print(f"{name:<24} {('all' if ufilter is None else ufilter):>3} {len(rs):>3} {sum(base[key(r)]['won'] for r in rs):>5} {sum(r['won'] for r in rs):>5}"
              f" {st.mean(outcome(base[key(r)]) for r in rs):6.2f} {st.mean(outcome(r) for r in rs):6.2f} {st.mean(d):+6.2f} {se:5.2f}"
              f" {sum(x > 0 for x in d):>2} {sum(x == 0 for x in d):>2} {sum(x < 0 for x in d):>2}  {len(bw):>3}/{len(rs):<3}"
              f" {(st.median(x[0] for x in bw) if bw else 0):>4} {(st.median(x[3] for x in bw) if bw else 0):>6}"
              f"   | {len(late):>3} {(st.mean(dl) if dl else 0):+5.2f} {sel:5.2f}")
