class KokoroDartSpeed {
  const KokoroDartSpeed({
    this.min = 0.5,
    this.max = 2.0,
    this.defaultValue = 1.0,
  });

  final double min;
  final double max;
  final double defaultValue;

  void check(double value) {
    if (value < min || value > max) {
      throw RangeError.value(value, 'speed', 'must be between $min and $max');
    }
  }
}

class KokoroDartLanguage {
  const KokoroDartLanguage({
    required this.code,
    required this.kokoroCode,
    required this.name,
    required this.defaultVoice,
  });

  final String code;
  final String kokoroCode;
  final String name;
  final String defaultVoice;
}

class KokoroDartVoice {
  const KokoroDartVoice({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.gender,
  });

  final String id;
  final String name;
  final String languageCode;
  final String gender;
}

class KokoroDartSynthesisOptions {
  const KokoroDartSynthesisOptions({
    this.voice = 'af_heart',
    this.language = 'en-us',
    this.speed = 1.0,
    this.trim = true,
  });

  factory KokoroDartSynthesisOptions.forLanguage(String language) {
    final lang = KokoroDartCatalog.language(language);
    return KokoroDartSynthesisOptions(
      language: lang.code,
      voice: lang.defaultVoice,
    );
  }

  final String voice;
  final String language;
  final double speed;
  final bool trim;

  KokoroDartSynthesisOptions copyWith({
    String? voice,
    String? language,
    double? speed,
    bool? trim,
  }) => KokoroDartSynthesisOptions(
    voice: voice ?? this.voice,
    language: language ?? this.language,
    speed: speed ?? this.speed,
    trim: trim ?? this.trim,
  );
}

class KokoroDartCatalog {
  KokoroDartCatalog._();

  static const speed = KokoroDartSpeed();

  static const languages = [
    KokoroDartLanguage(
      code: 'en-us',
      kokoroCode: 'a',
      name: 'American English',
      defaultVoice: 'af_heart',
    ),
    KokoroDartLanguage(
      code: 'en-gb',
      kokoroCode: 'b',
      name: 'British English',
      defaultVoice: 'bf_alice',
    ),
    KokoroDartLanguage(
      code: 'es',
      kokoroCode: 'e',
      name: 'Spanish',
      defaultVoice: 'ef_dora',
    ),
    KokoroDartLanguage(
      code: 'fr-fr',
      kokoroCode: 'f',
      name: 'French',
      defaultVoice: 'ff_siwis',
    ),
    KokoroDartLanguage(
      code: 'hi',
      kokoroCode: 'h',
      name: 'Hindi',
      defaultVoice: 'hf_alpha',
    ),
    KokoroDartLanguage(
      code: 'it',
      kokoroCode: 'i',
      name: 'Italian',
      defaultVoice: 'if_sara',
    ),
    KokoroDartLanguage(
      code: 'ja',
      kokoroCode: 'j',
      name: 'Japanese',
      defaultVoice: 'jf_alpha',
    ),
    KokoroDartLanguage(
      code: 'pt-br',
      kokoroCode: 'p',
      name: 'Brazilian Portuguese',
      defaultVoice: 'pf_dora',
    ),
    KokoroDartLanguage(
      code: 'zh',
      kokoroCode: 'z',
      name: 'Mandarin Chinese',
      defaultVoice: 'zf_xiaobei',
    ),
  ];

  static List<KokoroDartVoice> get voices =>
      _voiceIds.map(_voice).toList(growable: false);

  static bool supportsLanguage(String code) =>
      languages.any((language) => language.code == code);

  static bool supportsVoice(String id) => _voiceIds.contains(id);

  static KokoroDartLanguage language(String code) => languages.firstWhere(
    (language) => language.code == code,
    orElse: () =>
        throw ArgumentError.value(code, 'code', 'unsupported language'),
  );

  static List<KokoroDartVoice> voicesForLanguage(String code) {
    language(code);
    return voices
        .where((voice) => voice.languageCode == code)
        .toList(growable: false);
  }

  static KokoroDartVoice defaultVoiceForLanguage(String code) =>
      voice(language(code).defaultVoice);

  static KokoroDartVoice voice(String id) {
    if (!_voiceIds.contains(id)) {
      throw ArgumentError.value(id, 'id', 'unsupported voice');
    }
    return _voice(id);
  }

  static KokoroDartVoice _voice(String id) {
    final parts = id.split('_');
    final prefix = parts.first;
    final languageCode = _languageByVoicePrefix[prefix] ?? 'en-us';
    final gender = prefix.endsWith('f') ? 'female' : 'male';
    final name = parts
        .skip(1)
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
    return KokoroDartVoice(
      id: id,
      name: name,
      languageCode: languageCode,
      gender: gender,
    );
  }

  static const _languageByVoicePrefix = {
    'af': 'en-us',
    'am': 'en-us',
    'bf': 'en-gb',
    'bm': 'en-gb',
    'ef': 'es',
    'em': 'es',
    'ff': 'fr-fr',
    'hf': 'hi',
    'hm': 'hi',
    'if': 'it',
    'im': 'it',
    'jf': 'ja',
    'jm': 'ja',
    'pf': 'pt-br',
    'pm': 'pt-br',
    'zf': 'zh',
    'zm': 'zh',
  };

  static const _voiceIds = [
    'af_alloy',
    'af_aoede',
    'af_bella',
    'af_heart',
    'af_jessica',
    'af_kore',
    'af_nicole',
    'af_nova',
    'af_river',
    'af_sarah',
    'af_sky',
    'am_adam',
    'am_echo',
    'am_eric',
    'am_fenrir',
    'am_liam',
    'am_michael',
    'am_onyx',
    'am_puck',
    'am_santa',
    'bf_alice',
    'bf_emma',
    'bf_isabella',
    'bf_lily',
    'bm_daniel',
    'bm_fable',
    'bm_george',
    'bm_lewis',
    'ef_dora',
    'em_alex',
    'em_santa',
    'ff_siwis',
    'hf_alpha',
    'hf_beta',
    'hm_omega',
    'hm_psi',
    'if_sara',
    'im_nicola',
    'jf_alpha',
    'jf_gongitsune',
    'jf_nezumi',
    'jf_tebukuro',
    'jm_kumo',
    'pf_dora',
    'pm_alex',
    'pm_santa',
    'zf_xiaobei',
    'zf_xiaoni',
    'zf_xiaoxiao',
    'zf_xiaoyi',
    'zm_yunjian',
    'zm_yunxi',
    'zm_yunxia',
    'zm_yunyang',
  ];
}
