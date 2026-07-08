import 'dart:typed_data';

Uint8List pcm16Wav(Int16List samples, {int sampleRate = 24000}) {
  final dataBytes = samples.length * 2;
  final out = BytesBuilder(copy: false)
    ..add(_ascii('RIFF'))
    ..add(_u32(36 + dataBytes))
    ..add(_ascii('WAVEfmt '))
    ..add(_u32(16))
    ..add(_u16(1))
    ..add(_u16(1))
    ..add(_u32(sampleRate))
    ..add(_u32(sampleRate * 2))
    ..add(_u16(2))
    ..add(_u16(16))
    ..add(_ascii('data'))
    ..add(_u32(dataBytes));

  final body = ByteData(dataBytes);
  for (var i = 0; i < samples.length; i++) {
    body.setInt16(i * 2, samples[i], Endian.little);
  }
  out.add(body.buffer.asUint8List());
  return out.toBytes();
}

Int16List floatToPcm16(List<num> samples) {
  final out = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    out[i] = (samples[i].toDouble().clamp(-1.0, 1.0) * 32767).round();
  }
  return out;
}

Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);

Uint8List _u16(int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _u32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}
