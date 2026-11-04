import 'package:admin_ui/src/common/ui/tree_editor.dart';
import 'package:admin_ui/src/history/diff_model.dart';
import 'package:admin_ui/src/history/ui/diff_view.dart';
import 'package:admin_ui/src/history/ui/quick_diff.dart';
import 'package:admin_ui/src/history/ui/version_timeline.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {AdminTokens? tokens}) => MaterialApp(
  theme: buildAppTheme(tokens ?? defaultTokens),
  home: Scaffold(body: child),
);

const _base = VersionRef(
  id: 'v1',
  label: 'Spring update',
  author: 'Ada Park',
  initials: 'AP',
  timestamp: 'last week',
  status: VersionStatus.published,
);
const _draft = VersionRef(
  id: 'draft',
  label: 'Working draft',
  author: 'You',
  initials: 'YO',
  timestamp: 'now',
  status: VersionStatus.draft,
);

const _diff = VersionDiff(
  base: _base,
  compare: _draft,
  locales: ['en', 'fr'],
  fields: [
    FieldDiff(
      label: 'Title',
      fieldKey: 'title',
      kind: DiffFieldKind.text,
      translatable: true,
      locales: [
        LocaleDiff(
          locale: 'en',
          op: DiffOp.changed,
          before: 'Old',
          after: 'New',
        ),
        LocaleDiff(
          locale: 'fr',
          op: DiffOp.changed,
          before: 'Vieux',
          after: 'Neuf',
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('DiffView: its toggles are buttons that say when they are on', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const SizedBox(width: 900, height: 600, child: DiffView(diff: _diff)),
      ),
    );

    expect(
      tester.getSemantics(find.text('FR').first),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    await tester.tap(find.text('FR').first);
    await tester.pump();
    expect(
      tester.getSemantics(find.text('FR').first),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: false),
    );
    expect(
      tester.getSemantics(find.text('Unchanged')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('the restore actions are named and keyboard-reachable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var restored = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 900,
          height: 600,
          child: DiffView(diff: _diff, onRestorePart: (_) => restored++),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Restore')),
      isSemantics(isButton: true, isFocusable: true, label: 'Restore'),
    );

    // Focus it and press Enter.
    Focus.of(tester.element(find.text('Restore'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(restored, 1);
    handle.dispose();
  });

  testWidgets('VersionTimeline marks the compared endpoints selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          height: 400,
          child: VersionTimeline(
            versions: const [_draft, _base],
            baseId: 'v1',
            compareId: 'draft',
            onTap: (_) {},
          ),
        ),
      ),
    );
    for (final label in ['Working draft', 'Spring update']) {
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('DiffOpTag text reads on its fill in every shipped palette', (
    tester,
  ) async {
    for (final theme in adminThemes) {
      for (final palette in [theme.palette, theme.darkPalette!]) {
        await tester.pumpWidget(
          _host(
            const Row(
              children: [
                DiffOpTag(DiffOp.added),
                DiffOpTag(DiffOp.removed),
                DiffOpTag(DiffOp.changed),
                DiffOpTag(DiffOp.moved),
              ],
            ),
            tokens: AdminTokens.from(palette: palette),
          ),
        );
        for (final label in ['Added', 'Removed', 'Changed', 'Moved']) {
          final text = tester.widget<Text>(find.text(label));
          final box = tester.widget<Container>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(Container),
                )
                .first,
          );
          final fill = (box.decoration! as BoxDecoration).color!;
          expect(
            contrastRatio(text.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.name} ${palette.brightness} $label',
          );
        }
      }
    }
  });

  group('TreeEditor', () {
    const entries = [
      TreeEditorEntry(id: 'home', title: 'Home'),
      TreeEditorEntry(id: 'about', title: 'About'),
    ];

    Widget editor({String? selectedId}) => Center(
      child: SizedBox(
        width: 520,
        child: TreeEditor(
          maxDepth: 2,
          entries: entries,
          selectedId: selectedId,
          onSelect: (_) {},
          onMove: (_, _, _) {},
          onToggleVisible: (_) {},
          onAddChild: (_) {},
          onDelete: (_) {},
        ),
      ),
    );

    testWidgets('hidden row actions leave the semantics tree until shown', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(editor()));
      expect(find.bySemanticsLabel('Delete'), findsNothing);
      expect(find.bySemanticsLabel('Hide'), findsNWidgets(2));
      expect(find.bySemanticsLabel('More actions'), findsNWidgets(2));

      await tester.pumpWidget(_host(editor(selectedId: 'about')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a keyboard move is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(editor()));
      Focus.of(tester.element(find.text('Home'))).requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(
        tester.takeAnnouncements(),
        contains(isAccessibilityAnnouncement('Home moved down')),
      );
      handle.dispose();
    });
  });
}
