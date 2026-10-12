"""Assemble GIFs from the Godot captures, without changing the model or texture."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
frames_dir = root / ".local/keleken-preview"
out = root / "docs/evidence/keleken"
out.mkdir(exist_ok=True)
try:
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 22)
except OSError:
    font = ImageFont.load_default()
for clip, duration, label in [("idle", 6400, "Olhares em repouso"), ("walk", 1200, "Caminhada"), ("run", 800, "Corrida")]:
    frames = []
    for path in sorted(frames_dir.glob(f"{clip}-loop-*.png")):
        frame = Image.open(path).convert("RGB").resize((480, 480), Image.Resampling.LANCZOS)
        draw = ImageDraw.Draw(frame)
        draw.text((20, 16), label, font=font, fill="#d9e4ed")
        if not frames:
            frames.append(frame.quantize(colors=128))
        else:
            frames.append(frame.quantize(palette=frames[0]))
    assert len(frames) == (96 if clip == "idle" else 36)
    frames[0].save(out / f"{clip}.gif", save_all=True, append_images=frames[1:],
                   duration=round(duration / len(frames)), loop=0, disposal=1, optimize=True)
Image.open(frames_dir / "walk-2.png").save(out / "animation_study.png")
print("KELEKEN packaged idle.gif, walk.gif, run.gif, animation_study.png")
