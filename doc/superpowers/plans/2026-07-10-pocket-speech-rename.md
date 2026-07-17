# Pocket Speech Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the experimental multi-model offline TTS package from kokorodart to Pocket Speech without retaining pre-release compatibility aliases.

**Architecture:** Keep Kokoro and KittenTTS as explicit provider implementations. Add a tiny `PocketSpeech` namespace with `kokoro` and `kitten` constructors, while sharing only the provider-neutral audio result and speed metadata.

**Tech Stack:** Dart 3.12, Flutter 3.44+, flutter_onnxruntime, Python 3 stdlib download tools, Flutter test.

## Global Constraints

- Project name: **Pocket Speech**.
- Dart package name: `pocket_speech`.
- Intended GitHub repository: `TrebuchetDynamics/pocket-speech-dart`.
- Primary public API: `PocketSpeech`.
- Tagline: **Offline speech synthesis for Flutter and Dart**.
- Scope remains local/offline TTS; do not add cloud-provider abstractions.
- Kokoro and KittenTTS model names, filenames, voice IDs, and attribution remain provider-specific.
- Do not retain `KokoroDart` or `KittenDart` compatibility aliases because the package is unpublished and experimental.
- Do not rename the external GitHub repository without separate explicit delivery approval.

## File Structure

- Rename `lib/kokorodart.dart` to `lib/pocket_speech.dart`: public package barrel.
- Create `lib/src/pocket_speech.dart`: two static provider constructors only.
- Create `lib/src/audio.dart`: provider-neutral `PocketSpeechAudio`.
- Rename `lib/src/kokorodart.dart` to `lib/src/kokoro_tts.dart`: Kokoro public wrapper.
- Rename `lib/src/kittendart.dart` to `lib/src/kitten_tts.dart`: KittenTTS public wrapper.
- Rename `lib/src/catalog.dart` to `lib/src/kokoro_catalog.dart`: Kokoro languages, voices, and synthesis options plus shared speed bounds.
- Create `test/package_identity_test.dart`: package metadata and stale-import regression checks.
- Create `test/pocket_speech_test.dart`: public constructor and shared-audio contract.
- Rename `test/catalog_test.dart` to `test/kokoro_catalog_test.dart`.
- Modify examples, integration tests, platform runner metadata, tools, and documentation in place.

---

### Task 1: Rename the Dart package identity

**Files:**
- Rename: `lib/kokorodart.dart` → `lib/pocket_speech.dart`
- Modify: `pubspec.yaml`
- Modify: `example/main.dart`
- Modify: `integration_test/recursive_tts_stt_e2e_test.dart`
- Modify: `test/catalog_test.dart`
- Modify: `test/deep_vendor_test.dart`
- Modify: `test/kitten_test.dart`
- Modify: `test/wav_test.dart`
- Create: `test/package_identity_test.dart`

**Interfaces:**
- Produces: import root `package:pocket_speech/pocket_speech.dart`.
- Preserves: existing public classes until Task 2.

- [ ] **Step 1: Add a failing package-identity test**

Create `test/package_identity_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package metadata and Dart imports use Pocket Speech', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('name: pocket_speech'));
    expect(
      pubspec,
      contains('repository: https://github.com/TrebuchetDynamics/pocket-speech-dart'),
    );
    expect(File('lib/pocket_speech.dart').existsSync(), isTrue);
    expect(File('lib/kokorodart.dart').existsSync(), isFalse);

    final dartFiles = [
      ...Directory('lib').listSync(recursive: true),
      ...Directory('test').listSync(recursive: true),
      ...Directory('integration_test').listSync(recursive: true),
      ...Directory('example').listSync(recursive: true),
    ].whereType<File>().where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('package:kokorodart/')),
        reason: file.path,
      );
    }
  });
}
```

- [ ] **Step 2: Run the test and confirm the old identity fails**

Run:

```bash
flutter test test/package_identity_test.dart
```

Expected: FAIL because `pubspec.yaml` still declares `kokorodart` and `lib/pocket_speech.dart` does not exist.

- [ ] **Step 3: Rename the barrel and package metadata**

Run:

