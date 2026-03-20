import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/app_mode/app_mode_cubit.dart';
import 'package:openflight_mobile/bloc/club/club_cubit.dart';
import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/bloc/target_distance/target_distance_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';
import 'package:openflight_mobile/ui/screens/home_screen.dart';

class OpenFlightApp extends StatelessWidget {
  const OpenFlightApp({super.key, LaunchMonitorClient? client})
      : _client = client;

  /// Injectable for tests; defaults to [MockLaunchMonitorClient].
  final LaunchMonitorClient? _client;

  @override
  Widget build(BuildContext context) {
    // Single shared client instance — all cubits receive a reference to it.
    final client = _client ?? MockLaunchMonitorClient();

    return RepositoryProvider<LaunchMonitorClient>.value(
      value: client,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ConnectionCubit(client)),
          BlocProvider(create: (_) => ShotCubit(client)),
          BlocProvider(create: (_) => ClubCubit(client)),
          BlocProvider(create: (_) => TargetDistanceCubit()),
          BlocProvider(create: (_) => AppModeCubit()),
        ],
        child: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
      ),
    );
    // Auto-connect so the UI is live immediately.
    context.read<ConnectionCubit>().connect(host: 'mock');
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OpenFlight',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      );
}
