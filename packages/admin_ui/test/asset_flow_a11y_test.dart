import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Every shipped palette, light and dark.
Iterable<(String, AdminPalette)> get _palettes sync* {
  for (final theme in adminThemes) {
    yield ('${theme.name} Light', theme.palette);
    if (theme.darkPalette case final dark?) yield ('${theme.name} Dark', dark);
  }
}

Widget _themed(AdminPalette palette, Widget child) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: Scaffold(body: Center(child: child)),
);

class _Source implements AssetSource {
  @override
  Future<Asset?> resolve(String id) async =>
      const Asset(id: 'a', name: 'hero.jpg', swatch: Color(0xFF3A7BD5));

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult.empty;

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

void main() {
  group('comment count', () {
    for (final (name, palette) in _palettes) {
      testWidgets('$name: the count reads at 4.5:1 at rest, hovered and '
          'pressed', (tester) async {
        await tester.pumpWidget(
          _themed(palette, CommentFieldButton(count: 3, onTap: () {})),
        );
        final digits = tester.widget<Text>(find.text('3'));
        final foreground = digits.style!.color!;
        for (final (surface, label) in [
          (palette.surface, 'surface'),
          (palette.background, 'background'),
          (Color.alphaBlend(palette.hoverOverlay, palette.surface), 'hovered'),
          (
            Color.alphaBlend(palette.pressedOverlay, palette.background),
            'pressed',
          ),
        ]) {
          expect(
            contrastRatio(foreground, surface),
            greaterThanOrEqualTo(4.5),
            reason: 'digits on $label',
          );
        }
      });
    }
  });

  group('import sheet', () {
    Future<void> open(WidgetTester tester, AdminPalette palette) async {
      await tester.pumpWidget(
        _themed(
          palette,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showProviderImport(
                context,
                item: const ProviderItem(id: 'x', title: 'x'),
                providerLabel: 'Stockly',
                choosesSize: true,
                loadSizes: () async => const [
                  ProviderSize(
                    id: 's',
                    label: 'Small',
                    width: 500,
                    height: 333,
                    format: 'jpg',
                  ),
                  ProviderSize(id: 'l', label: 'Large'),
                ],
                onImport: (_) async =>
                    throw Exception('HTTP 402 Payment Required'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('sizes are radios named with their dimensions', (tester) async {
      await open(tester, irisPalette);
      expect(
        tester.getSemantics(find.text('Small')),
        isSemantics(
          label: 'Small, 500 × 333 · JPG',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Large')),
        isSemantics(label: 'Large', isChecked: false),
      );
    });

    testWidgets('a size row shows its hover over the fill', (tester) async {
      await open(tester, irisPalette);
      Color fill() {
        final box = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Large'),
                matching: find.byType(Container),
              )
              .first,
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      final rest = fill();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.text('Large')));
      addTearDown(mouse.removePointer);
      await tester.pumpAndSettle();
      expect(fill(), isNot(rest));
      expect(
        fill(),
        Color.alphaBlend(irisPalette.hoverOverlay, irisPalette.background),
      );
    });

    for (final (name, palette) in _palettes) {
      testWidgets('$name: a failed license is a danger alert in words', (
        tester,
      ) async {
        await open(tester, palette);
        await tester.tap(find.text('License & add'));
        await tester.pumpAndSettle();

        expect(find.text('Couldn’t license this image'), findsOneWidget);
        final message = find.text('That needs a paid plan or more credit.');
        expect(message, findsOneWidget);
        expect(find.textContaining('402'), findsNothing);
        final alert = tester.widget<Alert>(find.byType(Alert));
        expect(alert.severity, Severity.danger);
        expect(
          tester.getSemantics(find.byType(Alert)),
          isSemantics(isLiveRegion: true),
        );
      });
    }
  });

  group('asset editor', () {
    testWidgets('is a dialog named by its title, which keeps the label’s '
        'case, with a labelled close', (tester) async {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final cell = scope.assetRef('hero')..assetId.set('a');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
          home: Scaffold(
            body: AssetSourceScope(
              source: _Source(),
              child: LangScope(
                locales: const [
                  LocaleInfo(
                    code: 'en',
                    native: 'English',
                    status: LocaleStatus.source,
                  ),
                ],
                visibleLocales: const {'en'},
                sourceLocale: 'en',
                activeLocale: 'en',
                onVisibleLocalesChanged: (_) {},
                child: ModalAnchor(
                  child: Builder(
                    builder: (context) => TextButton(
                      onPressed: () =>
                          showAssetEditor(context, cell, label: 'Hero image'),
                      child: const Text('edit'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Hero image'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Edit Hero image')),
        isSemantics(isHeader: true),
      );
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Hero image'), findsNothing);
    });
  });
}
