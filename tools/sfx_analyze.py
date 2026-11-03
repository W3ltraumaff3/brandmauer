"""Spectral and loudness check of the rendered sound effects (docs/specs/audio.md §2, §4.8).

Dev tool, not part of the game or CI. Needs numpy and scipy; the music check
also needs ffmpeg (PATH, $FFMPEG or the Miniconda default below).

    python tools/sfx_analyze.py            # per-file table + PASS/WARN list
    python tools/sfx_analyze.py --music    # + key estimate and spectrum of assets/music/*.mp3
    python tools/sfx_analyze.py --mix      # + 4-player firefight with cues over gameplay music
    python tools/sfx_analyze.py --all      # everything (add --passes to list the passed checks)

Loudness: "LUFS" is BS.1770 K-weighting, max over a 400 ms window (momentary,
LUFS-M); "fast" uses a 100 ms window for very short sounds. "EQL" is the level
of the loudest 100 ms weighted by the ISO 226 70-phon equal-loudness contour,
used to compare notes of different pitch (the Pfand scale).
"""

import argparse
import glob
import math
import os
import re
import shutil
import subprocess
import wave

import numpy as np
from scipy import signal

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SFX_DIR = os.path.join(ROOT, "assets", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "music")
FFMPEG_DEFAULT = r"C:\Users\Weltr\Miniconda3\Library\bin\ffmpeg.exe"

# Spec §2: peak tier (dBFS) and category per id (variants share the id).
PEAKS = {
    "shoot": -16, "melee": -13, "hit": -14, "crit": -8, "kill": -11, "kill_elite": -5,
    "explosion": -8, "pfand": -10, "pfand_top": -9, "hurt": -6, "down": -3, "revive": -4,
    "levelup": -4, "wave_start": -3, "wave_end": -4, "boss_intro": -2, "wende": -7,
    "streik": -12, "vote": -8, "buy_1": -6, "buy_2": -5, "buy_3": -4, "buy_4": -2,
    "sell": -8, "combine_2": -4, "combine_3": -3, "combine_4": -2, "ui_click": -14, "error": -10,
}
CATEGORY = {
    "shoot": "Combat", "melee": "Combat", "hit": "Combat", "crit": "Combat", "kill": "Combat",
    "explosion": "Combat", "pfand": "Reward", "pfand_top": "Reward", "buy_1": "Reward",
    "buy_2": "Reward", "buy_3": "Reward", "buy_4": "Reward", "combine_2": "Reward",
    "combine_3": "Reward", "combine_4": "Reward", "vote": "UI", "sell": "UI", "ui_click": "UI",
    "error": "UI",
}
ROUTINE = ("shoot", "hit", "melee")           # the frequent combat sounds
REWARDS = ("pfand", "buy_1", "buy_2", "buy_3", "buy_4", "kill_elite", "levelup",
           "combine_2", "combine_3", "combine_4")
PRIO5 = ("down", "wave_start", "wave_end", "boss_intro")
PRIO4 = ("kill_elite", "revive", "levelup", "wende", "streik")
SMALL = ("shoot", "hit", "melee", "kill", "ui_click", "pfand")   # §4.8: high-passed at 150 Hz
HARSH_OK = ("streik",)   # a referee whistle lives at 2.9 kHz by design
BANDS = [("sub", 0, 60), ("low", 60, 250), ("lowmid", 250, 1000), ("mid", 1000, 4000),
         ("pres", 4000, 8000), ("air", 8000, 1e9)]
PFAND_STEPS = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
NOTE_NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]


def base_id(name):
    if re.fullmatch(r"pfand_\d+", name):
        return "pfand"
    m = re.fullmatch(r"(shoot|melee|hit|kill|explosion)_\d", name)
    return m.group(1) if m else name


# ------------------------------------------------------------------ measures


def read_wav(path):
    with wave.open(path, "rb") as w:
        assert w.getsampwidth() == 2 and w.getnchannels() == 1, path
        rate = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
    return x, rate


def db(x, floor=-200.0):
    return max(floor, 20.0 * math.log10(x)) if x > 0 else floor


