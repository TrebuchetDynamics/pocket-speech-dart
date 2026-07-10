import 'dart:io';

import 'package:pocket_speech/pocket_speech.dart';

Future<void> main() async {
  final tts = PocketSpeech.kokoro(
    const KokoroTtsConfig(
      modelAsset: 'assets/kokoro-v1.0.onnx',
      voicesAsset: 'assets/voices.json',
    ),
  );

  final wav = await tts.synthesizeWav('Hello from local Kokoro.');
  await File('kokoro.wav').writeAsBytes(wav);
}
