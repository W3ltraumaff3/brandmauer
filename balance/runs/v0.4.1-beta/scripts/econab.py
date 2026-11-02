"""econab.py <dir> <side> [umfrage]: per wave, mean Pfand on arrival / spent / buys, base vs side (pairs)."""
import json, os, statistics as st, sys
d, side = sys.argv[1], sys.argv[2]
uf = int(sys.argv[3]) if len(sys.argv) > 3 else None
b = side.split("_")[0]
load = lambda f: [json.loads(l) for l in open(os.path.join(d, f + ".jsonl"), encoding="utf-8")]
key = lambda r: (r["umfrage"], r["seed"])
base = {key(r): r for r in load(b + "_base")}
rows = {}
for r in load(side):
    if uf is not None and r["umfrage"] != uf:
        continue
    a = base[key(r)]
    for tag, x in (("A", a), ("B", r)):
        for w in x["waves"]:
            s = w.get("shop") or {}
            if s:
                rows.setdefault((w["wave"], tag), []).append((s["pfand_in"], s["pfand_in"] - s["pfand_left"], s["bought"]))
print("wave   A in  spent buys |   B in  spent buys")
for w in range(1, 21):
    out = []
    for tag in "AB":
        v = rows.get((w, tag))
        out.append(f"{st.mean(x[0] for x in v):6.0f} {st.mean(x[1] for x in v):6.0f} {st.mean(x[2] for x in v):4.1f} n{len(v)}" if v else " " * 22)
    print(f"{w:>4}  " + " | ".join(out))
