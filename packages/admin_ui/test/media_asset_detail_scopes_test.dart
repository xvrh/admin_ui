// showAssetDetail from a page under AdminScope's anchor: the anchor is above
// the page's LangScope and AssetSourceScope, so the sheet takes them from the
// page's context. And an anchor's sheet sits above the keyboard, even under
// a Scaffold that took the keyboard out of its body's MediaQuery.

import 'dart:typed_data';

import 'package:admin_ui/src/assets/asset_source.dart';
import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/common/ui/admin_scope.dart';
import 'package:admin_ui/src/common/ui/field_presence.dart';
import 'package:admin_ui/src/common/ui/modal_anchor.dart';
import 'package:admin_ui/src/common/ui/side_sheet.dart';
import 'package:admin_ui/src/fields/ui/lane_stack.dart';
import 'package:admin_ui/src/forms/asset_detail.dart';
import 'package:admin_ui/src/i18n/lang_scope.dart';
import 'package:admin_ui/src/i18n/locale_status.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _asset = Asset(
  id: '35',
  name: 'gloves.jpg',
  width: 1200,
  height: 800,
  alt: {'en': 'Gloves', 'fr': 'Gants'},
);

const _locales = [
  LocaleInfo(code: 'en', status: LocaleStatus.source),
  LocaleInfo(code: 'fr', status: LocaleStatus.translated),
  LocaleInfo(code: 'ar', status: LocaleStatus.translated),
];

class _Source implements AssetSource {
  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult.empty;

  @override
  Future<Asset?> resolve(String id) async => null;

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

/// A page under the frame's AdminScope that mounts its own language and
/// asset scopes, and no anchor, and opens the asset from inside them.
class _Page extends StatefulWidget {
  final AssetSource source;
  final void Function(BuildContext context) onOpen;
  final ValueChanged<Set<String>> onVisible;

  const _Page({
    required this.source,
    required this.onOpen,
    required this.onVisible,
  });

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  Set<String> _visible = const {'en', 'fr', 'ar'};

