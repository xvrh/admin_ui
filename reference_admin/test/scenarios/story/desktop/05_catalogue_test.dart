import 'package:admin_ui/widgets.dart' show ThumbnailImage;
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/keys/catalogue_keys.dart';

import '../../../support/harness.dart';

// The catalogue: the list with its views, filters, columns and stock edited
// in place; the product editor in three languages; its photos, sizes and
// peers; its history; a viewer's read-only look; and a new product.

/// The Boston fern: in three languages, with photos, sizes and five
/// versions.
const _fern = 'p-12';

/// [text] inside the control keyed [key].
Finder _in(Key key, Object text) => find.descendant(
  of: find.byKey(key),
  matching: text is IconData ? find.byIcon(text) : find.text('$text'),
);

/// Material's words as the mounted app reads them: the leave prompt's
/// cancel is Material's.
// FRICTION(F-315): the kit's own prompts take some words from Material,
// which `s.kit` does not carry.
MaterialLocalizations _material(ScenarioTester s) =>
    MaterialLocalizations.of(s.tester.element(find.byType(Navigator).first));

/// Two taps close together, which open a table cell's editor. Raw, then
/// settled: flutterware has no double-tap verb, and an `act` would name a
/// step the export does not want.
// FRICTION(T-001): no double-tap verb either.
Future<void> _doubleTap(ScenarioTester s, Object target) async {
  final at = s.tester.getCenter(s.finderFor(target));
  await s.tester.tapAt(at);
  await s.tester.pump(const Duration(milliseconds: 60));
  await s.tester.tapAt(at);
  await s.settle();
}

/// A tap on the page's title: away from the cell being edited, which saves
/// it.
Future<void> _tapAway(ScenarioTester s) => s.tap(
  find.descendant(
    of: find.byKey(CatalogueKeys.productsPage),
    matching: find.text(s.strings.shell.navProducts),
  ),
);

/// Width over height of the library picture [assetId].
double _photoAspect(Shop shop, String assetId) {
  final asset = shop.db.assets.firstWhere((a) => a.id == assetId);
  return asset.width! / asset.height!;
}

