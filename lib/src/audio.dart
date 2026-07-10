import 'dart:typed_data';

import 'wav.dart';

const pocketSpeechSampleRate = 24000;

class PocketSpeechAudio {
  const PocketSpeechAudio({
    required this.samples,
    required this.sampleRate,
    required this.phonemes,
  });

  PocketSpeechAudio.empty()
    : samples = const <num>[],
      sampleRate = pocketSpeechSampleRate,
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
