import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kokorodart/kokorodart.dart';

import '../test/support/recursive_tts_stt.dart';

const _e2eEnabled = bool.fromEnvironment('KOKORODART_E2E');
const _modelAsset = String.fromEnvironment(
  'KOKORODART_MODEL_ASSET',
  defaultValue: 'test_assets/kokoro/kokoro-v1.0.onnx',
);
const _voicesAsset = String.fromEnvironment(
  'KOKORODART_VOICES_ASSET',
  defaultValue: 'test_assets/kokoro/voices.json',
);
const _sttCommand = String.fromEnvironment('KOKORODART_STT_COMMAND');
const _enVoice = String.fromEnvironment(
  'KOKORODART_EN_VOICE',
  defaultValue: 'af_heart',
);
const _esVoice = String.fromEnvironment(
  'KOKORODART_ES_VOICE',
  defaultValue: 'ef_dora',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final enabled =
      _e2eEnabled || Platform.environment['KOKORODART_E2E'] == 'true';
  final commandText =
      Platform.environment['KOKORODART_STT_COMMAND'] ?? _sttCommand;
  final skipReason = enabled
      ? null
      : 'Set KOKORODART_E2E=true to run real local TTS/STT e2e.';

  test(
    'English and Spanish survive TTS STT TTS STT',
    () async {
      if (commandText.isEmpty) {
        fail(
          'Set KOKORODART_STT_COMMAND to a JSON string array, e.g. '
          '["python3","-m","whisper","{wav}","--language","{lang}","--model","tiny","--output_format","txt","--output_dir","{dir}"]',
        );
      }

      final tts = KokoroDart(
        const KokoroDartConfig(
          modelAsset: _modelAsset,
          voicesAsset: _voicesAsset,
        ),
      );
      final stt = LocalSttCommand(parseSttCommand(commandText));
      final cases = [
        const RecursiveSpeechCase(
          name: 'english',
          seedText: 'Kokoro speaks English locally for a private assistant.',
          ttsLanguage: 'en-us',
          sttLanguage: 'en',
          voice: _enVoice,
        ),
        const RecursiveSpeechCase(
          name: 'spanish',
          seedText: 'Kokoro habla espanol localmente para una prueba privada.',
          ttsLanguage: 'es',
          sttLanguage: 'es',
          voice: _esVoice,
        ),
      ];

      for (final speechCase in cases) {
        final steps = await runRecursiveTtsStt(
          speechCase,
          synthesizeWav: (text, currentCase, _) => tts.synthesizeWav(
            text,
            voice: currentCase.voice,
            language: currentCase.ttsLanguage,
          ),
          transcribe: stt.transcribe,
        );

        for (final step in steps) {
          expect(
            step.similarity,
            greaterThanOrEqualTo(0.72),
            reason: '${speechCase.name} pass ${step.pass}: ${step.transcript}',
          );
        }
      }
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
