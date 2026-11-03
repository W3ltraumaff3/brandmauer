"""Synthesizes the game's sound effects (docs/specs/audio.md §2, §4).

Pure stdlib, deterministic: every file has its own seed ("brandmauer-sfx:" +
file name), so running it twice gives byte-identical files and editing one
sound leaves the others unchanged. Output: 16-bit mono WAV, 44100 Hz, to
assets/sfx/<name>.wav. Files in assets/sfx that this script no longer renders
are removed together with their .import files.

Each file is normalized to its peak tier from the spec §2 table (PEAKS), not
to full scale: the loudness hierarchy is baked into the files.

Mix layout (checked with tools/sfx_analyze.py): routine combat sounds (shoot,
hit, melee) keep their body below ~400 Hz and their clicks above ~3 kHz, so
the tonal rewards (Pfand, level-up, elite kill) own the 400 Hz - 2.5 kHz
range in a firefight. All tonal sounds are tuned to KEY_ROOT (G), whose major
pentatonic fits most gameplay tracks (D major, A minor, D minor).

These sounds are our own work, so they need no CREDITS entry.

    python tools/gen_sfx.py
"""

import math
import os
import random
import struct
import wave

RATE = 44100
MAX_PARTIAL = 0.45 * RATE
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
TAU = 2.0 * math.pi

# The Pfand scale and every tonal cue (level-up, buy, combine, waves) are tuned to
# this root; the listen test (spec §8) may move it. G4: the major pentatonic
# G A B D E fits the gameplay tracks best (tools/sfx_analyze.py --music).
PFAND_ROOT = 392.00
KEY_ROOT = PFAND_ROOT
PFAND_STEPS = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
SMALL_HP = 150.0  # high-pass on small sounds against masking (spec §4.8)

# Peak tier per id in dBFS (spec §2). Variants share their id's tier.
PEAKS = {
    "shoot": -16, "melee": -13, "hit": -14, "crit": -8, "kill": -11, "kill_elite": -5,
    "explosion": -8, "pfand": -10, "pfand_top": -9, "hurt": -6, "down": -3, "revive": -4,
    # wende and streik are near-pure sustained tones (crest ~5 dB): at the spec's -5 dBFS
    # they measured 4-9 LU above the level-up, so they sit lower (sfx_analyze.py hierarchy).
    "levelup": -4, "wave_start": -3, "wave_end": -4, "boss_intro": -2, "wende": -7,
    "streik": -12, "vote": -8, "buy_1": -6, "buy_2": -5, "buy_3": -4, "buy_4": -2,
    "sell": -8, "combine_2": -4, "combine_3": -3, "combine_4": -2, "ui_click": -14, "error": -10,
}
LONG = {"boss_intro", "wave_start", "buy_4"}
PEAK_TOLERANCE_DB = 0.3

rng = random.Random(0)


def key(semitones):
    """A pitch in Hz, semitones above KEY_ROOT."""
    return KEY_ROOT * 2.0 ** (semitones / 12.0)


# ---------------------------------------------------------------- primitives


def n_samples(dur):
    return int(round(dur * RATE))


def silence(dur):
    return [0.0] * n_samples(dur)


def lerp(a, b, t):
    return a + (b - a) * t


def sweep(f0, f1, curve=1.0):
    """Frequency function going from f0 to f1 (exponential if both > 0)."""

    def f(t):
        t = t ** curve
        if f0 > 0 and f1 > 0:
            return f0 * (f1 / f0) ** t
        return lerp(f0, f1, t)

    return f


def _blep(t, dt):
    """PolyBLEP residual for a unit step at phase 0 (t, dt in cycles)."""
    if t < dt:
        t /= dt
        return t + t - t * t - 1.0
    if t > 1.0 - dt:
        t = (t - 1.0) / dt
        return t * t + t + t + 1.0
    return 0.0


