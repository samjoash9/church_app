#!/usr/bin/env python3

"""
=============================================================
 Audio Compressor Script (Python)
 Strategy: Cut to 30 mins + Re-encode at 96 kbps (stereo)
 Reduces ~295MB → ~90MB (approx. 70% reduction)
 Requires: ffmpeg installed on your system
=============================================================
"""

import os
import subprocess
import shutil
import sys
from pathlib import Path

# --- CONFIG (edit these if needed) ---
INPUT_DIR   = "assets/audio/"             # Folder containing your .mp3 files
OUTPUT_DIR  = "assets/mono/"  # Folder where compressed files will be saved
DURATION    = 1800            # 30 minutes in seconds
BITRATE     = "96k"           # Audio bitrate (use "64k" for aggressive compression)
CHANNELS    = 1               # 2 = stereo, 1 = mono (mono saves ~50% more space)
FORMAT      = "mp3"           # Output format: "mp3" or "ogg"
# -------------------------------------

# ANSI colors
GREEN  = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN   = "\033[0;36m"
RED    = "\033[0;31m"
RESET  = "\033[0m"

def colored(text, color):
    return f"{color}{text}{RESET}"

def check_ffmpeg():
    """Check if ffmpeg is installed."""
    if shutil.which("ffmpeg") is None:
        print(colored("❌ FFmpeg is not installed.", RED))
        print()
        print("Install it with:")
        print("  macOS:   brew install ffmpeg")
        print("  Ubuntu:  sudo apt install ffmpeg")
        print("  Windows: https://ffmpeg.org/download.html")
        print()
        sys.exit(1)

def get_file_size_mb(path):
    """Return file size in MB."""
    return os.path.getsize(path) / (1024 * 1024)

def compress_file(input_path, output_path):
    """Run ffmpeg to compress a single audio file."""
    cmd = [
        "ffmpeg",
        "-i", str(input_path),
        "-t", str(DURATION),
        "-ac", str(CHANNELS),
        "-b:a", BITRATE,
        "-map_metadata", "0",
        "-y",
        str(output_path),
        "-loglevel", "error"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode == 0, result.stderr

def main():
    print()
    print(colored("======================================", CYAN))
    print(colored("       🎵 Audio Compressor Script     ", CYAN))
    print(colored("======================================", CYAN))
    print()

    # Check ffmpeg
    check_ffmpeg()

    # Resolve paths
    input_dir  = Path(INPUT_DIR).resolve()
    output_dir = Path(OUTPUT_DIR).resolve()

    # Find all mp3 files
    mp3_files = sorted(input_dir.glob("*.mp3"))

    if not mp3_files:
        print(colored(f"❌ No .mp3 files found in: {input_dir}", RED))
        sys.exit(1)

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"📂 Input folder  : {colored(str(input_dir), CYAN)}")
    print(f"📁 Output folder : {colored(str(output_dir), CYAN)}")
    print(f"⏱  Duration      : {colored('30 minutes', CYAN)}")
    print(f"🎚  Bitrate       : {colored(BITRATE, CYAN)}")
    print(f"🔊 Channels      : {colored('Stereo' if CHANNELS == 2 else 'Mono', CYAN)}")
    print(f"🗂  Format        : {colored(FORMAT, CYAN)}")
    print(f"📄 Files found   : {colored(str(len(mp3_files)), CYAN)}")
    print()
    print(colored("Starting compression...", YELLOW))
    print()

    total_input_size  = 0.0
    total_output_size = 0.0
    success_count     = 0
    failed_count      = 0

    for file in mp3_files:
        output_file = output_dir / f"{file.stem}.{FORMAT}"
        input_mb    = get_file_size_mb(file)
        total_input_size += input_mb

        print(f"  🔄 Processing: {colored(file.name, CYAN)}")

        ok, err = compress_file(file, output_file)

        if ok:
            output_mb = get_file_size_mb(output_file)
            total_output_size += output_mb
            savings = round((1 - output_mb / input_mb) * 100)
            print(f"  ✅ Done: {input_mb:.1f} MB → {output_mb:.1f} MB "
                  f"(saved ~{colored(f'{savings}%', GREEN)})")
            success_count += 1
        else:
            print(colored(f"  ❌ Failed: {file.name}", RED))
            if err:
                print(colored(f"     {err.strip()}", RED))
            failed_count += 1

        print()

    # Summary
    total_savings = round((1 - total_output_size / total_input_size) * 100) if total_input_size > 0 else 0
    failed_str    = colored(f" | {failed_count} failed", RED) if failed_count > 0 else ""

    print(colored("======================================", CYAN))
    print(colored("           ✅ Compression Done!       ", GREEN))
    print(colored("======================================", CYAN))
    print()
    print(f"  Files processed : {colored(f'{success_count} / {len(mp3_files)}', GREEN)}{failed_str}")
    print(f"  Total before    : {colored(f'{total_input_size:.1f} MB', YELLOW)}")
    print(f"  Total after     : {colored(f'{total_output_size:.1f} MB', GREEN)}")
    print(f"  Total saved     : {colored(f'~{total_savings}%', GREEN)}")
    print()
    print(f"  📁 Compressed files saved to: {colored(str(output_dir), CYAN)}")
    print()

if __name__ == "__main__":
    main()