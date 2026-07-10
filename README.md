# Pocket Speech

Offline speech synthesis for Flutter and Dart. Pocket Speech runs Kokoro and KittenTTS model packs on-device through ONNX Runtime and returns PCM/WAV bytes for app playback.

> **Large asset warning:** Kokoro runs locally/offline, but the assets are not tiny: the ONNX model is about 326 MB and the full voices file is about 28 MB. For mobile apps, treat Kokoro as an optional voice pack unless offline-on-first-launch is worth the install-size cost.

## Public status

Target repo: `TrebuchetDynamics/pocket-speech-dart`.

Experimental package status:

| Platform | Status |
| --- | --- |
| Linux desktop | ✅ Real recursive EN/ES TTS→STT e2e passed |
| Android | Unverified |
| iOS | Unverified |

`publish_to: none` stays enabled until this is ready for pub.dev.

## Why this shape

- Kokoro needs a large ONNX model plus voice embeddings (`kokoro-v1.0.onnx`, `voices-v1.0.bin` or converted `voices.json`).
- KittenTTS provides smaller English-only 15M, 40M, and 80M ONNX alternatives.
- Direct ONNX/runtime wiring lives in the local engine so app code is not coupled to provider-specific wrapper packages.
- No cloud TTS API is called by this wrapper. Bundle, asset-pack, or download model assets depending on your offline and app-size tradeoff.

## Install

```yaml
dependencies:
  pocket_speech:
    path: ../pocket-speech-dart
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

### KittenTTS model packs

Download one or several KittenTTS 0.8 variants:

```bash
python3 -m pip install numpy
python3 tool/download_kitten_assets.py --out assets/kitten \
  --models nano-fp32,micro,mini
```

Available model IDs are `mini` (~78 MB), `micro` (~41 MB), `nano-fp32` (~57 MB), and `nano-int8` (~24 MB). Each selected folder contains `model.onnx`, the original `voices.npz`, and a Flutter-readable `voices.json`. Upstream currently warns that `nano-int8` may have issues, so `nano-fp32` is the default.

Then add only the runtime assets you selected to your Flutter app:

```yaml
flutter:
  assets:
    - assets/kokoro/kokoro-v1.0.onnx
    - assets/kokoro/voices.json
    - assets/kitten/nano-fp32/model.onnx
    - assets/kitten/nano-fp32/voices.json
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
import 'package:pocket_speech/pocket_speech.dart';

final tts = PocketSpeech.kokoro(
  const KokoroTtsConfig(
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

KittenTTS uses the same audio result type and eight English voices:

```dart
final kitten = PocketSpeech.kitten(
  const KittenTtsConfig(
    modelAsset: 'assets/kitten/nano-fp32/model.onnx',
    voicesAsset: 'assets/kitten/nano-fp32/voices.json',
    model: KittenTtsModel.nanoFp32,
  ),
);

final wavBytes = await kitten.synthesizeWav(
  'Kitten TTS is running locally.',
  voice: 'Jasper',
);
```

Use `KittenCatalog.models` and `KittenCatalog.voices` to populate app download and voice selectors.

## List voices, languages, and settings

```dart
final languages = KokoroCatalog.languages;
final spanishVoices = KokoroCatalog.voicesForLanguage('es');
final speed = KokoroCatalog.speed; // min 0.5, default 1.0, max 2.0

final options = KokoroSynthesisOptions.forLanguage('es').copyWith(
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
  --dart-define=POCKET_SPEECH_E2E=true \
  --dart-define=POCKET_SPEECH_STT_COMMAND='["python3","-m","whisper","{wav}","--language","{lang}","--model","tiny","--device","cpu","--fp16","False","--output_format","txt","--output_dir","{dir}"]'
```

What it runs for both English and Spanish:

```text
seed text → Kokoro TTS WAV → local STT transcript → Kokoro TTS WAV → local STT transcript
```

`POCKET_SPEECH_STT_COMMAND` is a JSON string array. Placeholders:

- `{wav}`: generated WAV path
- `{lang}`: `en` or `es`
- `{dir}`: temp output directory for tools like Whisper that write `.txt`

Optional overrides: `POCKET_SPEECH_MODEL_ASSET`, `POCKET_SPEECH_VOICES_ASSET`, `POCKET_SPEECH_EN_VOICE`, `POCKET_SPEECH_ES_VOICE`.

## Notes

- Sample rate is 24 kHz mono.
- Default English voice is `af_heart`; default Spanish e2e voice is `ef_dora`.
- This package does not commit or redistribute model files.
