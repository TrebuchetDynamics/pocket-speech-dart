# Pocket Speech Rename Design

## Decision

Rename the reusable offline TTS library as follows:

- Project name: **Pocket Speech**
- Dart package: `pocket_speech`
- GitHub repository: `pocket-speech-dart`
- Primary public API prefix: `PocketSpeech`
- Tagline: **Offline speech synthesis for Flutter and Dart**

## Scope

Pocket Speech is a reusable, model-agnostic library for local/offline TTS. Kokoro and KittenTTS are model families supported by the library, not library-level identities. The name leaves room for additional offline engines and model formats without implying cloud TTS support.

## Rename Surface

The implementation rename will update package metadata, imports, public wrapper names, documentation, examples, tests, environment-variable prefixes, and repository URLs. Provider-specific names such as `Kokoro`, `KittenTTS`, model filenames, voice IDs, and attribution remain unchanged.

Compatibility aliases for `KokoroDart` are not required before public release because `publish_to: none` marks the package experimental. Existing Navivox references should migrate directly to the new `PocketSpeech` API.

## Validation

The rename is complete when:

1. `pubspec.yaml` declares `pocket_speech` and the new repository URL.
2. No package imports still use `package:kokorodart/`.
3. Public examples use `PocketSpeech` naming while provider-specific configuration remains explicit.
4. Flutter analysis and all Dart/Python tests pass.
5. Documentation and third-party notices retain Kokoro and KittenTTS attribution.