  @override
  Widget build(BuildContext context) {
    return AssetSourceScope(
      source: widget.source,
      child: LangScope(
        locales: _locales,
        visibleLocales: _visible,
        sourceLocale: 'en',
        activeLocale: 'en',
        onVisibleLocalesChanged: (visible) {
          widget.onVisible(visible);
          setState(() => _visible = visible);
        },
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => widget.onOpen(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  AssetSource? source,
  required void Function(BuildContext context) onOpen,
  ValueChanged<Set<String>>? onVisible,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: AdminScope(
        child: Scaffold(
          body: _Page(
            source: source ?? _Source(),
            onOpen: onOpen,
            onVisible: onVisible ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

List<LocaleInfo> _lanes(WidgetTester tester) =>
    tester.widget<LaneStack>(find.byType(LaneStack)).lanes;

void main() {
  testWidgets('from AdminScope, the alt editor gets the page languages', (
    tester,
  ) async {
    Map<String, String>? saved;
    final shown = <Set<String>>[];
    final source = _Source();
    AssetSource? seen;
    await _pumpFrame(
      tester,
      source: source,
      onVisible: shown.add,
      onOpen: (context) => showAssetDetail(
        ModalAnchor.of(context),
        context: context,
        asset: _asset,
        onSaveAlt: (alt) async {
          saved = alt;
          return Asset(id: _asset.id, name: _asset.name, alt: alt);
        },
        footerActions: [
          Builder(
            builder: (context) {
              seen = AssetSourceScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(seen, same(source));

    // Each lane says whether the asset has alt text in it.
    expect(_lanes(tester).map((l) => (l.code, l.status)), [
      ('en', LocaleStatus.source),
      ('fr', LocaleStatus.translated),
      ('ar', LocaleStatus.missing),
    ]);

    const arabic = 'قفازات';
    await tester.enterText(find.byType(EditableText).at(2), arabic);
    await tester.pump();
    await tester.tap(find.text('Save alt text'));
    await tester.pumpAndSettle();
    expect(saved, {'en': 'Gloves', 'fr': 'Gants', 'ar': arabic});
    expect(_lanes(tester).last.status, LocaleStatus.translated);

    // The languages in view are the sheet's, and the page hears of them.
    final scope = tester.widget<LangScope>(
      find
          .ancestor(
            of: find.byType(LaneStack),
            matching: find.byType(LangScope),
          )
          .first,
    );
    scope.onVisibleLocalesChanged({'en', 'ar'});
    await tester.pumpAndSettle();
    expect(shown, [
      {'en', 'ar'},
    ]);
    expect(_lanes(tester).map((l) => l.code), ['en', 'ar']);
  });

  testWidgets('an action in the sheet finds the scopes the asset editor '
      'relays, so an editor it opens has them too', (tester) async {
    ExternalProviderScope? providers;
    FieldPresenceScope? presence;
    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: AdminScope(
          child: Scaffold(
            body: ExternalProviderScope(
              providers: const [],
              child: FieldPresenceScope(
                child: Builder(
                  builder: (context) {
                    page = context;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    showAssetDetail(
      ModalAnchor.of(page),
      asset: _asset,
      context: page,
      footerActions: [
        Builder(
          builder: (context) {
            providers = context
                .getInheritedWidgetOfExactType<ExternalProviderScope>();
            presence = context
                .getInheritedWidgetOfExactType<FieldPresenceScope>();
            return const Text('crop');
          },
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('crop'), findsOneWidget);
    expect(providers, isNotNull);
    expect(presence, isNotNull);
  });

  testWidgets('without the page context, the anchor has no languages', (
    tester,
  ) async {
    await _pumpFrame(
      tester,
      onOpen: (context) => showAssetDetail(
        ModalAnchor.of(context),
        asset: _asset,
        onSaveAlt: (alt) async => null,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.takeException().toString(),
      contains('no LangScope above it'),
    );
  });

  testWidgets('an anchor below the page scopes keeps them live', (
    tester,
  ) async {
    final modals = ModalAnchorController();
    final visible = ValueNotifier<Set<String>>({'en', 'fr', 'ar'});
    addTearDown(visible.dispose);
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: visible,
            builder: (context, shown, _) => LangScope(
              locales: _locales,
              visibleLocales: shown,
              sourceLocale: 'en',
              activeLocale: 'en',
              onVisibleLocalesChanged: (v) => visible.value = v,
              child: ModalAnchor(
                controller: modals,
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showAssetDetail(
                      modals,
                      context: context,
                      asset: _asset,
                      onSaveAlt: (alt) async => null,
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_lanes(tester), hasLength(3));

    // The page changes its languages by itself: the sheet follows at once.
    visible.value = {'fr'};
    await tester.pump();
    expect(_lanes(tester).map((l) => l.code), ['fr']);
  });

  group('the keyboard', () {
    Future<void> openSheet(
      WidgetTester tester, {
      required bool pageAnchor,
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final modals = ModalAnchorController();
      Widget anchor(Widget child) =>
          ModalAnchor(controller: modals, child: child);
      const page = SizedBox.expand();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: pageAnchor
              ? Scaffold(body: anchor(page))
              : anchor(const Scaffold(body: page)),
        ),
      );
      modals.showSheet<void>(
        builder: (context) => SideSheet(
          title: 'Sheet',
          footer: Text('inset ${MediaQuery.viewInsetsOf(context).bottom}'),
          child: const SizedBox.expand(),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final pageAnchor in [false, true]) {
      testWidgets(
        'an anchor ${pageAnchor ? 'under' : 'above'} the Scaffold keeps its '
        'sheet above it',
        (tester) async {
          await openSheet(tester, pageAnchor: pageAnchor);
          expect(tester.getRect(find.byType(SideSheet)).bottom, 400);

          // 150 logical pixels of keyboard at a pixel ratio of 2.
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(tester.getRect(find.byType(SideSheet)).bottom, 400 - 150);
          // Below it the inset is spent, so nothing pads for it twice.
          expect(find.text('inset 0.0'), findsOneWidget);

          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(tester.getRect(find.byType(SideSheet)).bottom, 400);
        },
      );
    }
  });
}
