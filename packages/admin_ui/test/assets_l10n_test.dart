import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _assets = [
  Asset(id: 'a', name: 'hero.jpg', width: 1920, height: 1080),
  Asset(id: 'b', name: 'logo.png', width: 512, height: 512),
  Asset(id: 'c', name: 'spec.pdf', type: AssetType.document, bytes: 1500000),
];

/// A tool button's tip. material_ui's Tooltip is not the one flutter_test's
/// byTooltip knows.
Finder _tip(String message) =>
    find.byWidgetPredicate((w) => w is Tooltip && w.message == message);

Widget _host(Widget child, {Locale locale = const Locale('fr')}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 640, height: 560, child: child),
    ),
  ),
);

class _Source implements AssetSource {
  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => const AssetBrowseResult([], 0);

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
  group('the library speaks French', () {
    testWidgets('its states, toolbar and footer', (tester) async {
      await tester.pumpWidget(
        _host(const AssetLibrary(assets: [], loading: true)),
      );
      expect(find.text('Chargement des médias…'), findsOneWidget);

      await tester.pumpWidget(
        _host(const AssetLibrary(assets: [], query: 'zzz')),
      );
      expect(find.text('Aucun média correspondant'), findsOneWidget);
      expect(
        find.text('Essayez une autre recherche ou un autre filtre.'),
        findsOneWidget,
      );
      expect(find.text('Rechercher des médias'), findsOneWidget);
      expect(find.text('Tous les types'), findsOneWidget);

      await tester.pumpWidget(
        _host(const AssetLibrary(assets: [], error: 'hors ligne')),
      );
      expect(find.text('Impossible de charger les médias'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          AssetLibrary(
            assets: _assets,
            view: AssetView.list,
            total: 40,
            selectionMode: AssetSelectionMode.multiple,
            selected: const {'a', 'b'},
            onToggle: (_) {},
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      expect(find.text('3 sur 40 médias'), findsOneWidget);
      expect(find.text('2 sélectionnés'), findsOneWidget);
      expect(find.text('Sélectionner'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget, reason: 'Material’s');
      // Sizes and dimensions in the app's locale.
      expect(find.text('1,5 Mo'), findsOneWidget);
      expect(find.textContaining('1920 × 1080'), findsOneWidget);
    });

    testWidgets('an empty pick reads as nothing selected', (tester) async {
      await tester.pumpWidget(
        _host(
          AssetLibrary(
            assets: _assets,
            selectionMode: AssetSelectionMode.single,
            onToggle: (_) {},
            onConfirm: () {},
          ),
        ),
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });
  });

  testWidgets('without the delegate the library stays in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: const Scaffold(body: AssetLibrary(assets: [], loading: true)),
      ),
    );
    expect(find.text('Loading assets…'), findsOneWidget);
  });

  group('the asset editor', () {
    Future<void> open(WidgetTester tester, Locale locale) async {
      final cell = LocalScope().assetRef('hero');
      await tester.pumpWidget(
        _host(
          locale: locale,
          AssetSourceScope(
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
                        showAssetEditor(context, cell, label: 'Image Hero'),
                    child: const Text('edit'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('edit'));
      await tester.pumpAndSettle();
    }

    for (final (locale, title, done) in const [
      (Locale('en'), 'Edit Image Hero', 'Done'),
      (Locale('fr'), 'Modifier : Image Hero', 'Terminé'),
      (Locale('ar'), 'تعديل: Image Hero', 'تم'),
    ]) {
      testWidgets('places the field label as given in $locale', (tester) async {
        await open(tester, locale);
        expect(find.text(title), findsOneWidget);
        expect(find.text(done), findsOneWidget);
      });
    }

    test('editItem is a placeholder in every language', () {
      for (final strings in const <AssetsMessages>[
        AssetsMessagesEn(),
        AssetsMessagesFr(),
        AssetsMessagesAr(),
      ]) {
        expect(strings.editItem('Hero IMAGE'), contains('Hero IMAGE'));
      }
    });
  });

  group('licensing', () {
    test('counts downloads with all six Arabic plural forms', () {
      const ar = AssetsMessagesAr();
      final forms = {
        for (final n in [0, 1, 2, 3, 11, 100]) n: ar.licenseNotice(n),
      };
      expect(forms[0], contains('دون استخدام أي تنزيل'));
      expect(forms[1], endsWith('تنزيلًا واحدًا'));
      expect(forms[2], endsWith('تنزيلين'));
      expect(forms[3], endsWith('3 تنزيلات'));
      expect(forms[11], endsWith('11 تنزيلًا'));
      expect(forms[100], endsWith('100 تنزيل'));
      expect(forms.values.toSet(), hasLength(6));
    });

    test('English and French pick the singular for one download', () {
      expect(
        const AssetsMessagesEn().licenseNotice(1),
        'Licensing adds it to your library and uses 1 download',
      );
      expect(
        const AssetsMessagesEn().licenseNotice(3),
        endsWith('3 downloads'),
      );
      expect(
        const AssetsMessagesFr().licenseNotice(1),
        endsWith('1 téléchargement'),
      );
      expect(
        const AssetsMessagesFr().licenseDetail('Stockly', 2),
        'Ajoute l’image à votre médiathèque et utilise 2 téléchargements de '
        'votre forfait Stockly.',
      );
    });

    testWidgets('the provider browser shows the Arabic notice once picked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          locale: const Locale('ar'),
          ProviderBrowser(
            providerLabel: 'Stockly',
            items: const [ProviderItem(id: 'p1', title: 'Dunes')],
            total: 12,
            selectedId: 'p1',
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      expect(
        find.text('يضيفها الترخيص إلى مكتبتك ويستخدم تنزيلًا واحدًا'),
        findsOneWidget,
      );
      expect(find.text('استخدام الصورة'), findsOneWidget);
      expect(find.text('1 من 12 نتيجة'), findsOneWidget);
      expect(find.text('البحث في Stockly'), findsOneWidget);
    });
  });

  group('accepted files', () {
    testWidgets('the hint and the refusals follow the app', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      const accept = AssetAccept(
        mimeTypes: {'image/*'},
        maxBytes: 10 * 1000 * 1000,
      );
      expect(accept.hintOf(context), 'Images uniquement · jusqu’à 10 Mo');
      expect(
        accept.describeRefusals(const [
          AssetRefusal('a.docx', AssetRefusalReason.type),
          AssetRefusal('b.zip', AssetRefusalReason.type),
        ], context),
        'Impossible d’ajouter a.docx, b.zip : ce ne sont pas des images.',
      );
      expect(
        accept.describeRefusals(const [
          AssetRefusal('a.docx', AssetRefusalReason.type),
          AssetRefusal('big.png', AssetRefusalReason.size),
        ], context),
        'Impossible d’ajouter a.docx (pas une image), big.png (plus de '
        '10 Mo).',
      );
    });
  });

  group('the cropper', () {
    testWidgets('names its tools and its free ratio in French', (tester) async {
      await tester.pumpWidget(
        _host(
          ImageCropper(
            image: MemoryImage(Uint8List(0)),
            imageAspect: 1.5,
            onChanged: (_) {},
            aspectPresets: AspectPreset.defaults,
            onAspectChanged: (_) {},
            allowRotate: true,
            allowFlip: true,
            allowReset: true,
            allowStraighten: true,
          ),
        ),
      );
      expect(find.text('Libre'), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);
      expect(find.text('Redresser'), findsOneWidget);
      expect(_tip('Faire pivoter à gauche'), findsOneWidget);
      expect(_tip('Retourner verticalement'), findsOneWidget);
      expect(_tip('Réinitialiser'), findsOneWidget);
    });

    testWidgets('mirrors its toolbar in Arabic but not its straighten axis', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          locale: const Locale('ar'),
          ImageCropper(
            image: MemoryImage(Uint8List(0)),
            imageAspect: 1.5,
            onChanged: (_) {},
            aspectPresets: AspectPreset.defaults,
            onAspectChanged: (_) {},
            allowRotate: true,
            allowStraighten: true,
          ),
        ),
      );
      final free = tester.getRect(find.text('حر'));
      final rotate = tester.getRect(_tip('تدوير لليسار'));
      expect(free.left, greaterThan(rotate.right), reason: 'presets at start');
      final slider = find.byType(ValueSlider);
      expect(
        Directionality.of(tester.element(slider)),
        TextDirection.ltr,
        reason: 'the angle turns with the image, which never mirrors',
      );
      expect(
        tester.getRect(find.text('تعديل الميل')).left,
        greaterThan(tester.getRect(slider).right),
        reason: 'the label still leads the row',
      );
    });
  });

  testWidgets('a picked tile shows its check at the top end', (tester) async {
    Future<Rect> check(Locale locale) async {
      await tester.pumpWidget(
        _host(
          locale: locale,
          UnconstrainedBox(
            alignment: AlignmentDirectional.topStart,
            constrainedAxis: Axis.vertical,
            child: SizedBox(
              width: 150,
              child: MediaTile(
                thumbnail: const MediaThumb(swatch: Color(0xFF2266AA)),
                title: 'hero.jpg',
                selected: true,
                check: MediaTileCheck.selected,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      final tile = tester.getRect(find.byType(MediaTile));
      final disc = tester.getRect(find.byIcon(Icons.check));
      return disc.shift(-tile.topLeft);
    }

    final ltr = await check(const Locale('en'));
    final rtl = await check(const Locale('ar'));
    expect(ltr.center.dx, greaterThan(75));
    expect(rtl.center.dx, lessThan(75));
    expect(rtl.center.dx, moreOrLessEquals(150 - ltr.center.dx));
    expect(rtl.top, ltr.top);
  });
}
