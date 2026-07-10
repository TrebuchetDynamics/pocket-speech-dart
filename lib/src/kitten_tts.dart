import 'dart:typed_data';

import 'audio.dart';
import 'kokoro_catalog.dart';
import 'kokoro_engine/kokoro_engine.dart' as engine;

enum KittenTtsModel {
  mini('mini', 78268016, false),
  micro('micro', 41384970, false),
  nanoFp32('nano-fp32', 56767095, false),
  nanoInt8('nano-int8', 24369971, true);

  const KittenTtsModel(this.id, this.sizeBytes, this.isQuantized);

  final String id;
  final int sizeBytes;
  final bool isQuantized;
}

class KittenTtsConfig {
  const KittenTtsConfig({
    required this.modelAsset,
    required this.voicesAsset,
    this.model = KittenTtsModel.nanoFp32,
  });

  final String modelAsset;
  final String voicesAsset;
  final KittenTtsModel model;
}

class KittenCatalog {
  KittenCatalog._();

  static const models = KittenTtsModel.values;
  static const voices = <String>[
    'Bella',
    'Jasper',
    'Luna',
    'Bruno',
    'Rosie',
    'Hugo',
    'Kiki',
    'Leo',
  ];

  static bool supportsVoice(String voice) =>
      voices.contains(voice) || _voiceAliases.containsValue(voice);

  static String resolveVoice(String voice) {
    final resolved = _voiceAliases[voice] ?? voice;
    if (!_voiceAliases.containsValue(resolved)) {
      throw ArgumentError.value(voice, 'voice', 'unsupported KittenTTS voice');
    }
    return resolved;
  }

  static double speedPrior(KittenTtsModel model, String voice) {
    if (model != KittenTtsModel.nanoFp32 && model != KittenTtsModel.nanoInt8) {
      return 1.0;
    }
    return voice == 'expr-voice-4-m' ? 0.9 : 0.8;
  }

  static const _voiceAliases = {
    'Bella': 'expr-voice-2-f',
    'Jasper': 'expr-voice-2-m',
    'Luna': 'expr-voice-3-f',
    'Bruno': 'expr-voice-3-m',
    'Rosie': 'expr-voice-4-f',
    'Hugo': 'expr-voice-4-m',
    'Kiki': 'expr-voice-5-f',
    'Leo': 'expr-voice-5-m',
  };
}

class KittenTts {
  KittenTts(this.config)
    : _engine = engine.Kokoro(
        engine.KokoroConfig(
          modelPath: config.modelAsset,
          voicesPath: config.voicesAsset,
          isKitten: true,
        ),
      );

  final KittenTtsConfig config;
  final engine.Kokoro _engine;
  var _ready = false;

  Future<PocketSpeechAudio> synthesize(
    String text, {
    String voice = 'Jasper',
    double speed = 1.0,
    bool trim = true,
  }) async {
    KokoroCatalog.speed.check(speed);
    if (text.trim().isEmpty) return PocketSpeechAudio.empty();
    final voiceId = KittenCatalog.resolveVoice(voice);
    if (!_ready) {
      await _engine.initialize();
      _ready = true;
    }
    final result = await _engine.createTTS(
      text: text,
      voice: voiceId,
      speed: speed * KittenCatalog.speedPrior(config.model, voiceId),
      trim: trim,
    );
    return PocketSpeechAudio(
      samples: List<num>.unmodifiable(result.audio),
      sampleRate: result.sampleRate,
      phonemes: result.phonemes,
    );
  }

  Future<Uint8List> synthesizeWav(
    String text, {
    String voice = 'Jasper',
    double speed = 1.0,
    bool trim = true,
  }) async =>
      (await synthesize(text, voice: voice, speed: speed, trim: trim)).toWav();

  Future<void> dispose() => _engine.dispose();
}
