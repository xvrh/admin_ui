import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title and message', (tester) async {
    await tester.pumpWidget(
      _host(const AnnouncementBar('Down for maintenance.', title: 'Notice')),
    );
    expect(find.textContaining('Notice'), findsOneWidget);
    expect(find.textContaining('Down for maintenance.'), findsOneWidget);
  });

  testWidgets('shows action and fires dismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _host(
        AnnouncementBar(
          'Update ready.',
          action: const Icon(Icons.bolt),
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    expect(find.byIcon(Icons.bolt), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(dismissed, isTrue);
  });

  testWidgets('the dismiss is a labelled button that keeps the height', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const AnnouncementBar('Notice.')));
    final plain = tester.getSize(find.byType(AnnouncementBar)).height;

    await tester.pumpWidget(
      _host(AnnouncementBar('Notice.', onDismiss: () {})),
    );
    expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
    final close = tester.getSize(find.byType(IconAction));
    expect(close.width, greaterThanOrEqualTo(24));
    expect(close.height, greaterThanOrEqualTo(24));
    expect(tester.getSize(find.byType(AnnouncementBar)).height, plain);
    handle.dispose();
  });

  testWidgets('no dismiss affordance without onDismiss', (tester) async {
    await tester.pumpWidget(_host(const AnnouncementBar('Just a notice.')));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('icon and rule take the text-safe foreground and border', (
    tester,
  ) async {
    for (final severity in Severity.values) {
      late SeverityStyle style;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: antPalette)),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                style = severityStyleOf(context, severity);
                return AnnouncementBar('Notice', severity: severity);
              },
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(style.icon));
      expect(icon.color, style.foreground);
      expect(
        contrastRatio(icon.color!, style.surface),
        greaterThanOrEqualTo(3),
        reason: '$severity icon',
      );
      final bar = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(style.icon),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (bar.decoration! as BoxDecoration).border! as Border;
      expect(border.bottom.color, style.border);
    }
  });
}
