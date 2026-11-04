import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/src/collection/saved_view.dart';
import 'package:admin_ui/src/collection/ui/saved_views_bar.dart';
import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/l10n/admin_ui_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _views = [
  SavedView(id: 'all', name: 'All', isDefault: true),
  SavedView(id: 'pub', name: 'Published', scope: SavedViewScope.shared),
];

/// The menu caret of the tab named [name].
Finder _caret(String name) => find.byWidgetPredicate(
  (w) => w is IconAction && w.label == '$name options',
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 900, child: child)),
);

void main() {
  testWidgets('renders a tab per view and selects on tap', (tester) async {
    SavedView? picked;
    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (v) => picked = v,
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);

    await tester.tap(find.text('Published'));
    expect(picked?.id, 'pub');
  });

  testWidgets('shows Save / Reset only when dirty', (tester) async {
    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (_) {},
          onSaveChanges: () {},
          onDiscardChanges: () {},
        ),
      ),
    );
    expect(find.text('Save'), findsNothing);
    expect(find.text('Reset'), findsNothing);

    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: true,
          onSelect: (_) {},
          onSaveChanges: () {},
          onDiscardChanges: () {},
        ),
      ),
    );
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('the active tab offers its menu without a pointer', (
    tester,
  ) async {
    SavedView? deleted;
    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (_) {},
          onDelete: (v) => deleted = v,
          onRenamed: (_, _) {},
        ),
      ),
    );
    await tester.tap(_caret('All'));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted?.id, 'all');
  });

  testWidgets(
    'an inactive tab\'s menu stays open after the pointer moves onto it',
    (tester) async {
      SavedView? deleted;
      await tester.pumpWidget(
        _host(
          SavedViewsBar(
            views: _views,
            activeId: 'none', // nothing active → carets appear only on hover
            dirty: false,
            onSelect: (_) {},
            onDelete: (v) => deleted = v,
            onRenamed: (_, _) {},
          ),
        ),
      );
      final caret = _caret('Published');
      Opacity shown() => tester.widget<Opacity>(
        find.ancestor(of: caret, matching: find.byType(Opacity)).first,
      );
      expect(shown().opacity, 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      // Hover the inactive tab → its caret appears.
      await mouse.moveTo(tester.getCenter(find.text('Published')));
      await tester.pumpAndSettle();
      expect(shown().opacity, 1);

      await tester.tap(caret);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      // Move onto the popover — leaves the tab (drops hover). Must NOT dismiss.
      await mouse.moveTo(tester.getCenter(find.text('Delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted?.id, 'pub');
    },
  );

  testWidgets('Duplicate names the copy in the app’s language', (tester) async {
    String? copyName;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AdminLocalizations.supportedLocales,
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: SavedViewsBar(
              views: _views,
              activeId: 'pub',
              dirty: false,
              onSelect: (_) {},
              onDuplicate: (_, name) => copyName = name,
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is IconAction && w.label == 'Options de la vue Published',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dupliquer'));
    await tester.pumpAndSettle();
    expect(copyName, 'Published (copie)');
  });

  testWidgets('tabs expose tab role + selected state to a11y', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (_) {},
        ),
      ),
    );

    final all = tester.getSemantics(find.text('All'));
    expect(all, isSemantics(isSelected: true));
    expect(all.getSemanticsData().role, SemanticsRole.tab);
    expect(
      tester.getSemantics(find.text('Published')),
      isSemantics(isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('a tab activates via the keyboard (Enter)', (tester) async {
    SavedView? picked;
    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (v) => picked = v,
        ),
      ),
    );

    // Tab to the first focus stop, then activate it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
  });

  testWidgets('clicking a tab drops keyboard focus (no stale ring)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (_) {},
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();
    expect(focused!.hasFocus, isFalse);
  });
}
