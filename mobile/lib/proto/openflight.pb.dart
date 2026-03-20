// Hand-crafted protobuf wire-format message classes for openflight.proto.
//
// Uses binary protobuf wire format (wire-compatible with standard protoc output)
// implemented in pure Dart — no dependency on the 'protobuf' package.
//
// Re-generate from proto/openflight.proto with:
//   dart pub global activate protoc_plugin
//   protoc --dart_out=grpc:lib/proto -Iproto proto/openflight.proto
//   (then remove this file and use the generated one instead)
//
// ignore_for_file: constant_identifier_names

import 'dart:convert' show utf8;
import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Wire-format encode helpers
// ---------------------------------------------------------------------------

List<int> _varint(int value) {
  final out = <int>[];
  var v = value;
  do {
    var byte = v & 0x7F;
    v >>>= 7;
    if (v != 0) byte |= 0x80;
    out.add(byte);
  } while (v != 0);
  return out;
}

List<int> _fieldFloat(int fieldNum, double v) {
  final bd = ByteData(4)..setFloat32(0, v, Endian.little);
  return [..._varint((fieldNum << 3) | 5), ...bd.buffer.asUint8List()];
}

List<int> _fieldVarint(int fieldNum, int v) =>
    [..._varint((fieldNum << 3) | 0), ..._varint(v)];

List<int> _fieldBool(int fieldNum, bool v) => _fieldVarint(fieldNum, v ? 1 : 0);

List<int> _fieldString(int fieldNum, String v) {
  final bytes = utf8.encode(v);
  return [
    ..._varint((fieldNum << 3) | 2),
    ..._varint(bytes.length),
    ...bytes,
  ];
}

// ---------------------------------------------------------------------------
// Wire-format decode helpers
// ---------------------------------------------------------------------------

(int, int) _readVarint(Uint8List buf, int pos) {
  int result = 0, shift = 0;
  while (true) {
    final b = buf[pos++];
    result |= (b & 0x7F) << shift;
    if ((b & 0x80) == 0) return (result, pos);
    shift += 7;
  }
}

double _readFloat(Uint8List buf, int pos) =>
    ByteData.sublistView(buf, pos, pos + 4).getFloat32(0, Endian.little);

String _readString(Uint8List buf, int pos, int length) =>
    utf8.decode(buf.sublist(pos, pos + length));

Uint8List _toUint8(List<int> data) =>
    data is Uint8List ? data : Uint8List.fromList(data);

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

class Empty {
  Empty();

  Uint8List writeToBuffer() => Uint8List(0);

  static Empty fromBuffer(List<int> data) => Empty();
}

class ShotData {
  double ballSpeedMph;
  double clubSpeedMph;
  double launchAngleV;
  double launchAngleH;
  int spinRpm;
  double carryYards;
  String clubId;
  int timestamp;

  ShotData({
    this.ballSpeedMph = 0.0,
    this.clubSpeedMph = 0.0,
    this.launchAngleV = 0.0,
    this.launchAngleH = 0.0,
    this.spinRpm = 0,
    this.carryYards = 0.0,
    this.clubId = '',
    this.timestamp = 0,
  });

  Uint8List writeToBuffer() {
    final out = <int>[];
    if (ballSpeedMph != 0.0) out.addAll(_fieldFloat(1, ballSpeedMph));
    if (clubSpeedMph != 0.0) out.addAll(_fieldFloat(2, clubSpeedMph));
    if (launchAngleV != 0.0) out.addAll(_fieldFloat(3, launchAngleV));
    if (launchAngleH != 0.0) out.addAll(_fieldFloat(4, launchAngleH));
    if (spinRpm != 0) out.addAll(_fieldVarint(5, spinRpm));
    if (carryYards != 0.0) out.addAll(_fieldFloat(6, carryYards));
    if (clubId.isNotEmpty) out.addAll(_fieldString(7, clubId));
    if (timestamp != 0) out.addAll(_fieldVarint(8, timestamp));
    return Uint8List.fromList(out);
  }

