import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'support/recursive_tts_stt.dart';

void main() {
  test('normalizes English and Spanish speech text', () {
    expect(
      normalizeSpeechText('¡Kokoro habla ESPAÑOL, rápido!'),
      'kokoro habla espanol rapido',
    );
    expect(
      normalizeSpeechText('Kokoro speaks locally.'),
      'kokoro speaks locally',
    );
  });

  test('runs tts stt tts stt in order', () async {
    final spoken = <String>[];
    final transcripts = ['Hello local Kokoro test.', 'hello local kokoro test'];

    final steps = await runRecursiveTtsStt(
      RecursiveSpeechCase(
        name: 'english',
        seedText: 'Hello, local Kokoro test.',
        ttsLanguage: 'en-us',
        sttLanguage: 'en',
        voice: 'af_heart',
      ),
      synthesizeWav: (text, speechCase, pass) async {
        spoken.add('$pass:${speechCase.ttsLanguage}:${speechCase.voice}:$text');
        return Uint8List.fromList([pass]);
      },
      transcribe: (wav, speechCase, pass) async => transcripts[pass - 1],
    );

    expect(spoken, [
      '1:en-us:af_heart:Hello, local Kokoro test.',
      '2:en-us:af_heart:Hello local Kokoro test.',
    ]);
    expect(steps.map((step) => step.transcript), transcripts);
  });

  test('rejects empty transcript before the next tts pass', () async {
    await expectLater(
      runRecursiveTtsStt(
        const RecursiveSpeechCase(
          name: 'english',
          seedText: 'Hello, local Kokoro test.',
          ttsLanguage: 'en-us',
          sttLanguage: 'en',
          voice: 'af_heart',
        ),
        synthesizeWav: (_, _, _) async => Uint8List(0),
        transcribe: (_, _, _) async => '',
      ),
      throwsStateError,
    );
  });

  test('parses stt command as a json string list', () {
    expect(parseSttCommand('["python3","-m","whisper","{wav}"]'), [
      'python3',
      '-m',
      'whisper',
      '{wav}',
    ]);
    expect(() => parseSttCommand('[]'), throwsFormatException);
    expect(() => parseSttCommand('["python3",3]'), throwsFormatException);
  });
}
