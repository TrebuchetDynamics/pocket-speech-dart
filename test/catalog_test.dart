import 'package:flutter_test/flutter_test.dart';
import 'package:kokorodart/kokorodart.dart';

void main() {
  test('catalog lists languages and default voices', () {
    expect(KokoroDartCatalog.supportsLanguage('en-us'), isTrue);
    expect(KokoroDartCatalog.supportsLanguage('es'), isTrue);
    expect(KokoroDartCatalog.language('es').kokoroCode, 'e');
    expect(KokoroDartCatalog.defaultVoiceForLanguage('es').id, 'ef_dora');
  });

  test('catalog filters voices by language', () {
    final english = KokoroDartCatalog.voicesForLanguage('en-us');
    final spanish = KokoroDartCatalog.voicesForLanguage('es');

    expect(english.map((voice) => voice.id), contains('af_heart'));
    expect(english.every((voice) => voice.languageCode == 'en-us'), isTrue);
    expect(
      spanish.map((voice) => voice.id),
      containsAll(['ef_dora', 'em_alex']),
    );
    expect(spanish.every((voice) => voice.languageCode == 'es'), isTrue);
  });

  test('options make app settings explicit', () {
    final options = KokoroDartSynthesisOptions.forLanguage(
      'es',
    ).copyWith(speed: 1.25);

    expect(options.language, 'es');
    expect(options.voice, 'ef_dora');
    expect(options.speed, 1.25);
    expect(options.trim, isTrue);
  });

  test('catalog rejects unsupported app choices', () {
    expect(KokoroDartCatalog.supportsLanguage('xx'), isFalse);
    expect(KokoroDartCatalog.supportsVoice('missing_voice'), isFalse);
    expect(() => KokoroDartCatalog.language('xx'), throwsArgumentError);
    expect(() => KokoroDartCatalog.voice('missing_voice'), throwsArgumentError);
    expect(
      () => KokoroDartSynthesisOptions.forLanguage('xx'),
      throwsArgumentError,
    );
  });

  test('speed setting is shared by catalog and synthesis', () async {
    expect(KokoroDartCatalog.speed.defaultValue, 1.0);
    expect(() => KokoroDartCatalog.speed.check(0.25), throwsRangeError);
    expect(() => KokoroDartCatalog.speed.check(1.5), returnsNormally);

    final tts = KokoroDart(
      const KokoroDartConfig(
        modelAsset: 'model.onnx',
        voicesAsset: 'voices.json',
      ),
    );
    await expectLater(
      tts.synthesizeWithOptions(
        'hello',
        const KokoroDartSynthesisOptions(speed: 0.25),
      ),
      throwsRangeError,
    );
  });
}
