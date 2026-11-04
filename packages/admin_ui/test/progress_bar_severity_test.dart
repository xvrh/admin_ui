// ProgressBar.severity: each status fills in a shade of its own colour.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 600, child: child)),
  ),
);

void main() {
  group('ProgressBar.severity (was tone)', () {
    Color fill(WidgetTester tester) {
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      return (bar.valueColor! as AlwaysStoppedAnimation<Color?>).value!;
    }

    testWidgets('warning and info take a shade of their status colours', (
      tester,
    ) async {
      final palette = defaultTokens.palette;
      final track = [palette.border, palette.surface, palette.background];
      await tester.pumpWidget(
        _host(const ProgressBar(value: 0.5, severity: Severity.warning)),
      );
      expect(
        fill(tester),
        palette.readableOn(palette.warning, surfaces: track, minContrast: 3),
      );
      await tester.pumpWidget(
        _host(const ProgressBar(value: 0.5, severity: Severity.info)),
      );
      expect(
        fill(tester),
        palette.readableOn(palette.info, surfaces: track, minContrast: 3),
      );
    });
  });
}
