"""Turns the frames from test/capture_gif_test.dart into the README GIFs.

    CAPTURE=1 flutter test test/capture_gif_test.dart
    python3 tool/make_gifs.py

Needs Pillow. Writes ../screenshots/<name>.gif for each folder in
build/gif_frames/.
"""
from pathlib import Path

from PIL import Image

FRAMES = Path(__file__).parent.parent / 'build' / 'gif_frames'
OUT = Path(__file__).parent.parent.parent / 'screenshots'
WIDTH = 300

for folder in sorted(p for p in FRAMES.iterdir() if p.is_dir()):
    files = sorted(folder.glob('*.png'))
    if not files:
        continue
    first = Image.open(files[0])
    size = (WIDTH, round(first.height * WIDTH / first.width))
    frames = [Image.open(f).convert('RGB').resize(size, Image.LANCZOS) for f in files]
    # One shared palette keeps colors stable between frames and files small.
    palette = frames[len(frames) // 2].quantize(colors=128, method=Image.Quantize.MEDIANCUT)
    quantized = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    out = OUT / f'{folder.name}.gif'
    quantized[0].save(out, save_all=True, append_images=quantized[1:],
                      duration=100, loop=0, optimize=True)
    print(f'{out.name}: {len(frames)} frames, {out.stat().st_size // 1024} KB')
