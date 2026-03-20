import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/app_mode/app_mode_cubit.dart';
import 'package:openflight_mobile/bloc/club/club_cubit.dart';
import 'package:openflight_mobile/bloc/clubs/user_clubs_cubit.dart';
import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/bloc/session/session_cubit.dart';
import 'package:openflight_mobile/bloc/settings/settings_cubit.dart';
import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/bloc/target_distance/target_distance_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/utils/app_bloc_observer.dart';
import 'package:openflight_mobile/core/utils/app_logger.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';
import 'package:openflight_mobile/services/session_service.dart';
import 'package:openflight_mobile/ui/screens/home_screen.dart';

class OpenFlightApp extends StatelessWidget {
  const OpenFlightApp({super.key, LaunchMonitorClient? client})
      : _client = client;

  final LaunchMonitorClient? _client;

  @override
  Widget build(BuildContext context) {
    Bloc.observer = const AppBlocObserver();

    final client = _client ?? MockLaunchMonitorClient();
    final sessionService = SessionService();

    return RepositoryProvider<LaunchMonitorClient>.value(
      value: client,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ConnectionCubit(client)),
          BlocProvider(create: (_) => ShotCubit(client)),
          BlocProvider(create: (_) => ClubCubit(client)),
          BlocProvider(create: (_) => TargetDistanceCubit()),
          BlocProvider(create: (_) => AppModeCubit()),
          BlocProvider(
            create: (_) => SettingsCubit()..load(),
          ),
          BlocProvider(
            create: (_) => UserClubsCubit()..load(),
          ),
          BlocProvider(
            create: (_) => SessionCubit(sessionService),
          ),
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

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0F13),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    context.read<ConnectionCubit>().connect(host: 'mock');
    AppLogger.info('App started', tag: 'app');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-save the active session when the app moves to background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final sessionCubit = context.read<SessionCubit>();
      if (sessionCubit.isRecording) {
        AppLogger.info('App paused — ending active session', tag: 'app');
        sessionCubit.endSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OpenFlight',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: BlocListener<ShotCubit, ShotState>(
          // Forward every new shot to the active session.
          listenWhen: (prev, curr) => curr.latestShot != prev.latestShot,
          listener: (ctx, state) {
            if (state.latestShot != null) {
              ctx.read<SessionCubit>().addShot(state.latestShot!);
            }
          },
          child: const HomeScreen(),
        ),
      );
}
