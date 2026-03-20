// This file is hand-scaffolded from proto/openflight.proto.
// Re-generate with:
//   dart pub global activate protoc_plugin
//   protoc --dart_out=grpc:lib/proto -Iproto proto/openflight.proto
//
// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unused_import

library;

import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Empty extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'Empty',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'openflight'),
    createEmptyInstance: create,
  )..hasRequiredFields = false;

  Empty._() : super();
  factory Empty() => create();
  factory Empty.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Empty.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static Empty? _defaultInstance;

  static Empty create() => Empty._();
  @$core.Deprecated('Using this can add significant overhead to your binary.')
  static Empty getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Empty clone(Empty v) => v.deepCopy();
  @$core.override
  Empty deepCopy() => clone(this);
  @$core.override
  Empty createEmptyInstance() => create();
  @$core.override
  $pb.PbList<Empty> createRepeated() => $pb.PbList<Empty>();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault2() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);
}

class ShotData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'ShotData',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'openflight'),
    createEmptyInstance: create,
  )
    ..a<$core.double>(1, _omitFieldNames ? '' : 'ballSpeedMph',
        $pb.PbFieldType.OF)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'clubSpeedMph',
        $pb.PbFieldType.OF)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'launchAngleV',
        $pb.PbFieldType.OF)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'launchAngleH',
        $pb.PbFieldType.OF)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'spinRpm', $pb.PbFieldType.O3)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'carryYards',
        $pb.PbFieldType.OF)
    ..aOS(7, _omitFieldNames ? '' : 'clubId')
    ..aInt64(8, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  ShotData._() : super();
  factory ShotData({
    $core.double? ballSpeedMph,
    $core.double? clubSpeedMph,
    $core.double? launchAngleV,
    $core.double? launchAngleH,
    $core.int? spinRpm,
    $core.double? carryYards,
    $core.String? clubId,
    $core.int? timestamp,
  }) {
    final result = create();
    if (ballSpeedMph != null) result.ballSpeedMph = ballSpeedMph;
    if (clubSpeedMph != null) result.clubSpeedMph = clubSpeedMph;
    if (launchAngleV != null) result.launchAngleV = launchAngleV;
    if (launchAngleH != null) result.launchAngleH = launchAngleH;
    if (spinRpm != null) result.spinRpm = spinRpm;
    if (carryYards != null) result.carryYards = carryYards;
    if (clubId != null) result.clubId = clubId;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  factory ShotData.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ShotData.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static ShotData? _defaultInstance;

  @$core.Deprecated('Using this can add significant overhead to your binary.')
  static ShotData getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ShotData>(create);

  static ShotData create() => ShotData._();
  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShotData clone(ShotData v) => v.deepCopy();
  @$core.override
  ShotData deepCopy() => clone(this);
  @$core.override
  ShotData createEmptyInstance() => create();
  @$core.override
  $pb.PbList<ShotData> createRepeated() => $pb.PbList<ShotData>();
  @$core.pragma('dart2js:noInline')
  static ShotData getDefault2() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ShotData>(create);

  @$core.pragma('dart2js:noInline')
  static ShotData _defaultFactory() => ShotData._();

  $core.double get ballSpeedMph => $_getN(0);
  set ballSpeedMph($core.double v) {
    $_setFloat(0, v);
  }

  $core.bool hasBallSpeedMph() => $_has(0);
  void clearBallSpeedMph() => $_clearField(1);

  $core.double get clubSpeedMph => $_getN(1);
  set clubSpeedMph($core.double v) {
    $_setFloat(1, v);
  }

  $core.bool hasClubSpeedMph() => $_has(1);
  void clearClubSpeedMph() => $_clearField(2);

  $core.double get launchAngleV => $_getN(2);
  set launchAngleV($core.double v) {
    $_setFloat(2, v);
  }

  $core.bool hasLaunchAngleV() => $_has(2);
  void clearLaunchAngleV() => $_clearField(3);

  $core.double get launchAngleH => $_getN(3);
  set launchAngleH($core.double v) {
    $_setFloat(3, v);
  }

  $core.bool hasLaunchAngleH() => $_has(3);
  void clearLaunchAngleH() => $_clearField(4);

  $core.int get spinRpm => $_getIZ(4);
  set spinRpm($core.int v) {
    $_setSignedInt32(4, v);
  }

  $core.bool hasSpinRpm() => $_has(4);
  void clearSpinRpm() => $_clearField(5);

  $core.double get carryYards => $_getN(5);
  set carryYards($core.double v) {
    $_setFloat(5, v);
  }

  $core.bool hasCarryYards() => $_has(5);
  void clearCarryYards() => $_clearField(6);

  $core.String get clubId => $_getSZ(6);
  set clubId($core.String v) {
    $_setString(6, v);
  }

  $core.bool hasClubId() => $_has(6);
  void clearClubId() => $_clearField(7);

  $core.int get timestamp => $_getIZ(7);
  set timestamp($core.int v) {
    $_setInt64(7, v);
  }

  $core.bool hasTimestamp() => $_has(7);
  void clearTimestamp() => $_clearField(8);
}

class UserConfig extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'UserConfig',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'openflight'),
    createEmptyInstance: create,
  )
    ..aOS(1, _omitFieldNames ? '' : 'currentClub')
    ..a<$core.double>(2, _omitFieldNames ? '' : 'targetDistanceYards',
        $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  UserConfig._() : super();
  factory UserConfig({
    $core.String? currentClub,
    $core.double? targetDistanceYards,
  }) {
    final result = create();
    if (currentClub != null) result.currentClub = currentClub;
    if (targetDistanceYards != null) {
      result.targetDistanceYards = targetDistanceYards;
    }
    return result;
  }

  factory UserConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UserConfig.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static UserConfig? _defaultInstance;
  static UserConfig create() => UserConfig._();
  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserConfig clone(UserConfig v) => v.deepCopy();
  @$core.override
  UserConfig deepCopy() => clone(this);
  @$core.override
  UserConfig createEmptyInstance() => create();
  @$core.override
  $pb.PbList<UserConfig> createRepeated() => $pb.PbList<UserConfig>();

  $core.String get currentClub => $_getSZ(0);
  set currentClub($core.String v) {
    $_setString(0, v);
  }

  $core.bool hasCurrentClub() => $_has(0);
  void clearCurrentClub() => $_clearField(1);

  $core.double get targetDistanceYards => $_getN(1);
  set targetDistanceYards($core.double v) {
    $_setFloat(1, v);
  }

  $core.bool hasTargetDistanceYards() => $_has(1);
  void clearTargetDistanceYards() => $_clearField(2);
}

class ConfigResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'ConfigResponse',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'openflight'),
    createEmptyInstance: create,
  )
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  ConfigResponse._() : super();
  factory ConfigResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  factory ConfigResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConfigResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static ConfigResponse? _defaultInstance;
  static ConfigResponse create() => ConfigResponse._();
  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfigResponse clone(ConfigResponse v) => v.deepCopy();
  @$core.override
  ConfigResponse deepCopy() => clone(this);
  @$core.override
  ConfigResponse createEmptyInstance() => create();
  @$core.override
  $pb.PbList<ConfigResponse> createRepeated() => $pb.PbList<ConfigResponse>();

  $core.bool get success => $_getBF(0);
  set success($core.bool v) {
    $_setBool(0, v);
  }

  $core.bool hasSuccess() => $_has(0);
  void clearSuccess() => $_clearField(1);
}

class PingResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'PingResponse',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'openflight'),
    createEmptyInstance: create,
  )
    ..aInt64(1, _omitFieldNames ? '' : 'serverTime')
    ..hasRequiredFields = false;

  PingResponse._() : super();
  factory PingResponse({$core.int? serverTime}) {
    final result = create();
    if (serverTime != null) result.serverTime = serverTime;
    return result;
  }

  factory PingResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PingResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static PingResponse? _defaultInstance;
  static PingResponse create() => PingResponse._();
  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PingResponse clone(PingResponse v) => v.deepCopy();
  @$core.override
  PingResponse deepCopy() => clone(this);
  @$core.override
  PingResponse createEmptyInstance() => create();
  @$core.override
  $pb.PbList<PingResponse> createRepeated() => $pb.PbList<PingResponse>();

  $core.int get serverTime => $_getIZ(0);
  set serverTime($core.int v) {
    $_setInt64(0, v);
  }

  $core.bool hasServerTime() => $_has(0);
  void clearServerTime() => $_clearField(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
