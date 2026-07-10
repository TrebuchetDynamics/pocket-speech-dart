import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_speech/pocket_speech.dart';
import 'package:pocket_speech/src/kokoro_engine/src/tokenizer.dart';

void main() {
  test('KittenTTS catalog exposes all downloadable models and voices', () {
    expect(KittenCatalog.models, hasLength(4));
    expect(
      KittenCatalog.models.map((model) => model.id),
      containsAll(['mini', 'micro', 'nano-fp32', 'nano-int8']),
    );
    expect(KittenCatalog.resolveVoice('Jasper'), 'expr-voice-2-m');
    expect(KittenCatalog.supportsVoice('Leo'), isTrue);
    expect(() => KittenCatalog.resolveVoice('missing'), throwsArgumentError);
    expect(
      KittenCatalog.speedPrior(KittenTtsModel.nanoFp32, 'expr-voice-4-m'),
      0.9,
    );
  });

  test('KittenTTS tokenizer matches the upstream 0.8 symbol table', () {
    expect(Tokenizer().tokenize('həlˈoʊ.', kitten: true), [
      50,
      83,
      54,
      156,
      57,
      135,
      16,
      4,
    ]);
  });
}
