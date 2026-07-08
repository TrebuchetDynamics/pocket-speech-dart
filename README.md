# kokorodart

A Flutter/Dart package for offline Kokoro TTS with an optional large local model pack. Its owned `kokoro_engine` code runs inference on-device through ONNX Runtime and returns PCM/WAV bytes for app playback.

> **Large asset warning:** Kokoro runs locally/offline, but the assets are not tiny: the ONNX model is about 326 MB and the full voices file is about 28 MB. For mobile apps, treat Kokoro as an optional voice pack unless offline-on-first-launch is worth the install-size cost.

## Public status

Target repo: `TrebuchetDynamics/kokorodart`.

Experimental package status:

| Platform | Status |
| --- | --- |
| Linux desktop | ✅ Real recursive EN/ES TTS→STT e2e passed |
| Android | Unverified |
| iOS | Unverified |

`publish_to: none` stays enabled until this is ready for pub.dev.

## Why this shape

- Kokoro needs a large ONNX model plus voice embeddings (`kokoro-v1.0.onnx`, `voices-v1.0.bin` or converted `voices.json`).
- Direct ONNX/runtime wiring lives in the local `kokoro_engine`; this package keeps Navivox behind one small owned API instead of coupling app code to another wrapper package.
- No cloud TTS API is called by this wrapper. Bundle, asset-pack, or download model assets depending on your offline and app-size tradeoff.

## Install from Navivox

```yaml
dependencies:
  kokorodart:
    path: ../kokorodart
```

## Download assets

Download the Kokoro ONNX model and export only the voices your app needs:

```bash
python3 -m pip install numpy
python3 tool/download_kokoro_assets.py --out assets/kokoro --voices af_heart,ef_dora
```

This writes:

```text
assets/kokoro/kokoro-v1.0.onnx
assets/kokoro/voices-v1.0.bin
assets/kokoro/voices.json
```

Size/checksum notes:

- `kokoro-v1.0.onnx` is about 326 MB.
- `voices-v1.0.bin` is about 28 MB.
- `voices.json` size depends on `--voices`.
- The script prints exact byte sizes and SHA-256 hashes after download/generation.

Do not commit these large files unless your app intentionally vendors Kokoro assets.

Then add runtime assets to your Flutter app:

```yaml
flutter:
  assets:
    - assets/kokoro/kokoro-v1.0.onnx
    - assets/kokoro/voices.json
```

## Play Store asset strategy

For a Play Console app, do not put a ~326 MB TTS model in the base APK/AAB unless offline-on-first-launch matters more than install size.

Better defaults:

- Offline-first app: use Play Asset Delivery install-time or fast-follow asset packs.
- Smaller initial install: use Play Asset Delivery on-demand packs, then block TTS until assets arrive.
- Non-Play distribution or custom hosting: do first-run in-app download with resume, SHA-256 verification, and a clear Wi-Fi/storage prompt.

Tradeoff: if assets are downloaded after install, the app is not fully offline until that download or asset-pack install completes.

## Use

```dart
import 'package:kokorodart/kokorodart.dart';

final tts = KokoroDart(
  const KokoroDartConfig(
    modelAsset: 'assets/kokoro/kokoro-v1.0.onnx',
    voicesAsset: 'assets/kokoro/voices.json',
  ),
);

final wavBytes = await tts.synthesizeWav(
  'Kokoro is running locally.',
  voice: 'af_heart',
  language: 'en-us',
);
```

## List voices, languages, and settings

```dart
final languages = KokoroDartCatalog.languages;
final spanishVoices = KokoroDartCatalog.voicesForLanguage('es');
final speed = KokoroDartCatalog.speed; // min 0.5, default 1.0, max 2.0

final options = KokoroDartSynthesisOptions.forLanguage('es').copyWith(
  voice: 'ef_dora',
  speed: 1.15,
);

final wavBytes = await tts.synthesizeWavWithOptions(
  'Kokoro habla localmente.',
  options,
);
```

## Upstream Kokoro notes

`hexgrad/kokoro` documents Kokoro-82M as an Apache-licensed, 82M-parameter open-weight TTS model. Its Python `KPipeline` uses language codes like `en-us`/`a` for American English and `es`/`e` for Spanish. Voice names are language-prefixed; useful defaults for this package are `af_heart` for English and `ef_dora` for Spanish.

## Real recursive TTS/STT e2e

The live test is opt-in because it needs large local model files and a local STT command. It does not call a cloud API.

```bash
python3 -m pip install numpy openai-whisper
# Downloads ONNX + voices-v1.0.bin; exports af_heart and ef_dora into voices.json.
python3 tool/setup_e2e_assets.py
flutter test integration_test/recursive_tts_stt_e2e_test.dart -d linux \
  --dart-define=KOKORODART_E2E=true \
  --dart-define=KOKORODART_STT_COMMAND='["python3","-m","whisper","{wav}","--language","{lang}","--model","tiny","--device","cpu","--fp16","False","--output_format","txt","--output_dir","{dir}"]'
```

What it runs for both English and Spanish:

```text
seed text → Kokoro TTS WAV → local STT transcript → Kokoro TTS WAV → local STT transcript
```

`KOKORODART_STT_COMMAND` is a JSON string array. Placeholders:

- `{wav}`: generated WAV path
- `{lang}`: `en` or `es`
- `{dir}`: temp output directory for tools like Whisper that write `.txt`

Optional overrides: `KOKORODART_MODEL_ASSET`, `KOKORODART_VOICES_ASSET`, `KOKORODART_EN_VOICE`, `KOKORODART_ES_VOICE`.

## Notes

- Sample rate is 24 kHz mono.
- Default English voice is `af_heart`; default Spanish e2e voice is `ef_dora`.
- This package does not commit or redistribute model files.