void main() {
  scenario('Browsing the catalogue', (s) async {
    final shop = await openShop(
      s,
      at: const Products(),
      shot: const Shot('Products', tags: ['tour']),
    );
    final strings = s.strings.catalogue;
    expect(find.byKey(CatalogueKeys.collection), findsOneWidget);

    await s.tap(
      _in(
        CatalogueKeys.savedViews,
        strings.savedViewName('products-low-stock', ''),
      ),
      shot: const Shot('Products · low stock'),
    );
    expect(shop.route, const Products(savedView: 'products-low-stock'));
    for (final p in shop.db.products.where((p) => p.isLowStock)) {
      expect(find.byKey(CatalogueKeys.product(p.id)), findsOneWidget);
    }

    await s.tap(_in(CatalogueKeys.savedViews, strings.allProducts));
    await s.tap(_in(CatalogueKeys.filters, strings.filterMissingArabic));
    await s.tap(
      find.text(s.kit.collection.yes).last,
      shot: const Shot('Products · missing Arabic'),
    );
    final missing = [
      for (final p in shop.db.products)
        if (p.missingLanguages.contains('ar')) p.id,
    ];
    expect(missing, hasLength(5));
    for (final id in missing) {
      expect(find.byKey(CatalogueKeys.product(id)), findsOneWidget);
    }

    await s.tap(CatalogueKeys.columns, shot: const Shot('Products · columns'));
    await s.tap(find.text(strings.colUpdated).last);
    await s.tap(CatalogueKeys.columns);

    final row = missing.first;
    final before = shop.db.productById(row).stock;
    shop.calls.clear();
    await _doubleTap(s, CatalogueKeys.stock(row));
    expect(shop.route, const Products());
    await s.enterText(
      CatalogueKeys.stockEditor,
      '42',
      shot: const Shot('Products · editing stock'),
    );
    await _tapAway(s);
    expect(before, isNot(42));
    expect(shop.calls.countOf(Endpoint.patchStock), 1);
    expect(shop.db.productById(row).stock, 42);

    // A count the shop refuses goes back on the row.
    await _doubleTap(s, CatalogueKeys.stock(row));
    await s.enterText(CatalogueKeys.stockEditor, '-3');
    await _tapAway(s);
    expect(shop.calls.countOf(Endpoint.patchStock), 2);
    expect(shop.db.productById(row).stock, 42);
    expect(_in(CatalogueKeys.stock(row), '42'), findsOneWidget);
  });

  scenario('Editing a product', (s) async {
    final shop = await openShop(
      s,
      at: const ProductDetail(_fern),
      shot: const Shot('Product', tags: ['tour']),
    );
    final strings = s.strings.catalogue;
    final revisions = shop.db.revisions[_fern]!.length;

    await s.tap(
      _in(CatalogueKeys.localeTabs, 'FR'),
      shot: const Shot('Product · French copy'),
    );
    await s.tap(
      _in(CatalogueKeys.localeTabs, 'AR'),
      shot: const Shot('Product · Arabic copy'),
    );
    const arabic = 'سرخس كثيف الأوراق يحب الضوء غير المباشر والهواء الرطب.';
    await s.enterText(
      CatalogueKeys.description,
      arabic,
      shot: const Shot('Product · unsaved changes'),
    );

    await navTo(
      s,
      Nav.dashboard,
      shot: const Shot('Product · leave without saving?'),
    );
    await s.tap(find.text(_material(s).cancelButtonLabel));
    expect(shop.route, const ProductDetail(_fern));

    shop.calls.clear();
    // A valid SKU, corrected at once: the check waits for the typing to
    // pause and asks about the last one only. Its debounce draws no frame:
    // two frames photograph it pending.
    await typeValues(
      s,
      CatalogueKeys.sku,
      ['PS-010', 'PS-0101', 'PS-010', 'PS-0100'],
      shot: const Shot('Product · checking SKU'),
      settle: const Settle.frames(2),
    );
    await s.wait(const Duration(seconds: 1));
    expect(shop.calls.countOf(Endpoint.skuAvailable), 1);
    expect(shop.calls.all.last.args['sku'], 'PS-0100');

    await s.tap(_in(CatalogueKeys.localeTabs, 'EN'));
    await s.enterText(CatalogueKeys.name, '');
    await s.enterText(
      CatalogueKeys.compareAt,
      '10',
      shot: const Shot('Product · two fields need attention'),
    );

    await s.enterText(CatalogueKeys.name, 'Boston fern');
    await s.enterText(CatalogueKeys.compareAt, '29.50');

    await s.split({
      'it saves': () async {
        await s.tap(
          _in(CatalogueKeys.saveBar, strings.save),
          shot: const Shot('Product · saved'),
        );
        expect(shop.calls.countOf(Endpoint.saveProduct), 1);
        final saved = shop.db.productById(_fern);
        expect(saved.sku, 'PS-0100');
        expect(saved.description['ar'], arabic);
        expect(saved.compareAtCents, 2950);
        expect(shop.db.revisions[_fern], hasLength(revisions + 1));
        expect(shop.route, const ProductDetail(_fern));
      },
      'the SKU is taken': () async {
        shop.faults.failNext(
          Endpoint.saveProduct,
          const ShopError.validation({'sku': ValidationCodes.taken}),
        );
        await s.tap(
          _in(CatalogueKeys.saveBar, strings.save),
          shot: const Shot('Product · SKU already used'),
        );
        expect(_in(CatalogueKeys.sku, strings.skuTaken), findsOneWidget);
        expect(shop.db.revisions[_fern], hasLength(revisions));
        expect(shop.db.productById(_fern).sku, isNot('PS-0100'));
      },
    });
  });

  scenario('Signing out with unsaved edits', (s) async {
    final shop = await openShop(s, at: const ProductDetail(_fern));
    const edited = 'Boston fern, large';
    final name = find.descendant(
      of: find.byKey(CatalogueKeys.name),
      matching: find.byType(EditableText),
    );
    await s.enterText(name, edited);

    await s.tap(ShellKeys.userMenu);
    await s.tap(
      find.text(s.strings.shell.signOut),
      shot: const Shot('Product · sign out with unsaved edits?'),
    );
    // Signing out leaves the page like any other way out: it asks first.
    expect(find.text(_material(s).cancelButtonLabel), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.signOut), 0);

    await s.tap(find.text(_material(s).cancelButtonLabel));
    expect(shop.route, const ProductDetail(_fern));
    expect(shop.api.currentStaff, isNotNull);
    expect(shop.calls.countOf(Endpoint.signOut), 0);
    expect(s.tester.widget<EditableText>(name).controller.text, edited);
  });

  scenario('Photos and variants', (s) async {
    final shop = await openShop(s, at: const ProductDetail(_fern));
    final strings = s.strings.catalogue;
    final photos = shop.db.productById(_fern).photoIds;
    final pot = shop.db.assets.firstWhere(
      (a) => a.name == 'planter-on-a-windowsill.png',
    );

    await s.scrollTo(CatalogueKeys.photos);
    await s.tap(
      _in(CatalogueKeys.photos, Icons.add),
      shot: const Shot('Product · choose photos'),
    );
    await s.tap(find.text(pot.name));
    await s.tap(
      find.text(s.kit.assets.select),
      shot: const Shot('Product · photos added'),
    );

    await s.tap(
      find
          .descendant(
            of: find.byKey(CatalogueKeys.photos),
            matching: find.byType(ThumbnailImage),
          )
          .first,
    );
    await s.tap(
      find.text(s.kit.assets.editCrop),
      shot: const Shot('Product · crop photo'),
    );
    await s.tap(find.text('1:1'));
    await s.tap(find.text(s.kit.apply));
    await s.tap(find.text(s.kit.assets.done));

    await s.scrollTo(_in(CatalogueKeys.variants, strings.addVariant));
    await s.tap(_in(CatalogueKeys.variants, strings.addVariant));
    final row = find.descendant(
      of: find.byKey(CatalogueKeys.variants),
      matching: find.byType(EditableText),
    );
    await s.enterText(row.at(8), '24 cm');
    await s.enterText(row.at(9), 'XL');
    await s.enterText(row.at(10), '18');
    await s.enterText(row.at(11), '3', shot: const Shot('Product · variants'));

    await s.scrollTo(CatalogueKeys.description);
    expect(_in(CatalogueKeys.description, 'Samir'), findsNothing);
    await s.act(
      'Product · someone else is here',
      () => shop.api.simulate.peerJoins(_fern),
    );
    expect(find.byKey(CatalogueKeys.presence), findsOneWidget);
    expect(_in(CatalogueKeys.description, 'Samir'), findsOneWidget);

    await s.tap(_in(CatalogueKeys.saveBar, strings.save));
    final saved = shop.db.productById(_fern);
    expect(saved.photoIds, [...photos, pot.id]);
    final crop = saved.photoCrops[photos.first]!;
    expect(
      (crop.right - crop.left) * _photoAspect(shop, photos.first),
      moreOrLessEquals(crop.bottom - crop.top, epsilon: 0.01),
      reason: 'the first photo is kept cropped square',
    );
    expect(saved.variants, hasLength(3));
    expect(saved.variants.last.size, '24 cm');
    expect(saved.variants.last.priceDeltaCents, 1800);
  });

  scenario('What changed, and undoing it', (s) async {
    final shop = await openShop(
      s,
      at: const ProductDetail(_fern, tab: ProductTab.history),
      shot: const Shot('Product history'),
    );
    final strings = s.strings.catalogue;
    final before = [...shop.db.revisions[_fern]!];
    expect(before, hasLength(5));

    await s.tap(
      // The timeline words its number chip like the label in some
      // languages; the label comes first.
      _in(CatalogueKeys.timeline, strings.versionLabel('2')).first,
      shot: const Shot('Product history · diff'),
    );
    await s.tap(
      _in(CatalogueKeys.diff, strings.restore).first,
      shot: const Shot('Product history · restore?'),
    );
    await s.tap(
      find.text(strings.restore).last,
      shot: const Shot('Product · restored'),
    );
    expect(shop.calls.countOf(Endpoint.restoreRevision), 1);
    final after = shop.db.revisions[_fern]!;
    expect(after, hasLength(6));
    for (final (i, r) in before.indexed) {
      expect(identical(after[i], r), isTrue, reason: 'version ${r.version}');
    }
    final restored = shop.db.productById(_fern);
    expect(restored.revision, 6);
    expect(restored.priceCents, before[1].snapshot.priceCents);
    expect(shop.route, const ProductDetail(_fern));
  });

  scenario('A viewer can look but not edit', (s) async {
    final shop = await openShop(
      s,
      as: Role.viewer,
      at: const ProductDetail(_fern),
      shot: const Shot('Product · read-only'),
    );
    expect(find.byKey(CatalogueKeys.readOnly), findsOneWidget);
    expect(find.byKey(CatalogueKeys.saveBar), findsNothing);
    expect(find.text(s.strings.catalogue.save), findsNothing);
    expect(shop.calls.countOf(Endpoint.saveProduct), 0);
    expect(shop.calls.countOf(Endpoint.patchStock), 0);

    await s.scrollTo(CatalogueKeys.photos);
    expect(_in(CatalogueKeys.photos, Icons.add), findsNothing);
    await s.tap(
      find
          .descendant(
            of: find.byKey(CatalogueKeys.photos),
            matching: find.byType(ThumbnailImage),
          )
          .first,
    );
    // A read-only gallery opens no editor.
    expect(find.text(s.kit.assets.editCrop), findsNothing);
  });

  scenario('Adding a product', (s) async {
    final shop = await openShop(
      s,
      at: const NewProduct(),
      shot: const Shot('New product'),
    );
    final strings = s.strings.catalogue;
    final count = shop.db.products.length;

    await s.tap(
      find.text(strings.create),
      shot: const Shot('New product · fix the highlighted fields'),
    );
    expect(shop.calls.countOf(Endpoint.createProduct), 0);

    await s.enterText(CatalogueKeys.newName, 'Kentia palm');
    await s.enterText(CatalogueKeys.newSku, 'PS-0061');
    await s.tap(CatalogueKeys.newCategory);
    await s.tap(find.text(shop.db.categories.first.name[s.language]!).last);
    await s.enterText(CatalogueKeys.newPrice, '39.90');
    await s.enterText(CatalogueKeys.newStock, '8');
    await s.tap(
      find.text(strings.create),
      shot: const Shot('New product · created'),
    );
    expect(shop.calls.countOf(Endpoint.createProduct), 1);
    expect(shop.db.products, hasLength(count + 1));
    final created = shop.db.products.last;
    expect(created.sku, 'PS-0061');
    expect(created.name, {'en': 'Kentia palm'});
    expect(shop.route, ProductDetail(created.id));
  });
}