def k_weight(x, rate):
    """BS.1770 K-weighting (pre-filter shelf + RLB high-pass), bilinear designs."""
    f0, g, q = 1681.974450955533, 3.999843853973347, 0.7071752369554196
    k = math.tan(math.pi * f0 / rate)
    vh = 10 ** (g / 20)
    vb = vh ** 0.4996667741545416
    a0 = 1 + k / q + k * k
    b1 = [(vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0, (vh - vb * k / q + k * k) / a0]
    a1 = [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
    f0, q = 38.13547087602444, 0.5003270373238773
    k = math.tan(math.pi * f0 / rate)
    a0 = 1 + k / q + k * k
    a2 = [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
    return signal.lfilter([1, -2, 1], a2, signal.lfilter(b1, a1, x))


def lufs_max(x, rate, win=0.4):
    """Max K-weighted loudness over a sliding window (zero-padded for short sounds)."""
    y = k_weight(np.concatenate([x, np.zeros(int(win * rate))]), rate) ** 2
    n = int(win * rate)
    cs = np.concatenate([[0.0], np.cumsum(y)])
    c = (cs[n:] - cs[:-n]) / n
    m = float(c.max()) if len(c) else float(np.mean(y))
    return -0.691 + 10 * math.log10(m) if m > 0 else -200.0


# ISO 226:2003 equal-loudness contour data.
_ISO_F = [20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000,
          1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500]
_ISO_AF = [0.532, 0.506, 0.480, 0.455, 0.432, 0.409, 0.387, 0.367, 0.349, 0.330, 0.315, 0.301,
           0.288, 0.276, 0.267, 0.259, 0.253, 0.250, 0.246, 0.244, 0.243, 0.243, 0.243, 0.242,
           0.242, 0.245, 0.254, 0.271, 0.301]
_ISO_LU = [-31.6, -27.2, -23.0, -19.1, -15.9, -13.0, -10.3, -8.1, -6.2, -4.5, -3.1, -2.0, -1.1,
           -0.4, 0.0, 0.3, 0.5, 0.0, -2.7, -4.1, -1.0, 1.7, 2.5, 1.2, -2.1, -7.1, -11.2, -10.7, -3.1]
_ISO_TF = [78.5, 68.7, 59.5, 51.1, 44.0, 37.5, 31.5, 26.5, 22.1, 17.9, 14.4, 11.4, 8.6, 6.2, 4.4,
           3.0, 2.2, 2.4, 3.5, 1.7, -1.3, -4.2, -6.0, -5.4, -1.5, 6.0, 12.6, 13.9, 12.3]


def iso226_weight_db(freqs, phon=70.0):
    """Sensitivity in dB relative to 1 kHz (positive = sounds louder at equal SPL)."""
    lp = []
    for af, lu, tf in zip(_ISO_AF, _ISO_LU, _ISO_TF):
        a = 4.47e-3 * (10 ** (0.025 * phon) - 1.15) + (0.4 * 10 ** ((tf + lu) / 10 - 9)) ** af
        lp.append(10 / af * math.log10(a) - lu + 94)
    w = phon - np.array(lp)
    freqs = np.asarray(freqs, dtype=float)
    out = np.interp(np.log10(np.clip(freqs, 20, 12500)), np.log10(_ISO_F), w)
    hi = freqs > 12500
    out[hi] = w[-1] - 20 * np.log10(freqs[hi] / 12500)   # rolls off fast
    out[freqs < 20] = -60
    return out


def spectrum(x, rate):
    n = 1 << max(12, int(math.ceil(math.log2(len(x)))))
    win = np.hanning(len(x)) if len(x) > 64 else np.ones(len(x))
    s = np.abs(np.fft.rfft(x * win, n)) ** 2
    return np.fft.rfftfreq(n, 1 / rate), s


def band_shares(f, s):
    tot = s.sum() or 1.0
    return {name: float(s[(f >= lo) & (f < hi)].sum() / tot) for name, lo, hi in BANDS}


def eql_db(x, rate):
    """Equal-loudness-weighted level of the loudest 100 ms (dB, arbitrary ref)."""
    n = int(0.1 * rate)
    if len(x) > n:
        cs = np.concatenate([[0.0], np.cumsum(x * x)])
        i = int(np.argmax(cs[n:] - cs[:-n]))
        x = x[i:i + n]
    f, s = spectrum(x, rate)
    w = 10 ** (iso226_weight_db(f) / 10)
    return 10 * math.log10((s * w).sum() / len(x) + 1e-30)


def fundamental(x, rate, lo=200.0, hi=3000.0):
    """Strongest spectral peak in [lo, hi], refined with parabolic interpolation."""
    seg = x[: int(0.08 * rate)]
    n = 1 << 16
    s = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), n))
    f = np.fft.rfftfreq(n, 1 / rate)
    i = int(np.argmax(np.where((f >= lo) & (f <= hi), s, 0)))
    if 0 < i < len(s) - 1:
        a, b, c = np.log(s[i - 1] + 1e-12), np.log(s[i] + 1e-12), np.log(s[i + 1] + 1e-12)
        i = i + 0.5 * (a - c) / (a - 2 * b + c)
    return i * rate / n


