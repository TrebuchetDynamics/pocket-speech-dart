import 'kitten_tts.dart';
import 'kokoro_tts.dart';

abstract final class PocketSpeech {
  static KokoroTts kokoro(KokoroTtsConfig config) => KokoroTts(config);

  static KittenTts kitten(KittenTtsConfig config) => KittenTts(config);
}
