// The sample under "Version history" in README.md, verbatim below the
// imports. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';

typedef Product = ({
  Map<String, String> name,
  String sku,
  int priceCents,
  List<String> tags,
});

/// What changed in a product from version [base], where it was [a], to
/// version [compare], where it is [b].
VersionDiff productDiff(
  VersionRef base,
  Product a,
  VersionRef compare,
  Product b,
) => VersionDiff.of(
  base: base,
  compare: compare,
  fields: [
    FieldDiff.translated('name', 'Name', a.name, b.name, locales: ['en', 'fr']),
    FieldDiff.text('sku', 'SKU', a.sku, b.sku),
    FieldDiff.scalar(
      'price',
      'Price',
      a.priceCents,
      b.priceCents,
      format: (cents) => '€${(cents / 100).toStringAsFixed(2)}',
    ),
    FieldDiff.scalar(
      'tags',
      'Tags',
      a.tags,
      b.tags,
      format: (t) => t.join(', '),
    ),
  ],
);
