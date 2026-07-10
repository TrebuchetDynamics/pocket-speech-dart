#!/usr/bin/env python3
"""Download one or more KittenTTS 0.8 ONNX model packs."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import urllib.request

MODELS = {
    "mini": {
        "repo": "KittenML/kitten-tts-mini-0.8",
        "file": "kitten_tts_mini_v0_8.onnx",
        "size": 78_268_016,
        "sha256": "0f5bbae4fc4800c98dbc544a87ecfa79510de2fb8222db30d12e5bfe9177df91",
        "voices_sha256": "40ad2638952b77b7b2f30127e2608e169fc69dd256b53bd8aaa3409a33193c42",
    },
    "micro": {
        "repo": "KittenML/kitten-tts-micro-0.8",
        "file": "kitten_tts_micro_v0_8.onnx",
        "size": 41_384_970,
        "sha256": "95481626fee1ba70ce683e69c534fc7cb38433c46ce42d3abbeafb4b9f1a4123",
        "voices_sha256": "112710c1be8ad0e967c190fb0fd95cbe5848ec4791b93209f20b28b7da20dac1",
    },
    "nano-fp32": {
        "repo": "KittenML/kitten-tts-nano-0.8-fp32",
        "file": "kitten_tts_nano_v0_8.onnx",
        "size": 56_767_095,
        "sha256": "320564d2615f235de972ca27a7f39551c94185cfa24ca85b07a29084135f1e5e",
        "voices_sha256": "8aa7cee235abb0739cb51e6559685f65a4dacd95568833d05699b1633f519b3f",
    },
    "nano-int8": {
        "repo": "KittenML/kitten-tts-nano-0.8-int8",
        "file": "kitten_tts_nano_v0_8.onnx",
        "size": 24_369_971,
        "sha256": "f7b0afcbee92870b32b8e0276d855b954dc25470c9f051b376ac7eee537c76fc",
        "voices_sha256": "8aa7cee235abb0739cb51e6559685f65a4dacd95568833d05699b1633f519b3f",
    },
}
VOICES_SIZE = 3_278_902


def parse_models(value: str) -> list[str]:
    models = list(dict.fromkeys(item.strip() for item in value.split(",") if item.strip()))
    unknown = [model for model in models if model not in MODELS]
    if not models or unknown:
        choices = ", ".join(MODELS)
        raise argparse.ArgumentTypeError(f"models must be selected from: {choices}")
    return models


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(
    path: pathlib.Path,
    url: str,
    expected_size: int,
    expected_sha256: str,
    force: bool = False,
) -> pathlib.Path:
    if force and path.exists():
        path.unlink()
    if not path.exists():
        print(f"download {url}")
        urllib.request.urlretrieve(url, path)
    if path.stat().st_size != expected_size or sha256_file(path) != expected_sha256:
        raise RuntimeError(f"download verification failed: {path}")
    return path


def export_voices(source: pathlib.Path, destination: pathlib.Path, force: bool) -> pathlib.Path:
    if destination.exists() and not force:
        return destination
    try:
        import numpy as np
    except ImportError as error:
        raise SystemExit("Install numpy to export voices.json: python3 -m pip install numpy") from error
    voices = np.load(source)
    destination.write_text(
        json.dumps({voice: voices[voice].tolist() for voice in voices.files}),
        encoding="utf-8",
    )
    return destination


def download_assets(
    out: pathlib.Path,
    models: list[str],
    force: bool = False,
) -> list[pathlib.Path]:
    paths = []
    for model in models:
        info = MODELS[model]
        directory = out / model
        directory.mkdir(parents=True, exist_ok=True)
        base = f"https://huggingface.co/{info['repo']}/resolve/main"
        onnx = download(
            directory / "model.onnx",
            f"{base}/{info['file']}?download=true",
            info["size"],
            info["sha256"],
            force,
        )
        voices = download(
            directory / "voices.npz",
            f"{base}/voices.npz?download=true",
            VOICES_SIZE,
            info["voices_sha256"],
            force,
        )
        paths.extend([onnx, voices, export_voices(voices, directory / "voices.json", force)])
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=pathlib.Path, default=pathlib.Path("assets/kitten"))
    parser.add_argument("--models", type=parse_models, default=parse_models("nano-fp32"))
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    paths = download_assets(args.out, args.models, args.force)
    print("ready")
    for path in paths:
        print(f"{path}: {path.stat().st_size} bytes, sha256={sha256_file(path)}")


if __name__ == "__main__":
    main()
