# Contributing

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

## Real e2e

Large Kokoro model files are not committed. Regenerate local test assets when needed:

```bash
python3 -m pip install numpy openai-whisper
python3 tool/setup_e2e_assets.py
```

Then run the command in the README.

Do not commit files under `test_assets/kokoro/` except `.gitkeep`.
