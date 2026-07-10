import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_speech/pocket_speech.dart';

void main() {
  test('PocketSpeech creates explicit provider implementations', () async {
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

    await kokoro.dispose();
    await kitten.dispose();
  });
}
