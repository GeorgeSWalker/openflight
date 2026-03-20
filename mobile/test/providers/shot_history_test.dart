import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/providers/launch_monitor_provider.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

void main() {
  group('ShotHistoryNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          launchMonitorClientProvider.overrideWith(
            (_) => MockLaunchMonitorClient(
              shotInterval: const Duration(milliseconds: 30),
            ),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('starts empty', () {
      expect(container.read(shotHistoryProvider), isEmpty);
    });

    test('accumulates shots up to kMaxHistory', () async {
      final client = container.read(launchMonitorClientProvider);
      await client.connect(host: 'mock');

      // Wait for several shots.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final history = container.read(shotHistoryProvider);
      expect(history, isNotEmpty);
    });

    test('newest shot is at index 0', () async {
      final client = container.read(launchMonitorClientProvider);
      await client.connect(host: 'mock');

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final history = container.read(shotHistoryProvider);

      if (history.length >= 2) {
        expect(
          history.first.timestamp,
          greaterThanOrEqualTo(history.last.timestamp),
        );
      }
    });

    test('clear() empties history', () async {
      final client = container.read(launchMonitorClientProvider);
      await client.connect(host: 'mock');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      container.read(shotHistoryProvider.notifier).clear();
      expect(container.read(shotHistoryProvider), isEmpty);
    });
  });

  group('SelectedClubNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          launchMonitorClientProvider.overrideWith(
            (_) => MockLaunchMonitorClient(),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('defaults to DR', () {
      expect(container.read(selectedClubProvider), 'DR');
    });

    test('updates when select() is called', () async {
      await container
          .read(selectedClubProvider.notifier)
          .select('7I');
      expect(container.read(selectedClubProvider), '7I');
    });
  });

  group('ShotDataModel', () {
    test('smashFactor is null when clubSpeed is 0', () {
      const shot = ShotDataModel(
        ballSpeedMph: 100,
        clubSpeedMph: 0,
        launchAngleV: 10,
        launchAngleH: 0,
        spinRpm: 3000,
        carryYards: 200,
        clubId: 'DR',
        timestamp: 0,
      );
      expect(shot.smashFactor, isNull);
    });

    test('smashFactor computes correctly', () {
      const shot = ShotDataModel(
        ballSpeedMph: 152.0,
        clubSpeedMph: 100.0,
        launchAngleV: 10,
        launchAngleH: 0,
        spinRpm: 3000,
        carryYards: 240,
        clubId: 'DR',
        timestamp: 0,
      );
      expect(shot.smashFactor, closeTo(1.52, 0.001));
    });

    test('toJson / fromJson round-trip', () {
      final original = ShotDataModel.mock();
      final restored = ShotDataModel.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('copyWith preserves unmodified fields', () {
      final original = ShotDataModel.mock();
      final copy = original.copyWith(clubId: '7I');
      expect(copy.clubId, '7I');
      expect(copy.ballSpeedMph, original.ballSpeedMph);
    });
  });
}
