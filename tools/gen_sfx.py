"""Gera SFX sintetizados pro Polaridade.

Pure Python (stdlib only). Salva WAV mono 16-bit 44100Hz em assets/audio/.
"""
import struct
import math
import random
import os

SR = 44100  # sample rate


def write_wav(path, samples_int16):
    n = len(samples_int16)
    data = struct.pack(f'<{n}h', *samples_int16)
    with open(path, 'wb') as f:
        # RIFF header
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + len(data)))
        f.write(b'WAVE')
        # fmt chunk
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))   # chunk size
        f.write(struct.pack('<H', 1))    # PCM
        f.write(struct.pack('<H', 1))    # mono
        f.write(struct.pack('<I', SR))   # sample rate
        f.write(struct.pack('<I', SR * 2))  # byte rate
        f.write(struct.pack('<H', 2))    # block align
        f.write(struct.pack('<H', 16))   # bits per sample
        # data chunk
        f.write(b'data')
        f.write(struct.pack('<I', len(data)))
        f.write(data)


def to_int16(buf):
    return [max(-32768, min(32767, int(s * 32767))) for s in buf]


def env_adsr(n, attack=0.01, decay=0.1, sustain=0.7, release=0.2):
    """ADSR envelope normalizado a duração total = 1."""
    out = []
    a_n = int(n * attack)
    d_n = int(n * decay)
    r_n = int(n * release)
    s_n = max(0, n - a_n - d_n - r_n)
    for i in range(a_n):
        out.append(i / max(1, a_n))
    for i in range(d_n):
        out.append(1.0 - (1.0 - sustain) * (i / max(1, d_n)))
    for i in range(s_n):
        out.append(sustain)
    for i in range(r_n):
        out.append(sustain * (1.0 - i / max(1, r_n)))
    while len(out) < n:
        out.append(0)
    return out[:n]


def env_exp(n, decay=4.0):
    return [math.exp(-decay * i / n) for i in range(n)]


def sine(freq, n, phase=0):
    return [math.sin(2 * math.pi * freq * i / SR + phase) for i in range(n)]


def sine_sweep(f0, f1, n):
    out = []
    phase = 0
    for i in range(n):
        t = i / SR
        freq = f0 + (f1 - f0) * (i / n)
        phase += 2 * math.pi * freq / SR
        out.append(math.sin(phase))
    return out


def noise(n):
    return [random.uniform(-1, 1) for _ in range(n)]


def lowpass(samples, cutoff=2000):
    """Filtro lowpass de 1ª ordem (RC)."""
    rc = 1.0 / (2 * math.pi * cutoff)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    out = [0.0] * len(samples)
    prev = 0
    for i, s in enumerate(samples):
        prev = prev + alpha * (s - prev)
        out[i] = prev
    return out


def mix(*streams, gains=None):
    if gains is None:
        gains = [1.0 / len(streams)] * len(streams)
    length = max(len(s) for s in streams)
    out = [0.0] * length
    for s, g in zip(streams, gains):
        for i, v in enumerate(s):
            out[i] += v * g
    return out


def mult(samples, env):
    n = min(len(samples), len(env))
    return [samples[i] * env[i] for i in range(n)]


# ─── SFX ───

def make_tap():
    n = int(SR * 0.03)
    s = sine(1200, n)
    e = env_exp(n, decay=12.0)
    return mult(s, e)


def make_place():
    n = int(SR * 0.18)
    # Kick: tom baixo com pitch sweep + click
    kick = sine_sweep(160, 60, n)
    click = sine(800, int(SR * 0.005))
    body = mult(kick, env_exp(n, decay=6.0))
    head = click + [0] * (n - len(click))
    out = mix(body, head, gains=[0.7, 0.3])
    return out


