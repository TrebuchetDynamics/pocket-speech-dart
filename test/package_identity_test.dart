import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package metadata and Dart imports use Pocket Speech', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('name: pocket_speech'));
    expect(
      pubspec,
      contains(
        'repository: https://github.com/TrebuchetDynamics/pocket-speech-dart',
      ),
    );
    expect(File('lib/pocket_speech.dart').existsSync(), isTrue);
    expect(File('lib/kokorodart.dart').existsSync(), isFalse);

    final dartFiles = [
      ...Directory('lib').listSync(recursive: true),
      ...Directory('test').listSync(recursive: true),
      ...Directory('integration_test').listSync(recursive: true),
      ...Directory('example').listSync(recursive: true),
    ].whereType<File>().where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(
          contains(
            'package:'
            'kokorodart/',
          ),
        ),
        reason: file.path,
      );
      expect(
        source,
        isNot(
          contains(
            'Kokoro'
            'Dart',
          ),
        ),
        reason: file.path,
      );
      expect(
        source,
        isNot(
          contains(
            'Kitten'
            'Dart',
          ),
        ),
        reason: file.path,
      );
    }

    final runtimeFiles = [
      File('integration_test/recursive_tts_stt_e2e_test.dart'),
      File('test/support/recursive_tts_stt.dart'),
      File('tool/setup_e2e_assets.py'),
      File('linux/CMakeLists.txt'),
      File('linux/runner/my_application.cc'),
    ];
    for (final file in runtimeFiles) {
      expect(
        file.readAsStringSync(),
        isNot(
          contains(
            'KOKORO'
            'DART',
          ),
        ),
        reason: file.path,
      );
    }
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('set(BINARY_NAME "pocket_speech")'),
    );
  });
}
