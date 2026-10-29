#!/usr/bin/env python3
"""Export Sportsman's Quest with Godot 4.7 stable.

Templates come from the Godot editor's own template folder. This script
does not point at a machine-local custom_template path.

    GODOT=/path/to/Godot_v4.7.2-stable python tools/export_release.py linux
    python tools/export_release.py windows|linux|macos|web
    python tools/export_release.py pack TARGET

`pack` runs --export-pack and does not need export templates.
The other targets run --export-release and do.

Install templates that match the editor build exactly, for example
4.7.2.stable, via Editor -> Manage Export Templates, or unzip
Godot_v4.7.2-stable_export_templates.tpz into:

    Windows: %APPDATA%\\Godot\\export_templates\\4.7.2.stable\\
    Linux:   ~/.local/share/godot/export_templates/4.7.2.stable/
    macOS:   ~/Library/Application Support/Godot/export_templates/4.7.2.stable/

Web uses the nothreads template because preset "Web" sets
variant/thread_support=false and leaves custom_template/release empty.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

TARGETS = {
    "windows": ("Windows Desktop (Ultra-Lite)", os.path.join("dist", "SportsmansQuest.exe")),
    "linux": ("Linux Desktop", os.path.join("dist", "linux", "SportsmansQuest.x86_64")),
    "macos": ("macOS Desktop", os.path.join("dist", "macos", "SportsmansQuest.zip")),
    "web": ("Web", os.path.join("dist", "web", "index.html")),
}


def godot_bin() -> str:
    return os.environ.get("GODOT", "godot")


def run_godot(args: list[str]) -> int:
    cmd = [godot_bin(), "--headless", "--path", ROOT, *args]
    print(" ", " ".join(cmd))
    return subprocess.call(cmd)


def export_release(target: str) -> int:
    preset, rel = TARGETS[target]
    dest = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    code = run_godot(["--export-release", preset, dest])
    if code != 0:
        print(
            "Export failed. Install Godot 4.7 stable export templates "
            "that match this editor, then retry. Do not set a custom_template path.",
            file=sys.stderr,
        )
        return code
    print(f"Wrote {dest} ({os.path.getsize(dest):,} bytes)")
    return 0


def export_pack(target: str) -> int:
    preset, rel = TARGETS[target]
    dest = os.path.join(ROOT, os.path.splitext(rel)[0] + ".pck")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    code = run_godot(["--export-pack", preset, dest])
    if code != 0:
        return code
    print(f"Wrote {dest} ({os.path.getsize(dest):,} bytes)")
    return 0


def zip_windows() -> int:
    dist = os.path.join(ROOT, "dist")
    exe = os.path.join(dist, "SportsmansQuest.exe")
    if not os.path.isfile(exe):
        print(f"Missing {exe}. Run: python tools/export_release.py windows", file=sys.stderr)
        return 1
    zip_path = os.path.join(dist, "SportsmansQuest_Windows_ReadyToPlay.zip")
    if os.path.exists(zip_path):
        os.remove(zip_path)
    note = """Sportsman's Quest
Run SportsmansQuest.exe. The pack is embedded.
Day Hunt or Night Hunt from the main menu.
Esc pauses. F10 returns to the menu.
This zip is a local rebuild. It does not replace the live itch build.
"""
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(exe, "SportsmansQuest.exe")
        zf.writestr("README.txt", note)
    print(f"Wrote {zip_path} ({os.path.getsize(zip_path):,} bytes)")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0
    cmd = argv[1]
    if cmd == "pack":
        if len(argv) < 3 or argv[2] not in TARGETS:
            print("usage: export_release.py pack windows|linux|macos|web", file=sys.stderr)
            return 2
        return export_pack(argv[2])
    if cmd == "zip-windows":
        return zip_windows()
    if cmd not in TARGETS:
        print(f"Unknown target {cmd}. Choose {', '.join(TARGETS)}.", file=sys.stderr)
        return 2
    if shutil.which(godot_bin()) is None and not os.path.isfile(godot_bin()):
        print(f"Godot binary not found: {godot_bin()}", file=sys.stderr)
        print("Set GODOT to a Godot 4.7 stable editor binary.", file=sys.stderr)
        return 1
    return export_release(cmd)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
