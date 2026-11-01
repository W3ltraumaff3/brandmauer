"""Synthesizes the game's retro sound effects (architecture §8 SFX ids).

Pure stdlib, fixed seed, deterministic: running it twice gives byte-identical
files. Output: 16-bit mono WAV, 22050 Hz, to assets/sfx/<id>.wav.

These sounds are our own work, so they need no CREDITS entry.

    python tools/gen_sfx.py
"""

import math
import os
import random
import struct
import wave

RATE = 22050
PEAK = 0.89  # about -1 dBFS
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
TAU = 2.0 * math.pi

rng = random.Random(1989)


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


def osc(dur, freq, shape="sine", duty=0.5, vibrato=(0.0, 0.0)):
    """Phase-accumulating oscillator. freq is a number or f(t in 0..1) -> Hz."""
    n = n_samples(dur)
    out = []
    phase = 0.0
    vib_rate, vib_depth = vibrato
    for i in range(n):
        t = i / max(n - 1, 1)
        fr = freq(t) if callable(freq) else freq
        if vib_depth:
            fr *= 1.0 + vib_depth * math.sin(TAU * vib_rate * i / RATE)
        phase = (phase + fr / RATE) % 1.0
        if shape == "sine":
            v = math.sin(TAU * phase)
        elif shape == "square":
            v = 1.0 if phase < duty else -1.0
        elif shape == "saw":
            v = 2.0 * phase - 1.0
        elif shape == "tri":
            v = 4.0 * abs(phase - 0.5) - 1.0
        else:
            raise ValueError(shape)
        out.append(v)
    return out


def noise(dur):
    return [rng.uniform(-1.0, 1.0) for _ in range(n_samples(dur))]


def lowpass(sig, cutoff):
    """One-pole lowpass; cutoff is Hz or f(t in 0..1) -> Hz."""
    out = []
    y = 0.0
    n = len(sig)
    for i, x in enumerate(sig):
        c = cutoff(i / max(n - 1, 1)) if callable(cutoff) else cutoff
        a = 1.0 - math.exp(-TAU * c / RATE)
        y += a * (x - y)
        out.append(y)
    return out


def highpass(sig, cutoff):
    low = lowpass(sig, cutoff)
    return [x - l for x, l in zip(sig, low)]


def env(sig, attack=0.003, decay=None, release=0.01, curve=1.0):
    """Attack, then exponential-ish decay to the end (or a flat sustain if
    decay is None), with a short release so nothing clicks."""
    n = len(sig)
    a = max(1, n_samples(attack))
    r = max(1, n_samples(release))
    out = []
    for i, x in enumerate(sig):
        g = 1.0
        if i < a:
            g = i / a
        elif decay is not None:
            g = math.exp(-((i - a) / RATE) / decay)
        if i > n - r:
            g *= (n - i) / r
        out.append(x * g ** curve)
    return out


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


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def bitcrush(sig, steps=16):
    return [round(x * steps) / steps for x in sig]


def tone(dur, freq, shape="square", decay=None, duty=0.5, vibrato=(0.0, 0.0), attack=0.003):
    return env(osc(dur, freq, shape, duty, vibrato), attack=attack, decay=decay)


def bell(dur, base, partials, decay):
    """Inharmonic bell/clink: partials are (ratio, amplitude, decay_scale)."""
    layers = [gain(env(osc(dur, base * r), attack=0.001, decay=decay * d), amp) for r, amp, d in partials]
    return mix(*layers)


