import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// `SavedViewsBar.canEdit` says which views are the person's to change: one
// it answers false for offers no Rename, no Delete and no Save.

const _mine = SavedView(id: 'mine', name: 'Mine', isDefault: true, position: 1);
const _shop = SavedView(
  id: 'shop',
  name: 'To ship',
  scope: SavedViewScope.shared,
);
const _views = [_shop, _mine];

/// The views the person saved themself.
bool _own(SavedView view) => view.scope == SavedViewScope.personal;

/// What the bar was asked to do, in order.
final _asked = <String>[];

SavedViewsBar _bar({
  bool Function(SavedView view)? canEdit,
  String? activeId = 'shop',
  bool dirty = false,
  bool every = true,
  SavedViewsLayout layout = SavedViewsLayout.strip,
}) => SavedViewsBar(
  views: _views,
  activeId: activeId,
  dirty: dirty,
  layout: layout,
  canEdit: canEdit,
  onSelect: (_) {},
  onSaveChanges: () => _asked.add('save'),
  onDiscardChanges: () => _asked.add('reset'),
  onCreate: (_) {},
  onRenamed: (view, name) => _asked.add('rename ${view.id}'),
  onDelete: (view) => _asked.add('delete ${view.id}'),
  onDuplicate: every ? (view, _) => _asked.add('duplicate ${view.id}') : null,
  onSetDefault: every ? (view) => _asked.add('default ${view.id}') : null,
  onReorder: every ? (ids) => _asked.add('order $ids') : null,
);

Future<void> _pump(
  WidgetTester tester,
  SavedViewsBar bar, {
  double width = 900,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: bar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The menu caret of the tab named [name].
Finder _caret(String name) => find.byWidgetPredicate(
  (w) => w is IconAction && w.label == '$name options',
);

/// Opens the menu of the tab named [name], with a secondary click: an
/// inactive tab's caret shows only under a pointer.
Future<void> _open(WidgetTester tester, String name) async {
  await tester.tap(find.text(name), buttons: kSecondaryButton);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

/// The rows of the open menu, which are of a private type.
final _rows = find.byWidgetPredicate((w) => '${w.runtimeType}' == '_MenuRow');

/// The entries of the open menu, top to bottom: each row's label, its first
/// text.
List<String> _entries(WidgetTester tester) => [
  for (final row in _rows.evaluate())
    tester
        .widget<Text>(
          find
              .descendant(
                of: find.byElementPredicate((e) => e == row),
                matching: find.byType(Text),
              )
              .first,
        )
        .data!,
];

final _save = find.widgetWithText(Button, 'Save');
final _reset = find.widgetWithText(Button, 'Reset');
final _plus = find.byWidgetPredicate(
  (w) => w is Button && w.semanticLabel == 'Save current as a new view',
);

void main() {
  setUp(_asked.clear);

  group('with no canEdit', () {
    testWidgets('every view offers Rename and Delete', (tester) async {
      await _pump(tester, _bar());

      await _open(tester, 'To ship');
      expect(_entries(tester), containsAll(['Rename', 'Delete']));
      await _close(tester);

      await _open(tester, 'Mine');
      expect(_entries(tester), containsAll(['Rename', 'Delete']));
    });

    testWidgets('the active view offers Save while dirty', (tester) async {
      await _pump(tester, _bar(dirty: true));
      expect(_save, findsOneWidget);
    });
  });

  group('a view that is not the person\'s to change', () {
    testWidgets('offers no Rename and no Delete', (tester) async {
      await _pump(tester, _bar(canEdit: _own));

      await _open(tester, 'To ship');
      expect(_entries(tester), isNot(contains('Rename')));
      expect(_entries(tester), isNot(contains('Delete')));
    });

    testWidgets('still offers Duplicate, the default and the moves', (
      tester,
    ) async {
      await _pump(tester, _bar(canEdit: _own));

      await _open(tester, 'To ship');
      expect(_entries(tester), ['Duplicate', 'Set as default', 'Move right']);

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(_asked, ['duplicate shop']);
    });

    testWidgets('has no menu when Rename and Delete were all of it', (
      tester,
    ) async {
      await _pump(tester, _bar(canEdit: _own, every: false));
      // The active tab shows its caret without a pointer, when it has a menu.
      expect(_caret('To ship'), findsNothing);

      await _pump(tester, _bar(every: false));
      expect(_caret('To ship'), findsOneWidget);
    });

    testWidgets('offers no Save while it is active and dirty, and keeps '
        'Reset and the +', (tester) async {
      await _pump(tester, _bar(canEdit: _own, dirty: true));
      expect(_save, findsNothing);
      expect(_reset, findsOneWidget);
      expect(_plus, findsOneWidget);

      await tester.tap(_reset);
      expect(_asked, ['reset']);
    });
  });

  group('a view that is', () {
    testWidgets('offers Rename and Delete beside one that is not', (
      tester,
    ) async {
      await _pump(tester, _bar(canEdit: _own));

      await _open(tester, 'Mine');
      expect(_entries(tester), ['Rename', 'Duplicate', 'Move left', 'Delete']);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(_asked, ['delete mine']);
    });

    testWidgets('offers Save while it is active and dirty', (tester) async {
      await _pump(tester, _bar(canEdit: _own, activeId: 'mine', dirty: true));
      expect(_save, findsOneWidget);

      await tester.tap(_save);
      expect(_asked, ['save']);
    });
  });

  testWidgets('canEdit is asked about the view, not the active one', (
    tester,
  ) async {
    // The shop's view is active; the person's own is not.
    await _pump(tester, _bar(canEdit: _own, dirty: true));
    expect(_save, findsNothing);

    await _open(tester, 'Mine');
    expect(_entries(tester), contains('Rename'));
  });

  testWidgets('an active id that is none of the views keeps Save', (
    tester,
  ) async {
    await _pump(
      tester,
      _bar(canEdit: (_) => false, activeId: 'gone', dirty: true),
    );
    expect(_save, findsOneWidget);
  });

  testWidgets('with no view active there is no Save, whatever canEdit says', (
    tester,
  ) async {
    await _pump(
      tester,
      _bar(canEdit: (_) => true, activeId: null, dirty: true),
    );
    expect(_save, findsNothing);
    expect(_reset, findsOneWidget);
  });

  group('the compact form', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Button && w.trailingIcon != null && w.label == 'To ship',
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists the active view\'s actions without Rename and Delete', (
      tester,
    ) async {
      await _pump(
        tester,
        _bar(canEdit: _own, layout: SavedViewsLayout.menu),
        width: 360,
      );
      await openMenu(tester);
      expect(_entries(tester), [
        'To ship',
        'Mine',
        'Duplicate',
        'Set as default',
      ]);
    });

    testWidgets('lists them with both when the view is the person\'s', (
      tester,
    ) async {
      await _pump(tester, _bar(layout: SavedViewsLayout.menu), width: 360);
      await openMenu(tester);
      expect(_entries(tester), [
        'To ship',
        'Mine',
        'Rename',
        'Duplicate',
        'Set as default',
        'Delete',
      ]);
    });

    testWidgets('offers no Save for a view that is not', (tester) async {
      await _pump(
        tester,
        _bar(canEdit: _own, dirty: true, layout: SavedViewsLayout.menu),
        width: 360,
      );
      expect(_save, findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Button && w.semanticLabel == 'Reset',
        ),
        findsOneWidget,
      );
      expect(_plus, findsOneWidget);
    });
  });
}
