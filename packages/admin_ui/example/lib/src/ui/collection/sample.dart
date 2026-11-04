import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Shared fake content for the Collection demos (states, cells, selection,
/// pagination). Plain data — the demos pass it into the pure [CollectionTable].
class Product {
  final int id;
  final String name;
  final String sku;
  final Color swatch;
  final String status;
  final Severity tone;
  final String category;
  final double price;
  final int? stock;
  final String author;
  final String updated;
  final DateTime updatedAt;
  final Map<String, LocaleStatus?> locales;
  final List<String> tags;
  final bool featured;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.swatch,
    required this.status,
    required this.tone,
    required this.category,
    required this.price,
    required this.stock,
    required this.author,
    required this.updated,
    required this.updatedAt,
    required this.locales,
    required this.tags,
    required this.featured,
  });
}

const _names = [
  'Aurora Wool Coat',
  'Trailhead Boots — waterproof full-grain leather',
  'Cedar Throw Blanket',
  'Summit Daypack',
  'Linen Camp Shirt',
  'Harbor Wool Socks',
  'Meridian Rain Shell',
  'Drift Merino Beanie',
  'Cove Canvas Tote',
  'Ridgeline Fleece',
];
const _statuses = [
  ('Published', Severity.success),
  ('Draft', Severity.info),
  ('Needs review', Severity.warning),
  ('Archived', Severity.danger),
];
const _categories = ['Apparel', 'Footwear', 'Accessories', 'Home', 'Outdoor'];
const _authors = ['Ada Lovelace', 'Alan Turing', 'Grace Hopper', 'Linus T.'];
const _swatches = [
  Color(0xFF5b5bd6),
  Color(0xFF2f9e63),
  Color(0xFFcf8a00),
  Color(0xFFd24b3e),
  Color(0xFF4EABFB),
];
const _localeSets = <Map<String, LocaleStatus?>>[
  {'en': LocaleStatus.source, 'fr': LocaleStatus.translated, 'de': null},
  {
    'en': LocaleStatus.source,
    'fr': LocaleStatus.translated,
    'de': LocaleStatus.outdated,
  },
  {'en': LocaleStatus.missing, 'fr': null, 'de': null},
];
const _tagSets = <List<String>>[
  ['new', 'seasonal'],
  ['bestseller'],
  ['clearance', 'limited', 'web-only'],
  [],
];

List<Product> sampleProducts(int n) => List.generate(n, (i) {
  final s = _statuses[i % _statuses.length];
  return Product(
    id: 1000 + i,
    name: _names[i % _names.length],
    sku: 'SKU-${(9000 + i).toRadixString(36).toUpperCase()}',
    swatch: _swatches[i % _swatches.length],
    status: s.$1,
    tone: s.$2,
    category: _categories[i % _categories.length],
    price: ((i * 37) % 9000) / 100 + 19.99,
    stock: i % 6 == 0 ? null : (i * 13) % 500,
    author: _authors[i % _authors.length],
    updated: '2026-0${(i % 9) + 1}-${'${(i % 27) + 1}'.padLeft(2, '0')}',
    updatedAt: DateTime(2026, (i % 9) + 1, (i % 27) + 1),
    locales: _localeSets[i % _localeSets.length],
    tags: _tagSets[i % _tagSets.length],
    featured: i % 3 == 0,
  );
});

/// A thumb + name + SKU identity cell from a [Product].
Widget productIdentity(Product p) => TableIdentity(
  leading: TableThumb(color: p.swatch, size: 32),
  title: p.name,
  subtitle: p.sku,
);

/// Full-bleed demo frame: optional [controls] row, a bordered card holding the
/// [table] and an optional [footer] (pager).
Widget collectionFrame(
  BuildContext context, {
  Widget? controls,
  required Widget table,
  Widget? footer,
}) {
  return Scaffold(
    backgroundColor: context.colors.background,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controls != null)
          Padding(padding: const EdgeInsets.all(24), child: controls),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, controls == null ? 24 : 0, 24, 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(context.radii.radiusLarge),
                border: Border.all(color: context.colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.radii.radiusLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: table),
                    ?footer,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// [products] as the in-memory source every collection demo fetches from: the
/// fields their columns sort on and their filter bars edit, with the search box
/// looking in name and SKU.
LocalCollectionSource<Product> productSource(List<Product> products) =>
    LocalCollectionSource(
      products,
      fields: {
        'name': (p) => p.name,
        'sku': (p) => p.sku,
        'status': (p) => p.status,
        'category': (p) => p.category,
        'price': (p) => p.price,
        'stock': (p) => p.stock,
        'author': (p) => p.author,
        'updated': (p) => p.updatedAt,
        'featured': (p) => p.featured,
      },
      searchFields: const {'name', 'sku'},
    );
