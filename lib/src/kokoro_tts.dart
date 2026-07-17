import 'dart:typed_data';

import 'kokoro_engine/kokoro_engine.dart' as kokoro;

import 'audio.dart';
import 'kokoro_catalog.dart';

class KokoroTtsConfig {
  const KokoroTtsConfig({
    required this.modelAsset,
    required this.voicesAsset,
    this.isInt8 = false,
  });

  final String modelAsset;
  final String voicesAsset;
  final bool isInt8;

  kokoro.KokoroConfig toUpstream() => kokoro.KokoroConfig(
    modelPath: modelAsset,
    voicesPath: voicesAsset,
    isInt8: isInt8,
  );
}

class KokoroTts {
  KokoroTts(KokoroTtsConfig config)
    : _engine = kokoro.Kokoro(config.toUpstream());

  final kokoro.Kokoro _engine;
  var _ready = false;

  Future<PocketSpeechAudio> synthesize(
    String text, {
    String voice = 'af_heart',
    String language = 'en-us',
    double speed = 1.0,
    bool trim = true,
  }) async {
    KokoroCatalog.speed.check(speed);
    KokoroCatalog.language(language);
    if (text.trim().isEmpty) return PocketSpeechAudio.empty();
    if (!_ready) {
      await _engine.initialize();
      _ready = true;
    }

    final result = await _engine.createTTS(
      text: text,
      voice: voice,
      lang: language,
      speed: speed,
      trim: trim,
    );
    return PocketSpeechAudio(
      samples: List<num>.unmodifiable(result.audio),
      sampleRate: result.sampleRate,
      phonemes: result.phonemes,
    );
  }

  Future<PocketSpeechAudio> synthesizeWithOptions(
    String text,
    KokoroSynthesisOptions options,
  ) => synthesize(
    text,
    voice: options.voice,
    language: options.language,
    speed: options.speed,
    trim: options.trim,
  );

  Future<Uint8List> synthesizeWav(
    String text, {
    String voice = 'af_heart',
    String language = 'en-us',
    double speed = 1.0,
    bool trim = true,
  }) async => (await synthesize(
    text,
    voice: voice,
    language: language,
    speed: speed,
    trim: trim,
  )).toWav();

  Future<Uint8List> synthesizeWavWithOptions(
    String text,
    KokoroSynthesisOptions options,
  ) async => (await synthesizeWithOptions(text, options)).toWav();

  Future<void> dispose() => _engine.dispose();
}
