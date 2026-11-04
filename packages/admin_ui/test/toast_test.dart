import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(void Function(BuildContext) onTap) => MaterialApp(
  home: ToastScope(
    child: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => onTap(context),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('show raises a toast; the close button dismisses it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host((c) => ToastScope.of(c).show(const Toast('Saved.'))),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsNothing);
  });

  testWidgets('the action fires and dismisses the toast', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      _host(
        (c) => ToastScope.of(c).show(
          Toast('Deleted.', actionLabel: 'Undo', onAction: () => undone = true),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Deleted.'), findsNothing);
  });

  testWidgets('the severity icon takes the text-safe foreground', (
    tester,
  ) async {
    late SeverityStyle style;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: carbonPalette)),
        home: ToastScope(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                style = severityStyleOf(context, Severity.warning);
                return TextButton(
                  onPressed: () => ToastScope.of(
                    context,
                  ).show(const Toast('Unstable.', severity: Severity.warning)),
                  child: const Text('go'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(style.icon));
    expect(icon.color, style.foreground);
    expect(icon.color, isNot(style.accent));
  });

  for (final (name, radii) in const [
    // Material's 4dp snackbar corner, not its 12dp control radius.
    (
      'Material',
      AdminRadii(
        radiusSmall: 8,
        radius: 12,
        radiusLarge: 16,
        radiusMenu: 4,
        radiusDialog: 28,
      ),
    ),
    // Carbon's square notifications, not its 2px control radius.
    (
      'Carbon',
      AdminRadii(
        radiusSmall: 0,
        radius: 2,
        radiusLarge: 4,
        radiusMenu: 0,
        radiusDialog: 0,
      ),
    ),
  ]) {
    testWidgets('$name: a toast rounds like a menu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(
            AdminTokens.from(palette: irisPalette, radii: radii),
          ),
          home: ToastScope(
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      ToastScope.of(context).show(const Toast('Saved.')),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final card = tester.widget<Material>(
        find
            .ancestor(of: find.text('Saved.'), matching: find.byType(Material))
            .first,
      );
      expect(
        (card.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(radii.radiusMenu),
      );
    });
  }
}
