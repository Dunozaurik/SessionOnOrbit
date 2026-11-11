"""Процедурная генерация звуков для «Сессии на орбите».

Все звуки синтезируются этим скриптом, поэтому являются собственными ассетами
и не требуют лицензий. Запуск из корня проекта:

    python tools/generate_sfx.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"

random.seed(7)


def tone(freq, dur, vol=0.5, shape="sine", attack=0.005, decay=None):
    """Один тон. decay — постоянная экспоненциального затухания, иначе линейный спад."""
    samples = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        phase = (freq * t) % 1.0
        if shape == "square":
            s = 1.0 if phase < 0.5 else -1.0
        elif shape == "tri":
            s = 4.0 * abs(phase - 0.5) - 1.0
        else:
            s = math.sin(2 * math.pi * phase)
        env = min(1.0, t / attack) if attack > 0 else 1.0
        env *= math.exp(-t / decay) if decay else max(0.0, 1.0 - t / dur)
        samples.append(s * vol * env)
    return samples


def silence(dur):
    return [0.0] * int(RATE * dur)


def concat(*parts):
    return [s for part in parts for s in part]


def mix(*parts):
    out = [0.0] * max(len(p) for p in parts)
    for part in parts:
        for i, s in enumerate(part):
            out[i] += s
    return out


def save(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        ))
    print(f"{name}.wav  {len(samples) / RATE:.2f} c")


def shuttle(dur=3.0):
    """Гул подлетающего шаттла: шум с плавающим фильтром + низкий рокот."""
    out, lp = [], 0.0
    n = int(RATE * dur)
    for i in range(n):
        t = i / RATE
        x = t / dur
        env = math.sin(math.pi * x) ** 1.5
        cutoff = 0.02 + 0.25 * math.sin(math.pi * x)
        lp += cutoff * (random.uniform(-1, 1) - lp)
        rumble = math.sin(2 * math.pi * (40 + 25 * x) * t)
        out.append((lp * 1.6 + rumble * 0.35) * env * 0.6)
    return out


def airlock(dur=0.7):
    """Шипение открывающегося шлюза: шум с быстрой атакой и затуханием + низкий «тук»."""
    out, lp = [], 0.0
    for i in range(int(RATE * dur)):
        t = i / RATE
        env = min(1.0, t / 0.02) * math.exp(-t / 0.22)
        lp += 0.35 * (random.uniform(-1, 1) - lp)
        thump = math.sin(2 * math.pi * 70 * t) * math.exp(-t / 0.06)
        out.append((lp * 0.9 + thump * 0.6) * env * 0.7)
    return out


def main():
    save("click", tone(1400, 0.04, 0.35, attack=0.001, decay=0.01))
    save("interact", concat(tone(660, 0.06, 0.3, "tri"), tone(990, 0.08, 0.3, "tri")))
    save("blip", tone(520, 0.03, 0.12, "square", attack=0.001))
    save("pickup", concat(
        tone(1047, 0.06, 0.3, "tri"),
        tone(1319, 0.06, 0.3, "tri"),
        tone(1568, 0.2, 0.3, "tri", decay=0.08),
    ))
    save("egg", mix(
        concat(*(tone(f, 0.09, 0.28, "tri") for f in (523, 659, 784)),
               tone(1047, 0.6, 0.3, "tri", decay=0.2)),
        concat(*(tone(f / 2, 0.09, 0.08, "square") for f in (523, 659, 784)),
               tone(523, 0.6, 0.08, "square", decay=0.15)),
    ))
    save("denied", mix(tone(140, 0.25, 0.18, "square"), tone(147, 0.25, 0.18, "square")))
    save("ding", mix(
        tone(880, 1.4, 0.35, attack=0.002, decay=0.35),
        tone(1320, 1.4, 0.2, attack=0.002, decay=0.25),
        tone(2200, 0.6, 0.08, attack=0.001, decay=0.1),
    ))
    save("chat", concat(
        tone(1500, 0.05, 0.25, attack=0.002, decay=0.03),
        silence(0.04),
        tone(2000, 0.07, 0.25, attack=0.002, decay=0.04),
    ))
    save("shuttle", shuttle())
    save("door", airlock())
    save("success", concat(
        tone(784, 0.08, 0.25, "tri"),
        tone(1047, 0.08, 0.25, "tri"),
        tone(1319, 0.3, 0.28, "tri", decay=0.12),
    ))


if __name__ == "__main__":
    main()
