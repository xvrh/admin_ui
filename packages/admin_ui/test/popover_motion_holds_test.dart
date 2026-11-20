import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// What a Popover holds, in each theme whose popover motion keeps it on
// screen after it is asked to close: a pick is taken, the popover goes, and
// nothing is thrown on the way. The motion itself is measured in
// popover_motion_test.dart.

Widget _app(AdminTokens tokens, Widget body) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(body: body),
);

void main() {
  group('in a theme whose popovers move', () {
    // The motion themes, where a popover outlives its close.
    final moving = [
      for (final theme in adminThemes)
        if (theme.tokens.overlay.popoverMotion != null) theme,
    ];

    for (final theme in moving) {
      testWidgets('${theme.name}: a menu and its submenu leave together', (
        tester,
      ) async {
        final picked = <String>[];
        await tester.pumpWidget(
          _app(
            theme.tokens,
            Center(
              child: Menu(
                entries: [
                  MenuItem('Rename', onSelect: () => picked.add('Rename')),
                  MenuSubmenu(
                    'Move to',
                    entries: [
                      MenuItem('Blog', onSelect: () => picked.add('Blog')),
                    ],
                  ),
                ],
                builder: (context, c) => TextButton(
                  onPressed: c.toggle,
                  child: const Text('Actions'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Move to'));
        await tester.pumpAndSettle();
        expect(find.text('Blog'), findsOneWidget);

        await tester.tap(find.text('Blog'));
        await tester.pump();
        expect(picked, ['Blog']);
        await tester.pumpAndSettle();
        expect(find.text('Blog'), findsNothing);
        expect(find.text('Rename'), findsNothing);
        expect(tester.takeException(), isNull);

        // And it opens again afterwards.
        await tester.tap(find.text('Actions'));
        await tester.pumpAndSettle();
        expect(find.text('Rename'), findsOneWidget);
      });

      testWidgets('${theme.name}: a select takes its pick and closes', (
        tester,
      ) async {
        String? value = 'draft';
        await tester.pumpWidget(
          _app(
            theme.tokens,
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: StatefulBuilder(
                  builder: (context, setState) => SelectBody(
                    options: const [
                      SelectOption(value: 'draft', label: 'Draft'),
                      SelectOption(value: 'review', label: 'In review'),
                    ],
                    value: value,
                    onChanged: (v) => setState(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Draft'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('In review'));
        await tester.pumpAndSettle();
        expect(value, 'review');
        // The list is gone; the trigger shows the pick.
        expect(find.text('Draft'), findsNothing);
        expect(find.text('In review'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${theme.name}: a combobox takes its pick and closes', (
        tester,
      ) async {
        String? value;
        await tester.pumpWidget(
          _app(
            theme.tokens,
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (context, setState) => Combobox<String>(
                    value: value,
                    options: const [
                      ComboboxOption('a', 'Apple'),
                      ComboboxOption('b', 'Banana'),
                    ],
                    onChanged: (v) => setState(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ban');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Banana').last);
        await tester.pumpAndSettle();
        expect(value, 'b');
        expect(find.text('Apple'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