def finish(sig):
    """Normalize to PEAK, remove DC and fade the edges."""
    mean = sum(sig) / len(sig)
    sig = [x - mean for x in sig]
    peak = max(abs(x) for x in sig) or 1.0
    sig = [x * PEAK / peak for x in sig]
    fade = min(n_samples(0.004), len(sig) // 4)
    for i in range(fade):
        sig[i] *= i / fade
        sig[-1 - i] *= i / fade
    return sig


# --------------------------------------------------------------------- sounds


def s_hit():
    body = tone(0.07, sweep(420, 140), "square", decay=0.025, duty=0.3)
    crack = env(highpass(noise(0.05), 1500), attack=0.001, decay=0.012)
    return mix(body, gain(crack, 0.7))


def s_crit():
    hit = tone(0.08, sweep(700, 200), "square", decay=0.03, duty=0.25)
    crack = env(highpass(noise(0.06), 2500), attack=0.001, decay=0.015)
    ring = gain(tone(0.22, sweep(1600, 2400, 0.5), "square", decay=0.06, duty=0.125), 0.45)
    return mix(hit, gain(crack, 0.8), (0.03, ring))


def s_kill():
    pop = tone(0.2, sweep(900, 110), "square", decay=0.07)
    puff = env(lowpass(noise(0.18), sweep(5000, 400)), attack=0.002, decay=0.05)
    boing = gain(tone(0.16, sweep(300, 600), "tri", decay=0.06, vibrato=(28, 0.08)), 0.5)
    return mix(pop, gain(puff, 0.6), (0.05, boing))


def s_shoot():
    pew = tone(0.13, sweep(1500, 260, 0.6), "square", decay=0.05, duty=0.25)
    click = env(highpass(noise(0.02), 3000), attack=0.0005, decay=0.004)
    return mix(pew, gain(click, 0.5))


def s_melee():
    swoosh = env(
        lowpass(highpass(noise(0.17), 400), lambda t: 600 + 3500 * math.sin(math.pi * t)),
        attack=0.06,
        decay=0.05,
    )
    thud = tone(0.1, sweep(170, 60), "sine", decay=0.04)
    return mix(gain(swoosh, 0.8), (0.08, thud))


def s_pickup():
    # Bottle clink: glassy inharmonic partials, two quick taps.
    glass = [(1.0, 1.0, 1.0), (2.32, 0.6, 0.7), (4.25, 0.35, 0.45), (6.8, 0.15, 0.3)]
    c1 = bell(0.22, 2350, glass, 0.06)
    c2 = gain(bell(0.3, 2600, glass, 0.08), 0.8)
    tick = env(highpass(noise(0.01), 4000), attack=0.0005, decay=0.002)
    return mix(c1, gain(tick, 0.4), (0.075, c2), (0.075, gain(tick, 0.3)))


def s_levelup():
    notes = [523.25, 659.25, 783.99, 1046.5]
    parts = [(i * 0.07, tone(0.12, f, "square", decay=0.08, duty=0.25)) for i, f in enumerate(notes)]
    sparkle = gain(tone(0.3, 2093.0, "square", decay=0.1, duty=0.125, vibrato=(18, 0.02)), 0.4)
    return mix(*parts, (0.28, tone(0.3, 1046.5, "square", decay=0.12, duty=0.5)), (0.3, sparkle))


def s_buy():
    # Cash register: lever clack, drawer rattle, then the "ching" bell.
    clack = mix(
        env(highpass(noise(0.03), 1200), attack=0.0005, decay=0.008),
        tone(0.06, sweep(240, 90), "square", decay=0.02, duty=0.3),
    )
    rattle = env(lowpass(noise(0.08), 2500), attack=0.002, decay=0.03)
    ching = bell(0.6, 2100, [(1.0, 1.0, 1.0), (1.5, 0.7, 0.9), (2.76, 0.45, 0.6), (4.07, 0.25, 0.4)], 0.18)
    ching = [x * (1.0 + 0.25 * math.sin(TAU * 9 * i / RATE)) for i, x in enumerate(ching)]
    return mix(clack, (0.05, gain(rattle, 0.5)), (0.11, ching), (0.11, gain(clack, 0.4)))


def s_hurt():
    oof = tone(0.24, sweep(380, 130), "square", decay=0.1, duty=0.4, vibrato=(35, 0.12))
    smack = env(lowpass(noise(0.05), 1800), attack=0.001, decay=0.015)
    return mix(oof, gain(smack, 0.7))


def s_down():
    fall = tone(0.7, sweep(560, 70, 0.8), "square", decay=0.35, duty=0.5, vibrato=(9, 0.07))
    thump = tone(0.18, sweep(110, 40), "sine", decay=0.07)
    return mix(fall, (0.55, gain(thump, 0.9)))


def s_revive():
    rise = tone(0.45, sweep(220, 880, 0.7), "tri", decay=0.3)
    sparkle = [(0.25 + i * 0.06, gain(tone(0.12, f, "square", decay=0.05, duty=0.125), 0.5))
               for i, f in enumerate([1318.5, 1568.0, 2093.0])]
    return mix(gain(rise, 0.9), *sparkle)


def s_wave_start():
    # Kazoo-ish fanfare: da-da-daaa.
    def kazoo(dur, f):
        buzz = osc(dur, f, "saw", vibrato=(6, 0.02))
        return env(lowpass(buzz, 2200), attack=0.02, decay=None, release=0.05)

    drum = env(lowpass(noise(0.12), 900), attack=0.001, decay=0.04)
    return mix(
        kazoo(0.14, 392.0),
        (0.17, kazoo(0.14, 392.0)),
        (0.34, kazoo(0.75, 523.25)),
        (0.34, gain(kazoo(0.75, 659.25), 0.6)),
        gain(drum, 0.8),
        (0.34, gain(drum, 1.0)),
        (1.1, silence(0.05)),
    )


def s_wave_end():
    notes = [(0.0, 783.99), (0.12, 659.25), (0.24, 523.25)]
    parts = [(off, tone(0.16, f, "square", decay=0.1, duty=0.25)) for off, f in notes]
    chord = [gain(tone(0.45, f, "tri", decay=0.2), 0.6) for f in (523.25, 659.25, 783.99)]
    return mix(*parts, *[(0.38, c) for c in chord])


def s_boss_intro():
    # Ominous low brass with tremolo plus two big drum hits.
    def brass(dur, f):
        layer = mix(osc(dur, f, "saw"), gain(osc(dur, f * 1.007, "saw"), 0.8), gain(osc(dur, f / 2, "square"), 0.5))
        layer = lowpass(layer, sweep(300, 1400, 0.5))
        trem = [x * (0.75 + 0.25 * math.sin(TAU * 7 * i / RATE)) for i, x in enumerate(layer)]
        return env(trem, attack=0.08, decay=None, release=0.25)

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

    whoop = tone(0.6, f, "sine", decay=None, vibrato=(12, 0.03))
    whoop = env(whoop, attack=0.01, decay=None, release=0.08)
    buzz = gain(tone(0.6, lambda t: f(t) / 2, "square", decay=None, duty=0.3), 0.15)
    return mix(whoop, env(buzz, attack=0.01, decay=None, release=0.08))


def s_streik():
    # Referee/pea whistle: short tweet, then a longer trilled blast.
    def blast(dur):
        trill = [2900 * (1.0 + 0.045 * (1 if math.sin(TAU * 32 * i / RATE) > 0 else -1)) for i in range(n_samples(dur))]
        n = len(trill)
        w = osc(dur, lambda t: trill[min(int(t * (n - 1)), n - 1)], "sine")
        breath = gain(highpass(noise(dur), 3000), 0.12)
        return env(mix(w, breath), attack=0.01, decay=None, release=0.03)

    return mix(blast(0.12), (0.18, blast(0.5)))


def s_vote():
    # Rubber stamp thud on paper.
    thud = tone(0.22, sweep(130, 45), "sine", decay=0.06)
    slap = env(lowpass(noise(0.06), 3000), attack=0.0005, decay=0.012)
    knock = tone(0.05, 420, "square", decay=0.012, duty=0.3)
    return mix(thud, gain(slap, 0.9), gain(knock, 0.35))


def s_explosion():
    rumble = env(lowpass(noise(0.9), sweep(4000, 120, 0.4)), attack=0.002, decay=0.25)
    boom = tone(0.6, sweep(90, 30), "sine", decay=0.2)
    crackle = env(bitcrush(highpass(noise(0.4), 2000), 6), attack=0.001, decay=0.06)
    return mix(rumble, gain(boom, 1.0), gain(crackle, 0.35))


def s_ui_click():
    return mix(tone(0.03, sweep(1800, 1200), "square", decay=0.008, duty=0.25),
               gain(env(highpass(noise(0.01), 4000), attack=0.0005, decay=0.002), 0.4))


def s_error():
    # Bonk-bonk: two low buzzy descending notes.
    return mix(
        tone(0.13, 196.0, "square", decay=0.08, duty=0.4),
        (0.15, tone(0.2, 146.83, "square", decay=0.1, duty=0.4)),
    )


SOUNDS = {
    "hit": s_hit,
    "crit": s_crit,
    "kill": s_kill,
    "shoot": s_shoot,
    "melee": s_melee,
    "pickup": s_pickup,
    "levelup": s_levelup,
    "buy": s_buy,
    "hurt": s_hurt,
    "down": s_down,
    "revive": s_revive,
    "wave_start": s_wave_start,
    "wave_end": s_wave_end,
    "boss_intro": s_boss_intro,
    "wende": s_wende,
    "streik": s_streik,
    "vote": s_vote,
    "explosion": s_explosion,
    "ui_click": s_ui_click,
    "error": s_error,
}

LONG = {"boss_intro", "wave_start"}


def write_wav(path, sig):
    frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(round(x * 32767))))) for x in sig)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for sid, fn in SOUNDS.items():
        rng.seed("brandmauer-sfx:" + sid)  # per-sound seed: editing one sound leaves the others unchanged
        sig = finish(fn())
        dur = len(sig) / RATE
        limit = 1.5 if sid in LONG else 1.0
        assert dur <= limit, f"{sid} is {dur:.2f}s (limit {limit}s)"
        write_wav(os.path.join(OUT_DIR, sid + ".wav"), sig)
        print(f"{sid:12s} {dur:.2f}s")


if __name__ == "__main__":
    main()
