#!/usr/bin/env python3
"""
PiTimelapse v3 — Raspberry Pi Camera Module 3 (12MP / 1080p timelapse)

First-time setup: python3 timeLapse_v3.py --bootstrap-pi

Run from cron:
  * * * * * python3 /home/pi/timeLapse_v3.py my_project
"""

import os
import sys
import time
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

try:
    from picamera2 import Picamera2
except ImportError:
    print("picamera2 not found. Run: sudo apt install python3-picamera2", file=sys.stderr)
    sys.exit(1)

# ── Configuration ────────────────────────────────────────────────────────────

WEB_ROOT = "/var/www/html"
LOCK_DIR = "/var/lock/pitimelapse_v3"

# Camera Module 3 native max: 4608×2592 (12 MP, 16:9)
CAM_MAX_WIDTH = 4608
CAM_MAX_HEIGHT = 2592

# Output video scale — 1920:1080 suits Pi Zero W processing headroom.
# Change to 3840:2160 for 4K on Pi 4/5 (much slower encode).
VIDEO_SCALE = "1920:1080"

JPEG_QUALITY = 95          # capture quality (0-95 for Pillow)
TIMELAPSE_RAW = "timelapse.mp4"
FILE_LIST = "pictures.txt"
TIMELAPSE_BANNER = "timelapse_banner.mp4"
TIMELAPSE_BANNER_STATIC = "timelapse_banner_static.mp4"

# Font search order for timestamp overlay
_FONT_PATHS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
]

# ── Helpers ──────────────────────────────────────────────────────────────────

_APT_PACKAGES = [
    "python3-picamera2",
    "python3-pil",
    "ffmpeg",
    "apache2",
    "imagemagick",
]


def bootstrap_pi():
    """Install all system-level dependencies. Run once on a fresh Pi."""
    print("Bootstrapping Pi — installing system packages (requires sudo)...")
    subprocess.run(
        ["sudo", "apt", "install", "-y"] + _APT_PACKAGES,
        check=True,
    )
    print("Bootstrap complete.")


def display_usage():
    name = Path(sys.argv[0]).name
    print(f"PiTimelapse v3 — Raspberry Pi Camera Module 3")
    print(f"Creates/updates a timelapse project under {WEB_ROOT} — run from cron.\n")
    print(f"Usage: {name} <project-name> [width] [height] [quality]")
    print(f"       {name} --bootstrap-pi\n")
    print(f"  --bootstrap-pi  Install all system dependencies via apt (run once on a new Pi)")
    print(f"  width           capture width  (default: {CAM_MAX_WIDTH})")
    print(f"  height          capture height (default: {CAM_MAX_HEIGHT})")
    print(f"  quality         JPEG quality 1-95 (default: {JPEG_QUALITY})\n")
    print(f"Examples:")
    print(f"  python3 {name} --bootstrap-pi")
    print(f"  python3 {name} my_lapse")
    print(f"  python3 {name} my_lapse 1920 1080 90\n")
    print(f"Crontab (every minute):")
    print(f"  * * * * * python3 /home/pi/{name} my_lapse")
    print(f"Crontab (every 5 minutes):")
    print(f"  */5 * * * * python3 /home/pi/{name} my_lapse")


def acquire_lock():
    """mkdir-based lock identical in spirit to v2's simple locking."""
    try:
        os.makedirs(LOCK_DIR)
    except FileExistsError:
        # Another instance is running; cron will retry next interval.
        sys.exit(1)


def release_lock():
    try:
        os.rmdir(LOCK_DIR)
    except OSError:
        pass


def _load_font(size: int) -> ImageFont.FreeTypeFont:
    for path in _FONT_PATHS:
        try:
            return ImageFont.truetype(path, size)
        except (IOError, OSError):
            continue
    return ImageFont.load_default()