def analyze(path):
    x, rate = read_wav(path)
    peak = float(np.max(np.abs(x)))
    tp = float(np.max(np.abs(signal.resample_poly(x, 4, 1))))
    rms = float(np.sqrt(np.mean(x * x)))
    f, s = spectrum(x, rate)
    tot = s.sum() or 1.0
    name = os.path.splitext(os.path.basename(path))[0]
    return {
        "name": name, "id": base_id(name), "x": x, "rate": rate,
        "dur": len(x) / rate, "peak": db(peak), "tpeak": db(tp), "rms": db(rms),
        "lufs": lufs_max(x, rate, 0.4), "lufs_fast": lufs_max(x, rate, 0.1),
        "eql": eql_db(x, rate), "dc": float(np.mean(x)), "crest": db(peak) - db(rms),
        "centroid": float((f * s).sum() / tot), "bands": band_shares(f, s),
        "above16k": float(s[f >= 16000].sum() / tot),
        "harsh": float(s[(f >= 2000) & (f < 5000)].sum() / tot),
        "clip": int(np.sum(np.abs(x) >= 32767 / 32768)),
    }


def main_band(r):
    return max(r["bands"], key=r["bands"].get)


# --------------------------------------------------------------------- music


def ffmpeg_bin():
    return os.environ.get("FFMPEG") or shutil.which("ffmpeg") or FFMPEG_DEFAULT


def decode(path, rate=22050):
    out = subprocess.run([ffmpeg_bin(), "-v", "quiet", "-i", path, "-ac", "1", "-ar", str(rate), "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(out, dtype="<i2").astype(np.float64) / 32768.0


KK_MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
KK_MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])


def chroma(x, rate):
    """Pitch-class profile 60 Hz - 2 kHz, each STFT frame normalized (0 = C)."""
    f, _, z = signal.stft(x, rate, nperseg=8192, noverlap=4096)
    ok = (f >= 60) & (f <= 2000)
    mag = np.abs(z)[ok]
    pc = np.round(12 * np.log2(f[ok] / 440.0) + 9).astype(int) % 12
    frame_norm = mag / (mag.sum(axis=0, keepdims=True) + 1e-12)
    c = np.array([frame_norm[pc == k].sum() for k in range(12)])
    return c / c.sum()


def key_scores(c):
    res = []
    for tonic in range(12):
        for mode, prof in (("major", KK_MAJOR), ("minor", KK_MINOR)):
            res.append((float(np.corrcoef(c, np.roll(prof, tonic))[0, 1]), tonic, mode))
    return sorted(res, reverse=True)


def pentatonic_fit(c, root_pc):
    """Share of the chroma energy that falls on the major pentatonic of root_pc."""
    return float(sum(c[(root_pc + s) % 12] for s in (0, 2, 4, 7, 9)))


