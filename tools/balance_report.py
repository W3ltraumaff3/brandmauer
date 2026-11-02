"""Summarises tools/balance_matrix.sh output (docs/specs/balancing.md section 2).

    python tools/balance_report.py <runs.jsonl> [--min-n 8] [--build status]
    python tools/balance_report.py --ab <a.jsonl> <b.jsonl> [--match players,umfrage,seed,build,char]
    python tools/balance_report.py --sides <dir> <base side> [--group build,umfrage]   (tools/balance_ab.sh output)

Mortal runs: win rate and median wave per player count x Umfrage (and per build).
Immortal runs: per wave the damage taken (share of max HP), kill speed, boss
kill times and what a greedy shopper could buy, plus a weapon table.
Build runs: per-build weapon tables, boss kill times per build, healing by
source (Krankenschein = regen vs. Umverteilung = lifesteal), damage taken by
source, effect uptime. --ab compares two files on matching seeds.
Older JSON lines (without the bot-2 fields) still work; those tables stay empty.
"""
import argparse
import json
import math
import statistics
import sys
from collections import Counter, defaultdict

MIN_N = 8
LONG_WAVE = 12          # "long run": reached this wave (removes most survival bias)
BOSS_WAVES = (5, 10, 15, 20)


def load(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        runs = [json.loads(line) for line in f if line.startswith("{")]
    broken = [r for r in runs if "wave" not in r or "final" not in r]
    if broken:
        print(f"{path}: skipping {len(broken)} incomplete lines (failed runs)")
    return [r for r in runs if r not in broken]


def outcome(r):
    return 21 if r["won"] else r["wave"]


def mean(xs, default=float("nan")):
    xs = list(xs)
    return statistics.mean(xs) if xs else default


def header(runs, path):
    """Which bot and content produced the runs; warns when a file mixes them."""
    bots = Counter(r.get("bot", 1) for r in runs)
    hashes = Counter((r.get("content") or {}).get("all", "?") + ("/" + r["code"] if r.get("code") else "") for r in runs)
    tags = Counter(r.get("tag", "") for r in runs if r.get("tag"))
    print(f"{path}: {len(runs)} runs; bot {dict(bots)}; content {dict(hashes)}" + (f"; tags {dict(tags)}" if tags else ""))
    if len(hashes) > 1 or len(bots) > 1:
        print("  WARNING: mixed content or bot versions in one file; split them before comparing.")
    secs = [r["secs"] for r in runs if "secs" in r]
    if secs:
        jobs = Counter(r.get("jobs", 0) for r in runs)
        print(f"  wall time per run: median {statistics.median(secs):.0f} s, max {max(secs):.0f} s"
              f" (jobs {dict(jobs)}; 0 = not recorded)")
    ms = [r["ms_per_game_s"] for r in runs if "ms_per_game_s" in r]
    if ms:
        print(f"  cost: median {statistics.median(ms):.1f} ms wall time per simulated second")
    sw = Counter(" ".join(f"{k}={int(v)}" for k, v in sorted(r["switches"].items()) if not v) or "all on"
                 for r in runs if "switches" in r)
    if sw:
        print(f"  switches off: {dict(sw)}; ult: {dict(Counter(r.get('ult', '?') for r in runs))}")


def mortal(runs):
    cells = defaultdict(list)
    for r in runs:
        cells[(r["players"], r["umfrage"])].append(r)
    umfragen = sorted({u for _, u in cells})
    print("\nMortal bots: wins/runs, median wave reached (21 = won)")
    print("players " + "".join(f"  U{u:<10}" for u in umfragen))
    for n in sorted({n for n, _ in cells}):
        row = f"{n:>7} "
        for u in umfragen:
            rs = cells.get((n, u), [])
            if not rs:
                row += " " * 13
                continue
            wins = sum(1 for r in rs if r["won"])
            med = statistics.median(outcome(r) for r in rs)
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


def _effects(title, rows, min_n=MIN_N, top=None):
    """rows: list of (key, outcome) per player-run; prints mean outcome with vs. without."""
    if not rows:
        return
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


def components(runs, min_n=MIN_N):
    """Which characters, items, weapons and level-up stats go with better or worse
    outcomes (players of a run share its outcome). Pooled over all builds."""
    chars, items, weapons, picks = [], [], [], []
    eff = defaultdict(lambda: [0, 0])   # weapon id -> [damage, Pfand spent]
    for r in runs:
        o = outcome(r)
        for p in r["final"]:
            chars.append((p["char"], o))
            for it in set(p["items"]):
                items.append((it, o))
            for w in set(x.split(":")[0] for x in p["weapons"]):
                weapons.append((w, o))
            for st in set(x.split(":")[0] for x in p.get("picks", [])):
                picks.append((st, o))
            for wid, spent in p.get("spent", {}).items():
                if wid in p.get("weapon_dmg", {}):
                    eff[wid][0] += p["weapon_dmg"][wid]
                    eff[wid][1] += spent
    _effects("Characters", chars, min_n=max(1, min_n // 2))
    _effects("Items (owned at the end)", items, min_n=min_n, top=12)
    _effects("Weapons (owned at the end, pooled over builds)", weapons, min_n=min_n)
    _effects("Level-up stats (picked at least once)", picks, min_n=min_n)
    print("\nWeapon damage per Pfand spent (bought weapons, all runs):")
    for wid, (dmg, spent) in sorted(eff.items(), key=lambda kv: -kv[1][0] / max(1, kv[1][1])):
        print(f"  {dmg / max(1, spent):8.1f}  ({dmg} dmg / {spent} Pfand)  {wid}")


def weapon_rows(runs):
    """Per weapon id: one entry per owning player-run with outcome, damage share,
    bought damage/Pfand and the Späti wave it was first owned."""
    rows = defaultdict(list)
    players = []
    for r in runs:
        o = outcome(r)
        end_wave = 20 if r["won"] else r["wave"]
        for p in r["final"]:
            if not isinstance(p.get("weapons"), list):
                continue   # v0.2.2 lines: weapon count only
            owned = set(x.split(":")[0] for x in p["weapons"]) | set(p.get("weapon_wave", {}))
            players.append((o, owned))
            total = max(1, p.get("damage_total", 0))
            for wid in owned:
                dmg = p.get("weapon_dmg", {}).get(wid, 0)
                first = p.get("weapon_wave", {}).get(wid)
                rows[wid].append({"o": o, "share": dmg / total, "dmg": dmg, "spent": p.get("spent", {}).get(wid, 0),
                                  "first": first, "owned_waves": (end_wave - first) if first is not None else None})
    return rows, players


def weapon_table(runs, title, min_n=MIN_N, mortal_runs=True):
    rows, players = weapon_rows(runs)
    if not rows:
        return
    print(f"\n{title}  (n = owning player-runs, min {min_n})")
    if mortal_runs:
        print("  weapon                  n  win%  dwave  share  dmg/P  dmg/P long  dmg/P/wave  1st buy")
    else:
        print("  weapon                  n  share  dmg/P  dmg/P/wave  1st buy")
    out = []
    for wid, es in rows.items():
        if len(es) < min_n:
            continue
        without = [o for o, owned in players if wid not in owned]
        d_wave = mean(e["o"] for e in es) - mean(without) if without else float("nan")
        bought = [e for e in es if e["spent"] > 0]
        dmgp = sum(e["dmg"] for e in bought) / max(1, sum(e["spent"] for e in bought)) if bought else float("nan")
        long = [e for e in bought if e["o"] >= LONG_WAVE]
        dmgp_long = sum(e["dmg"] for e in long) / max(1, sum(e["spent"] for e in long)) if long else float("nan")
        # bought (not start) copies only: damage per Pfand per wave owned
        per_wave = [e for e in bought if e["first"] and e["owned_waves"] and e["owned_waves"] > 0]
        dpw = (sum(e["dmg"] for e in per_wave) / max(1, sum(e["spent"] * e["owned_waves"] for e in per_wave))
               if per_wave else float("nan"))
        firsts = [e["first"] for e in es if e["first"] is not None]
        first = f"w{statistics.median(firsts):g}" if firsts else "-"
        share = mean(e["share"] for e in es)
        wins = sum(1 for e in es if e["o"] >= 21) / len(es)
        out.append((d_wave if mortal_runs else -share, wid, len(es), wins, d_wave, share, dmgp, dmgp_long, dpw, first))
    out.sort(key=lambda x: -x[0] if not math.isnan(x[0]) else 99)
    for _, wid, n, wins, d_wave, share, dmgp, dmgp_long, dpw, first in out:
        if mortal_runs:
            print(f"  {wid:<22} {n:>3}  {wins:4.0%}  {_f(d_wave, '+5.1f')}  {share:4.0%}  {_f(dmgp, '5.0f')}"
                  f"  {_f(dmgp_long, '10.0f')}  {_f(dpw, '10.1f')}  {first:>7}")
        else:
            print(f"  {wid:<22} {n:>3}  {share:4.0%}  {_f(dmgp, '5.0f')}  {_f(dpw, '10.1f')}  {first:>7}")


def _f(x, spec):
    """Formats a number, '-' (right-aligned to the same width) when there is none."""
    width = int("".join(c for c in spec.split(".")[0] if c.isdigit()) or 0)
    return "-".rjust(width) if x is None or (isinstance(x, float) and math.isnan(x)) else format(x, spec)


def boss_table(runs, group):
    """Boss/elite kill times per group (build or player count): median s (killed/fights)."""
    cells = defaultdict(list)
    for r in runs:
        for w in r["waves"]:
            if "enc" in w and w["wave"] in BOSS_WAVES:
                # a fight the team survived without a kill: the elite fled at the wave timer
                fled = "enc_kill" not in w and "enc_left" in w and w["downs"] < r["players"] and not (
                    r["wave"] == w["wave"] and not r["won"])
                cells[(group(r), w["wave"])].append("fled" if fled else w.get("enc_kill"))
    if not cells:
        return
    print("\nBoss kill time per " + ("build" if group is _build_key else "group")
          + ": median s (killed/fights, fled = survived the wave but the elite left at the timer;"
          " needs enc_left, bot 3 from v0.4); fights the team died in count as not killed")
    print("  group            " + "".join(f"  wave {b:<13}" for b in BOSS_WAVES))
    for g in sorted({g for g, _ in cells}):
        row = f"  {g:<16} "
        for b in BOSS_WAVES:
            ks = cells.get((g, b), [])
            killed = [k for k in ks if k is not None and k != "fled"]
            fled = sum(1 for k in ks if k == "fled")
            cell = (f"  {statistics.median(killed):>5.0f}s ({len(killed)}/{len(ks)})" if killed
                    else (f"  never ({0}/{len(ks)})" if ks else ""))
            row += (cell + (f" {fled}f" if fled else "")).ljust(20)
        print(row)


def _build_key(r):
    b = r.get("build") or "-"
    return b + (f"/{r['char']}" if r.get("char") else "")


def _wave_times(r):
    return {w["wave"]: float(w.get("t", 0.0)) for w in r["waves"]}


def _point_minutes(p, stat, times):
    """Stat points x minutes in waves, from the per-Späti loadout (stats of the
    Späti after wave k apply in wave k + 1). None without loadout data."""
    lo = p.get("loadout")
    if not lo:
        return None
    total = 0.0
    for e in lo:
        total += float(e["stats"].get(stat, 0.0)) * times.get(e["w"] + 1, 0.0) / 60.0
    return total


def healing(runs, group):
    """Healing by source per group and Krankenschein (regen) vs. Umverteilung (lifesteal).
    Mortal runs only: immortal bots are refilled every frame, so they hardly heal."""
    rows = [(r, p) for r in runs if not r.get("immortal") for p in r["final"] if "heal" in p]
    if not rows:
        return
    print("\nHealing by source (HP per player-run; % = share of damage taken)")
    kinds = ["regen", "lifesteal"] + (["sani"] if any("sani" in p["heal"] for _, p in rows) else []) + ["other"]
    print("  group              n  taken  " + "  ".join(f"{k:<10}" for k in kinds))
    by = defaultdict(list)
    for r, p in rows:
        by[group(r)].append(p)
    for g in sorted(by):
        ps = by[g]
        taken = mean(p.get("taken_total", 0) for p in ps)
        cols = []
        for k in kinds:
            v = mean(p["heal"].get(k, 0) for p in ps)
            cols.append(f"{v:5.0f} {v / max(1.0, taken):4.0%}")
        print(f"  {g:<16} {len(ps):>3}  {taken:5.0f}  " + "  ".join(cols))
    # Krankenschein vs. Umverteilung: HP healed per stat point and minute, and outcomes by end stats.
    reg_hp = ls_hp = reg_pm = ls_pm = 0.0
    for r, p in rows:
        t = _wave_times(r)
        rpm, lpm = _point_minutes(p, "hp_regen", t), _point_minutes(p, "lifesteal", t)
        if rpm is not None:
            reg_hp += p["heal"].get("regen", 0)
            reg_pm += rpm
            ls_hp += p["heal"].get("lifesteal", 0)
            ls_pm += lpm
    print("\nKrankenschein (regen) vs. Umverteilung (lifesteal)")
    if reg_pm or ls_pm:
        print(f"  HP per stat point and minute: Krankenschein {reg_hp / max(1e-9, reg_pm):.2f}"
              f" ({reg_pm:.0f} point-min), Umverteilung {ls_hp / max(1e-9, ls_pm):.2f} ({ls_pm:.0f} point-min)")
    buckets = defaultdict(list)
    for r, p in rows:
        reg, ls = p["stats"].get("hp_regen", 0), p["stats"].get("lifesteal", 0)
        k = ("both" if reg >= 3 and ls >= 3 else "Krankenschein >= 3" if reg >= 3
             else "Umverteilung >= 3" if ls >= 3 else "neither")
        buckets[k].append((r, p))
    print("  end stats             n  mean wave  regen HP  lifesteal HP  taken")
    for k in ("Krankenschein >= 3", "Umverteilung >= 3", "both", "neither"):
        es = buckets.get(k, [])
        if es:
            print(f"  {k:<19} {len(es):>3}  {mean(outcome(r) for r, _ in es):9.1f}  {mean(p['heal']['regen'] for _, p in es):8.0f}"
                  f"  {mean(p['heal']['lifesteal'] for _, p in es):12.0f}  {mean(p.get('taken_total', 0) for _, p in es):5.0f}")


def _weapon_classes():
    """Weapon id -> (kind, main scaling) read from src/data/content.gd; {} if that fails."""
    import os
    import re
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "data", "content.gd")
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return {}
    block = text.split("const WEAPONS := {", 1)[-1].split("\nconst ", 1)[0]
    out = {}
    for m in re.finditer(r'^\t"(\w+)": \{"kind": "(\w+)"(.*?)\n(?=\t"|\})', block, re.S | re.M):
        sc = re.search(r'"scale": \{([^}]*)\}', m.group(3))
        scales = re.findall(r'"(\w+)": ([\d.]+)', sc.group(1)) if sc else []
        main = max(scales, key=lambda x: float(x[1]))[0] if scales else "-"
        out[m.group(1)] = (m.group(2), main)
    return out


def delivery(runs, min_n=MIN_N):
    """Weapon delivery metrics (bot 3, metrics=1): damage per cast, projectile hit
    rate, time from cast to first damage, zone occupancy and summon activity."""
    agg = defaultdict(lambda: defaultdict(float))
    for r in runs:
        for p in r["final"]:
            for wid, d in p.get("delivery", {}).items():
                a = agg[wid]
                a["n"] += 1
                a["dmg"] += p.get("weapon_dmg", {}).get(wid, 0)
                for k, v in d.items():
                    a[k] += v
    if not agg:
        return
    classes = _weapon_classes()
    print(f"\nWeapon delivery (pooled player-runs, min {min_n}; zone = per cast, busy = share of the"
          " zone's / summon's life with an enemy inside / in reach)")
    print("  class   weapon               kind       n  dmg/cast  hit%  1st dmg  zone en-s  zone busy  summon busy")
    rows = []
    for wid, a in agg.items():
        if a["n"] < min_n or a["casts"] <= 0:
            continue
        kind, main = classes.get(wid, ("?", "?"))
        hit = a["hits"] / a["shots"] if a["shots"] else float("nan")
        first = a["first_s"] / a["first_n"] if a["first_n"] else float("nan")
        zen = a["zone_enemy_s"] / a["casts"] if a["zones"] else float("nan")
        zbusy = a["zone_busy"] / a["zone_life"] if a["zone_life"] else float("nan")
        sbusy = a["summon_busy"] / a["summon_s"] if a["summon_s"] else float("nan")
        rows.append((main, wid, kind, int(a["n"]), a["dmg"] / a["casts"], hit, first, zen, zbusy, sbusy))
    rows.sort()
    for main, wid, kind, n, dpc, hit, first, zen, zbusy, sbusy in rows:
        print(f"  {main:<7} {wid:<20} {kind:<8} {n:>4}  {dpc:8.1f}  {_f(hit, '4.0%')}  {_f(first, '6.2f')}s"
              f"  {_f(zen, '9.2f')}  {_f(zbusy, '9.0%')}  {_f(sbusy, '11.0%')}")


def shop_stats(runs, group):
    """Späti behaviour of bot 3 (shop=1): per player-run."""
    by = defaultdict(list)
    for r in runs:
        for p in r["final"]:
            if p.get("shop3"):
                by[group(r)].append(p["shop3"])
    if not by:
        return
    print("\nSpaeti behaviour (mean per player-run)")
    print("  group             sold  lu_rerolls  repairs  defensive items")
    for g in sorted(by):
        ss = by[g]
        print(f"  {g:<16} {mean(s.get('sold', 0) for s in ss):5.1f}  {mean(s.get('lu_rerolls', 0) for s in ss):10.1f}"
              f"  {mean(s.get('repairs', 0) for s in ss):7.1f}  {mean(s.get('defensive', 0) for s in ss):15.1f}")


def taken_by(runs, group, top=6):
    """Damage taken by source (enemy type, enemy projectile, enemy hazard; a best guess per hit)."""
    by = defaultdict(Counter)
    for r in runs:
        for p in r["final"]:
            for k, v in p.get("taken_by", {}).items():
                by[group(r)][k] += v
    if not by:
        return
    print(f"\nDamage taken by source (share, top {top})")
    for g in sorted(by):
        c = by[g]
        total = max(1, sum(c.values()))
        print(f"  {g:<16} " + ", ".join(f"{k} {v / total:.0%}" for k, v in c.most_common(top)))


def behaviour(runs, group):
    """Effect uptime (share of enemy-seconds), summons alive and standing still."""
    by = defaultdict(list)
    for r in runs:
        by[group(r)].append(r)
    if not any("effects" in w for r in runs for w in r["waves"]):
        return
    print("\nEffects and bot behaviour (mean per wave; still = time standing >= 0.6 s)")
    extra = [k for k in ("silence", "reverse", "sticker") if any(k in w.get("effects", {}) for r in runs for w in r["waves"])]
    print("  group              slow  poison  stun  immune" + "".join(f"  {k:>7}" for k in extra)
          + "  summons mean/max  still  ults/wave")
    for g in sorted(by):
        ws = [w for r in by[g] for w in r["waves"] if "effects" in w]
        ps = [p for r in by[g] for p in r["final"]]
        eff = lambda k: mean(w["effects"].get(k, 0.0) for w in ws)
        waves = sum(len(r["waves"]) for r in by[g]) * 1.0
        ults = sum(p.get("ults", 0) for p in ps) / max(1.0, waves * mean(r["players"] for r in by[g]))
        print(f"  {g:<16}  {eff('slow'):4.0%}  {eff('poison'):6.0%}  {eff('stun'):4.0%}  {eff('immune'):6.0%}"
              + "".join(f"  {eff(k):7.0%}" for k in extra)
              + f"  {mean(w.get('summons_mean', 0) for w in ws):7.1f}/{max((p.get('summons_max', 0) for p in ps), default=0):<3}"
              f"      {mean(p.get('still_share', 0) for p in ps):4.0%}  {ults:9.2f}")


def builds(runs, min_n=MIN_N):
    """Human-like build bots: win rate and median wave per build (x character) x Umfrage."""
    cells = defaultdict(list)
    for r in runs:
        cells[(_build_key(r), r["umfrage"])].append(outcome(r))
    umfragen = sorted({u for _, u in cells})
    print("\nBuild bots: wins/runs, median wave (21 = won); build/char = char= override")
    print("build            " + "".join(f"  U{u:<10}" for u in umfragen))
    for b in sorted({b for b, _ in cells}):
        row = f"{b:<16} "
        for u in umfragen:
            vs = cells.get((b, u), [])
            row += f"  {sum(1 for v in vs if v >= 21)}/{len(vs)} w{statistics.median(vs):<6g}" if vs else " " * 13
        print(row)
    components(runs, min_n)
    for b in sorted({_build_key(r) for r in runs}):
        weapon_table([r for r in runs if _build_key(r) == b], f"Weapons within build {b}: dwave = with - without",
                     min_n=min_n)
    boss_table(runs, _build_key)
    healing(runs, _build_key)
    taken_by(runs, _build_key)
    behaviour(runs, _build_key)
    shop_stats(runs, _build_key)
    delivery(runs, min_n)


def _ab_key(r, fields):
    return tuple(r.get(f, "") for f in fields)


def ab(path_a, path_b, fields, min_n):
    """A/B on matching seeds: pairs runs with the same key and compares outcomes."""
    a, b = load(path_a), load(path_b)
    header(a, "A " + path_a)
    header(b, "B " + path_b)
    for name, runs in (("A", a), ("B", b)):
        opts = Counter(" ".join(f"{k}={','.join(r[k]) if isinstance(r[k], list) else r[k]}"
                                for k in ("start", "item", "prefer", "buy", "char", "ult", "dodge") if k in r and r[k] not in ("", [])) for r in runs)
        print(f"  {name} options: {dict(opts)}")
    ia = {}
    for r in a:
        ia.setdefault(_ab_key(r, fields), []).append(r)
    pairs = []
    for r in b:
        k = _ab_key(r, fields)
        if ia.get(k):
            pairs.append((ia[k].pop(0), r))
    print(f"\n{len(pairs)} pairs on {','.join(fields)} (A {len(a)} runs, B {len(b)} runs)")
    if not pairs:
        return
    groups = defaultdict(list)
    for x, y in pairs:
        groups[f"{x.get('build') or '-'} {x['players']}p U{x['umfrage']}" + (" imm" if x.get("immortal") else "")].append((x, y))
        groups["all" + (" immortal" if x.get("immortal") else "")].append((x, y))
    print("  group              pairs  A wins  B wins  A mean  B mean  B-A  +-SE  B>A  B=A  B<A")
    for g in sorted(groups, key=lambda s: (s.startswith("all"), s)):
        ps = groups[g]
        d = [outcome(y) - outcome(x) for x, y in ps]
        se = statistics.stdev(d) / math.sqrt(len(d)) if len(d) > 1 else float("nan")
        print(f"  {g:<18} {len(ps):>5}  {sum(x['won'] for x, _ in ps):>6}  {sum(y['won'] for _, y in ps):>6}"
              f"  {mean(outcome(x) for x, _ in ps):6.2f}  {mean(outcome(y) for _, y in ps):6.2f}"
              f"  {mean(d):+4.2f}  {_f(se, '4.2f')}{sum(1 for v in d if v > 0):>4}  {sum(1 for v in d if v == 0):>3}"
              f"  {sum(1 for v in d if v < 0):>3}")
    # damage and boss kill times, paired
    print("\n  per pair: team damage per second of wave and boss kill times (medians, A -> B)")
    dps_a = [mean(w.get("dps", 0) for w in x["waves"]) for x, _ in pairs]
    dps_b = [mean(w.get("dps", 0) for w in y["waves"]) for _, y in pairs]
    print(f"  dps/player (mean over waves): {statistics.median(dps_a):.1f} -> {statistics.median(dps_b):.1f}")
    for bw in BOSS_WAVES:
        ka = [w["enc_kill"] for x, _ in pairs for w in x["waves"] if w["wave"] == bw and "enc_kill" in w]
        kb = [w["enc_kill"] for _, y in pairs for w in y["waves"] if w["wave"] == bw and "enc_kill" in w]
        if ka or kb:
            fa = sum(1 for x, _ in pairs for w in x["waves"] if w["wave"] == bw and "enc" in w)
            fb = sum(1 for _, y in pairs for w in y["waves"] if w["wave"] == bw and "enc" in w)
            ma = f"{statistics.median(ka):.0f}s" if ka else "-"
            mb = f"{statistics.median(kb):.0f}s" if kb else "-"
            print(f"  wave {bw:>2} boss: {ma} ({len(ka)}/{fa}) -> {mb} ({len(kb)}/{fb})")
    # the weapons/items under test
    focus = sorted({e.split(":")[0] for _, y in pairs for k in ("start", "prefer", "item", "buy") for e in y.get(k, [])})
    for wid in focus:
        own_b = [p for _, y in pairs for p in y["final"] if wid in p.get("items", []) or wid in p.get("weapon_dmg", {})
                 or any(w.split(":")[0] == wid for w in p["weapons"])]
        n_b = sum(len(y["final"]) for _, y in pairs)
        if any(wid in p.get("items", []) for p in own_b):
            print(f"  B {wid} (item): owned by {len(own_b)}/{n_b} player-runs")
            continue
        share = mean(p.get("weapon_dmg", {}).get(wid, 0) / max(1, p.get("damage_total", 0)) for p in own_b)
        print(f"  B {wid}: owned by {len(own_b)}/{n_b} player-runs, damage share {share:.0%}")
    heal = lambda runs, k: mean(p.get("heal", {}).get(k, 0) for r in runs for p in r["final"])
    if any("heal" in p for _, y in pairs for p in y["final"]):
        xs, ys = [x for x, _ in pairs if not x.get("immortal")], [y for _, y in pairs if not y.get("immortal")]
        if xs:
            print("  heal per player-run (mortal): " + ", ".join(
                f"{k} {heal(xs, k):.0f} -> {heal(ys, k):.0f}" for k in ("regen", "lifesteal", "other")))
    weapon_table([y for _, y in pairs], "B weapons (paired runs)", min_n=min_n,
                 mortal_runs=not all(y.get("immortal") for _, y in pairs))


def sides(d, base, group, match):
    """tools/balance_ab.sh output: every side against the base side on matching runs
    (mean outcome, paired difference +- SE, B>A / B=A / B<A), boss kill medians per side."""
    import os
    files = sorted(f for f in os.listdir(d) if f.endswith(".jsonl"))
    runs = {f[:-6]: load(os.path.join(d, f)) for f in files}
    if base not in runs:
        sys.exit(f"no side {base} in {d}: {list(runs)}")
    key = lambda r: tuple(str(r.get(f, "")) for f in match)
    bmap = {key(r): r for r in runs[base]}
    gkey = lambda r: ",".join(str(r.get(g) or "-") for g in group) if group else "all"
    print(f"Sides vs {base} (paired on {','.join(match)}; outcome = wave reached, 21 = won)")
    print(f"  {'side':<12} {'group':<16} {'n':>3} {'wins':>4} {'mean':>6} {'B-A':>6} {'SE':>5}  B>A B=A B<A"
          + "".join(f"  w{w:<5}" for w in BOSS_WAVES))
    for name, rs in runs.items():
        groups = defaultdict(list)
        for r in rs:
            groups[gkey(r)].append(r)
            if group:
                groups["all"].append(r)
        for g in sorted(groups, key=lambda x: (x == "all", x)):
            g_rs = groups[g]
            diffs = [outcome(r) - outcome(bmap[key(r)]) for r in g_rs if key(r) in bmap]
            se = statistics.stdev(diffs) / math.sqrt(len(diffs)) if len(diffs) > 1 else float("nan")
            boss = []
            for bw in BOSS_WAVES:
                ks = [w["enc_kill"] for r in g_rs for w in r["waves"] if w["wave"] == bw and "enc_kill" in w]
                boss.append(f"{statistics.median(ks):5.0f}s" if ks else "     -")
            print(f"  {name:<12} {g:<16} {len(g_rs):>3} {sum(r['won'] for r in g_rs):>4} {mean(outcome(r) for r in g_rs):6.2f}"
                  f" {mean(diffs, 0.0):+6.2f} {_f(se, '5.2f')}  {sum(x > 0 for x in diffs):>3} {sum(x == 0 for x in diffs):>3}"
                  f" {sum(x < 0 for x in diffs):>3}" + "".join(f"  {b}" for b in boss))


RANGED_STARTERS = ("stricknadeln", "gendersternchen", "pfandflasche", "megafon")


def wave1(runs):
    """Wave-1 income per start weapon (runs with stop=1, balancing.md §2): Pfand at the first
    Späti. Warns when a start weapon earns less than 85 % of the ranged starters (D-117)."""
    by = defaultdict(list)
    for r in runs:
        if not r.get("waves"):
            continue
        start = ",".join(s.split(":")[0] for s in r.get("start", [])) or "own:" + (r.get("char") or "-")
        by[start].append(float(r["waves"][0]["shop"].get("pfand_in", 0)))
    if not by:
        return
    ref = [v for k in RANGED_STARTERS for v in by.get(k, [])]
    ref_m = mean(ref) if ref else float("nan")
    print(f"\nWave-1 income: Pfand at the first Späti per start weapon (ranged starters {ref_m:.1f})")
    for k in sorted(by, key=lambda k: -mean(by[k])):
        m = mean(by[k])
        warn = "  WARNING: below 85 % of the ranged starters" if ref and m < 0.85 * ref_m else ""
        print(f"  {k:<22} n={len(by[k]):<3} {m:5.1f}{warn}")


def main():
    try:
        sys.stdout.reconfigure(errors="replace")   # Windows consoles (cp1252) and umlauts in ids
    except AttributeError:
        pass
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*")
    ap.add_argument("--ab", nargs=2, metavar=("A", "B"), help="compare two files on matching runs")
    ap.add_argument("--sides", nargs=2, metavar=("DIR", "BASE"), help="balance_ab.sh output: every side vs BASE")
    ap.add_argument("--group", default="", help="--sides: group rows by these fields, e.g. build,umfrage")
    ap.add_argument("--match", default="players,umfrage,seed,build,char,immortal,random",
                    help="fields that pair runs in --ab (default: %(default)s)")
    ap.add_argument("--min-n", type=int, default=MIN_N, help="min player-runs per row (default %(default)s)")
    ap.add_argument("--build", help="only runs of this build (build/char keys work too)")
    args = ap.parse_args()
    if args.ab:
        ab(args.ab[0], args.ab[1], args.match.split(","), args.min_n)
        return
    if args.sides:
        sides(args.sides[0], args.sides[1], [g for g in args.group.split(",") if g], args.match.split(","))
        return
    if len(args.files) != 1:
        ap.error("give one runs file (or --ab A B)")
    runs = load(args.files[0])
    if args.build:
        runs = [r for r in runs if (r.get("build") or "-") == args.build or _build_key(r) == args.build]
    header(runs, args.files[0])
    early = [r for r in runs if "stop=1" in str(r.get("args", "")).split()]
    if early:
        wave1(early)
        runs = [r for r in runs if r not in early]
        if not runs:
            return
    bld = [r for r in runs if r.get("build") and not r.get("immortal")]
    if bld:
        builds(bld, args.min_n)
    imb = [r for r in runs if r.get("build") and r.get("immortal")]
    rest = [r for r in runs if not r.get("build")]
    rnd = [r for r in rest if r.get("random")]
    m = [r for r in rest if not r.get("immortal") and not r.get("random")]
    im = [r for r in rest if r.get("immortal")] + imb
    if m:
        mortal(m)
        healing(m, lambda r: f"{r['players']}p U{r['umfrage']}")
    if im:
        immortal(im)
        weapon_table(im, "Weapons in immortal runs (no survival bias; share = of the player's damage)",
                     min_n=args.min_n, mortal_runs=False)
        boss_table(im, _build_key)
        taken_by(im, lambda r: f"{r['players']}p U{r['umfrage']}")
        behaviour(im, _build_key)
        delivery(im, args.min_n)
    if rnd:
        mortal([r for r in rnd if not r.get("immortal")])
        components([r for r in rnd if not r.get("immortal")], args.min_n)


if __name__ == "__main__":
    main()
