"""Процедурная генерация фоновой музыки для «Сессии на орбите».

Лёгкий светлый космический эмбиент: мажорные аккорды, мягкий бас, арпеджио и эхо.
Дорожка зацикливается без щелчка. Музыка синтезируется этим скриптом, поэтому
является собственным ассетом и не требует лицензий. Запуск из корня проекта:

    python tools/generate_music.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "music" / "ambient.wav"

SEG = 10.0  # длина одного аккорда (4 такта), с
BEAT = 0.625  # 96 ударов в минуту
EIGHTH = BEAT / 2
CHORDS = [  # C – G – Am – F: светлая, «взлетающая» последовательность
    [130.81, 196.00, 261.63, 329.63, 392.00, 587.33],
    [98.00, 196.00, 246.94, 293.66, 392.00, 587.33],
    [110.00, 164.81, 220.00, 261.63, 329.63, 493.88],
    [87.31, 174.61, 220.00, 261.63, 349.23, 523.25],
]
ARPS = [  # ноты арпеджио для каждого аккорда, по возрастанию
    [261.63, 329.63, 392.00, 523.25, 659.25],
    [293.66, 392.00, 493.88, 587.33, 783.99],
    [329.63, 440.00, 523.25, 659.25, 880.00],
    [349.23, 440.00, 523.25, 698.46, 880.00],
]
ARP_PATTERN = [0, 1, 2, 3, 4, 3, 2, 1]
TOTAL = SEG * len(CHORDS)
N = int(RATE * TOTAL)

random.seed(21)
buf = [0.0] * N


def add_wrapped(start, samples):
    """Добавляет звук в буфер с переносом через конец — так дорожка зацикливается."""
    for i, s in enumerate(samples):
        buf[(start + i) % N] += s


# Пэды: каждая нота звучит 14 с (перекрытие соседних аккордов), огибающая — sin².
PAD_LEN = int(RATE * 14.0)
for ci, chord in enumerate(CHORDS):
    start = int(RATE * (ci * SEG - 2.0))
    for freq in chord:
        for detune in (-0.4, 0.4):
            f = freq * (1.0 + detune * 0.002)
            samples = []
            for i in range(PAD_LEN):
                t = i / RATE
                env = math.sin(math.pi * i / PAD_LEN) ** 2
                s = math.sin(2 * math.pi * f * t) + 0.35 * math.sin(4 * math.pi * f * t)
                samples.append(s * env * 0.03)
            add_wrapped(start, samples)

# Бас: мягкая корневая нота на каждую долю такта.
for ci, chord in enumerate(CHORDS):
    for bar in range(4):
        for hit in (0.0, 1.5):  # два удара на такт
            start = int(RATE * (ci * SEG + bar * 4 * BEAT + hit * BEAT))
            samples = []
            for i in range(int(RATE * 1.2)):
                t = i / RATE
                env = min(1.0, t / 0.01) * math.exp(-t / 0.5)
                samples.append(math.sin(2 * math.pi * chord[0] * t) * env * 0.09)
            add_wrapped(start, samples)

# Арпеджио: восьмые, бодрый «пинг» с лёгкими паузами.
for ci, arp in enumerate(ARPS):
    steps = int(SEG / EIGHTH)
    for k in range(steps):
        if random.random() < 0.18:
            continue
        freq = arp[ARP_PATTERN[k % len(ARP_PATTERN)]]
        start = int(RATE * (ci * SEG + k * EIGHTH))
        samples = []
        for i in range(int(RATE * 1.0)):
            t = i / RATE
            env = min(1.0, t / 0.004) * math.exp(-t / 0.22)
            s = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)
            samples.append(s * env * 0.055)
        add_wrapped(start, samples)

# Колокольчики сверху: редкие, звонкие.
for _ in range(9):
    freq = random.choice([1046.5, 1174.7, 1318.5, 1568.0])
    start = int(RATE * random.uniform(0, TOTAL))
    samples = []
    for i in range(int(RATE * 3.0)):
        t = i / RATE
        env = min(1.0, t / 0.005) * math.exp(-t / 0.6)
        s = math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(2 * math.pi * freq * 2.76 * t)
        samples.append(s * env * 0.03)
    add_wrapped(start, samples)

# Эхо с переносом через конец дорожки (в такт: восьмая и четверть с точкой).
for delay, gain in ((EIGHTH * 3, 0.3), (BEAT * 2, 0.18)):
    shift = int(RATE * delay)
    src = buf[:]
    for i in range(N):
        buf[(i + shift) % N] += src[i] * gain

peak = max(abs(s) for s in buf)
scale = 0.55 / peak
OUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUT), "wb") as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(RATE)
    f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in buf))
print("записано", OUT, round(TOTAL), "с")