def osc(dur, freq, shape="sine", duty=0.5, vibrato=(0.0, 0.0), bandlimited=True):
    """Phase-accumulating oscillator. freq is a number or f(t in 0..1) -> Hz.

    Squares and saws are band-limited with PolyBLEP unless bandlimited=False;
    sine and triangle start at zero crossing.
    """
    n = n_samples(dur)
    out = [0.0] * n
    phase = 0.0
    vib_rate, vib_depth = vibrato
    for i in range(n):
        fr = freq(i / max(n - 1, 1)) if callable(freq) else freq
        if vib_depth:
            fr *= 1.0 + vib_depth * math.sin(TAU * vib_rate * i / RATE)
        dt = min(fr / RATE, 0.5)
        if shape == "sine":
            v = math.sin(TAU * phase)
        elif shape == "tri":
            v = 4.0 * abs((phase + 0.75) % 1.0 - 0.5) - 1.0
        elif shape == "saw":
            v = 2.0 * phase - 1.0
            if bandlimited:
                v -= _blep(phase, dt)
        elif shape == "square":
            v = 1.0 if phase < duty else -1.0
            if bandlimited:
                v += _blep(phase, dt) - _blep((phase - duty) % 1.0, dt)
        else:
            raise ValueError(shape)
        out[i] = v
        phase += dt
        if phase >= 1.0:
            phase -= 1.0
    return out


def noise(dur):
    return [rng.uniform(-1.0, 1.0) for _ in range(n_samples(dur))]


def _biquad_coeffs(kind, f, q):
    f = min(max(f, 5.0), 0.49 * RATE)
    w = TAU * f / RATE
    cw, al = math.cos(w), math.sin(w) / (2.0 * q)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
    else:  # band-pass, 0 dB peak gain
        b0, b1, b2 = al, 0.0, -al
    a0 = 1 + al
    return b0 / a0, b1 / a0, b2 / a0, -2 * cw / a0, (1 - al) / a0


def biquad(sig, kind, cutoff, q=0.7071, stages=1):
    """RBJ biquad (lp, hp, bp); cutoff is Hz or f(t in 0..1) -> Hz."""
    n = len(sig)
    for _ in range(stages):
        out = [0.0] * n
        x1 = x2 = y1 = y2 = 0.0
        b0, b1, b2, a1, a2 = _biquad_coeffs(kind, cutoff(0.0) if callable(cutoff) else cutoff, q)
        for i, x in enumerate(sig):
            if callable(cutoff) and i % 16 == 0:
                b0, b1, b2, a1, a2 = _biquad_coeffs(kind, cutoff(i / max(n - 1, 1)), q)
            y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2, x1, y2, y1 = x1, x, y1, y
            out[i] = y
        sig = out
    return sig


def lowpass(sig, cutoff, q=0.7071, stages=1):
    return biquad(sig, "lp", cutoff, q, stages)


def highpass(sig, cutoff, q=0.7071, stages=1):
    return biquad(sig, "hp", cutoff, q, stages)


def bandpass(sig, f, q=2.0):
    return biquad(sig, "bp", f, q)


def env(sig, attack=0.003, decay=None, release=0.01, curve=1.0):
    """Attack, then exponential decay to the end (or a flat sustain if decay is
    None), with a short release so nothing clicks."""
    n = len(sig)
    a = max(1, n_samples(attack))
    r = max(1, n_samples(release))
    out = [0.0] * n
    for i, x in enumerate(sig):
        g = 1.0
        if i < a:
            g = i / a
        elif decay is not None:
            g = math.exp(-((i - a) / RATE) / decay)
        if i > n - r:
            g *= (n - i) / r
        out[i] = x * g ** curve
    return out


def tremolo(sig, rate, depth):
    return [x * (1.0 - depth + depth * math.sin(TAU * rate * i / RATE)) for i, x in enumerate(sig)]


def gain(sig, g):
    return [x * g for x in sig]


def mix(*parts):
    """Mix (offset_seconds, signal) pairs or plain signals."""
    norm = [(0.0, p) if isinstance(p, list) else p for p in parts]
    length = max(n_samples(off) + len(sig) for off, sig in norm)
    out = [0.0] * length
    for off, sig in norm:
        start = n_samples(off)
        for i, x in enumerate(sig):
            out[start + i] += x
    return out


def pad(sig, dur):
    """Extend with silence to dur seconds."""
    return sig + [0.0] * max(0, n_samples(dur) - len(sig))


