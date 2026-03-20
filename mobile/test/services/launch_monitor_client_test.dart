import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:openflight_mobile/core/models/connection_state_model.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

void main() {
  group('MockLaunchMonitorClient', () {
    late MockLaunchMonitorClient client;

    setUp(() {
      client = MockLaunchMonitorClient(
        shotInterval: const Duration(milliseconds: 50),
      );
    });

    tearDown(() => client.dispose());

    test('starts in disconnected state', () {
      expect(client.currentState.status, ConnectionStatus.disconnected);
    });

    test('transitions to connected after connect()', () async {
      final states = <ConnectionStatus>[];
      final sub = client.connectionState.listen((s) => states.add(s.status));

      await client.connect(host: 'mock');
      await sub.cancel();

      expect(states, containsAllInOrder([
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
      ]));
    });

    test('emits ShotDataModel objects on the shots stream', () async {
      await client.connect(host: 'mock');

      final shot = await client.shots.first
          .timeout(const Duration(milliseconds: 500));

      expect(shot, isA<ShotDataModel>());
      expect(shot.ballSpeedMph, greaterThan(0));
      expect(shot.carryYards, greaterThan(0));
    });

    test('emits multiple different shots over time', () async {
      await client.connect(host: 'mock');

      final shots = await client.shots
          .take(3)
          .toList()
          .timeout(const Duration(seconds: 2));

      expect(shots.length, 3);
      // Timestamps should be distinct.
      final timestamps = shots.map((s) => s.timestamp).toSet();
      expect(timestamps.length, greaterThan(1));
    });

    test('returns to disconnected after disconnect()', () async {
      await client.connect(host: 'mock');
      await client.disconnect();

      expect(client.currentState.status, ConnectionStatus.disconnected);
    });

    test('updateConfig returns true when connected', () async {
      await client.connect(host: 'mock');
      final ok = await client.updateConfig(clubId: '7I');
      expect(ok, isTrue);
    });

    test('updateConfig returns false when disconnected', () async {
      final ok = await client.updateConfig(clubId: '7I');
      expect(ok, isFalse);
    });
  });
}
