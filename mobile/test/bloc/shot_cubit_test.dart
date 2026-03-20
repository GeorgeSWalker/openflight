import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

void main() {
  group('ShotCubit', () {
    late MockLaunchMonitorClient client;

    setUp(() {
      client = MockLaunchMonitorClient(
        shotInterval: const Duration(milliseconds: 40),
      );
    });

    tearDown(() => client.dispose());

    test('initial state has no shot and empty history', () {
      final cubit = ShotCubit(client);
      expect(cubit.state.hasShot, isFalse);
      expect(cubit.state.history, isEmpty);
      cubit.close();
    });

    blocTest<ShotCubit, ShotState>(
      'emits states with shots after client connects',
      build: () => ShotCubit(client),
      act: (_) async {
        await client.connect(host: 'mock');
        // Wait for at least two shot intervals.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      verify: (cubit) {
        expect(cubit.state.hasShot, isTrue);
        expect(cubit.state.history, isNotEmpty);
        expect(cubit.state.latestShot, isA<ShotDataModel>());
      },
    );

    blocTest<ShotCubit, ShotState>(
      'newest shot is always at index 0 of history',
      build: () => ShotCubit(client),
      act: (_) async {
        await client.connect(host: 'mock');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      verify: (cubit) {
        final history = cubit.state.history;
        if (history.length >= 2) {
          expect(
            history.first.timestamp,
            greaterThanOrEqualTo(history.last.timestamp),
          );
        }
      },
    );

    blocTest<ShotCubit, ShotState>(
      'clearHistory() empties history but keeps latestShot',
      build: () => ShotCubit(client),
      act: (cubit) async {
        await client.connect(host: 'mock');
        await Future<void>.delayed(const Duration(milliseconds: 200));
        cubit.clearHistory();
      },
      verify: (cubit) {
        expect(cubit.state.history, isEmpty);
        expect(cubit.state.latestShot, isNotNull);
      },
    );

    test('history does not exceed kMaxHistory', () async {
      final fastClient = MockLaunchMonitorClient(
        shotInterval: const Duration(milliseconds: 10),
      );
      final cubit = ShotCubit(fastClient);
      await fastClient.connect(host: 'mock');
      await Future<void>.delayed(
        const Duration(milliseconds: ShotCubit.kMaxHistory * 12 + 50),
      );
      expect(cubit.state.history.length, lessThanOrEqualTo(ShotCubit.kMaxHistory));
      await cubit.close();
      await fastClient.dispose();
    });
  });

  group('ShotState', () {
    test('hasShot is false when latestShot is null', () {
      expect(const ShotState().hasShot, isFalse);
    });

    test('hasShot is true when latestShot is set', () {
      final state = ShotState(latestShot: ShotDataModel.mock());
      expect(state.hasShot, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      final original = ShotState(
        latestShot: ShotDataModel.mock(),
        history: [ShotDataModel.mock()],
      );
      final copy = original.copyWith(latestShot: ShotDataModel.mock(clubId: '7I'));
      expect(copy.history.length, 1);
      expect(copy.latestShot?.clubId, '7I');
    });

    test('Equatable equality works', () {
      final s1 = ShotState(latestShot: ShotDataModel.mock(timestamp: 1));
      final s2 = ShotState(latestShot: ShotDataModel.mock(timestamp: 1));
      expect(s1, equals(s2));
    });
  });
}
