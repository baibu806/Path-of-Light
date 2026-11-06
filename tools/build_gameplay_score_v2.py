"""Build the gameplay mix from the accepted dark-Celtic opening palette.

The opening cue supplies the instrumental world; new distant boy/girl lines
are mixed as an audible third texture, never as a foreground lead.
"""

from pathlib import Path
import wave

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parent
SOURCE = next((WORKSPACE / "Audio").glob("*03.wav"))
OUTPUT = ROOT / "assets" / "audio" / "music" / "ruins_light_gameplay_v2.wav"
TAU = np.pi * 2.0


def read_wav(path):
    with wave.open(str(path), "rb") as f:
        assert f.getsampwidth() == 2 and f.getnchannels() == 2
        rate = f.getframerate()
        pcm = np.frombuffer(f.readframes(f.getnframes()), dtype="<i2")
    return rate, pcm.reshape(-1, 2).astype(np.float32) / 32768.0


def write_wav(path, rate, audio):
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(audio, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(pcm.tobytes())


def spectral_shape(audio, rate):
    """Soften foreground brilliance while preserving the authored palette."""
    result = np.zeros_like(audio)
    frequency = np.fft.rfftfreq(len(audio), 1.0 / rate)
    curve = np.ones_like(frequency)
    curve *= np.clip(frequency / 75.0, 0.15, 1.0)
    curve *= np.where(frequency < 3600, 1.0, np.exp(-(frequency - 3600) / 4200))
    # Gameplay needs less cinematic weight than the opening.
    curve *= 0.84
    for channel in range(2):
        spectrum = np.fft.rfft(audio[:, channel])
        result[:, channel] = np.fft.irfft(spectrum * curve, len(audio)).astype(np.float32)
    return result


def note_hz(midi):
    return 440.0 * 2.0 ** ((midi - 69.0) / 12.0)


def add_voice(track, rate, start, length, midi, gain, female, pan):
    begin = int(start * rate)
    size = min(int(length * rate), len(track) - begin)
    if size <= 0:
        return
    t = np.arange(size, dtype=np.float32) / rate
    f = note_hz(midi)
    # Slow natural pitch drift; formant bands create a far-away open vowel.
    phase = TAU * f * t + 0.018 * np.sin(TAU * (4.7 if female else 4.2) * t)
    fundamental = np.sin(phase)
    voice = fundamental + 0.26 * np.sin(2 * phase) + 0.10 * np.sin(3 * phase)
    formant = 940.0 if female else 720.0
    voice += 0.11 * np.sin(TAU * formant * t) * fundamental
    attack = np.minimum(1.0, t / 0.38)
    release = np.minimum(1.0, (length - t) / 0.72)
    env = np.clip(attack * release, 0, 1) ** 0.75
    signal = voice * env * gain
    track[begin:begin + size, 0] += signal * np.sqrt((1 - pan) * 0.5)
    track[begin:begin + size, 1] += signal * np.sqrt((1 + pan) * 0.5)


def add_distant_duet(track, rate):
    # Same melody and phrasing in both languages. The tiny onset difference is
    # linguistic breathing, not call-and-response.
    motif = [(0.0, 62, 2.2), (2.4, 65, 1.7), (4.4, 67, 2.0),
             (6.7, 69, 2.3), (9.3, 67, 1.8), (11.4, 65, 1.9),
             (13.6, 62, 3.6)]
    voices = np.zeros_like(track)
    for origin in (17.0, 51.0, 72.0):
        for offset, note, length in motif:
            add_voice(voices, rate, origin + offset, length, note - 12, 0.055, False, -0.10)
            add_voice(voices, rate, origin + offset + 0.045, length, note, 0.046, True, 0.10)
    # Broad outdoor distance, not a church tail.
    for delay, gain, swap in ((0.23, 0.26, True), (0.57, 0.17, False), (0.91, 0.10, True)):
        shifted = np.roll(voices, int(delay * rate), axis=0)
        if swap:
            shifted = shifted[:, ::-1]
        voices += shifted * gain
    track += voices


def seamless(audio, rate, seconds=4.0):
    count = int(seconds * rate)
    curve = np.linspace(0, 1, count, dtype=np.float32)[:, None]
    shared = audio[-count:] * (1 - curve) + audio[:count] * curve
    audio[:count] = shared
    audio[-count:] = shared
    return audio


def main():
    rate, source = read_wav(SOURCE)
    music = spectral_shape(source, rate)
    # Keep sufficient headroom for environment and repair feedback.
    music *= 0.48 / max(float(np.max(np.abs(music))), 1e-6)
    add_distant_duet(music, rate)
    music = seamless(music, rate)
    music = np.tanh(music * 1.18) * 0.82
    write_wav(OUTPUT, rate, music)
    print(f"source={SOURCE}")
    print(f"wrote={OUTPUT} duration={len(music) / rate:.2f}s peak={np.max(np.abs(music)):.4f}")


if __name__ == "__main__":
    main()
