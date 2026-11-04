import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders title, message and the severity icon', (tester) async {
    await tester.pumpWidget(
      _host(
        const Alert(
          'Something needs attention.',
          title: 'Heads up',
          severity: Severity.warning,
        ),
      ),
    );

    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('Something needs attention.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('the dismiss button fires onDismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _host(Alert('Bye', onDismiss: () => dismissed = true)),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(dismissed, isTrue);
  });

  testWidgets('warning and danger are live regions unless told otherwise', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final (severity, liveRegion, expected) in const [
      (Severity.info, null, false),
      (Severity.success, null, false),
      (Severity.warning, null, true),
      (Severity.danger, null, true),
      (Severity.danger, false, false),
      (Severity.info, true, true),
    ]) {
      await tester.pumpWidget(
        _host(Alert('Message', severity: severity, liveRegion: liveRegion)),
      );
      expect(
        tester.getSemantics(find.byType(Alert)),
        isSemantics(isLiveRegion: expected),
        reason: '$severity, liveRegion: $liveRegion',
      );
    }
    handle.dispose();
  });

  testWidgets('the dismiss is a labelled button that keeps the height', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const Alert('Saved.')));
    final plain = tester.getSize(find.byType(Alert)).height;

    await tester.pumpWidget(_host(Alert('Saved.', onDismiss: () {})));
    expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
    final close = tester.getSize(find.byType(IconAction));
    expect(close.width, greaterThanOrEqualTo(24));
    expect(close.height, greaterThanOrEqualTo(24));
    expect(tester.getSize(find.byType(Alert)).height, plain);
    handle.dispose();
  });

  testWidgets('an action centres on the first line, as the close does', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 480,
          child: Alert(
            'Out of date.',
            action: Button.ghost(
              'Review',
              size: ControlSize.small,
              onPressed: () {},
            ),
            onDismiss: () {},
          ),
        ),
      ),
    );
    final line = tester.getCenter(find.text('Out of date.')).dy;
    expect(tester.getCenter(find.byType(Button)).dy, closeTo(line, 0.5));
    expect(tester.getCenter(find.byType(IconAction)).dy, closeTo(line, 0.5));
    expect(tester.getCenter(find.byType(Icon).first).dy, closeTo(line, 0.5));
  });

  testWidgets('a one-line alert keeps 12px above and below its line, with '
      'or without an action and a close', (tester) async {
    for (final (action, dismiss) in [
      (false, false),
      (true, false),
      (false, true),
      (true, true),
    ]) {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 480,
            child: Alert(
              'Out of date.',
              action: action
                  ? Button.ghost(
                      'Review',
                      size: ControlSize.small,
                      onPressed: () {},
                    )
                  : null,
              onDismiss: dismiss ? () {} : null,
            ),
          ),
        ),
      );
      final reason = 'action $action, close $dismiss';
      final alert = tester.getRect(find.byType(Alert));
      final text = tester.getRect(find.text('Out of date.'));
      expect(text.height, 20, reason: reason);
      // Inside the 1px border.
      expect(text.top - (alert.top + 1), 12, reason: reason);
      expect(alert.bottom - 1 - text.bottom, 12, reason: reason);
      expect(alert.height, 1 + 12 + 20 + 12 + 1, reason: reason);
    }
  });

  for (final (name, palette) in const [
    ('Iris Light', irisPalette),
    ('Ant Light', antPalette),
    ('Carbon Light', carbonPalette),
    ('Fluent Dark', fluentDarkPalette),
  ]) {
    testWidgets('$name: icon and border come from the severity style', (
      tester,
    ) async {
      for (final severity in Severity.values) {
        late SeverityStyle style;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(AdminTokens.from(palette: palette)),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  style = severityStyleOf(context, severity);
                  return Alert('Message', severity: severity);
                },
              ),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(style.icon));
        expect(icon.color, style.foreground);
        // A glyph, so the non-text minimum on its own tinted surface.
        expect(
          contrastRatio(icon.color!, style.surface),
          greaterThanOrEqualTo(3),
          reason: '$severity icon',
        );
        final box = tester.widget<Container>(
          find
              .ancestor(
                of: find.byIcon(style.icon),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = box.decoration! as BoxDecoration;
        expect(decoration.color, style.surface);
        expect((decoration.border! as Border).top.color, style.border);
      }
    });
  }
}
