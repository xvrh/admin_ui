import 'package:admin_ui/history.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/widgets.dart' show presenceInitials;
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import 'catalogue_widgets.dart';

/// The keys [productDiff] files each field under: what a per-field restore
/// is handed back.
abstract final class DiffKeys {
  static const name = 'name';
  static const description = 'description';
  static const sku = 'sku';
  static const price = 'price';
  static const compareAt = 'compareAt';
  static const stock = 'stock';
  static const status = 'status';
  static const category = 'category';
  static const tags = 'tags';
  static const featured = 'featured';
  static const care = 'care';
  static const variants = 'variants';
  static const photos = 'photos';
}

/// [revision] as the timeline shows it; [current] marks the newest.
VersionRef versionRef(
  BuildContext context,
  ProductRevision revision, {
  required bool current,
}) {
  final strings = context.strings.catalogue;
  final n = context.adminFormats.integer(revision.version);
  return VersionRef(
    id: 'v${revision.version}',
    label: strings.versionLabel(n),
    author: revision.by,
    initials: presenceInitials(revision.by),
    timestamp: formatDateTime(context, revision.at),
    status: current ? VersionStatus.current : VersionStatus.archived,
    number: revision.version,
  );
}

/// What changed from [base] to [compare], field by field, words in the
/// page's language.
VersionDiff productDiff(
  BuildContext context, {
  required ProductRevision base,
  required ProductRevision compare,
  required bool compareIsCurrent,
  required CatalogueLookups lookups,
}) {
  final strings = context.strings.catalogue;
  final formats = context.adminFormats;
  final yesNo = context.adminL10n.collection;
  final language = Localizations.localeOf(context).languageCode;
  final a = base.snapshot;
  final b = compare.snapshot;
  String money(int cents) => formatMoney(context, cents);

  return VersionDiff.of(
    base: versionRef(context, base, current: false),
    compare: versionRef(context, compare, current: compareIsCurrent),
    fields: [
      FieldDiff.translated(
        DiffKeys.name,
        strings.fieldName,
        a.name,
        b.name,
        locales: shopLanguages,
      ),
      FieldDiff.translated(
        DiffKeys.description,
        strings.fieldDescription,
        a.description,
        b.description,
        locales: shopLanguages,
      ),
      FieldDiff.scalar(DiffKeys.sku, strings.fieldSku, a.sku, b.sku),
      FieldDiff.scalar(
        DiffKeys.price,
        strings.fieldPrice,
        a.priceCents,
        b.priceCents,
        format: money,
      ),
      FieldDiff.scalar(
        DiffKeys.compareAt,
        strings.fieldCompareAt,
        a.compareAtCents,
        b.compareAtCents,
        format: money,
      ),
      FieldDiff.scalar(
        DiffKeys.stock,
        strings.stockField,
        a.stock,
        b.stock,
        format: formats.integer,
      ),
      FieldDiff.scalar(
        DiffKeys.status,
        strings.fieldStatus,
        a.status,
        b.status,
        format: context.strings.shell.productStatus,
        kind: DiffFieldKind.choice,
      ),
      FieldDiff.scalar(
        DiffKeys.category,
        strings.fieldCategory,
        a.categoryId,
        b.categoryId,
        format: (id) => lookups.categoryName(id, language),
        kind: DiffFieldKind.choice,
      ),
      FieldDiff.scalar(
        DiffKeys.tags,
        strings.fieldTags,
        a.tags,
        b.tags,
        format: (tags) => tags.join(', '),
      ),
      FieldDiff.scalar(
        DiffKeys.featured,
        strings.fieldFeatured,
        a.featured,
        b.featured,
        format: (featured) => featured ? yesNo.yes : yesNo.no,
      ),
      FieldDiff.scalar(
        DiffKeys.care,
        strings.fieldCare,
        a.care,
        b.care,
        format: (care) =>
            [for (final e in care.entries) '${e.key}: ${e.value}'].join(' · '),
      ),
      FieldDiff.scalar(
        DiffKeys.variants,
        strings.fieldVariants,
        a.variants,
        b.variants,
        format: (variants) => [
          for (final v in variants)
            '${v.size} (${money(v.priceDeltaCents)}, ${formats.integer(v.stock)})',
        ].join(' · '),
      ),
      FieldDiff.scalar(
        DiffKeys.photos,
        strings.photosCount,
        a.photoIds,
        b.photoIds,
        format: (ids) => formats.integer(ids.length),
        kind: DiffFieldKind.media,
      ),
    ],
  );
}

/// [product] with the field [key] taken back from [base]: a restore of one
/// part of a version.
Product withFieldOf(Product product, Product base, String key) => switch (key) {
  DiffKeys.name => product.copyWith(name: base.name),
  DiffKeys.description => product.copyWith(description: base.description),
  DiffKeys.sku => product.copyWith(sku: base.sku),
  DiffKeys.price => product.copyWith(priceCents: base.priceCents),
  DiffKeys.compareAt => product.copyWith(
    compareAtCents: () => base.compareAtCents,
  ),
  DiffKeys.stock => product.copyWith(stock: base.stock),
  DiffKeys.status => product.copyWith(status: base.status),
  DiffKeys.category => product.copyWith(categoryId: base.categoryId),
  DiffKeys.tags => product.copyWith(tags: base.tags),
  DiffKeys.featured => product.copyWith(featured: base.featured),
  DiffKeys.care => product.copyWith(care: base.care),
  DiffKeys.variants => product.copyWith(variants: base.variants),
  DiffKeys.photos => product.copyWith(photoIds: base.photoIds),
  _ => product,
};
