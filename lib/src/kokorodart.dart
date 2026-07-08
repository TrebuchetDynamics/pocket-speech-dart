import 'dart:typed_data';

import 'kokoro_engine/kokoro_engine.dart' as kokoro;

import 'catalog.dart';
import 'wav.dart';

const kokoroSampleRate = 24000;

class KokoroDartConfig {
  const KokoroDartConfig({
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

class KokoroDart {
  KokoroDart(KokoroDartConfig config)
    : _engine = kokoro.Kokoro(config.toUpstream());

  final kokoro.Kokoro _engine;
  var _ready = false;

  Future<KokoroDartAudio> synthesize(
    String text, {
    String voice = 'af_heart',
    String language = 'en-us',
    double speed = 1.0,
    bool trim = true,
  }) async {
    KokoroDartCatalog.speed.check(speed);
    if (text.trim().isEmpty) return KokoroDartAudio.empty();
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
    return KokoroDartAudio(
      samples: List<num>.unmodifiable(result.audio),
      sampleRate: result.sampleRate,
      phonemes: result.phonemes,
    );
  }

  Future<KokoroDartAudio> synthesizeWithOptions(
    String text,
    KokoroDartSynthesisOptions options,
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
    KokoroDartSynthesisOptions options,
  ) async => (await synthesizeWithOptions(text, options)).toWav();
}

class KokoroDartAudio {
  const KokoroDartAudio({
    required this.samples,
    required this.sampleRate,
    required this.phonemes,
  });

  KokoroDartAudio.empty()
    : samples = const <num>[],
      sampleRate = kokoroSampleRate,
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
