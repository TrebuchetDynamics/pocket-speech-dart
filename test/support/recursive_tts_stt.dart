import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class RecursiveSpeechCase {
  const RecursiveSpeechCase({
    required this.name,
    required this.seedText,
    required this.ttsLanguage,
    required this.sttLanguage,
    required this.voice,
  });

  final String name;
  final String seedText;
  final String ttsLanguage;
  final String sttLanguage;
  final String voice;
}

class RecursiveSpeechStep {
  const RecursiveSpeechStep({
    required this.pass,
    required this.inputText,
    required this.transcript,
    required this.similarity,
  });

  final int pass;
  final String inputText;
  final String transcript;
  final double similarity;
}

typedef SynthesizeWav =
    Future<Uint8List> Function(
      String text,
      RecursiveSpeechCase speechCase,
      int pass,
    );

typedef TranscribeWav =
    Future<String> Function(
      Uint8List wav,
      RecursiveSpeechCase speechCase,
      int pass,
    );

Future<List<RecursiveSpeechStep>> runRecursiveTtsStt(
  RecursiveSpeechCase speechCase, {
  required SynthesizeWav synthesizeWav,
  required TranscribeWav transcribe,
  int passes = 2,
  double minSimilarity = 0.72,
}) async {
  var text = speechCase.seedText;
  final steps = <RecursiveSpeechStep>[];

  for (var pass = 1; pass <= passes; pass++) {
    final wav = await synthesizeWav(text, speechCase, pass);
    final transcript = (await transcribe(wav, speechCase, pass)).trim();
    if (transcript.isEmpty) {
      throw StateError(
        '${speechCase.name} pass $pass returned an empty transcript',
      );
    }

    final similarity = speechSimilarity(speechCase.seedText, transcript);
    if (similarity < minSimilarity) {
      throw StateError(
        '${speechCase.name} pass $pass similarity ${similarity.toStringAsFixed(2)} < $minSimilarity: "$transcript"',
      );
    }

    steps.add(
      RecursiveSpeechStep(
        pass: pass,
        inputText: text,
        transcript: transcript,
        similarity: similarity,
      ),
    );
    text = transcript;
  }

  return steps;
}

String normalizeSpeechText(String text) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };

  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final mapped = accents[char] ?? char;
    out.write(RegExp(r'[a-z0-9]').hasMatch(mapped) ? mapped : ' ');
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

double speechSimilarity(String expected, String actual) {
  final a = normalizeSpeechText(expected);
  final b = normalizeSpeechText(actual);
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 1;

  final distance = _levenshtein(a, b);
  final charScore = 1 - distance / math.max(a.length, b.length);
  final aTokens = a.split(' ').toSet();
  final bTokens = b.split(' ').toSet();
  final tokenScore = aTokens.intersection(bTokens).length / aTokens.length;
  return math.max(charScore, tokenScore).clamp(0, 1).toDouble();
}

int _levenshtein(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final next = List<int>.filled(b.length + 1, i + 1);
    for (var j = 0; j < b.length; j++) {
      final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      next[j + 1] = math.min(
        math.min(next[j] + 1, prev[j + 1] + 1),
        prev[j] + cost,
      );
    }
    prev = next;
  }
  return prev.last;
}

List<String> parseSttCommand(String jsonText) {
  final decoded = jsonDecode(jsonText);
  if (decoded is! List ||
      decoded.isEmpty ||
      decoded.any((item) => item is! String)) {
    throw const FormatException(
      'STT command must be a non-empty JSON string array',
    );
  }
  return decoded.cast<String>();
}

class LocalSttCommand {
  const LocalSttCommand(
    this.command, {
    this.timeout = const Duration(minutes: 5),
  });

  final List<String> command;
  final Duration timeout;

  Future<String> transcribe(
    Uint8List wav,
    RecursiveSpeechCase speechCase,
    int pass,
  ) async {
    final temp = await Directory.systemTemp.createTemp('pocket-speech-stt-');
    try {
      final wavFile = File('${temp.path}/${speechCase.name}-$pass.wav');
      final outDir = Directory('${temp.path}/out')..createSync();
      await wavFile.writeAsBytes(wav, flush: true);

      final replacements = {
        '{wav}': wavFile.path,
        '{lang}': speechCase.sttLanguage,
        '{dir}': outDir.path,
      };
      String fill(String value) {
        var out = value;
        for (final entry in replacements.entries) {
          out = out.replaceAll(entry.key, entry.value);
        }
        return out;
      }

      final result = await Process.run(
        command.first,
        command.skip(1).map(fill).toList(),
      ).timeout(timeout);

      if (result.exitCode != 0) {
        throw StateError(
          'STT failed (${result.exitCode}): ${result.stderr}\n${result.stdout}',
        );
      }

      final txtFiles =
          outDir
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.txt'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      if (txtFiles.isNotEmpty)
        return (await txtFiles.first.readAsString()).trim();
      return '${result.stdout}'.trim();
    } finally {
      await temp.delete(recursive: true);
    }
  }
}