def music_report():
    tracks = sorted(glob.glob(os.path.join(MUSIC_DIR, "*.mp3")))
    rows, gameplay = [], []
    spec_sum = {}
    for path in tracks:
        name = os.path.splitext(os.path.basename(path))[0]
        x = decode(path)
        c = chroma(x, 22050)
        f, s = signal.welch(x, 22050, nperseg=4096)
        bands = band_shares(f, s)
        rows.append((name, key_scores(c)[:3], c, bands, lufs_max(x, 22050, 3.0)))
        if name.startswith("gameplay"):
            gameplay.append(c)
            for k, v in bands.items():
                spec_sum[k] = spec_sum.get(k, 0) + v
    spec_sum = {k: v / max(len(gameplay), 1) for k, v in spec_sum.items()}
    print("\n== Music: key estimates (Krumhansl-Kessler) and band shares ==")
    print(f"{'track':28s} {'key 1':14s} {'key 2':14s} {'LUFS-S':>7s}  " + " ".join(f"{b:>6s}" for b, _, _ in BANDS))
    for name, ks, c, bands, lufs in rows:
        k1 = f"{NOTE_NAMES[ks[0][1]]} {ks[0][2][:3]} {ks[0][0]:.2f}"
        k2 = f"{NOTE_NAMES[ks[1][1]]} {ks[1][2][:3]} {ks[1][0]:.2f}"
        print(f"{name:28s} {k1:14s} {k2:14s} {lufs:7.1f}  " + " ".join(f"{100 * bands[b]:5.1f}%" for b, _, _ in BANDS))
    print("\nMajor-pentatonic fit (share of chroma on the scale) per candidate root:")
    print(f"{'root':5s} " + " ".join(f"{n[:12]:>12s}" for n, *_ in rows) + "   gameplay avg")
    fits = []
    for r in range(12):
        vals = [pentatonic_fit(c, r) for _, _, c, _, _ in rows]
        g = sum(pentatonic_fit(c, r) for c in gameplay) / max(len(gameplay), 1)
        fits.append((g, r))
        print(f"{NOTE_NAMES[r]:5s} " + " ".join(f"{v:12.2f}" for v in vals) + f"   {g:.3f}")
    fits.sort(reverse=True)
    print("Best roots for the gameplay tracks: " + ", ".join(f"{NOTE_NAMES[r]} ({v:.3f})" for v, r in fits[:3]))
    return spec_sum


# ----------------------------------------------------------------------- mix