```bash
mv lib/kokorodart.dart lib/pocket_speech.dart
python3 - <<'PY'
from pathlib import Path

pubspec = Path('pubspec.yaml')
text = pubspec.read_text()
text = text.replace('name: kokorodart', 'name: pocket_speech')
text = text.replace(
    'repository: https://github.com/TrebuchetDynamics/kokorodart',
    'repository: https://github.com/TrebuchetDynamics/pocket-speech-dart',
)
text = text.replace(
    'issue_tracker: https://github.com/TrebuchetDynamics/kokorodart/issues',
    'issue_tracker: https://github.com/TrebuchetDynamics/pocket-speech-dart/issues',
)
pubspec.write_text(text)

for root in ('lib', 'test', 'integration_test', 'example'):
    for path in Path(root).rglob('*.dart'):
        text = path.read_text()
        text = text.replace(
            'package:kokorodart/kokorodart.dart',
            'package:pocket_speech/pocket_speech.dart',
        )
        text = text.replace(
            'package:kokorodart/',
            'package:pocket_speech/',
        )
        path.write_text(text)
PY
flutter pub get
```

- [ ] **Step 4: Verify package identity and the existing suite**

Run:

```bash
flutter test test/package_identity_test.dart
flutter analyze
flutter test
```

Expected: package-identity test passes, analyzer reports no issues, and all Flutter tests pass.

---

### Task 2: Establish the Pocket Speech public API

**Files:**
- Create: `lib/src/pocket_speech.dart`
- Create: `lib/src/audio.dart`
- Rename: `lib/src/kokorodart.dart` → `lib/src/kokoro_tts.dart`
- Rename: `lib/src/kittendart.dart` → `lib/src/kitten_tts.dart`
- Rename: `lib/src/catalog.dart` → `lib/src/kokoro_catalog.dart`
- Modify: `lib/pocket_speech.dart`
- Rename: `test/catalog_test.dart` → `test/kokoro_catalog_test.dart`
- Modify: `test/kokoro_catalog_test.dart`
- Modify: `test/kitten_test.dart`
- Modify: `test/wav_test.dart`
- Modify: `example/main.dart`
- Modify: `integration_test/recursive_tts_stt_e2e_test.dart`
- Create: `test/pocket_speech_test.dart`

**Interfaces:**
- Produces: `PocketSpeech.kokoro(KokoroTtsConfig) -> KokoroTts`.
- Produces: `PocketSpeech.kitten(KittenTtsConfig) -> KittenTts`.
- Produces: `PocketSpeechAudio`, `PocketSpeechSpeed`, `KokoroCatalog`, and `KittenCatalog`.
- Removes: all public identifiers containing `KokoroDart` or `KittenDart`.

- [ ] **Step 1: Add a failing public-API test**

Create `test/pocket_speech_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_speech/pocket_speech.dart';

void main() {
  test('PocketSpeech creates explicit provider implementations', () {
    final kokoro = PocketSpeech.kokoro(
      const KokoroTtsConfig(
        modelAsset: 'kokoro.onnx',
        voicesAsset: 'kokoro.json',
      ),
    );
    final kitten = PocketSpeech.kitten(
      const KittenTtsConfig(
        modelAsset: 'kitten.onnx',
        voicesAsset: 'kitten.json',
      ),
    );

    expect(kokoro, isA<KokoroTts>());
    expect(kitten, isA<KittenTts>());
    expect(PocketSpeechAudio.empty().samples, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test and confirm the new API is absent**

Run:

```bash
flutter test test/pocket_speech_test.dart
```

Expected: compilation fails because `PocketSpeech`, `KokoroTtsConfig`, and `KittenTtsConfig` are not defined.

- [ ] **Step 3: Rename provider files and identifiers**

Run:

```bash
mv lib/src/kokorodart.dart lib/src/kokoro_tts.dart
mv lib/src/kittendart.dart lib/src/kitten_tts.dart
mv lib/src/catalog.dart lib/src/kokoro_catalog.dart
mv test/catalog_test.dart test/kokoro_catalog_test.dart
python3 - <<'PY'
from pathlib import Path

replacements = [
    ('KokoroDartSynthesisOptions', 'KokoroSynthesisOptions'),
    ('KokoroDartConfig', 'KokoroTtsConfig'),
    ('KokoroDartCatalog', 'KokoroCatalog'),
    ('KokoroDartLanguage', 'KokoroLanguage'),
    ('KokoroDartVoice', 'KokoroVoice'),
    ('KokoroDartSpeed', 'PocketSpeechSpeed'),
    ('KokoroDartAudio', 'PocketSpeechAudio'),
    ('kokoroSampleRate', 'pocketSpeechSampleRate'),
    ('KokoroDart', 'KokoroTts'),
    ('KittenDartModel', 'KittenTtsModel'),
    ('KittenDartConfig', 'KittenTtsConfig'),
    ('KittenDartCatalog', 'KittenCatalog'),
    ('KittenDart', 'KittenTts'),
    ("'catalog.dart'", "'kokoro_catalog.dart'"),
    ("'kokorodart.dart'", "'kokoro_tts.dart'"),
    ("'kittendart.dart'", "'kitten_tts.dart'"),
]
for root in ('lib', 'test', 'integration_test', 'example'):
    for path in Path(root).rglob('*.dart'):
        text = path.read_text()
        for old, new in replacements:
            text = text.replace(old, new)
        path.write_text(text)
