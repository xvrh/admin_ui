import 'package:admin_ui/assets.dart' show CropValue;
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/l10n.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../l10n/ref_strings.dart';

/// The product editor's cells, as typed handles over a [FormScope].
extension type ProductCells(FormScope _s) {
  TranslatedCell<String> get name => _s.translated('name');
  TranslatedCell<String> get description => _s.translated('description');
  ValueCell<String> get sku => _s.text('sku');
  ValueCell<double> get price => _s.decimal('price');
  ValueCell<double?> get compareAt => _s.decimalOrNull('compareAt');
  ValueCell<int> get stock => _s.number('stock');
  ValueCell<int> get lowStockAt => _s.number('lowStockAt');
  ValueCell<String> get category => _s.text('category');
  ValueCell<ProductStatus> get status => _s.enumCell(
    'status',
    encode: (s) => s.name,
    decode: ProductStatus.values.byName,
    fallback: ProductStatus.draft,
  );
  ValueCell<List<String>> get tags => _s.list('tags');

  /// One supplier, as the one-element id list `ReferenceField` edits.
  // FRICTION(F-304): ReferenceField edits a list; a single reference is a
  // list of at most one.
  ValueCell<List<String>> get supplier => _s.list('supplier');
  ValueCell<bool> get featured => _s.boolean('featured');
  ValueCell<DateTime?> get availableFrom => _s.dateOrNull('availableFrom');
  ValueCell<String> get labelColor => _s.text('labelColor');

  ValueCell<Map<String, String>> get care => _s.map('care');
  RecordListCell<VariantCells> get variants =>
      _s.recordList('variants', build: VariantCells.new);
  RecordListCell<PhotoCells> get photos =>
      _s.recordList('photos', build: PhotoCells.new);

  /// [base] with the cells' values: what a save sends.
  Product apply(Product base) => base.copyWith(
    name: _translated(name),
    description: _translated(description),
    sku: sku.value.trim(),
    priceCents: (price.value * 100).round(),
    compareAtCents: () => switch (compareAt.value) {
      final v? => (v * 100).round(),
      null => null,
    },
    stock: stock.value,
    lowStockAt: lowStockAt.value,
    categoryId: category.value,
    status: status.value,
    tags: tags.value,
    supplierId: supplier.value.firstOrNull ?? '',
    featured: featured.value,
    availableFrom: () => availableFrom.value,
    labelColor: _argbOf(labelColor.value) ?? base.labelColor,
    care: care.value,
    variants: [for (final v in variants.elements) v.toVariant()],
    photoIds: [for (final p in photos.elements) ?p.image.assetId.value],
    photoCrops: {
      for (final p in photos.elements)
        if ((p.image.assetId.value, p.image.crop.value)
            case (final id?, final crop?) when crop != CropValue.full)
          id: photoCropOf(crop),
    },
  );

  /// Sets every cell from [product].
  void fill(Product product) {
    for (final language in shopLanguages) {
      name.lane(language).set(product.name[language] ?? '');
      description.lane(language).set(product.description[language] ?? '');
    }
    sku.set(product.sku);
    price.set(product.priceCents / 100);
    compareAt.set(switch (product.compareAtCents) {
      final c? => c / 100,
      null => null,
    });
    stock.set(product.stock);
    lowStockAt.set(product.lowStockAt);
    category.set(product.categoryId);
    status.set(product.status);
    tags.set(product.tags);
    supplier.set([if (product.supplierId.isNotEmpty) product.supplierId]);
    featured.set(product.featured);
    availableFrom.set(product.availableFrom);
    labelColor.set(_hexOf(product.labelColor));
    care.set(product.care);
    _resize(variants, product.variants.length);
    for (final (i, v) in product.variants.indexed) {
      variants.elements[i].fill(v);
    }
    _resize(photos, product.photoIds.length);
    for (final (i, id) in product.photoIds.indexed) {
      photos.elements[i].image.assetId.set(id);
      photos.elements[i].image.crop.set(switch (product.photoCrops[id]) {
        final crop? => cropValueOf(crop),
        null => null,
      });
    }
  }

  /// The languages whose name or description differs from [base].
  Set<String> changedLanguages(Product base) => {
    for (final language in shopLanguages)
      if (name.lane(language).value != (base.name[language] ?? '') ||
          description.lane(language).value !=
              (base.description[language] ?? ''))
        language,
  };

  static Translated _translated(TranslatedCell<String> cell) => {
    for (final language in shopLanguages)
      if (cell.lane(language).value.trim() case final text when text.isNotEmpty)
        language: text,
  };
}

