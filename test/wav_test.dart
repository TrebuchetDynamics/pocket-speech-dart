import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kokorodart/kokorodart.dart';

void main() {
  test('writes a mono 16-bit wav header', () {
    final wav = pcm16Wav(Int16List.fromList([0, 32767]), sampleRate: 24000);

    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    expect(ByteData.sublistView(wav).getUint32(24, Endian.little), 24000);
    expect(ByteData.sublistView(wav).getUint32(40, Endian.little), 4);
  });

  test('converts float samples to clipped pcm16', () {
    expect(floatToPcm16([-2, -1, 0, 1, 2]), [-32767, -32767, 0, 32767, 32767]);
  });

  test('empty audio has Kokoro defaults', () {
    final audio = KokoroDartAudio.empty();

    expect(audio.sampleRate, kokoroSampleRate);
    expect(audio.duration, Duration.zero);
    expect(audio.toWav().length, 44);
  });

  test('rejects unsupported speed before model load', () async {
    final tts = KokoroDart(
      const KokoroDartConfig(
        modelAsset: 'model.onnx',
        voicesAsset: 'voices.json',
      ),
    );

    await expectLater(tts.synthesize('hi', speed: 3), throwsRangeError);
  });
}