def bitcrush(sig, steps=16):
    return [round(x * steps) / steps for x in sig]


def tone(dur, freq, shape="square", decay=None, duty=0.5, vibrato=(0.0, 0.0), attack=0.003, release=0.01):
    return env(osc(dur, freq, shape, duty, vibrato), attack=attack, decay=decay, release=release)


def click(dur, hp, lp=11000.0, decay=0.0008):
    """Short band-limited noise transient (no energy above lp, nothing aliases)."""
    return env(lowpass(highpass(noise(dur), hp, stages=2), lp), attack=0.0002, decay=decay, release=0.0005)


def bell(dur, base, partials, decay, attack=0.001):
    """Bell from (ratio, amplitude, decay_scale) partials; skips any above 0.45 x RATE."""
    layers = [gain(env(osc(dur, base * r), attack=attack, decay=decay * d), amp)
              for r, amp, d in partials if base * r <= MAX_PARTIAL]
    return mix(*layers)


# Harmonic ka-ching (spec §4.4): partials 1, 2, 3, 4.2.
CHING = [(1.0, 1.0, 1.0), (2.0, 0.55, 0.7), (3.0, 0.3, 0.5), (4.2, 0.18, 0.35)]


def finish(sig, peak_db, hp=None):
    """High-pass (small sounds), remove DC, fade the edges, normalize to peak_db dBFS."""
    if hp:
        sig = highpass(sig, hp)
    sig = highpass(sig, 20.0)  # DC blocker; thumps at 40-70 Hz pass
    fade_in = min(n_samples(0.0005), len(sig) // 4)
    fade_out = min(n_samples(0.008), len(sig) // 4)
    for i in range(fade_in):
        sig[i] *= i / fade_in
    for i in range(fade_out):
        sig[-1 - i] *= i / fade_out
    peak = max(abs(x) for x in sig) or 1.0
    return [x * 10 ** (peak_db / 20) / peak for x in sig]


# ------------------------------------------------- equal loudness (Pfand scale)

# ISO 226:2003, 70 phon: sensitivity in dB relative to 1 kHz at third-octave centers.
_EQL_F = [125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150,
          4000, 5000, 6300, 8000, 10000, 12500]
_EQL_DB = [-12.9, -10.2, -7.9, -5.9, -4.2, -2.6, -1.5, -0.5, 0.2, 0.0, -2.3, -3.5, -0.3, 2.4,
           3.2, 2.0, -1.3, -6.6, -11.5, -12.5, -7.0]


def _eql_weight(f):
    lf = math.log(min(max(f, _EQL_F[0]), _EQL_F[-1]))
    for i in range(len(_EQL_F) - 1):
        l0, l1 = math.log(_EQL_F[i]), math.log(_EQL_F[i + 1])
        if lf <= l1:
            return lerp(_EQL_DB[i], _EQL_DB[i + 1], (lf - l0) / (l1 - l0))
    return _EQL_DB[-1]


def _k_weight(f):
    """BS.1770 K-weighting gain in dB at f (the published 48 kHz biquads)."""
    z = complex(math.cos(TAU * f / 48000), -math.sin(TAU * f / 48000))
    h1 = (1.53512485958697 - 2.69169618940638 * z + 1.19839281085285 * z * z) / (
        1 - 1.69065929318241 * z + 0.73248077421585 * z * z)
    h2 = (1 - 2 * z + z * z) / (1 - 1.99004745483398 * z + 0.99007225036621 * z * z)
    return 20 * math.log10(abs(h1 * h2))


def _loudness_weight(f):
    """Blend of the ISO 226 contour and K-weighting: the contour alone would make the
    top notes louder (its 1.2-1.6 kHz dip), K-weighting alone quieter (its high shelf).
    The 45/55 mix leaves both models with about the same spread (~2.2 dB)."""
    return 0.45 * _eql_weight(f) + 0.55 * _k_weight(f)


def _note_partials(f):
    """(Hz, amplitude) of a Pfand note: triangle body (odd harmonics) + sine octave."""
    tri = [(f * k, 8 / (math.pi ** 2 * k * k)) for k in (1, 3, 5, 7, 9) if f * k <= MAX_PARTIAL]
    return tri + [(2 * f, 0.316 * pfand_octave_gain(f))]


def pfand_octave_gain(f):
    """The octave partial thins out on the high notes so the top doesn't get piercing."""
    return 1.0 / (1.0 + max(0.0, f / PFAND_ROOT - 1.0) * 0.3)


def pfand_trim_db(step):
    """Gain for note `step` relative to pfand_0 so the scale sounds equally loud."""

    def level(f):
        return 10 * math.log10(sum(a * a * 10 ** (_loudness_weight(fr) / 10) for fr, a in _note_partials(f)))

    f0 = PFAND_ROOT
    return -(level(f0 * 2 ** (PFAND_STEPS[step] / 12)) - level(f0))


# --------------------------------------------------------------------- sounds


def pfand_note(step, decay=0.07, dur=0.14):
    """Triangle body + sine octave (-10 dB) + 3 ms tick HP 4 kHz (-12 dB), §4.1."""
    f = PFAND_ROOT * 2 ** (PFAND_STEPS[step] / 12)
    body = mix(osc(dur, f, "tri"), gain(osc(dur, 2 * f), 0.316 * pfand_octave_gain(f)))
    body = env(body, attack=0.002, decay=decay, release=0.01)
    tick = gain(env(lowpass(highpass(noise(0.003), 4000, stages=2), 10000), attack=0.0002, decay=0.001,
                    release=0.0005), 0.25)
    return highpass(mix(body, tick), SMALL_HP)


def s_pfand(step):
    return lambda: pfand_note(step)


def s_pfand_top():
    # Shimmer: two pentatonic notes two octaves above the root, alternating at 12 Hz.
    dur = 0.3
    a = osc(dur, key(24), "tri")
    b = osc(dur, key(28), "tri")
    lfo = [0.5 + 0.5 * math.sin(TAU * 12 * i / RATE) for i in range(len(a))]
    shimmer = [x * g + y * (1.0 - g) for x, y, g in zip(a, b, lfo)]
    return env(lowpass(shimmer, 6000), attack=0.01, decay=0.12, release=0.04)


def s_shoot(v):
    # Soft "thup": the body stays low-mid (lowpassed), the click sits above 3 kHz.
    d = (-1.5, 0.0, 1.5)[v]
    k = 2 ** (d / 12)
    duty = (0.3, 0.25, 0.35)[v]
    pew = tone(0.12, sweep(340 * k, 100 * k, 0.35), "square", decay=0.03, duty=duty, attack=0.001)
    pew = lowpass(pew, 700, stages=2)
    tick = click(0.006, (3000, 3500, 2600)[v], 8000, decay=0.0012)
    return mix(pew, gain(tick, 0.45))


def s_melee(v):
    # Airy swish above 2.5 kHz plus a low-mid thud on contact.
    peak_lp = (5500, 6200, 4800)[v]
    swish = env(
        lowpass(highpass(noise(0.15), 2500, stages=2), lambda t: 3000 + (peak_lp - 3000) * math.sin(math.pi * t)),
        attack=0.05,
        decay=0.04,
    )
    k = 2 ** ((-1.0, 0.0, 1.0)[v] / 12)
    thud = lowpass(tone(0.09, sweep(260 * k, 120 * k), "square", decay=0.03, duty=0.4, attack=0.001), 700)
    return mix(gain(swish, 0.6), (0.07, thud))


def s_hit(v):
    # 1 ms click HP 3 kHz + PolyBLEP square 300 -> 120 Hz, 40 ms decay (§4.2).
    k = 2 ** ((-2, 0, 2)[v] / 12)
    # The pitch falls fast (curve 0.4), so most of the body's energy lies below the Pfand root.
    body = tone(0.08, sweep(300 * k, 120 * k, 0.4), "square", decay=0.04, duty=0.5, attack=0.001)
    body = lowpass(body, 1200, stages=2)   # keeps the square's harmonics out of the Pfand band
    tick = click(0.004, 3000, (7000, 9000, 11000)[v], decay=0.001)
    return mix(body, gain(tick, (0.6, 0.7, 0.8)[v]))


def s_crit():
    # Bright click + 70 Hz thump + a ~2 kHz ring from 10 ms (§4.2: B6, in key); keeps a hit body.
    tick = click(0.004, 5000, 12000, decay=0.001)
    thump = tone(0.18, sweep(90, 70, 0.3), "sine", decay=0.08, attack=0.001)
    body = lowpass(tone(0.06, sweep(420, 160), "square", decay=0.03, attack=0.001), 2500, stages=2)
    ring = env(bandpass(osc(0.19, key(28), "tri"), key(28), 4.0), attack=0.002, decay=0.05)
    return mix(gain(tick, 0.9), thump, gain(body, 0.5), (0.01, gain(ring, 1.4)))


def s_kill(v):
    # Pop 700 -> 150 Hz, noise puff 5 kHz -> 400 Hz, tonal tick a fifth above the pop's
    # end pitch (225 Hz, below the Pfand band) (§4.3). Variants -1/0/+1 semitone.
    k = 2 ** ((-1, 0, 1)[v] / 12)
    pop = lowpass(tone(0.12, sweep(700 * k, 150 * k), "square", decay=0.04, attack=0.001), 3000, stages=2)
    puff = env(lowpass(noise(0.1), sweep(5000, 400)), attack=0.002, decay=0.03)
    tick = tone(0.05, 150 * k * 1.5, "tri", decay=0.03, attack=0.001)
    return pad(mix(pop, gain(puff, 0.5), (0.035, gain(tick, 0.6))), 0.12)[: n_samples(0.12)]


def s_kill_elite():
    # Coin burst: Pfand notes 4, 7, 9 at 0 / 40 / 80 ms, a 60 Hz thump and the kill pop.
    notes = [gain(pfand_note(s, decay=0.11, dur=0.3), 10 ** (pfand_trim_db(s) / 20)) for s in (4, 7, 9)]
    thump = tone(0.4, sweep(85, 58, 0.3), "sine", decay=0.12, attack=0.002, release=0.05)
    pop = lowpass(tone(0.1, sweep(700, 150), "square", decay=0.035, attack=0.001), 2500, stages=2)
    return pad(mix(gain(thump, 1.1), gain(pop, 0.35), (0.0, notes[0]), (0.04, notes[1]), (0.08, notes[2])), 0.45)


def s_levelup():
    # Triangle + soft saw chord (root, third, fifth, octave) rolled over 60 ms, held
    # 0.5 s, octave shimmer on top (§4.5). Total 0.7 s.
    dur = 0.7
    parts = []
    for i, st in enumerate((0, 4, 7, 12)):
        off = i * 0.02
        f = key(st)
        voice = mix(osc(dur - off, f, "tri"), gain(lowpass(osc(dur - off, f, "saw"), 2200, stages=2), 0.35))
        hold = n_samples(0.5 - off)
        voice = [x * (1.0 if j < hold else math.exp(-(j - hold) / RATE / 0.06)) for j, x in enumerate(voice)]
        parts.append((off, gain(env(voice, attack=0.012, decay=1.2, release=0.03), 0.8 if st else 1.0)))
    shimmer = env(tremolo(osc(0.55, key(24), "tri"), 10, 0.5), attack=0.04, decay=0.25, release=0.05)
    return pad(mix(*parts, (0.1, gain(shimmer, 0.25))), dur)[: n_samples(dur)]


def register_clack():
    return mix(
        click(0.01, 1500, 7000, decay=0.003),
        lowpass(tone(0.06, sweep(240, 90), "square", decay=0.02, duty=0.3, attack=0.001), 1200),
    )


def drawer_rattle(dur=0.08):
    return env(bandpass(noise(dur), 2500, 1.2), attack=0.002, decay=0.03)


def ching(f, dur=0.6, decay=0.18):
    return tremolo(bell(dur, f, CHING, decay), 9, 0.12)


def s_buy(tier):
    # Lever clack + drawer rattle + ching (D6, the fifth of the key), then per tier
    # a fifth, an octave, or a major arpeggio on the tonic (§4.4).
    def render():
        clack = register_clack()
        base = [clack, (0.05, gain(drawer_rattle(), 0.5)), (0.11, gain(clack, 0.4)), (0.11, ching(key(19)))]
        if tier == 1:
            return pad(mix(*base), 0.7)
        if tier == 2:
            return pad(mix(*base, (0.17, gain(ching(key(26)), 0.7))), 0.8)
        if tier == 3:
            return pad(mix(*base, (0.17, gain(ching(key(26)), 0.7)), (0.23, gain(ching(key(31)), 0.45))), 0.9)
        arp = [(0.16 + i * 0.05, gain(ching(key(st), 0.7, 0.25), 0.85)) for i, st in enumerate((12, 16, 19, 24))]
        t_oct = 0.16 + 3 * 0.05
        thump = tone(0.35, sweep(85, 58, 0.3), "sine", decay=0.12, attack=0.002, release=0.05)
        shimmer = env(tremolo(osc(0.6, key(36), "tri"), 9, 0.6), attack=0.05, decay=0.25, release=0.08)
        return mix(*base, *arp, (t_oct, gain(thump, 0.4)), (t_oct, gain(lowpass(shimmer, 7000), 0.18)))

    return render


def s_sell():
    # A bell falling a fourth (G6 -> D6) and a short coin rattle, no thump.
    coins = mix(*[(0.02 + 0.035 * i, gain(bell(0.06, f, [(1.0, 1.0, 1.0), (2.0, 0.4, 0.6)], 0.02), 0.3))
                  for i, f in enumerate((4200, 3700, 4500))])
    return pad(mix(gain(register_clack(), 0.4), (0.0, gain(coins, 0.8)), (0.06, ching(key(24), 0.4, 0.12)),
                   (0.15, ching(key(19), 0.35, 0.14))), 0.5)[: n_samples(0.5)]


def s_combine(tier):
    # Two clinks 50 ms apart, then a chord of the new tier: dyad / triad / triad + octave + thump.
    def render():
        clinks = [(0.0, gain(bell(0.1, key(24), CHING[:2], 0.03), 0.5)),
                  (0.05, gain(bell(0.1, key(31), CHING[:2], 0.03), 0.45))]
        chord_st = {2: (12, 19), 3: (12, 16, 19), 4: (12, 16, 19, 24)}[tier]
        dur = {2: 0.5, 3: 0.6, 4: 0.78}[tier]
        ring = {2: 0.2, 3: 0.27, 4: 0.4}[tier]   # a higher tier rings longer
        chord = []
        for i, st in enumerate(chord_st):
            f = key(st)
            voice = mix(bell(dur, f, [(1.0, 1.0, 1.0), (2.0, 0.35, 0.6), (3.0, 0.12, 0.4)], ring),
                        gain(env(osc(dur, f, "tri"), attack=0.01, decay=ring * 0.8), 0.5))
            # The top octave enters softer, so the chord's sum doesn't spike (the loudness must
            # rise with the tier, not just the peak).
            chord.append((0.12 + 0.03 * i, gain(voice, 1.0 if i == 0 else 0.6 if i < 3 else 0.4)))
        extra = []
        if tier == 4:
            extra.append((0.12, gain(tone(0.35, sweep(85, 58, 0.3), "sine", decay=0.12, attack=0.002,
                                          release=0.05), 0.5)))
        return mix(*clinks, *chord, *extra)

    return render


def s_hurt():
    oof = tone(0.24, sweep(380, 130), "square", decay=0.1, duty=0.4, vibrato=(35, 0.12))
    smack = env(lowpass(noise(0.05), 1800), attack=0.001, decay=0.015)
    return mix(lowpass(oof, 3500), gain(smack, 0.7))


def s_down():
    fall = tone(0.7, sweep(560, 70, 0.8), "square", decay=0.35, duty=0.5, vibrato=(9, 0.07))
    thump = tone(0.18, sweep(110, 40), "sine", decay=0.07)
    return mix(lowpass(fall, 4000), (0.55, gain(thump, 0.9)))


def s_revive():
    rise = tone(0.45, sweep(key(-12), key(12), 0.7), "tri", decay=0.3)
    sparkle = [(0.25 + i * 0.06, gain(lowpass(tone(0.12, key(st), "square", decay=0.05, duty=0.125), 6000), 0.4))
               for i, st in enumerate((16, 19, 24))]
    return mix(gain(rise, 0.9), *sparkle)


def s_wave_start():
    # Kazoo-ish fanfare: da-da-daaa (fifth below, then root + third).
    def kazoo(dur, f):
        buzz = osc(dur, f, "saw", vibrato=(6, 0.02))
        return env(lowpass(buzz, 2200), attack=0.02, decay=None, release=0.05)

    drum = env(lowpass(noise(0.12), 900), attack=0.001, decay=0.04)
    return mix(
        kazoo(0.14, key(-5)),
        (0.17, kazoo(0.14, key(-5))),
        (0.34, kazoo(0.75, key(0))),
        (0.34, gain(kazoo(0.75, key(4)), 0.6)),
        gain(drum, 0.8),
        (0.34, gain(drum, 1.0)),
        (1.1, silence(0.05)),
    )


def s_wave_end():
    notes = [(0.0, key(7)), (0.12, key(4)), (0.24, key(0))]
    parts = [(off, lowpass(tone(0.16, f, "square", decay=0.1, duty=0.25), 5000)) for off, f in notes]
    chord = [gain(tone(0.45, key(st), "tri", decay=0.2), 0.6) for st in (0, 4, 7)]
    return mix(*parts, *[(0.38, c) for c in chord])


def s_boss_intro():
    # Ominous low brass with tremolo plus two big drum hits.
    def brass(dur, f):
        layer = mix(osc(dur, f, "saw"), gain(osc(dur, f * 1.007, "saw"), 0.8), gain(osc(dur, f / 2, "square"), 0.5))
        layer = lowpass(layer, sweep(300, 1400, 0.5))
        return env(tremolo(layer, 7, 0.25), attack=0.08, decay=None, release=0.25)

    def drum():
        return mix(tone(0.4, sweep(120, 38), "sine", decay=0.15),
                   gain(env(lowpass(noise(0.2), 600), attack=0.001, decay=0.05), 0.6))

    return mix(
        drum(),
        (0.3, drum()),
        (0.0, gain(brass(0.6, 82.41), 0.7)),
        (0.62, gain(brass(0.85, 77.78), 0.85)),
        (0.62, gain(brass(0.85, 116.54), 0.45)),
    )


def s_wende():
    # Political U-turn "whoop": down, then all the way back up.
    def f(t):
        return 250 + 650 * (1.0 - math.sin(math.pi * t)) if t > 0.5 else 900 - 650 * math.sin(math.pi * t)

    whoop = env(tone(0.6, f, "sine", decay=None, vibrato=(12, 0.03)), attack=0.01, decay=None, release=0.08)
    buzz = gain(lowpass(tone(0.6, lambda t: f(t) / 2, "square", decay=None, duty=0.3), 3000), 0.15)
    return mix(whoop, env(buzz, attack=0.01, decay=None, release=0.08))


def s_streik():
    # Referee/pea whistle: short tweet, then a longer trilled blast.
    def blast(dur):
        trill = [2900 * (1.0 + 0.045 * (1 if math.sin(TAU * 32 * i / RATE) > 0 else -1)) for i in range(n_samples(dur))]
        n = len(trill)
        w = osc(dur, lambda t: trill[min(int(t * (n - 1)), n - 1)], "sine")
        breath = gain(lowpass(highpass(noise(dur), 3000), 9000), 0.12)
        return env(mix(w, breath), attack=0.01, decay=None, release=0.03)

    return mix(blast(0.12), (0.18, blast(0.5)))


def s_vote():
    # Rubber stamp thud on paper.
    thud = tone(0.22, sweep(130, 45), "sine", decay=0.06)
    slap = env(lowpass(noise(0.06), 3000), attack=0.0005, decay=0.012)
    knock = lowpass(tone(0.05, 420, "square", decay=0.012, duty=0.3), 4000)
    return mix(thud, gain(slap, 0.9), gain(knock, 0.35))


def s_explosion(v):
    rumble = env(lowpass(noise(0.9), sweep((4000, 3200)[v], 120, 0.4)), attack=0.002, decay=0.25)
    boom = tone(0.6, sweep((90, 78)[v], 30), "sine", decay=0.2)
    crackle = env(lowpass(bitcrush(highpass(noise(0.4), 2000), 6), 9000), attack=0.001, decay=0.06)
    return mix(rumble, gain(boom, 1.0), gain(crackle, 0.35))


def s_ui_click():
    return mix(lowpass(tone(0.03, sweep(1800, 1200), "square", decay=0.008, duty=0.25, attack=0.0005), 6000),
               gain(click(0.006, 4000, 10000, decay=0.0015), 0.4))


def s_error():
    # Bonk-bonk: two low buzzy descending notes.
    return lowpass(mix(
        tone(0.13, 196.0, "square", decay=0.08, duty=0.4),
        (0.15, tone(0.2, 146.83, "square", decay=0.1, duty=0.4)),
    ), 3000)


def _variants(name, fn, count):
    return [(f"{name}_{v}", name, (lambda v=v: fn(v))) for v in range(count)]


# (file name, peak id, render function)
SOUNDS = (
    _variants("shoot", s_shoot, 3)
    + _variants("melee", s_melee, 3)
    + _variants("hit", s_hit, 3)
    + [("crit", "crit", s_crit)]
    + _variants("kill", s_kill, 3)
    + [("kill_elite", "kill_elite", s_kill_elite)]
    + _variants("explosion", s_explosion, 2)
    + [(f"pfand_{i}", "pfand", s_pfand(i)) for i in range(len(PFAND_STEPS))]
    + [("pfand_top", "pfand_top", s_pfand_top),
       ("hurt", "hurt", s_hurt), ("down", "down", s_down), ("revive", "revive", s_revive),
       ("levelup", "levelup", s_levelup), ("wave_start", "wave_start", s_wave_start),
       ("wave_end", "wave_end", s_wave_end), ("boss_intro", "boss_intro", s_boss_intro),
       ("wende", "wende", s_wende), ("streik", "streik", s_streik), ("vote", "vote", s_vote)]
    + [(f"buy_{t}", f"buy_{t}", s_buy(t)) for t in (1, 2, 3, 4)]
    + [("sell", "sell", s_sell)]
    + [(f"combine_{t}", f"combine_{t}", s_combine(t)) for t in (2, 3, 4)]
    + [("ui_click", "ui_click", s_ui_click), ("error", "error", s_error)]
)

HIGH_PASSED = {"shoot", "hit", "melee", "kill", "ui_click", "pfand", "pfand_top"}


def target_peak(name, sid):
    if sid == "pfand":
        return PEAKS["pfand"] + pfand_trim_db(int(name.split("_")[1]))
    return PEAKS[sid]


def write_wav(path, sig):
    ints = [max(-32767, min(32767, int(round(x * 32767)))) for x in sig]
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack("<%dh" % len(ints), *ints))
    return ints


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    names = set()
    for name, sid, fn in SOUNDS:
        rng.seed("brandmauer-sfx:" + name)
        peak_db = target_peak(name, sid)
        sig = finish(fn(), peak_db, SMALL_HP if sid in HIGH_PASSED else None)
        dur = len(sig) / RATE
        limit = 1.5 if sid in LONG else 1.0
        assert dur <= limit, f"{name} is {dur:.2f}s (limit {limit}s)"
        ints = write_wav(os.path.join(OUT_DIR, name + ".wav"), sig)
        peak = max(abs(x) for x in ints)
        assert peak < 32767, f"{name} clips"
        got = 20 * math.log10(peak / 32767)
        assert abs(got - peak_db) <= PEAK_TOLERANCE_DB, f"{name}: peak {got:.2f} dB, tier {peak_db:.2f} dB"
        names.add(name)
        print(f"{name:12s} {dur:.2f}s  peak {got:6.2f} dBFS")
    for f in sorted(os.listdir(OUT_DIR)):
        stem = f[: -len(".wav.import")] if f.endswith(".wav.import") else f[:-4] if f.endswith(".wav") else None
        if stem is not None and stem not in names:
            os.remove(os.path.join(OUT_DIR, f))
            print(f"removed {f}")


if __name__ == "__main__":
    main()