extension type VariantCells(RecordScope _e) {
  ValueCell<String> get size => _e.text('size');
  ValueCell<String> get skuSuffix => _e.text('skuSuffix');
  ValueCell<double> get priceDelta => _e.decimal('priceDelta');
  ValueCell<int> get stock => _e.number('stock');

  Variant toVariant() => Variant(
    size: size.value.trim(),
    skuSuffix: skuSuffix.value.trim(),
    priceDeltaCents: (priceDelta.value * 100).round(),
    stock: stock.value,
  );

  void fill(Variant v) {
    size.set(v.size);
    skuSuffix.set(v.skuSuffix);
    priceDelta.set(v.priceDeltaCents / 100);
    stock.set(v.stock);
  }
}

extension type PhotoCells(RecordScope _e) {
  AssetRefCell get image => _e.assetRef('image');
}

/// The shop's record of [crop].
PhotoCrop photoCropOf(CropValue crop) => PhotoCrop(
  left: crop.rect.left,
  top: crop.rect.top,
  right: crop.rect.right,
  bottom: crop.rect.bottom,
  focal: switch (crop.focal) {
    final f? => (f.dx, f.dy),
    null => null,
  },
  quarterTurns: crop.quarterTurns,
  flipH: crop.flipH,
  flipV: crop.flipV,
  angle: crop.angle,
);

/// The cropper's value for the shop's [crop].
CropValue cropValueOf(PhotoCrop crop) => CropValue(
  rect: Rect.fromLTRB(crop.left, crop.top, crop.right, crop.bottom),
  focal: switch (crop.focal) {
    (final x, final y) => Offset(x, y),
    null => null,
  },
  quarterTurns: crop.quarterTurns,
  flipH: crop.flipH,
  flipV: crop.flipV,
  angle: crop.angle,
);

void _resize(RecordListCell<Object?> list, int length) {
  while (list.elements.length > length) {
    list.removeAt(list.elements.length - 1);
  }
  while (list.elements.length < length) {
    list.add();
  }
}

String _hexOf(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int? _argbOf(String hex) {
  final digits = hex.trim().replaceFirst('#', '');
  if (digits.length != 6) return null;
  final rgb = int.tryParse(digits, radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}

/// SKUs read `PS-` and four digits.
final skuPattern = RegExp(r'^PS-\d{4}$');

/// The app's catalogue strings in the language [l10n] words the kit's
/// messages in: a custom validator is handed the kit's strings only.
// FRICTION(F-309): a FieldValidator gets AdminLocalizations, so an app's own
// message is looked up again by the kit's locale name.
CatalogueStrings _stringsOf(AdminLocalizations l10n) =>
    RefStrings.lookup(Locale(l10n.localeName)).catalogue;

/// A SKU that is not `PS-` and four digits.
String? checkSkuFormat(String sku, AdminLocalizations l10n) =>
    sku.trim().isEmpty || skuPattern.hasMatch(sku.trim())
    ? null
    : _stringsOf(l10n).skuFormat;

/// What a valid product is. [skuAvailable] asks the shop whether a SKU is
/// free, and [strings] words its answer in the page's language.
Iterable<ValidationRule> productRules(
  ProductCells f, {
  required Future<bool> Function(String sku) skuAvailable,
  required CatalogueStrings Function() strings,
}) => [
  FieldRules<String>(
    f.name,
    lanes: const ['en'],
    validators: [Validators.required(), Validators.maxLength(80)],
  ),
  FieldRules<String>(
    f.sku,
    validators: [Validators.required(), checkSkuFormat],
    asyncValidators: [
      (String sku) async =>
          await skuAvailable(sku.trim()) ? null : strings().skuTaken,
    ],
  ),
  FieldRules<double>(
    f.price,
    validators: [Validators.required(), Validators.min(0.01)],
  ),
  FormRule(
    watch: [f.price, f.compareAt],
    target: f.compareAt,
    check: (l10n) => switch (f.compareAt.value) {
      final c? when c <= f.price.value => _stringsOf(l10n).compareAtTooLow,
      _ => null,
    },
  ),
  FieldRules<int>(
    f.stock,
    validators: [Validators.required(), Validators.min(0)],
  ),
  FieldRules<int>(
    f.lowStockAt,
    validators: [Validators.required(), Validators.min(0)],
  ),
  FieldRules<String>(f.category, validators: [Validators.required()]),
  for (final v in f.variants.elements)
    FieldRules<String>(v.size, validators: [Validators.required()]),
];
