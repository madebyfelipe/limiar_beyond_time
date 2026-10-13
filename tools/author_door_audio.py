"""Create the original latch/hinge sounds used by the door cinematic (no samples)."""
from pathlib import Path
import math
import random
import struct
import wave

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 44100


def write(name, duration, sample):
    rng = random.Random(731)
    data = bytearray()
    for index in range(round(duration * RATE)):
        time = index / RATE
        value = max(-1.0, min(1.0, sample(time, rng)))
        data.extend(struct.pack("<h", round(value * 32767)))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(data)


def latch(time, rng):
    value = 0.0
    for onset, pitch in [(0.018, 740), (0.135, 430)]:
        local = time - onset
        if local >= 0:
            envelope = math.exp(-local * 65)
            value += envelope * (0.42 * math.sin(math.tau * pitch * local)
                                  + 0.27 * rng.uniform(-1, 1))
    return value


def creak(time, rng):
    envelope = math.sin(math.pi * min(time / 1.5, 1)) ** 0.7
    phase = math.tau * (180 * time + 24 * time * time)
    wobble = 2.8 * math.sin(math.tau * 4.2 * time)
    return envelope * (0.23 * math.sin(phase + wobble)
                       + 0.12 * math.sin(phase * 2.13 + wobble)
                       + 0.04 * rng.uniform(-1, 1))


def gate_latch(time, rng):
    """The gate's lever lifted out of its keeper: a heavier clack and its ring."""
    value = 0.0
    for onset, pitch, decay, gain in [(0.02, 310, 38, 0.5), (0.17, 520, 30, 0.34), (0.2, 1240, 16, 0.1)]:
        local = time - onset
        if local >= 0:
            envelope = math.exp(-local * decay)
            value += envelope * gain * (math.sin(math.tau * pitch * local)
                                         + 0.45 * rng.uniform(-1, 1))
    return value


def gate_swing(time, rng):
    """Two loaded hinges groaning lower and longer than a door, sheet rattling."""
    envelope = math.sin(math.pi * min(time / 2.2, 1)) ** 0.6
    phase = math.tau * (92 * time + 9 * time * time)
    wobble = 3.4 * math.sin(math.tau * 2.6 * time)
    rattle = math.exp(-(time % 0.29) * 48) * 0.09 * rng.uniform(-1, 1)
    return envelope * (0.24 * math.sin(phase + wobble)
                       + 0.11 * math.sin(phase * 2.71 + wobble)
                       + 0.05 * rng.uniform(-1, 1) + rattle)


if __name__ == "__main__":
    write("door_latch.wav", 0.35, latch)
    write("door_creak.wav", 1.5, creak)
    write("gate_latch.wav", 0.5, gate_latch)
    write("gate_swing.wav", 2.2, gate_swing)