def add_timestamp(image_path: str):
    """
    Burn the file's mtime into the top-right corner as lime text —
    matches the v2 ImageMagick NorthEast annotate style.
    Preserves the file mtime so add_stamps.sh-style retroactive stamping
    still works correctly if needed.
    """
    original_mtime = os.path.getmtime(image_path)
    ts_text = f" {datetime.fromtimestamp(original_mtime).strftime('%a %d %b %Y %H:%M:%S')}"

    img = Image.open(image_path)
    w, h = img.size
    font_size = max(40, w // 80)
    font = _load_font(font_size)
    draw = ImageDraw.Draw(img)

    bbox = draw.textbbox((0, 0), ts_text, font=font)
    text_w = bbox[2] - bbox[0]
    x = w - text_w - 5
    y = 5

    # Black drop-shadow keeps text readable on any background
    draw.text((x + 2, y + 2), ts_text, font=font, fill="black")
    draw.text((x, y), ts_text, font=font, fill="lime")

    img.save(image_path, "JPEG", quality=JPEG_QUALITY)

    # Restore original mtime so video assembly ordering stays intact
    os.utime(image_path, (original_mtime, original_mtime))


# ── Camera ───────────────────────────────────────────────────────────────────

def take_photo(output_path: str, width: int, height: int, quality: int):
    """
    Capture a still with Camera Module 3.
    - Configures full-resolution still mode
    - Waits for AEC/AWB to settle
    - Runs one autofocus cycle (PDAF on Camera Module 3)
    - Stamps timestamp on the saved JPEG
    """
    cam = Picamera2()
    config = cam.create_still_configuration(
        main={"size": (width, height)},
    )
    cam.configure(config)
    cam.start()

    # Allow auto-exposure and auto-white-balance to converge
    time.sleep(2)

    # One-shot autofocus — Camera Module 3 has PDAF; gracefully skip if unavailable
    try:
        cam.autofocus_cycle()
    except Exception:
        pass

    cam.options["quality"] = quality
    cam.capture_file(output_path)
    cam.stop()
    cam.close()

    add_timestamp(output_path)


# ── Video assembly ────────────────────────────────────────────────────────────

def build_timelapse(project_home: Path, project_name: str):
    """
    Rebuild the timelapse from all sequential JPEGs:
      1. timelapse.mp4          — raw concat, scaled to VIDEO_SCALE
      2. timelapse_banner.mp4   — with bottom-centre date-range text overlay
      3. timelapse_banner_static.mp4 — safe copy for browser viewing during writes
    """
    jpegs = sorted(
        [f for f in project_home.iterdir() if f.suffix == ".jpg"],
        key=lambda p: int(p.stem),
    )

    file_list = project_home / FILE_LIST
    file_list.write_text("\n".join(f"file {j.name}" for j in jpegs) + "\n")

    raw = project_home / TIMELAPSE_RAW
    raw.unlink(missing_ok=True)

    subprocess.run(
        [
            "nice", "-15",
            "ffmpeg", "-y",
            "-f", "concat", "-safe", "0",
            "-i", str(file_list),
            "-vf", f"scale={VIDEO_SCALE}",
            "-c:v", "libx264", "-pix_fmt", "yuv420p",
            str(raw),
        ],
        check=True,
    )

    # Build banner text matching v2 format exactly
    oldest_date = datetime.fromtimestamp(jpegs[0].stat().st_mtime).strftime("%d %B")
    now = datetime.now()
    month = now.strftime("%B")
    day = now.strftime("%d")
    esc_time = now.strftime("%H\\:%M\\:%S")
    banner_text = (
        f"Project {project_name} from {oldest_date} "
        f"to {month} the {day} at {esc_time}"
    )

    banner = project_home / TIMELAPSE_BANNER
    banner.unlink(missing_ok=True)

    subprocess.run(
        [
            "ffmpeg", "-y",
            "-i", str(raw),
            "-vf", (
                f"drawtext=text='{banner_text}'"
                ":x=(w-text_w)/2:y=h-th-40"
                ":fontsize=20:fontcolor=red"
            ),
            "-c:a", "copy",
            str(banner),
        ],
        check=True,
    )

    shutil.copy2(str(banner), str(project_home / TIMELAPSE_BANNER_STATIC))
    file_list.unlink()


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    args = sys.argv[1:]

    if not args or args[0] in ("-h", "--help"):
        display_usage()
        sys.exit(0)

    if args[0] == "--bootstrap-pi":
        bootstrap_pi()
        sys.exit(0)

    if len(args) > 4:
        display_usage()
        sys.exit(1)

    project_name = args[0]
    width   = int(args[1]) if len(args) > 1 else CAM_MAX_WIDTH
    height  = int(args[2]) if len(args) > 2 else CAM_MAX_HEIGHT
    quality = int(args[3]) if len(args) > 3 else JPEG_QUALITY

    acquire_lock()
    try:
        project_home = Path(WEB_ROOT) / project_name
        project_home.mkdir(parents=True, exist_ok=True)

        jpegs = sorted(
            [f for f in project_home.iterdir() if f.suffix == ".jpg"],
            key=lambda p: int(p.stem),
        )

        if not jpegs:
            # First run — take the seed photo; no video yet
            take_photo(str(project_home / "1.jpg"), width, height, quality)
        else:
            next_num = int(jpegs[-1].stem) + 1
            take_photo(str(project_home / f"{next_num}.jpg"), width, height, quality)

            # Brief pause so file metadata is fully flushed before ffmpeg reads it
            time.sleep(10)

            build_timelapse(project_home, project_name)
    finally:
        release_lock()


if __name__ == "__main__":
    main()