def mix_report(music_track="gameplay_ska_track"):
    """Spec §8 scenario 2: 4 players fight for 6 s over gameplay music. On top: a Pfand
    streak (0.5 s), a level-up (3 s), a down (4.5 s) and an elite kill (5.2 s).
    Each cue must stand >= 6 dB above the combat bed in its main octave band."""
    rate, dur = 44100, 6.0
    n = int(dur * rate) + rate
    rng = np.random.default_rng(7)
    cache = {}

    def load(name):
        if name not in cache:
            cache[name] = read_wav(os.path.join(SFX_DIR, name + ".wav"))[0]
        return cache[name]

    def place(buf, x, t, g_db=0.0, pitch=1.0):
        if pitch != 1.0:
            x = np.interp(np.arange(0, len(x) - 1, pitch), np.arange(len(x)), x)
        i = int(t * rate)
        buf[i:i + len(x)] += x[: len(buf) - i] * 10 ** (g_db / 20)

    # Combat bed with the spec §2 Cap / Gap / Pitch / Vol and the teammate gain
    # (Mates -12 dB + option 50 % = -6 dB).
    mate = -12 - 6.0
    table = {"shoot": (3, 25, 0.08, 1.5), "hit": (3, 35, 0.08, 1.5), "crit": (2, 70, 0.03, 0.0),
             "kill": (3, 40, 0.0, 1.0)}
    events = []
    for player in range(4):
        events += [(t, "shoot", 0.0 if player == 0 else mate) for t in np.arange(0.01 * player, dur, 0.08)]
    events += [(t, "hit", 0.0) for t in np.arange(0.03, dur, 0.06)]           # own hits only
    events += [(i / 3 + 0.1, "crit", 0.0 if i % 2 == 0 else mate) for i in range(int(dur * 3))]
    events += [(i / 2 + 0.25, "kill", 0.0) for i in range(int(dur * 2))]
    events.sort()
    combat = np.zeros(n)
    last, active = {}, {}
    for t, sid, g in events:
        cap, gap, sp, vol = table[sid]
        if t - last.get(sid, -1.0) < gap / 1000:
            continue
        playing = [s for s in active.get(sid, []) if s > t - 0.15]
        if len(playing) >= cap:
            playing.pop(0)   # approximation: the restarted voice is not cut
        active[sid] = playing + [t]
        last[sid] = t
        name = f"{sid}_{int(rng.integers(0, 3))}" if sid in ("shoot", "hit", "kill") else sid
        place(combat, load(name), t, g + rng.uniform(-vol, vol), 1 + rng.uniform(-sp, sp))

    streak = [(f"pfand_{min(i, 10)}", 0.5 + 0.12 * i) for i in range(14)] + [("pfand_top", 0.5 + 0.12 * 10)]
    cues = [("pfand streak", streak, "Reward"), ("pfand_0 alone", [("pfand_0", 2.45)], "Reward"),
            ("pfand_10 alone", [("pfand_10", 2.75)], "Reward"), ("levelup", [("levelup", 3.0)], "Event"),
            ("down", [("down", 4.5)], "Event"), ("kill_elite", [("kill_elite", 5.2)], "Event")]
    duck = np.ones(n)
    cue_sigs = []
    for label, parts, bus in cues:
        sig = np.zeros(n)
        for f, t in parts:
            place(sig, load(f), t)
            if bus == "Event":   # SFX_Combat sidechain (§3.1): about -6 dB, 300 ms release
                a, b = int(t * rate), int(t * rate) + len(load(f))
                duck[a:b] = np.minimum(duck[a:b], 0.5)
                rel = np.linspace(0.5, 1.0, int(0.3 * rate))[: len(duck[b:b + int(0.3 * rate)])]
                duck[b:b + len(rel)] = np.minimum(duck[b:b + len(rel)], rel)
        start = int(parts[0][1] * rate)
        end = max(int(t * rate) + len(load(f)) for f, t in parts)
        cue_sigs.append((label, sig, slice(start, end)))
    a = math.exp(-1 / (0.01 * rate))   # 10 ms attack smoothing
    duck = signal.lfilter([1 - a], [1, -a], duck - 1) + 1
    sfx_bus = 0.8
    combat_ducked = combat * duck * sfx_bus
    music = np.zeros(n)
    path = os.path.join(MUSIC_DIR, music_track + ".mp3")
    if os.path.exists(path):
        m = decode(path, 44100)[30 * rate: 30 * rate + n]
        music[: len(m)] = m * 0.5   # music bus 0.5 vs SFX bus 0.8 (Save defaults)
    total = combat_ducked + music + sum(s for _, s, _ in cue_sigs) * sfx_bus
    print(f"\n== Mix: 4-player firefight over {music_track} (music bus 0.5, SFX bus 0.8) ==")
    print(f"Mix sample peak {db(np.max(np.abs(total))):.1f} dBFS before the SFX limiter (ceiling -1 dB); "
          f"combat bed LUFS-M {lufs_max(combat * sfx_bus, rate):.1f}, music {lufs_max(music, rate):.1f}")
    edges = [125 * 2 ** k for k in range(7)]
    print(f"{'cue':14s} {'LUFS':>6s} " + " ".join(f"{e:>5d}+" for e in edges) + "   (cue minus combat bed per octave, dB)")

    def band_power(x, lo, hi, nper):
        f, p = signal.welch(x, rate, nperseg=nper)
        return p[(f >= lo) & (f < hi)].sum() * (f[1] - f[0]) + 1e-30

    # The bed is the average over the whole fight (so a cue isn't judged by which crit
    # happens to coincide with it), scaled by the ducking during the cue.
    play = slice(0, int(dur * rate))
    results = []
    for label, sig, seg in cue_sigs:
        nper = min(4096, seg.stop - seg.start)
        duck_db = 10 * math.log10(np.mean(duck[seg] ** 2))
        lv = []
        for lo in edges:
            cue = 10 * math.log10(band_power(sig[seg] * sfx_bus, lo, 2 * lo, nper))
            comb = 10 * math.log10(band_power(combat[play] * sfx_bus, lo, 2 * lo, 4096)) + duck_db
            mus = 10 * math.log10(band_power(music[play], lo, 2 * lo, 4096))
            bed_all = 10 * math.log10(10 ** (comb / 10) + 10 ** (mus / 10))
            lv.append((cue, lo, cue - comb, cue - bed_all))
        main = max(lv)
        print(f"{label:14s} {lufs_max(sig[seg] * sfx_bus, rate):6.1f} " + " ".join(f"{x[2]:6.1f}" for x in lv)
              + f"   main {main[1]}-{2 * main[1]} Hz: {main[2]:+.1f} vs combat, {main[3]:+.1f} vs combat+music")
        results.append((label, main[1], main[2], main[3]))
    return results


# --------------------------------------------------------------------- report