PY
```

- [ ] **Step 4: Extract provider-neutral audio**

Move the renamed `pocketSpeechSampleRate` constant and the complete `PocketSpeechAudio` class from `lib/src/kokoro_tts.dart` into `lib/src/audio.dart`. Keep these signatures:

```dart
const pocketSpeechSampleRate = 24000;

class PocketSpeechAudio {
  const PocketSpeechAudio({
    required this.samples,
    required this.sampleRate,
    required this.phonemes,
  });

  PocketSpeechAudio.empty()
    : samples = const <num>[],
      sampleRate = pocketSpeechSampleRate,
      phonemes = '';

  final List<num> samples;
  final int sampleRate;
  final String phonemes;

  Duration get duration => Duration(
    microseconds: sampleRate == 0
        ? 0
        : (samples.length * 1000000 ~/ sampleRate),
  );

  Int16List toPcm16() => floatToPcm16(samples);

  Uint8List toWav() => pcm16Wav(toPcm16(), sampleRate: sampleRate);
}
```

Add `dart:typed_data` and `wav.dart` imports to `audio.dart`. Import `audio.dart` from both provider wrappers and remove their now-unused typed-data imports only when no longer needed.

- [ ] **Step 5: Add the minimal provider namespace**

Create `lib/src/pocket_speech.dart`:

```dart
import 'kitten_tts.dart';
import 'kokoro_tts.dart';

abstract final class PocketSpeech {
  static KokoroTts kokoro(KokoroTtsConfig config) => KokoroTts(config);

  static KittenTts kitten(KittenTtsConfig config) => KittenTts(config);
}
```

Replace `lib/pocket_speech.dart` with:

```dart
/// Offline speech synthesis for Flutter and Dart.
library;

