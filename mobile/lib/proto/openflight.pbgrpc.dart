// Hand-crafted gRPC client/server stubs for openflight.proto.
// Re-generate with:
//   dart pub global activate protoc_plugin
//   protoc --dart_out=grpc:lib/proto -Iproto proto/openflight.proto
//
// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unused_import

library;

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;

import 'openflight.pb.dart' as $0;

export 'openflight.pb.dart';

class LaunchMonitorClient extends $grpc.Client {
  static final _$streamShots = $grpc.ClientMethod<$0.Empty, $0.ShotData>(
    '/openflight.LaunchMonitor/StreamShots',
    ($0.Empty value) => value.writeToBuffer(),
    ($core.List<$core.int> value) => $0.ShotData.fromBuffer(value),
  );
  static final _$updateConfig =
      $grpc.ClientMethod<$0.UserConfig, $0.ConfigResponse>(
    '/openflight.LaunchMonitor/UpdateConfig',
    ($0.UserConfig value) => value.writeToBuffer(),
    ($core.List<$core.int> value) => $0.ConfigResponse.fromBuffer(value),
  );
  static final _$ping = $grpc.ClientMethod<$0.Empty, $0.PingResponse>(
    '/openflight.LaunchMonitor/Ping',
    ($0.Empty value) => value.writeToBuffer(),
    ($core.List<$core.int> value) => $0.PingResponse.fromBuffer(value),
  );

  LaunchMonitorClient(
    $grpc.ClientChannel channel, {
    $grpc.CallOptions? options,
    $core.Iterable<$grpc.ClientInterceptor>? interceptors,
  }) : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseStream<$0.ShotData> streamShots(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
      _$streamShots,
      $async.Stream.value(request),
      options: options,
    );
  }

  $grpc.ResponseFuture<$0.ConfigResponse> updateConfig(
    $0.UserConfig request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateConfig, request, options: options);
  }

  $grpc.ResponseFuture<$0.PingResponse> ping(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$ping, request, options: options);
  }
}
