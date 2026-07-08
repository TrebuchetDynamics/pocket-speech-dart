import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kokorodart/src/kokoro_engine/src/tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'owned engine no longer exposes old kokoro_tts_flutter name in imports',
    () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in files) {
        expect(file.readAsStringSync(), isNot(contains('kokoro_tts_flutter')));
      }
    },
  );

  test(
    'Spanish phonemizer does not treat simple Spanish words as English',
    () async {
      final tokenizer = Tokenizer();
      final phonemes = await tokenizer.phonemize('hola llama coco', lang: 'es');

      expect(phonemes, contains('ola'));
      expect(phonemes, contains('ʎama'));
      expect(phonemes, contains('koko'));
      expect(phonemes, isNot(contains('hoʊ')));
    },
  );

  test('Spanish phonemizer handles locale variants and accents', () async {
    final tokenizer = Tokenizer();

    expect(await tokenizer.phonemize('', lang: 'Spanish'), '');
    expect(await tokenizer.phonemize('niño qué', lang: 'ES-ES'), contains('ɲ'));
    expect(await tokenizer.phonemize('queso', lang: 'e'), contains('keso'));
  });
}
