import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/core/models/connection_state_model.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

void main() {
  group('ConnectionCubit', () {
    late MockLaunchMonitorClient client;

    setUp(() {
      client = MockLaunchMonitorClient();
    });

    tearDown(() => client.dispose());

    test('initial state is disconnected', () {
      final cubit = ConnectionCubit(client);
      expect(cubit.state.status, ConnectionStatus.disconnected);
      cubit.close();
    });

    blocTest<ConnectionCubit, ConnectionStateModel>(
      'emits connecting then connected after connect()',
      build: () => ConnectionCubit(client),
      act: (cubit) => cubit.connect(host: 'mock'),
      expect: () => [
        isA<ConnectionStateModel>()
            .having((s) => s.status, 'status', ConnectionStatus.connecting),
        isA<ConnectionStateModel>()
            .having((s) => s.status, 'status', ConnectionStatus.connected),
      ],
    );

    blocTest<ConnectionCubit, ConnectionStateModel>(
      'emits disconnected after disconnect()',
      build: () => ConnectionCubit(client),
      act: (cubit) async {
        await cubit.connect(host: 'mock');
        await cubit.disconnect();
      },
      expect: () => [
        isA<ConnectionStateModel>()
            .having((s) => s.status, 'status', ConnectionStatus.connecting),
        isA<ConnectionStateModel>()
            .having((s) => s.status, 'status', ConnectionStatus.connected),
        isA<ConnectionStateModel>()
            .having((s) => s.status, 'status', ConnectionStatus.disconnected),
      ],
    );

    blocTest<ConnectionCubit, ConnectionStateModel>(
      'exposes lastPingMs once connected',
      build: () => ConnectionCubit(client),
      act: (cubit) => cubit.connect(host: 'mock'),
      verify: (cubit) {
        expect(cubit.state.lastPingMs, isNotNull);
      },
    );
  });
}
