#!/usr/bin/env python3
"""
generate_icons.py
-----------------
Generates all required iOS/iPadOS app icon sizes from a 1024×1024 source PNG
and updates the AppIcon.appiconset/Contents.json accordingly.

Usage:
    # Use the default generated master icon:
    python3 scripts/generate_icons.py

    # Use your own 1024×1024 source image:
    python3 scripts/generate_icons.py --source path/to/MyIcon-1024.png

Requirements:
    pip install Pillow
"""

import argparse
import json
import math
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Run: pip install Pillow")
    sys.exit(1)

APPICONSET_DIR = os.path.join(
    os.path.dirname(__file__),
    "..",
    "FamilyPhotos",
    "Assets.xcassets",
    "AppIcon.appiconset",
)

# (filename, pixel_size, idiom, scale, pt_size)
ICON_SPECS = [
    # iPhone
    ("AppIcon-20@1x.png",   20,  "iphone",          "1x", "20x20"),
    ("AppIcon-20@2x.png",   40,  "iphone",          "2x", "20x20"),
    ("AppIcon-20@3x.png",   60,  "iphone",          "3x", "20x20"),
    ("AppIcon-29@1x.png",   29,  "iphone",          "1x", "29x29"),
    ("AppIcon-29@2x.png",   58,  "iphone",          "2x", "29x29"),
    ("AppIcon-29@3x.png",   87,  "iphone",          "3x", "29x29"),
    ("AppIcon-40@2x.png",   80,  "iphone",          "2x", "40x40"),
    ("AppIcon-40@3x.png",   120, "iphone",          "3x", "40x40"),
    ("AppIcon-60@2x.png",   120, "iphone",          "2x", "60x60"),
    ("AppIcon-60@3x.png",   180, "iphone",          "3x", "60x60"),
    # iPad
    ("AppIcon-20@1x.png",   20,  "ipad",            "1x", "20x20"),
    ("AppIcon-20@2x.png",   40,  "ipad",            "2x", "20x20"),
    ("AppIcon-29@1x.png",   29,  "ipad",            "1x", "29x29"),
    ("AppIcon-29@2x.png",   58,  "ipad",            "2x", "29x29"),
    ("AppIcon-40@1x.png",   40,  "ipad",            "1x", "40x40"),
    ("AppIcon-40@2x.png",   80,  "ipad",            "2x", "40x40"),
    ("AppIcon-76@1x.png",   76,  "ipad",            "1x", "76x76"),
    ("AppIcon-76@2x.png",   152, "ipad",            "2x", "76x76"),
    ("AppIcon-83.5@2x.png", 167, "ipad",            "2x", "83.5x83.5"),
    # App Store
    ("AppIcon-1024.png",    1024, "ios-marketing",  "1x", "1024x1024"),
]


def resize_and_save(master: Image.Image, px: int, path: str) -> None:
    resized = master.resize((px, px), Image.LANCZOS)
    # Ensure RGB (no alpha) – required by Apple
    if resized.mode != "RGB":
        bg = Image.new("RGB", resized.size, (255, 255, 255))
        bg.paste(resized, mask=resized.split()[3] if resized.mode == "RGBA" else None)
        resized = bg
    resized.save(path, "PNG", optimize=True)


def build_contents_json(specs) -> dict:
    images = []
    for fname, _px, idiom, scale, pt_size in specs:
        entry = {
            "filename": fname,
            "idiom": idiom,
            "scale": scale,
            "size": pt_size,
        }
        images.append(entry)
    return {
        "images": images,
        "info": {"author": "xcode", "version": 1},
    }


def main():
    parser = argparse.ArgumentParser(description="Generate iOS app icon sizes")
    parser.add_argument(
        "--source",
        default=os.path.join(APPICONSET_DIR, "AppIcon-1024.png"),
        help="Path to 1024×1024 source PNG (default: AppIcon-1024.png in appiconset)",
    )
    args = parser.parse_args()

    source_path = os.path.abspath(args.source)
    if not os.path.exists(source_path):
        print(f"Error: source file not found: {source_path}")
        sys.exit(1)

    master = Image.open(source_path)
    if master.size != (1024, 1024):
        print(f"Warning: source image is {master.size}, expected (1024, 1024). Resizing...")
        master = master.resize((1024, 1024), Image.LANCZOS)

    # Ensure RGB
    if master.mode != "RGB":
        bg = Image.new("RGB", master.size, (255, 255, 255))
        if master.mode == "RGBA":
            bg.paste(master, mask=master.split()[3])
        else:
            bg.paste(master)
        master = bg

    os.makedirs(APPICONSET_DIR, exist_ok=True)

    generated_files = set()
    for fname, px, idiom, scale, pt_size in ICON_SPECS:
        dest = os.path.join(APPICONSET_DIR, fname)
        if fname not in generated_files:
            resize_and_save(master, px, dest)
            print(f"  ✓ {fname} ({px}×{px})")
            generated_files.add(fname)
        else:
            print(f"  ↩ {fname} (reused for {idiom} {pt_size} @{scale})")

    contents = build_contents_json(ICON_SPECS)
    contents_path = os.path.join(APPICONSET_DIR, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")
    print(f"\nUpdated: {contents_path}")
    print(f"Generated {len(generated_files)} unique PNG files.")


if __name__ == "__main__":
    main()
