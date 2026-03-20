import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/providers/launch_monitor_provider.dart';
import 'package:openflight_mobile/ui/screens/home_screen.dart';

class OpenFlightApp extends ConsumerStatefulWidget {
  const OpenFlightApp({super.key});

  @override
  ConsumerState<OpenFlightApp> createState() => _OpenFlightAppState();
}

class _OpenFlightAppState extends ConsumerState<OpenFlightApp> {
  @override
  void initState() {
    super.initState();
    // Force landscape on tablets; allow both on phones.
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
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    // Auto-connect using the mock client so the UI is live immediately.
    // Replace with a saved/default host when real hardware is present.
    final client = ref.read(launchMonitorClientProvider);
    await client.connect(host: 'mock', port: 50051);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OpenFlight',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      );
}
