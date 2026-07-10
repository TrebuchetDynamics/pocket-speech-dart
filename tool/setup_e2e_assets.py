#!/usr/bin/env python3
"""Download Kokoro ONNX assets for the local e2e tests."""

from __future__ import annotations

import os
import pathlib

from download_kokoro_assets import download_assets, report

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "test_assets" / "kokoro"


def main() -> None:
    voices = [voice.strip() for voice in os.environ.get("POCKET_SPEECH_E2E_VOICES", "af_heart,ef_dora").split(",") if voice.strip()]
    paths = download_assets(OUT, voices)
    print("ready")
    for path in paths:
        print(report(path))


if __name__ == "__main__":
    main()
