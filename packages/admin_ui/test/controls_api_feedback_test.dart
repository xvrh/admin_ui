import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: ToastScope(
    child: Scaffold(
      body: Center(child: SizedBox(width: 480, child: child)),
    ),
  ),
);

Future<void> _toast(WidgetTester tester, Toast toast) async {
  await tester.pumpWidget(
    _host(
      Builder(
        builder: (context) =>
            Button('Go', onPressed: () => ToastScope.of(context).show(toast)),
      ),
    ),
  );
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
}

void main() {
  group('Alert', () {
    testWidgets('icon replaces the severity glyph', (tester) async {
      await tester.pumpWidget(
        _host(
          const Alert(
            'Scheduled for 9:00',
            severity: Severity.info,
            icon: Icons.schedule,
          ),
        ),
      );
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    });

    testWidgets('showIcon: false drops the glyph and starts the text at the '
        'padding', (tester) async {
      await tester.pumpWidget(
        _host(const Alert('Saved', severity: Severity.success)),
      );
      final withIcon = tester.getTopLeft(find.text('Saved')).dx;
      final left = tester.getTopLeft(find.byType(Alert)).dx;
      final height = tester.getSize(find.byType(Alert)).height;

      await tester.pumpWidget(
        _host(
          const Alert('Saved', severity: Severity.success, showIcon: false),
        ),
      );
      expect(find.byType(Icon), findsNothing);
      // The 1px border, then the 12px padding.
      expect(
        tester.getTopLeft(find.text('Saved')).dx - left,
        1 + AdminSpacing.lg,
      );
      expect(tester.getTopLeft(find.text('Saved')).dx, lessThan(withIcon));
      expect(tester.getSize(find.byType(Alert)).height, height);
    });

    testWidgets('without the glyph, a title and an action still lay out', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Alert(
            'The import stopped at row 42.',
            title: 'Import failed',
            severity: Severity.danger,
            showIcon: false,
            action: Button('Retry', size: ControlSize.small, onPressed: () {}),
            onDismiss: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });
  });

  group('AnnouncementBar', () {
    testWidgets('showIcon: false drops the glyph', (tester) async {
      await tester.pumpWidget(
        _host(const AnnouncementBar('Maintenance tonight', showIcon: false)),
      );
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
      expect(
        tester.getTopLeft(find.byType(RichText).first).dx -
            tester.getTopLeft(find.byType(AnnouncementBar)).dx,
        AdminSpacing.xl,
      );
    });
  });

  group('Toast', () {
    testWidgets('icon replaces the severity glyph', (tester) async {
      await _toast(
        tester,
        const Toast('Link copied', icon: Icons.link, severity: Severity.info),
      );
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    });

    testWidgets('showIcon: false drops the glyph, keeps the height', (
      tester,
    ) async {
      await _toast(tester, const Toast('Saved.'));
      final card = find.ancestor(
        of: find.text('Saved.'),
        matching: find.byType(IntrinsicHeight),
      );
      final height = tester.getSize(card).height;
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await _toast(tester, const Toast('Saved.', showIcon: false));
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
      expect(tester.getSize(card).height, height);
    });
  });

  testWidgets('ToastScope.maybeOf finds the scope, or null', (tester) async {
    ToastScopeState? inside;
    ToastScopeState? outside;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Builder(
          builder: (context) {
            outside = ToastScope.maybeOf(context);
            return ToastScope(
              child: Builder(
                builder: (context) {
                  inside = ToastScope.maybeOf(context);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(outside, isNull);
    expect(inside, isNotNull);
  });
}
