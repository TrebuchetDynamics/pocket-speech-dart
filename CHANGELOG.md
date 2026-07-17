# Changelog

## Unreleased

- Renamed the package to Pocket Speech and added the provider-neutral `PocketSpeech` API.
- Added KittenTTS 0.8 mini, micro, nano-fp32, and nano-int8 model-pack downloads and local inference.
- Reject non-finite synthesis speeds before model inference.
- Refresh exported Kokoro voices when the requested voice selection changes.
- Limit the Kokoro catalog to languages supported by the built-in phonemizer.

## 0.1.0

- Initial experimental Kokoro Flutter/Dart package.
- Added owned `kokoro_engine` for local ONNX inference.
- Added voice/language/speed catalog and synthesis options.
- Added WAV output helpers.
- Added opt-in Linux recursive EN/ES TTS→STT e2e test.
- Kept pub.dev publishing disabled with `publish_to: none`.