  static ShotData fromBuffer(List<int> data) {
    final msg = ShotData();
    final buf = _toUint8(data);
    var pos = 0;
    while (pos < buf.length) {
      final (tag, p1) = _readVarint(buf, pos);
      pos = p1;
      final fn = tag >> 3;
      final wt = tag & 0x7;
      if (wt == 5) {
        // 32-bit float
        final v = _readFloat(buf, pos);
        pos += 4;
        if (fn == 1) msg.ballSpeedMph = v;
        if (fn == 2) msg.clubSpeedMph = v;
        if (fn == 3) msg.launchAngleV = v;
        if (fn == 4) msg.launchAngleH = v;
        if (fn == 6) msg.carryYards = v;
      } else if (wt == 0) {
        // varint
        final (v, p2) = _readVarint(buf, pos);
        pos = p2;
        if (fn == 5) msg.spinRpm = v;
        if (fn == 8) msg.timestamp = v;
      } else if (wt == 2) {
        // length-delimited
        final (length, p2) = _readVarint(buf, pos);
        pos = p2;
        if (fn == 7) msg.clubId = _readString(buf, pos, length);
        pos += length;
      } else {
        break; // unknown wire type — stop parsing
      }
    }
    return msg;
  }
}

class UserConfig {
  String currentClub;
  double targetDistanceYards;

  UserConfig({
    this.currentClub = '',
    this.targetDistanceYards = 0.0,
  });

  Uint8List writeToBuffer() {
    final out = <int>[];
    if (currentClub.isNotEmpty) out.addAll(_fieldString(1, currentClub));
    if (targetDistanceYards != 0.0) {
      out.addAll(_fieldFloat(2, targetDistanceYards));
    }
    return Uint8List.fromList(out);
  }

  static UserConfig fromBuffer(List<int> data) {
    final msg = UserConfig();
    final buf = _toUint8(data);
    var pos = 0;
    while (pos < buf.length) {
      final (tag, p1) = _readVarint(buf, pos);
      pos = p1;
      final fn = tag >> 3;
      final wt = tag & 0x7;
      if (wt == 2) {
        final (length, p2) = _readVarint(buf, pos);
        pos = p2;
        if (fn == 1) msg.currentClub = _readString(buf, pos, length);
        pos += length;
      } else if (wt == 5) {
        final v = _readFloat(buf, pos);
        pos += 4;
        if (fn == 2) msg.targetDistanceYards = v;
      } else if (wt == 0) {
        final (_, p2) = _readVarint(buf, pos);
        pos = p2;
      } else {
        break;
      }
    }
    return msg;
  }
}

class ConfigResponse {
  bool success;

  ConfigResponse({this.success = false});

  Uint8List writeToBuffer() {
    if (!success) return Uint8List(0);
    return Uint8List.fromList(_fieldBool(1, true));
  }

  static ConfigResponse fromBuffer(List<int> data) {
    final msg = ConfigResponse();
    final buf = _toUint8(data);
    var pos = 0;
    while (pos < buf.length) {
      final (tag, p1) = _readVarint(buf, pos);
      pos = p1;
      final fn = tag >> 3;
      final wt = tag & 0x7;
      if (wt == 0) {
        final (v, p2) = _readVarint(buf, pos);
        pos = p2;
        if (fn == 1) msg.success = v != 0;
      } else {
        break;
      }
    }
    return msg;
  }
}

class PingResponse {
  int serverTime;

  PingResponse({this.serverTime = 0});

  Uint8List writeToBuffer() {
    if (serverTime == 0) return Uint8List(0);
    return Uint8List.fromList(_fieldVarint(1, serverTime));
  }

  static PingResponse fromBuffer(List<int> data) {
    final msg = PingResponse();
    final buf = _toUint8(data);
    var pos = 0;
    while (pos < buf.length) {
      final (tag, p1) = _readVarint(buf, pos);
      pos = p1;
      final fn = tag >> 3;
      final wt = tag & 0x7;
      if (wt == 0) {
        final (v, p2) = _readVarint(buf, pos);
        pos = p2;
        if (fn == 1) msg.serverTime = v;
      } else {
        break;
      }
    }
    return msg;
  }
}
