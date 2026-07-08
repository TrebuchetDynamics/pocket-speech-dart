import 'dart:io';

import 'package:kokorodart/kokorodart.dart';

Future<void> main() async {
  final tts = KokoroDart(
    const KokoroDartConfig(
      modelAsset: 'assets/kokoro-v1.0.onnx',
      voicesAsset: 'assets/voices.json',
    ),
  );

  final wav = await tts.synthesizeWav('Hello from local Kokoro.');
  await File('kokoro.wav').writeAsBytes(wav);
}
