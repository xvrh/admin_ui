import 'package:admin_ui/assets.dart';
import 'package:admin_ui/collection.dart';
import 'package:admin_ui/fields.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';

/// What the catalogue's screens look products' photos and categories up in:
/// one browse of the media library and one read of the categories, shared
/// by every row instead of a call per row.
class CatalogueLookups {
  final Map<String, Asset> media;
  final Map<String, Category> categories;

  const CatalogueLookups({this.media = const {}, this.categories = const {}});

  // FRICTION(F-026): AssetSource resolves one id per call, so a list of
  // rows reads the library page by page once instead of an id per row.
  static Future<CatalogueLookups> load(ShopApi api) async {
    Future<List<Asset>> library() async {
      const page = 100;
      final all = <Asset>[];
      while (true) {
        final browsed = await api.assets.browse(index: all.length, size: page);
        all.addAll(browsed.items);
        if (browsed.items.isEmpty || all.length >= browsed.total) return all;
      }
    }

    final (media, categories) = await (library(), api.categories()).wait;
    return CatalogueLookups(
      media: {for (final a in media) a.id: a},
      categories: {for (final c in categories) c.id: c},
    );
  }

  ImageProvider? coverOf(Product product) => switch (product.photoIds) {
    [final first, ...] => media[first]?.thumbnail,
    _ => null,
  };

  String categoryName(String id, String language) => switch (categories[id]) {
    final c? => inLanguage(c.name, language),
    null => '',
  };
}

/// A product's cover photo, or a leaf where it has none.
class ProductThumb extends StatelessWidget {
  final ImageProvider? image;
  final double size;

  const ProductThumb({super.key, this.image, this.size = 32});

  @override
  Widget build(BuildContext context) =>
      TableThumb(image: image, icon: Icons.local_florist_outlined, size: size);
}

/// Which of the shop's languages a product is written in: English is the
/// source, a language missing its name or description reads as untranslated.
Map<String, LocaleStatus?> productLanguages(Product product) => {
  for (final language in shopLanguages)
    language: language == shopLanguages.first
        ? LocaleStatus.source
        : product.missingLanguages.contains(language)
        ? null
        : LocaleStatus.translated,
};

/// The language chrome of a product's copy: English the source, each other
/// language translated unless [missing] says its copy is incomplete.
List<LocaleInfo> productLocales(bool Function(String language) missing) => [
  for (final language in shopLanguages)
    LocaleInfo(
      code: language,
      status: language == shopLanguages.first
          ? LocaleStatus.source
          : missing(language)
          ? LocaleStatus.missing
          : LocaleStatus.translated,
    ),
];

/// Raises a toast from anywhere below the app's `ToastScope`.
void showCatalogueToast(
  BuildContext context,
  String message, {
  String? title,
  Severity severity = Severity.success,
}) {
  ToastScope.of(context).show(Toast(message, title: title, severity: severity));
}
