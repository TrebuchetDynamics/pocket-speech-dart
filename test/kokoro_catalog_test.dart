import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_speech/pocket_speech.dart';

void main() {
  test('catalog lists languages and default voices', () {
    expect(KokoroCatalog.languages.map((language) => language.code), [
      'en-us',
      'en-gb',
      'es',
    ]);
    expect(KokoroCatalog.supportsLanguage('en-us'), isTrue);
    expect(KokoroCatalog.supportsLanguage('es'), isTrue);
    expect(KokoroCatalog.supportsLanguage('fr-fr'), isFalse);
    expect(KokoroCatalog.supportsVoice('ff_siwis'), isFalse);
    expect(KokoroCatalog.language('es').kokoroCode, 'e');
    expect(KokoroCatalog.defaultVoiceForLanguage('es').id, 'ef_dora');
  });

  test('catalog filters voices by language', () {
    final english = KokoroCatalog.voicesForLanguage('en-us');
    final spanish = KokoroCatalog.voicesForLanguage('es');

    expect(english.map((voice) => voice.id), contains('af_heart'));
    expect(english.every((voice) => voice.languageCode == 'en-us'), isTrue);
    expect(
      spanish.map((voice) => voice.id),
      containsAll(['ef_dora', 'em_alex']),
    );
    expect(spanish.every((voice) => voice.languageCode == 'es'), isTrue);
  });

  test('options make app settings explicit', () {
    final options = KokoroSynthesisOptions.forLanguage(
      'es',
    ).copyWith(speed: 1.25);

    expect(options.language, 'es');
    expect(options.voice, 'ef_dora');
    expect(options.speed, 1.25);
    expect(options.trim, isTrue);
  });

  test('catalog rejects unsupported app choices', () {
    expect(KokoroCatalog.supportsLanguage('xx'), isFalse);
    expect(KokoroCatalog.supportsVoice('missing_voice'), isFalse);
    expect(() => KokoroCatalog.language('xx'), throwsArgumentError);
    expect(() => KokoroCatalog.voice('missing_voice'), throwsArgumentError);
    expect(() => KokoroSynthesisOptions.forLanguage('xx'), throwsArgumentError);
  });

  test('synthesis rejects unsupported languages before model load', () async {
    final tts = KokoroTts(
      const KokoroTtsConfig(
        modelAsset: 'model.onnx',
        voicesAsset: 'voices.json',
      ),
    );

    await expectLater(
      tts.synthesize('bonjour', language: 'fr-fr'),
      throwsArgumentError,
    );
  });

  test('speed setting is shared by catalog and synthesis', () async {
    expect(KokoroCatalog.speed.defaultValue, 1.0);
    expect(() => KokoroCatalog.speed.check(0.25), throwsRangeError);
    expect(() => KokoroCatalog.speed.check(double.nan), throwsRangeError);
    expect(() => KokoroCatalog.speed.check(1.5), returnsNormally);

    final tts = KokoroTts(
      const KokoroTtsConfig(
        modelAsset: 'model.onnx',
        voicesAsset: 'voices.json',
      ),
    );
    await expectLater(
      tts.synthesizeWithOptions(
        'hello',
        const KokoroSynthesisOptions(speed: 0.25),
      ),
      throwsRangeError,
    );
  });
}
