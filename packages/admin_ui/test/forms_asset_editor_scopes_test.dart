import 'dart:convert';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A library of one asset, which counts what it was asked.
class _Source implements AssetSource {
  final resolved = <String>[];
  var browsed = 0;

  static final _hero = Asset(
    id: 'a1',
    name: 'fern.png',
    width: 1,
    height: 1,
    thumbnail: MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      ),
    ),
  );

  @override
  Future<Asset?> resolve(String id) async {
    resolved.add(id);
    return id == _hero.id ? _hero : null;
  }

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async {
    browsed++;
    return AssetBrowseResult([_hero], 1);
  }

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

class _Presence implements PresenceChannel {
  @override
  int get clientId => 1;

  @override
  Map<int, Map<String, Object?>> get states => const {};

  @override
  void Function() onChange(void Function() cb) => () {};

  @override
  void setLocalField(String fieldId) {}
}

const _locales = [
  LocaleInfo(code: 'en', status: LocaleStatus.source),
  LocaleInfo(code: 'fr', status: LocaleStatus.translated),
];

/// A page with its own source, languages and presence, and no anchor of
/// its own: its dialogs open on the app's, above all three (as
/// [AdminScope]'s does), unless [pageAnchor] mounts one below them.
class _Page extends StatefulWidget {
  final _Source source;
  final PresenceChannel presence;
  final AssetRefCell cell;
  final bool pageAnchor;

  const _Page({
    required this.source,
    required this.presence,
    required this.cell,
    this.pageAnchor = false,
  });

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  Set<String> visible = {'en'};

  @override
  Widget build(BuildContext context) {
    Widget page = Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AssetRefField(widget.cell, label: 'Hero image'),
          TextButton(
            onPressed: () =>
                showAssetEditor(context, widget.cell, label: 'Hero image'),
            child: const Text('Edit hero'),
          ),
        ],
      ),
    );
    if (widget.pageAnchor) page = ModalAnchor(child: page);
    return AssetSourceScope(
      source: widget.source,
      child: LangScope(
        locales: _locales,
        visibleLocales: visible,
        sourceLocale: 'en',
        activeLocale: 'en',
        onVisibleLocalesChanged: (v) => setState(() => visible = v),
        child: FieldPresenceScope(channel: widget.presence, child: page),
      ),
    );
  }
}

Future<_Source> _pumpPage(
  WidgetTester tester,
  AssetRefCell cell, {
  bool pageAnchor = false,
  PresenceChannel? presence,
}) async {
  final source = _Source();
  tester.view.physicalSize = const Size(1000, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: ModalAnchor(
        child: Scaffold(
          body: _Page(
            source: source,
            presence: presence ?? _Presence(),
            cell: cell,
            pageAnchor: pageAnchor,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return source;
}

Finder get editor => find.byType(Modal);

Finder get altField => find.descendant(
  of: editor,
  matching: find.byWidgetPredicate(
    (w) => w is FieldShell && w.label == 'Alt text',
  ),
);

/// The alt text's language lanes the editor shows, by code.
Finder laneOf(String code) =>
    find.descendant(of: editor, matching: find.byKey(ValueKey('lane-$code')));

void main() {
  testWidgets('opened on the app anchor, the editor sees the page\'s '
      'source, languages and presence', (tester) async {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final hero = scope.assetRef('hero')..assetId.set('a1');
    final presence = _Presence();
    final source = await _pumpPage(tester, hero, presence: presence);

    await tester.tap(find.text('Edit hero'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(editor, findsOneWidget);
    expect(altField, findsOneWidget);
    expect(laneOf('en'), findsOneWidget);
    expect(source.resolved, contains('a1'));
    final inside = tester.element(laneOf('en'));
    expect(AssetSourceScope.maybeOf(inside), same(source));
    expect(FieldPresenceScope.maybeOf(inside), same(presence));
    expect(LangScope.of(inside).visibleLocales, {'en'});
  });

  testWidgets('Replace opens the picker over the page\'s source', (
    tester,
  ) async {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final hero = scope.assetRef('hero')..assetId.set('a1');
    final source = await _pumpPage(tester, hero);
    await tester.tap(find.text('Edit hero'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: editor, matching: find.text('Replace')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(source.browsed, greaterThan(0));
  });

  testWidgets('tapping the field\'s image opens the editor with no page '
      'anchor', (tester) async {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final hero = scope.assetRef('hero')..assetId.set('a1');
    await _pumpPage(tester, hero);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AssetRefField),
            matching: find.byType(ThumbnailImage),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(laneOf('en'), findsOneWidget);
  });

  testWidgets('a language shown from the editor goes to the page, and the '
      'editor follows it', (tester) async {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final hero = scope.assetRef('hero')..assetId.set('a1');
    await _pumpPage(tester, hero);
    await tester.tap(find.text('Edit hero'));
    await tester.pumpAndSettle();
    expect(laneOf('fr'), findsNothing);

    final inside = tester.element(laneOf('en'));
    LangScope.of(inside).onVisibleLocalesChanged({'en', 'fr'});
    await tester.pumpAndSettle();

    expect(tester.state<_PageState>(find.byType(_Page)).visible, {'en', 'fr'});
    expect(laneOf('fr'), findsOneWidget);
  });

  testWidgets('an anchor below the page\'s scopes keeps them live', (
    tester,
  ) async {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final hero = scope.assetRef('hero')..assetId.set('a1');
    await _pumpPage(tester, hero, pageAnchor: true);
    await tester.tap(find.text('Edit hero'));
    await tester.pumpAndSettle();
    expect(laneOf('fr'), findsNothing);

    final page = tester.state<_PageState>(find.byType(_Page));
    // ignore: invalid_use_of_protected_member
    page.setState(() => page.visible = {'en', 'fr'});
    await tester.pumpAndSettle();

    expect(laneOf('fr'), findsOneWidget);
  });
}
