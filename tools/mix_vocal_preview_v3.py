"""Mix a clearly articulated bilingual vocal preview over gameplay V2."""

from pathlib import Path
import wave
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
MUSIC = ROOT / "assets/audio/music/ruins_light_gameplay_v2.wav"
VOCALS = ROOT / "assets/audio/music/vocal_work"
OUTPUT = ROOT / "assets/audio/music/ruins_light_gameplay_v3_vocal_preview.wav"


def read(path):
    with wave.open(str(path), "rb") as f:
        rate = f.getframerate()
        channels = f.getnchannels()
        data = np.frombuffer(f.readframes(f.getnframes()), "<i2").astype(np.float32) / 32768
    return rate, data.reshape(-1, channels)


def write(path, rate, data):
    pcm = (np.clip(data, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(rate)
        f.writeframes(pcm.tobytes())


def resample(signal, source_rate, target_rate, duration=None):
    source = signal[:, 0]
    count = int((len(source) / source_rate if duration is None else duration) * target_rate)
    old = np.linspace(0, 1, len(source), endpoint=False)
    new = np.linspace(0, 1, count, endpoint=False)
    return np.interp(new, old, source).astype(np.float32)


def add_phrase(track, phrase, rate, start, pan, gain, note):
    begin = int(start * rate)
    size = min(len(phrase), len(track) - begin)
    if size <= 0: return
    phrase = phrase[:size]
    # Speech envelope drives a quiet pitch anchor: articulation stays clear,
    # while the ear hears a sustained melodic line rather than plain speech.
    window = max(1, int(rate * 0.025))
    envelope = np.sqrt(np.convolve(phrase * phrase, np.ones(window) / window, mode="same"))
    t = np.arange(size) / rate
    hz = 440 * 2 ** ((note - 69) / 12)
    anchor = np.sin(2 * np.pi * hz * t + 0.018 * np.sin(2 * np.pi * 4.6 * t))
    signal = phrase * gain + anchor * envelope * gain * 0.18
    left = np.sqrt((1 - pan) * 0.5); right = np.sqrt((1 + pan) * 0.5)
    track[begin:begin + size, 0] += signal * left
    track[begin:begin + size, 1] += signal * right


def main():
    rate, music = read(MUSIC)
    vocal = np.zeros_like(music)
    notes = [62, 65, 67, 62]
    line_seconds = 3.75
    for passage in (17.0, 63.0):
        for index, note in enumerate(notes, 1):
            gr, greek = read(VOCALS / f"greek_{index:02d}.wav")
            lr, latin = read(VOCALS / f"latin_{index:02d}.wav")
            greek = resample(greek, gr, rate, line_seconds)
            latin = resample(latin, lr, rate, line_seconds)
            start = passage + (index - 1) * 4.05
            add_phrase(vocal, greek, rate, start, -0.12, 0.125, note - 12)
            add_phrase(vocal, latin, rate, start + 0.035, 0.12, 0.112, note)
    dry = vocal.copy()
    for delay, gain, swap in ((0.16, .22, True), (0.39, .15, False), (0.71, .09, True)):
        echo = np.roll(dry, int(delay * rate), axis=0)
        if swap: echo = echo[:, ::-1]
        vocal += echo * gain
    mixed = music * 0.91 + vocal
    mixed = np.tanh(mixed * 1.08) * 0.88
    write(OUTPUT, rate, mixed)
    print(f"wrote={OUTPUT} duration={len(mixed)/rate:.2f}s peak={np.max(np.abs(mixed)):.4f}")


if __name__ == "__main__":
    main()
