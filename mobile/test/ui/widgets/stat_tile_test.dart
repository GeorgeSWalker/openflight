import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/ui/widgets/stat_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('StatTile', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatTile(label: 'Ball Speed', value: '152.4', unit: 'mph'),
      ));

      expect(find.text('BALL SPEED'), findsOneWidget);
      expect(find.text('152.4'), findsOneWidget);
      expect(find.text('mph'), findsOneWidget);
    });

    testWidgets('renders without unit', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatTile(label: 'Smash', value: '1.52'),
      ));

      expect(find.text('1.52'), findsOneWidget);
      expect(find.text('mph'), findsNothing);
    });

    testWidgets('highlighted tile uses accent border', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatTile(label: 'Carry', value: '248', highlighted: true),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });

  group('EmptyStatTile', () {
    testWidgets('shows dash placeholder', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyStatTile(label: 'Spin', unit: 'rpm'),
      ));

      expect(find.text('—'), findsOneWidget);
      expect(find.text('SPIN'), findsOneWidget);
    });
  });
}
