"""mklist.py <out list> <seeds> <umfragen> <spec> ...
spec = build:side=args;side=args  (a "base" side with no args is always added per build)
Lines: "<build>_<side> players=1 umfrage=U seed=S build=B tag=... <args>", longest builds first."""
import sys

out, seeds, umf = sys.argv[1], int(sys.argv[2]), [int(u) for u in sys.argv[3].split(",")]
lines = []
for spec in sys.argv[4:]:
    build, sides = spec.split(":", 1)
    extra = ""
    if "|" in build:
        build, extra = build.split("|", 1)
        extra = " " + extra
    pre = sides.split("@", 1)[0] if "@" in sides else ""
    sides = sides.split("@", 1)[1] if "@" in sides else sides
    sd = [("base", "")] + [tuple(s.split("=", 1)) if "=" in s else (s, "") for s in sides.split(";") if s]
    for u in umf:
        for s in range(1, seeds + 1):
            for name, args in sd:
                side = f"{pre or build}_{name}"
                lines.append(f"{side} players=1 umfrage={u} seed={s} build={build} jobs=16 tag={side}{extra} {args}".strip())
order = {"melee": 0, "tank": 1, "status": 2, "summon": 3, "crit": 4, "ranged": 5}
lines.sort(key=lambda l: order.get(l.split()[0].split("_")[0].rstrip("0123456789o"), 9))
open(out, "w", newline="\n").write("\n".join(lines) + "\n")
print(len(lines), "runs")
