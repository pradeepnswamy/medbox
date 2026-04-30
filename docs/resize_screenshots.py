#!/usr/bin/env python3
"""
resize_screenshots.py
─────────────────────
Resizes iPhone screenshots to App Store–required dimensions.

Usage
-----
  1. Save your screenshots into  docs/screenshots/originals/
  2. Run:  python3 docs/resize_screenshots.py
  3. Pick output size from the prompt (or pass it as an argument).
  4. Find the finished PNGs in  docs/screenshots/appstore/

Supported output sizes
  1284x2778  – iPhone 6.7″  (iPhone 14/15 Pro Max)  ← recommended
  1242x2688  – iPhone 6.5″  (iPhone 11 Pro Max / XS Max)
"""

import sys
import os
from pathlib import Path
from PIL import Image

SIZES = {
    "1": (1284, 2778, "6.7inch"),
    "2": (1242, 2688, "6.5inch"),
}

BANNER_H   = 140        # coloured caption bar at the bottom (0 = none)
BANNER_COL = (36, 123, 96)   # CarerMeds green  #247B60
TEXT_COL   = (255, 255, 255)

CAPTIONS = [
    "Dashboard at a glance",
    "All your medicines, organised",
    "Add a medicine in seconds",
    "Manage your patients",
    "Add a new patient",
    "All prescriptions, one place",
    "Log a prescription",
    "Stay on top of alerts",
]

# ── helpers ──────────────────────────────────────────────────────────────────

def fit_and_pad(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Scale image to fill target height, then centre-crop width if needed."""
    src_w, src_h = img.size
    scale = target_h / src_h
    new_w = round(src_w * scale)
    img = img.resize((new_w, target_h), Image.LANCZOS)
    if new_w < target_w:
        # pad sides with the edge colour
        canvas = Image.new("RGB", (target_w, target_h), img.getpixel((0, target_h // 2)))
        canvas.paste(img, ((target_w - new_w) // 2, 0))
        return canvas
    # centre-crop
    left = (new_w - target_w) // 2
    return img.crop((left, 0, left + target_w, target_h))


def add_banner(img: Image.Image, caption: str, banner_h: int) -> Image.Image:
    """Overlay a coloured caption bar at the bottom."""
    if not banner_h or not caption:
        return img
    try:
        from PIL import ImageDraw, ImageFont
        draw = ImageDraw.Draw(img)
        draw.rectangle([0, img.height - banner_h, img.width, img.height], fill=BANNER_COL)
        font_size = banner_h // 3
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except Exception:
            font = ImageFont.load_default()
        bbox = draw.textbbox((0, 0), caption, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        x = (img.width - tw) // 2
        y = img.height - banner_h + (banner_h - th) // 2
        draw.text((x, y), caption, fill=TEXT_COL, font=font)
    except Exception as e:
        print(f"  ⚠  Could not draw caption: {e}")
    return img

# ── main ─────────────────────────────────────────────────────────────────────

def main():
    script_dir = Path(__file__).parent
    input_dir  = script_dir / "screenshots" / "originals"
    output_dir = script_dir / "screenshots" / "appstore"

    input_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    # ── pick size ────────────────────────────────────────────────────────────
    if len(sys.argv) > 1 and sys.argv[1] in SIZES:
        choice = sys.argv[1]
    else:
        print("\nChoose output size:")
        for k, (w, h, label) in SIZES.items():
            print(f"  {k}. {w}×{h}  ({label})  ← recommended" if k == "1" else f"  {k}. {w}×{h}  ({label})")
        choice = input("\nEnter 1 or 2 [1]: ").strip() or "1"
        if choice not in SIZES:
            choice = "1"

    target_w, target_h, label = SIZES[choice]
    print(f"\nTarget: {target_w}×{target_h} ({label})")

    # ── find source images ───────────────────────────────────────────────────
    exts = {".png", ".jpg", ".jpeg"}
    files = sorted(p for p in input_dir.iterdir() if p.suffix.lower() in exts)

    if not files:
        print(f"\n⚠  No images found in {input_dir}")
        print(   "   Save your screenshots there, then re-run this script.")
        return

    print(f"Found {len(files)} image(s) → resizing…\n")

    for i, src in enumerate(files):
        img = Image.open(src).convert("RGB")
        out = fit_and_pad(img, target_w, target_h)

        caption = CAPTIONS[i] if i < len(CAPTIONS) else ""
        out = add_banner(out, caption, BANNER_H)

        stem = f"{i+1:02d}_{src.stem}"
        dest = output_dir / f"{stem}_{label}.png"
        out.save(dest, "PNG", optimize=True)
        print(f"  ✓  {src.name}  →  {dest.name}  ({out.size[0]}×{out.size[1]})")

    print(f"\nDone! Files saved to:\n  {output_dir}\n")


if __name__ == "__main__":
    main()
