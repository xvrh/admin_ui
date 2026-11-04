import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An in-memory store that throws from any call while [failing] is set.
class _Store implements SavedViewsStore {
  final inner = InMemorySavedViewsStore(
    latency: Duration.zero,
    seed: {
      'k': const [
        SavedView(id: 'a', name: 'A', isDefault: true),
        SavedView(id: 'b', name: 'B', position: 1),
        SavedView(id: 'c', name: 'C', position: 2),
      ],
    },
  );
  bool failing = false;

  Future<R> _call<R>(Future<R> Function() body) async {
    if (failing) throw Exception('Request failed with status 503');
    return body();
  }

  @override
  Future<List<SavedView>> list(String key) => _call(() => inner.list(key));
  @override
  Future<SavedView> create(String key, SavedView view) =>
      _call(() => inner.create(key, view));
  @override
  Future<void> update(String key, SavedView view) =>
      _call(() => inner.update(key, view));
  @override
  Future<void> delete(String key, String id) =>
      _call(() => inner.delete(key, id));
  @override
  Future<void> setDefault(String key, String id) =>
      _call(() => inner.setDefault(key, id));
  @override
  Future<void> reorder(String key, List<String> ids) =>
      _call(() => inner.reorder(key, ids));
}

CollectionController<int> _collection() => CollectionController<int>(
  fetcher: (q) async => const CollectionPage(items: [1, 2, 3], total: 3),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

const _views = [
  SavedView(id: 'all', name: 'All', isDefault: true),
  SavedView(id: 'pub', name: 'Published', scope: SavedViewScope.shared),
  SavedView(id: 'draft', name: 'Drafts'),
];

Future<void> _pumpBar(
  WidgetTester tester,
  SavedViewsBar bar, {
  double width = 900,
  AdminTokens? tokens,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: tokens == null ? null : buildAppTheme(tokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: bar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SavedViewsBar _bar({
  String activeId = 'all',
  void Function(SavedView view, String copyName)? onDuplicate,
  ValueChanged<SavedView>? onDelete,
  ValueChanged<List<String>>? onReorder,
  ValueChanged<SavedView>? onSelect,
  List<SavedView> views = _views,
  bool dirty = false,
  Object? error,
  VoidCallback? onRetry,
  SavedViewsLayout layout = SavedViewsLayout.auto,
}) => SavedViewsBar(
  views: views,
  activeId: activeId,
  dirty: dirty,
  layout: layout,
  onSelect: onSelect ?? (_) {},
  onDuplicate: onDuplicate ?? (_, _) {},
  onDelete: onDelete,
  onReorder: onReorder,
  error: error,
  onRetry: onRetry,
);

/// The caret of the tab labelled [name].
Finder _caret(String name) => find.byWidgetPredicate(
  (w) => w is IconAction && w.label == '$name options',
);

double _opacity(WidgetTester tester, String name) => tester
    .widget<Opacity>(
      find.ancestor(of: _caret(name), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  group('controller', () {
    test('a failed load resets loading and keeps the error', () async {
      final store = _Store()..failing = true;
      final col = _collection();
      final ctl = SavedViewsController<int>(
        store: store,
        collectionKey: 'k',
        collection: col,
      );
      expect(ctl.loading, isTrue);
      await _settle();
      expect(ctl.loading, isFalse);
      expect(ctl.lastError, isA<Exception>());
      expect(ctl.views, isEmpty);

      store.failing = false;
      await ctl.retry();
      expect(ctl.lastError, isNull);
      expect([for (final v in ctl.views) v.id], ['a', 'b', 'c']);
      expect(ctl.activeId, 'a');
    });

    test('a failed write leaves the views and reports', () async {
      final store = _Store();
      final ctl = SavedViewsController<int>(
        store: store,
        collectionKey: 'k',
        collection: _collection(),
      );
      await _settle();
      store.failing = true;

      await ctl.rename(ctl.views[1], 'Bee');
      expect(ctl.views[1].name, 'B');
      expect(ctl.lastError, isNotNull);

      expect(await ctl.saveAsNew('New'), isNull);
      expect(ctl.views, hasLength(3));

      await ctl.delete(ctl.views.first);
      expect(ctl.views, hasLength(3));

      ctl.clearError();
      expect(ctl.lastError, isNull);
    });

    test('reorder applies at once and persists', () async {
      final store = _Store();
      final ctl = SavedViewsController<int>(
        store: store,
        collectionKey: 'k',
        collection: _collection(),
      );
      await _settle();

      final pending = ctl.reorder(['c', 'a', 'b']);
      expect([for (final v in ctl.views) v.id], ['c', 'a', 'b']);
      await pending;
      final stored = await store.inner.list('k');
      expect([for (final v in stored) v.id], ['c', 'a', 'b']);
      expect([for (final v in stored) v.position], [0, 1, 2]);

      await ctl.move(ctl.views.first, 1);
      expect([for (final v in ctl.views) v.id], ['a', 'c', 'b']);
    });

    test('a failed reorder rolls back', () async {
      final store = _Store();
      final ctl = SavedViewsController<int>(
        store: store,
        collectionKey: 'k',
        collection: _collection(),
      );
      await _settle();
      store.failing = true;
      await ctl.reorder(['c', 'b', 'a']);
      expect([for (final v in ctl.views) v.id], ['a', 'b', 'c']);
      expect(ctl.lastError, isNotNull);
    });

    test('duplicate names the copy through nameForCopy', () async {
      final ctl = SavedViewsController<int>(
        store: _Store(),
        collectionKey: 'k',
        collection: _collection(),
        nameForCopy: (name) => 'Copie de $name',
      );
      await _settle();
      await ctl.duplicate(ctl.views.first);
      expect(ctl.views.last.name, 'Copie de A');

      final english = SavedViewsController<int>(
        store: _Store(),
        collectionKey: 'k',
        collection: _collection(),
      );
      await _settle();
      await english.duplicate(english.views.first);
      expect(english.views.last.name, 'A copy');
    });
  });

  group('tab menu', () {
    testWidgets('the active tab shows its caret without a pointer', (
      tester,
    ) async {
      await _pumpBar(tester, _bar());
      expect(_opacity(tester, 'All'), 1);
      // The others keep theirs in place, invisible.
      expect(_opacity(tester, 'Published'), 0);
      expect(_caret('Published'), findsOneWidget);
    });

    testWidgets('Tab reaches the active tab\'s caret, which opens the menu', (
      tester,
    ) async {
      String? copied;
      await _pumpBar(tester, _bar(onDuplicate: (v, _) => copied = v.id));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!.widget;
      expect(
        find.descendant(of: _caret('All'), matching: find.byWidget(focused)),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(copied, 'all');

      // Tab moves on past the strip: the hidden carets are no Tab stops.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final next = FocusManager.instance.primaryFocus?.context?.widget;
      for (final name in ['Published', 'Drafts']) {
        expect(
          find.descendant(
            of: _caret(name),
            matching: find.byWidget(next ?? const SizedBox()),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('Shift+F10 or the context-menu key open the focused tab\'s '
        'menu', (tester) async {
      String? deleted;
      await _pumpBar(tester, _bar(onDelete: (v) => deleted = v.id));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      // Escape hands focus to the caret; Shift+Tab goes back to the tab.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 'all');
    });

    testWidgets('a secondary click or a long press opens any tab\'s menu', (
      tester,
    ) async {
      String? copied;
      await _pumpBar(tester, _bar(onDuplicate: (v, _) => copied = v.id));
      await tester.tap(find.text('Published'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(copied, 'pub');

      await tester.longPress(find.text('Drafts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(copied, 'draft');
    });

    testWidgets('hover reveals an inactive tab\'s caret', (tester) async {
      await _pumpBar(tester, _bar());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Published')));
      await tester.pumpAndSettle();
      expect(_opacity(tester, 'Published'), 1);
    });

    testWidgets('Move left / Move right report the new order', (tester) async {
      List<String>? order;
      await _pumpBar(tester, _bar(onReorder: (ids) => order = ids));
      await tester.tap(_caret('All'));
      await tester.pumpAndSettle();
      expect(find.text('Move left'), findsNothing);
      await tester.tap(find.text('Move right'));
      await tester.pumpAndSettle();
      expect(order, ['pub', 'all', 'draft']);

      await tester.tap(find.text('Drafts'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.text('Move right'), findsNothing);
      await tester.tap(find.text('Move left'));
      await tester.pumpAndSettle();
      expect(order, ['all', 'draft', 'pub']);
    });
  });

  testWidgets('an overflowing strip offers every view in "More views"', (
    tester,
  ) async {
    SavedView? picked;
    final views = [
      for (var i = 0; i < 8; i++) SavedView(id: 'v$i', name: 'Saved view $i'),
    ];
    // Below the medium breakpoint the bar is a menu unless held to a strip.
    await _pumpBar(
      tester,
      _bar(
        views: views,
        activeId: 'v0',
        onSelect: (v) => picked = v,
        layout: SavedViewsLayout.strip,
      ),
      width: 420,
    );
    final more = find.byWidgetPredicate(
      (w) => w is IconAction && w.label == 'More views',
    );
    expect(more, findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.tap(more);
    await tester.pumpAndSettle();
    // The current view is a checked radio item, like every checked menu.
    expect(
      tester.getSemantics(find.text('Saved view 0').last),
      isSemantics(
        label: 'Saved view 0',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    semantics.dispose();
    await tester.tap(find.text('Saved view 7').last);
    await tester.pumpAndSettle();
    expect(picked?.id, 'v7');

    // Wide enough: no menu.
    await _pumpBar(tester, _bar(), width: 900);
    expect(more, findsNothing);
  });

  testWidgets('the bar words an error and offers Retry', (tester) async {
    var retried = 0;
    await _pumpBar(
      tester,
      _bar(
        error: Exception('Request failed with status 503'),
        onRetry: () => retried++,
      ),
    );
    expect(find.textContaining('server'), findsOneWidget);
    expect(find.textContaining('503'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  group('badges reach 3:1', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        if (dark && !theme.hasDark) continue;
        testWidgets('${theme.name} ${dark ? 'Dark' : 'Light'}', (tester) async {
          final tokens = runZoned(
            () => dark ? theme.dark! : theme.tokens,
            zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
          );
          final palette = tokens.palette;
          await _pumpBar(
            tester,
            _bar(dirty: true),
            tokens: AdminTokens.from(palette: palette, radii: tokens.radii),
          );
          final star = tester.widget<Icon>(find.byIcon(Icons.star_rounded));
          expect(
            contrastRatio(star.color!, palette.surface),
            greaterThanOrEqualTo(3),
          );
          final dot = tester.widget<Container>(
            find.descendant(
              of: find.byWidgetPredicate(
                (w) =>
                    w is Semantics && w.properties.label == 'Unsaved changes',
              ),
              matching: find.byType(Container),
            ),
          );
          expect(
            contrastRatio(
              (dot.decoration! as BoxDecoration).color!,
              palette.surface,
            ),
            greaterThanOrEqualTo(3),
          );
        });
      }
    }
  });
}