def make_flip():
    # Whoosh up + click
    n = int(SR * 0.25)
    sweep = sine_sweep(400, 800, n)
    nz = lowpass(noise(n), cutoff=3500)
    body = mix(sweep, nz, gains=[0.6, 0.4])
    e = env_exp(n, decay=5.0)
    return mult(body, e)


def make_attract():
    n = int(SR * 0.22)
    # Tom ascendente, brilhante
    sweep = sine_sweep(300, 900, n)
    e = env_adsr(n, attack=0.05, decay=0.3, sustain=0.5, release=0.5)
    return mult(sweep, e)


def make_repel():
    n = int(SR * 0.22)
    # Tom descendente, quente
    sweep = sine_sweep(700, 250, n)
    e = env_adsr(n, attack=0.05, decay=0.3, sustain=0.5, release=0.5)
    return mult(sweep, e)


def make_move():
    n = int(SR * 0.12)
    # Slide curto — noise filtrado
    nz = lowpass(noise(n), cutoff=2500)
    e = env_exp(n, decay=8.0)
    return mult(nz, e)


def make_destroy():
    n = int(SR * 0.4)
    # Explosão: noise + rumble
    nz = lowpass(noise(n), cutoff=4000)
    rumble = sine_sweep(100, 40, n)
    out = mix(nz, rumble, gains=[0.6, 0.4])
    e = env_exp(n, decay=4.0)
    return mult(out, e)


def make_line():
    n = int(SR * 0.6)
    # Acorde maior brilhante (chime)
    voices = [sine(f, n) for f in (523, 659, 784)]  # C5 E5 G5
    out = mix(*voices)
    e = env_adsr(n, attack=0.02, decay=0.2, sustain=0.4, release=0.6)
    return mult(out, e)


def make_victory():
    # Arpejo maior C-E-G-C
    notes = [523, 659, 784, 1047]
    dur = 0.25
    total_n = int(SR * dur * len(notes))
    out = [0.0] * total_n
    for i, f in enumerate(notes):
        n = int(SR * dur)
        s = sine(f, n)
        e = env_adsr(n, attack=0.05, decay=0.15, sustain=0.6, release=0.4)
        seg = mult(s, e)
        start = i * n
        for j, v in enumerate(seg):
            if start + j < total_n:
                out[start + j] += v * 0.5
    return out


def make_defeat():
    # Arpejo menor descendente
    notes = [659, 587, 523, 440]
    dur = 0.3
    total_n = int(SR * dur * len(notes))
    out = [0.0] * total_n
    for i, f in enumerate(notes):
        n = int(SR * dur)
        s = sine(f, n)
        e = env_adsr(n, attack=0.05, decay=0.2, sustain=0.5, release=0.5)
        seg = mult(s, e)
        start = i * n
        for j, v in enumerate(seg):
            if start + j < total_n:
                out[start + j] += v * 0.45
    return out


def make_draw():
    n = int(SR * 0.8)
    # Acorde sus2 (sensação suspensa, neutra)
    voices = [sine(f, n) for f in (440, 494, 659)]  # A B E
    out = mix(*voices)
    e = env_adsr(n, attack=0.03, decay=0.3, sustain=0.5, release=0.6)
    return mult(out, e)


SFX = {
    'tap': make_tap,
    'place': make_place,
    'flip': make_flip,
    'attract': make_attract,
    'repel': make_repel,
    'move': make_move,
    'destroy': make_destroy,
    'line': make_line,
    'victory': make_victory,
    'defeat': make_defeat,
    'draw': make_draw,
}


def main():
    out_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    for name, fn in SFX.items():
        samples = fn()
        # Normaliza pra evitar clipping
        peak = max(abs(s) for s in samples) if samples else 1
        if peak > 0:
            samples = [s / peak * 0.85 for s in samples]
        path = os.path.join(out_dir, f'{name}.wav')
        write_wav(path, to_int16(samples))
        print(f'gerado: {path} ({len(samples) / SR:.2f}s)')


if __name__ == '__main__':
    main()