def report(rows):
    print(f"{'file':12s} {'dur':>5s} {'peak':>6s} {'tpk':>6s} {'rms':>6s} {'LUFSm':>6s} {'fast':>6s} {'EQL':>6s} "
          f"{'crest':>5s} {'cent':>6s} " + " ".join(f"{b:>6s}" for b, _, _ in BANDS) + f" {'>16k':>6s} {'2-5k':>5s}")
    for r in rows:
        print(f"{r['name']:12s} {r['dur']:5.2f} {r['peak']:6.1f} {r['tpeak']:6.1f} {r['rms']:6.1f} {r['lufs']:6.1f} "
              f"{r['lufs_fast']:6.1f} {r['eql']:6.1f} {r['crest']:5.1f} {r['centroid']:6.0f} "
              + " ".join(f"{100 * r['bands'][b]:5.1f}%" for b, _, _ in BANDS)
              + f" {100 * r['above16k']:5.2f}% {100 * r['harsh']:4.0f}%")


def checks(rows):
    passes, warns = [], []
    by_id = {}
    for r in rows:
        by_id.setdefault(r["id"], []).append(r)

    def ok(cond, msg):
        (passes if cond else warns).append(msg)

    # Peak tiers, clipping, DC, aliasing, harshness, sub rumble.
    for r in rows:
        tier = PEAKS.get(r["id"])
        if tier is not None and r["id"] != "pfand":
            ok(abs(r["peak"] - tier) <= 0.3, f"{r['name']}: peak {r['peak']:.1f} vs tier {tier}")
        ok(r["clip"] == 0 and r["tpeak"] < -0.5, f"{r['name']}: no clipping (true peak {r['tpeak']:.1f})")
        ok(abs(r["dc"]) < 1e-3, f"{r['name']}: DC {r['dc']:.1e}")
        ok(r["above16k"] < 0.002, f"{r['name']}: energy >16 kHz {100 * r['above16k']:.2f} %")
        ok(r["harsh"] < 0.45 or r["id"] in HARSH_OK, f"{r['name']}: 2-5 kHz share {100 * r['harsh']:.0f} %")
        if r["id"] in SMALL:
            ok(r["bands"]["sub"] < 0.01, f"{r['name']}: sub <60 Hz {100 * r['bands']['sub']:.1f} %")

    # Loudness hierarchy.
    def loud(i):
        return max(x["lufs"] for x in by_id[i]) if i in by_id else None

    routine = max(loud(i) for i in ("shoot", "hit") if loud(i) is not None)
    for i in ("levelup", "buy_1", "kill_elite"):
        if loud(i) is not None:
            ok(loud(i) - routine >= 8, f"hierarchy: {i} {loud(i):.1f} LUFS is {loud(i) - routine:.1f} LU above shoot/hit")
    for chain in (("buy_1", "buy_2", "buy_3", "buy_4"), ("combine_2", "combine_3", "combine_4")):
        vals = [loud(i) for i in chain if i in by_id]
        ok(all(b - a >= 0.5 for a, b in zip(vals, vals[1:])),
           f"hierarchy: {' < '.join(chain)} rises ({', '.join(f'{v:.1f}' for v in vals)} LUFS)")
    # Event priorities (spec §2 Prio): prio-4 events stay near the level-up and below the
    # loudest prio-5 alert, so a whistle never drowns out a down.
    p5 = max(loud(i) for i in PRIO5 if i in by_id)
    for i in PRIO4:
        if i in by_id:
            ok(loud(i) <= p5 and loud(i) - loud("levelup") <= 3.0,
               f"hierarchy: prio-4 {i} {loud(i):.1f} LUFS (levelup {loud('levelup'):.1f}, loudest prio 5 {p5:.1f})")
    combat_routine = [x["lufs"] for i in ROUTINE for x in by_id.get(i, [])]
    rew = [x["lufs"] for i in REWARDS for x in by_id.get(i, [])]
    ok(max(combat_routine) < min(rew),
       f"hierarchy: loudest routine combat {max(combat_routine):.1f} < quietest reward {min(rew):.1f} LUFS")

    # Masking: each reward's main band vs the routine combat energy in that band.
    def avg_bands(ids):
        rs = [x for i in ids for x in by_id.get(i, [])]
        return {b: sum(x["bands"][b] * 10 ** (x["lufs"] / 10) for x in rs) / len(rs) for b, _, _ in BANDS}

    cb = avg_bands(ROUTINE)
    for i in REWARDS:
        if i not in by_id:
            continue
        rb = avg_bands([i])
        mb = max(rb, key=rb.get)
        margin = 10 * math.log10(rb[mb] / (cb[mb] + 1e-30))
        ok(margin >= 6, f"masking: {i} main band {mb} is {margin:.1f} dB above the routine combat energy there "
                        f"(routine share there {100 * cb[mb] / sum(cb.values()):.0f} %)")

    # Pfand scale.
    notes = sorted(by_id.get("pfand", []), key=lambda r: int(r["name"].split("_")[1]))
    if notes:
        f0 = [fundamental(r["x"], r["rate"]) for r in notes]
        steps = [12 * math.log2(f / f0[0]) for f in f0]
        err = max(abs(s - e) for s, e in zip(steps, PFAND_STEPS))
        ok(all(b > a for a, b in zip(f0, f0[1:])), "pfand: pitch rises monotonically")
        ok(err < 0.1, f"pfand: intervals within {err:.2f} semitones of the major pentatonic (root {f0[0]:.1f} Hz)")
        e = [r["eql"] for r in notes]
        ok(max(e) - min(e) <= 2.5, f"pfand: equal-loudness spread {max(e) - min(e):.1f} dB (EQL {min(e):.1f}..{max(e):.1f})")
        k = [r["lufs"] for r in notes]
        ok(max(k) - min(k) <= 2.5, f"pfand: LUFS spread {max(k) - min(k):.1f} LU ({min(k):.1f}..{max(k):.1f})")
        print("\nPfand notes: " + "  ".join(f"{r['name'][6:]}:{f:.0f}Hz/{r['peak']:.1f}dB/L{r['lufs']:.1f}/E{r['eql']:.1f}"
                                            for r, f in zip(notes, f0)))
    return passes, warns


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--music", action="store_true", help="key estimate and spectrum of the music tracks")
    ap.add_argument("--mix", action="store_true", help="simulate the firefight scenario over music")
    ap.add_argument("--all", action="store_true", help="--music and --mix")
    ap.add_argument("--passes", action="store_true", help="also list the passed checks")
    args = ap.parse_args()
    rows = [analyze(p) for p in sorted(glob.glob(os.path.join(SFX_DIR, "*.wav")))]
    order = {c: i for i, c in enumerate(("Combat", "Reward", "Event", "UI"))}

    def sort_key(r):
        tail = r["name"].rsplit("_", 1)[-1]
        return order[CATEGORY.get(r["id"], "Event")], r["id"], int(tail) if tail.isdigit() else 0, r["name"]

    rows.sort(key=sort_key)
    print("== Sound effects (assets/sfx) ==")
    for c in order:
        print(f"\n-- {c} --")
        report([r for r in rows if CATEGORY.get(r["id"], "Event") == c])
    passes, warns = checks(rows)
    if args.music or args.all:
        mus = music_report()
        print("\nReward main band vs. gameplay music band share:")
        rew = [r for r in rows if r["id"] in REWARDS]
        for r in rew:
            mb = main_band(r)
            print(f"  {r['name']:12s} main band {mb:6s} ({100 * r['bands'][mb]:.0f} %), music has {100 * mus[mb]:.0f} % there")
        densest = max(mus, key=mus.get)
        for i in REWARDS:
            bands = [main_band(r) for r in rew if r["id"] == i]
            if bands:
                share = sum(b == densest for b in bands) / len(bands)
                (passes if share < 0.5 else warns).append(
                    f"music: {i} main band is not the densest music band ({densest}) in {100 * (1 - share):.0f} % of files")
    if args.mix or args.all:
        for label, lo, over_combat, over_all in mix_report():
            (passes if over_combat >= 6 else warns).append(
                f"mix: {label} main octave {lo}-{2 * lo} Hz is {over_combat:+.1f} dB vs the combat bed, "
                f"{over_all:+.1f} dB vs combat + music")
    if args.passes:
        print("\nPASS:")
        for p in passes:
            print("  " + p)
    print(f"\n{len(passes)} PASS, {len(warns)} WARN")
    for w in warns:
        print("  WARN " + w)


if __name__ == "__main__":
    main()
