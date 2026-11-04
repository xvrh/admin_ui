import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/menu.dart';
import 'package:admin_ui/src/common/ui/tip.dart';
import 'package:admin_ui/src/shell/ui/save_bar.dart';
import 'package:admin_ui/src/theme/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Button _button(WidgetTester tester, String label) =>
    tester.widget<Button>(find.widgetWithText(Button, label));

void main() {
  testWidgets('clean: no indicator, Save disabled, Publish enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(SaveBar(state: SaveState.clean, onSave: () {}, onCommit: () {})),
    );

    expect(find.text('Unsaved changes'), findsNothing);
    expect(_button(tester, 'Save').onPressed, isNull);
    expect(_button(tester, 'Publish').onPressed, isNotNull);
  });

  testWidgets('unsaved: indicator shows, Save + Discard live', (tester) async {
    await tester.pumpWidget(
      _host(
        SaveBar(
          state: SaveState.unsaved,
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
        ),
      ),
    );

    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(_button(tester, 'Save').onPressed, isNotNull);
    expect(_button(tester, 'Discard').onPressed, isNotNull);
  });

  testWidgets('saving: Save spins and the whole bar is locked', (tester) async {
    await tester.pumpWidget(
      _host(
        SaveBar(
          state: SaveState.saving,
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
        ),
      ),
    );

    expect(find.text('Saving…'), findsOneWidget);
    expect(_button(tester, 'Save').loading, isTrue);
    expect(_button(tester, 'Publish').onPressed, isNull);
    expect(_button(tester, 'Discard').onPressed, isNull);
  });

  testWidgets('saved: appends the timestamp label', (tester) async {
    await tester.pumpWidget(
      _host(const SaveBar(state: SaveState.saved, savedLabel: '2m ago')),
    );

    expect(find.text('Saved · 2m ago'), findsOneWidget);
  });

  testWidgets('publishing spins Publish and locks the bar', (tester) async {
    await tester.pumpWidget(
      _host(
        SaveBar(
          state: SaveState.unsaved,
          committing: true,
          onSave: () {},
          onCommit: () {},
        ),
      ),
    );

    expect(_button(tester, 'Publish').loading, isTrue);
    expect(_button(tester, 'Save').onPressed, isNull);
  });

  testWidgets('save fires its callback when dirty', (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      _host(SaveBar(state: SaveState.unsaved, onSave: () => saved++)),
    );

    await tester.tap(find.widgetWithText(Button, 'Save'));
    expect(saved, 1);
  });

  testWidgets('a narrow bar folds Discard into the ⋯ menu', (tester) async {
    var discarded = 0;
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: const AdminBreakpoints().medium - 1,
            child: SaveBar(
              state: SaveState.unsaved,
              onDiscard: () => discarded++,
              onSave: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.widgetWithText(Button, 'Discard'), findsNothing);
    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.byType(Tip), findsWidgets);
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(discarded, 1);
  });

  group('a split Publish reads as one control', () {
    final caret = find.ancestor(
      of: find.byIcon(Icons.keyboard_arrow_down_rounded),
      matching: find.byType(Button),
    );
    Button action(WidgetTester tester) => tester.widget<Button>(
      find
          .descendant(
            of: find.byType(SplitButton),
            matching: find.byType(Button),
          )
          .first,
    );
    List<VoidCallback?> entries(WidgetTester tester) => [
      for (final entry
          in tester.widget<SplitButton>(find.byType(SplitButton)).entries)
        if (entry is MenuItem) entry.onSelect,
    ];
    Widget bar({
      SaveState state = SaveState.unsaved,
      bool publishing = false,
      int invalidCount = 0,
      bool publishEnabled = true,
      VoidCallback? onUnpublish,
    }) => _host(
      SaveBar(
        state: state,
        committing: publishing,
        invalidCount: invalidCount,
        commitEnabled: publishEnabled,
        onCommit: () {},
        commitMenu: [
          SaveBarAction(label: 'Unpublish', onPressed: onUnpublish ?? () {}),
        ],
      ),
    );

    testWidgets('publishing: the action spins, the caret is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(bar(publishing: true));
      expect(action(tester).loading, isTrue);
      expect(tester.widget<Button>(caret).onPressed, isNull);
      expect(entries(tester), [null]);
    });

    testWidgets('invalid: the action and the caret are both disabled', (
      tester,
    ) async {
      var unpublished = 0;
      await tester.pumpWidget(
        bar(invalidCount: 1, onUnpublish: () => unpublished++),
      );
      expect(action(tester).onPressed, isNull);
      expect(tester.widget<Button>(caret).onPressed, isNull);
      expect(entries(tester), [null]);
      await tester.tap(caret, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Unpublish'), findsNothing);
      expect(unpublished, 0);
    });

    testWidgets('clean with nothing to publish: Unpublish stays live', (
      tester,
    ) async {
      var unpublished = 0;
      await tester.pumpWidget(
        bar(
          state: SaveState.clean,
          publishEnabled: false,
          onUnpublish: () => unpublished++,
        ),
      );
      expect(action(tester).onPressed, isNull);
      expect(tester.widget<Button>(caret).onPressed, isNotNull);
      await tester.tap(caret);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unpublish'));
      await tester.pumpAndSettle();
      expect(unpublished, 1);
    });
  });

  testWidgets('a clean narrow bar offers Discard disabled', (tester) async {
    var discarded = 0;
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: const AdminBreakpoints().medium - 1,
            child: SaveBar(onDiscard: () => discarded++, onSave: () {}),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(discarded, 0);
  });
}
