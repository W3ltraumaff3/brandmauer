"""abfine.py <dir> ...: per side vs <build>_base on the same seeds, from the wave after the item was
bought: paired ratio of mean dps (B/A), of mean damage taken per wave (x max HP), Pfand spent after,
and boss kill times (waves 10, 15, 20) A -> B. Only pairs where B bought the item."""
import json, math, os, statistics as st, sys

def load(path):
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.startswith("{")]

runs = {}
for d in sys.argv[1:]:
    for f in sorted(os.listdir(d)):
        if f.endswith(".jsonl"):
            runs[f[:-6]] = load(os.path.join(d, f))
key = lambda r: (r["umfrage"], r["seed"], r.get("char", ""))

def gm(xs):
    xs = [x for x in xs if x > 0]
    return math.exp(st.mean(math.log(x) for x in xs)) if xs else float("nan")

def se_log(xs):
    xs = [math.log(x) for x in xs if x > 0]
    return st.stdev(xs) / math.sqrt(len(xs)) if len(xs) > 1 else float("nan")

print(f"{'side':<24} {'n':>3} {'dps B/A':>8} {'+-%':>5} {'taken B/A':>9} {'+-%':>5}  {'w10 kill':>13} {'w15 kill':>13} {'w20 kill':>13}  wins A->B")
for name in sorted(runs):
    b, side = name.split("_", 1)
    if side == "base" or f"{b}_base" not in runs:
        continue
    base = {key(r): r for r in runs[f"{b}_base"]}
    rd, rt, kills = [], [], {10: ([], []), 15: ([], []), 20: ([], [])}
    n = 0; wa = wb = 0
    for r in runs[name]:
        a = base.get(key(r))
        item = (r.get("buy") or [""])[0].split(":")[0]
        bw = [x[0] for p in r["final"] for x in p.get("buys", []) if x[1] == item]
        if not a or not bw:
            continue
        n += 1; wa += a["won"]; wb += r["won"]
        w0 = bw[0] + 1
        last = min(a["wave"], r["wave"])
        wa_ = [w for w in a["waves"] if w0 <= w["wave"] <= last and w["wave"] not in (10, 15, 20)]
        wb_ = [w for w in r["waves"] if w0 <= w["wave"] <= last and w["wave"] not in (10, 15, 20)]
        if wa_ and wb_:
            da, db = st.mean(w["dps"] for w in wa_), st.mean(w["dps"] for w in wb_)
            ta, tb = st.mean(w["taken"] for w in wa_), st.mean(w["taken"] for w in wb_)
            if da > 0 and db > 0:
                rd.append(db / da)
            if ta > 0 and tb > 0:
                rt.append(tb / ta)
        for bwv in kills:
            ka = [w["enc_kill"] for w in a["waves"] if w["wave"] == bwv and "enc_kill" in w]
            kb = [w["enc_kill"] for w in r["waves"] if w["wave"] == bwv and "enc_kill" in w]
            if ka and kb and bwv > bw[0]:
                kills[bwv][0].append(ka[0]); kills[bwv][1].append(kb[0])
    ks = "  ".join(f"{(st.median(kills[w][0]) if kills[w][0] else 0):5.0f}>{(st.median(kills[w][1]) if kills[w][1] else 0):4.0f}s({len(kills[w][0])})" for w in kills)
    print(f"{name:<24} {n:>3} {gm(rd):8.2f} {100*se_log(rd):5.0f} {gm(rt):9.2f} {100*se_log(rt):5.0f}  {ks}  {wa}->{wb}")
