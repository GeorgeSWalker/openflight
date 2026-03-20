import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openflight_mobile/bloc/club/club_cubit.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

void main() {
  group('ClubCubit', () {
    late MockLaunchMonitorClient client;

    setUp(() => client = MockLaunchMonitorClient());
    tearDown(() => client.dispose());

    test('defaults to DR', () {
      final cubit = ClubCubit(client);
      expect(cubit.state, 'DR');
      cubit.close();
    });

    blocTest<ClubCubit, String>(
      'emits new club id when select() is called',
      build: () => ClubCubit(client),
      act: (cubit) => cubit.select('7I'),
      expect: () => ['7I'],
    );

    blocTest<ClubCubit, String>(
      'multiple selects emit each club in order',
      build: () => ClubCubit(client),
      act: (cubit) async {
        await cubit.select('5W');
        await cubit.select('PW');
      },
      expect: () => ['5W', 'PW'],
    );
  });
}
