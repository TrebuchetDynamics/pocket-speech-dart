#!/usr/bin/env python3
"""Download Kokoro model assets for a Flutter app or local e2e run."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import urllib.request

BASE = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0"
FILES = {
    "kokoro-v1.0.onnx": (
        f"{BASE}/kokoro-v1.0.onnx",
        325_532_387,
    ),
    "voices-v1.0.bin": (
        f"{BASE}/voices-v1.0.bin",
        28_214_398,
    ),
}


def parse_voices(value: str) -> list[str]:
    voices = [voice.strip() for voice in value.split(",") if voice.strip()]
    if not voices:
        raise argparse.ArgumentTypeError("--voices must contain at least one voice")
    return voices


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def mib(size: int) -> str:
    return f"{size / 1024 / 1024:.1f} MiB"


def report(path: pathlib.Path) -> str:
    size = path.stat().st_size
    return f"{path.name}: {size} bytes ({mib(size)}), sha256={sha256_file(path)}"


def download(path: pathlib.Path, url: str, expected_size: int, force: bool) -> pathlib.Path:
    if force and path.exists():
        path.unlink()
    if not path.exists():
        print(f"download {url}")
        urllib.request.urlretrieve(url, path)
    size = path.stat().st_size
    if size != expected_size:
        raise RuntimeError(f"{path} size {size} != expected {expected_size}")
    return path


def export_voices(voices_bin: pathlib.Path, voices_json: pathlib.Path, voices: list[str], force: bool) -> pathlib.Path:
    if voices_json.exists() and not force:
        return voices_json

    try:
        import numpy as np
    except ImportError as error:
        raise SystemExit("Install numpy to export voices.json: python3 -m pip install numpy") from error

    data = np.load(voices_bin)
    missing = [voice for voice in voices if voice not in data.files]
    if missing:
        raise SystemExit(f"missing voices in {voices_bin}: {', '.join(missing)}")

    voices_json.write_text(
        json.dumps({voice: data[voice].tolist() for voice in voices}),
        encoding="utf-8",
    )
    return voices_json


def download_assets(out: pathlib.Path, voices: list[str], force: bool = False) -> list[pathlib.Path]:
    out.mkdir(parents=True, exist_ok=True)
    model = download(out / "kokoro-v1.0.onnx", *FILES["kokoro-v1.0.onnx"], force=force)
    voices_bin = download(out / "voices-v1.0.bin", *FILES["voices-v1.0.bin"], force=force)
    voices_json = export_voices(voices_bin, out / "voices.json", voices, force=force)
    return [model, voices_bin, voices_json]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=pathlib.Path, default=pathlib.Path("assets/kokoro"))
    parser.add_argument("--voices", type=parse_voices, default=parse_voices("af_heart,ef_dora"))
    parser.add_argument("--force", action="store_true", help="redownload and regenerate existing files")
    args = parser.parse_args()

    paths = download_assets(args.out, args.voices, force=args.force)
    print("ready")
    for path in paths:
        print(report(path))
    print("Do not commit these large files unless your app intentionally vendors Kokoro assets.")


if __name__ == "__main__":
    main()