export 'src/audio.dart';
export 'src/kitten_tts.dart';
export 'src/kokoro_catalog.dart';
export 'src/kokoro_tts.dart';
export 'src/pocket_speech.dart';
export 'src/wav.dart';
```

- [ ] **Step 6: Update provider imports and sample-rate references**

Ensure:

- `lib/src/kokoro_tts.dart` imports `audio.dart`, `kokoro_catalog.dart`, and `wav.dart` only if directly used.
- `lib/src/kitten_tts.dart` imports `audio.dart`, `kokoro_catalog.dart`, and the internal engine.
- Both wrappers return `Future<PocketSpeechAudio>` and `PocketSpeechAudio.empty()` for blank input.
- `PocketSpeechSpeed` remains in `kokoro_catalog.dart` and is used by both providers for the shared `0.5..2.0` speed boundary.
- `example/main.dart` constructs Kokoro through `PocketSpeech.kokoro(...)`.
- Integration tests use `PocketSpeech.kokoro(...)`.

- [ ] **Step 7: Verify the public API and reject stale names**

Add this assertion to `test/package_identity_test.dart` after collecting Dart files:

```dart
for (final file in dartFiles) {
  final source = file.readAsStringSync();
  expect(source, isNot(contains('KokoroDart')), reason: file.path);
  expect(source, isNot(contains('KittenDart')), reason: file.path);
}
```

Run:

```bash
dart format lib test integration_test example
flutter test test/pocket_speech_test.dart test/package_identity_test.dart
flutter analyze
flutter test
```

Expected: both focused tests pass, analyzer reports no issues, and all Flutter tests pass.

---

### Task 3: Rename runtime identifiers, platform metadata, and documentation

**Files:**
- Modify: `integration_test/recursive_tts_stt_e2e_test.dart`
- Modify: `test/support/recursive_tts_stt.dart`
- Modify: `tool/setup_e2e_assets.py`
- Modify: `linux/CMakeLists.txt`
- Modify: `linux/runner/my_application.cc`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `CONTRIBUTING.md`
- Modify: `THIRD_PARTY_NOTICES.md`
- Modify: `test/package_identity_test.dart`

**Interfaces:**
- Produces: `POCKET_SPEECH_*` e2e configuration variables.
- Produces: Linux binary `pocket_speech` and application title `Pocket Speech`.
- Preserves: provider-specific Kokoro and KittenTTS terminology and attribution.

- [ ] **Step 1: Extend the identity test for runtime and platform names**

Add to `test/package_identity_test.dart`:

```dart
final runtimeFiles = [
  File('integration_test/recursive_tts_stt_e2e_test.dart'),
  File('test/support/recursive_tts_stt.dart'),
  File('tool/setup_e2e_assets.py'),
  File('linux/CMakeLists.txt'),
  File('linux/runner/my_application.cc'),
];
for (final file in runtimeFiles) {
  expect(
    file.readAsStringSync(),
    isNot(contains('KOKORODART')),
    reason: file.path,
  );
}
expect(
  File('linux/CMakeLists.txt').readAsStringSync(),
  contains('set(BINARY_NAME "pocket_speech")'),
);
```

- [ ] **Step 2: Run the test and confirm stale runtime names fail**

Run:

```bash
flutter test test/package_identity_test.dart
```

Expected: FAIL because integration and Linux files still contain the old identity.

- [ ] **Step 3: Replace runtime and Linux identifiers**

Apply these exact replacements:

```text
KOKORODART_E2E_VOICES -> POCKET_SPEECH_E2E_VOICES
KOKORODART_E2E -> POCKET_SPEECH_E2E
KOKORODART_STT_COMMAND -> POCKET_SPEECH_STT_COMMAND
KOKORODART_MODEL_ASSET -> POCKET_SPEECH_MODEL_ASSET
KOKORODART_VOICES_ASSET -> POCKET_SPEECH_VOICES_ASSET
KOKORODART_EN_VOICE -> POCKET_SPEECH_EN_VOICE
KOKORODART_ES_VOICE -> POCKET_SPEECH_ES_VOICE
kokorodart-stt- -> pocket-speech-stt-
set(BINARY_NAME "kokorodart") -> set(BINARY_NAME "pocket_speech")
set(APPLICATION_ID "com.example.kokorodart") -> set(APPLICATION_ID "com.example.pocket_speech")
GTK title "kokorodart" -> GTK title "Pocket Speech"
```

Use longest environment-variable names first so `KOKORODART_E2E_VOICES` is not partially replaced.

- [ ] **Step 4: Rewrite package-level documentation**

Update `README.md` to use:

```yaml
dependencies:
  pocket_speech:
    path: ../pocket-speech-dart
```

Use this import and construction pattern in both Kokoro and KittenTTS examples:

```dart
import 'package:pocket_speech/pocket_speech.dart';

final kokoro = PocketSpeech.kokoro(
  const KokoroTtsConfig(
    modelAsset: 'assets/kokoro/kokoro-v1.0.onnx',
    voicesAsset: 'assets/kokoro/voices.json',
  ),
);

final kitten = PocketSpeech.kitten(
  const KittenTtsConfig(
    modelAsset: 'assets/kitten/nano-fp32/model.onnx',
    voicesAsset: 'assets/kitten/nano-fp32/voices.json',
    model: KittenTtsModel.nanoFp32,
  ),
);
```

Rename the README heading to `# Pocket Speech`, use the approved tagline, change repository links to `TrebuchetDynamics/pocket-speech-dart`, and document only `POCKET_SPEECH_*` environment variables. Add an Unreleased changelog bullet recording the package/API rename. Keep the existing Kokoro MIT-derived-engine notice and KittenTTS Apache-2.0 notice unchanged in substance.

- [ ] **Step 5: Run complete verification**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test example
flutter analyze
flutter test
python3 -m unittest discover -s test -p '*_python_test.py'
git diff --check
git grep -n "package:kokorodart/" -- '*.dart' && exit 1 || true
git grep -nE "KokoroDart|KittenDart|KOKORODART" -- lib test integration_test example tool README.md || true
```

Expected:

- formatter exits 0 with no changes;
- analyzer reports no issues;
- all Flutter and Python tests pass;
- diff check exits 0;
- old package imports produce no matches;
- old public/runtime identifiers produce no matches.

- [ ] **Step 6: Record the external repository handoff**

Report that local metadata now targets `TrebuchetDynamics/pocket-speech-dart`, but do not rename the GitHub repository, change remotes, publish to pub.dev, commit, or push without explicit delivery approval.
