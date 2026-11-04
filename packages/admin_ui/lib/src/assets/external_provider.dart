import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Orientation facet for a provider search.
enum ProviderOrientation { horizontal, vertical, square }

/// Visual kind facet (e.g. Shutterstock: photo / illustration / vector).
enum ProviderImageType { photo, illustration, vector }

/// The search facets a provider tab exposes. `null` = unconstrained.
class ProviderFilters {
  final ProviderOrientation? orientation;
  final ProviderImageType? imageType;

  const ProviderFilters({this.orientation, this.imageType});

  bool get isEmpty => orientation == null && imageType == null;

  ProviderFilters copyWith({
    ProviderOrientation? Function()? orientation,
    ProviderImageType? Function()? imageType,
  }) => ProviderFilters(
    orientation: orientation != null ? orientation() : this.orientation,
    imageType: imageType != null ? imageType() : this.imageType,
  );
}

/// One result from a provider search, identified by the provider's own [id] —
/// not a local asset until [ExternalAssetProvider.import] materialises it.
/// [preview] is the watermarked comp; [swatch] stands in where no preview image
/// is available (offline / demos).
class ProviderItem {
  final String id;
  final String? title;
  final ImageProvider? preview;
  final String? previewUrl;
  final Color? swatch;
  final int? width;
  final int? height;
  final String? contributor;

  const ProviderItem({
    required this.id,
    this.title,
    this.preview,
    this.previewUrl,
    this.swatch,
    this.width,
    this.height,
    this.contributor,
  });

  String? get dimsLabel =>
      (width != null && height != null) ? '$width × $height' : null;
}

/// A licensable size/format for a [ProviderItem].
class ProviderSize {
  final String id;
  final String label;
  final int? width;
  final int? height;
  final String? format;

  const ProviderSize({
    required this.id,
    required this.label,
    this.width,
    this.height,
    this.format,
  });

  String? get dimsLabel =>
      (width != null && height != null) ? '$width × $height' : null;
}

/// One page of provider search results.
class ProviderSearchResult {
  final List<ProviderItem> items;
  final int total;
  final int page;

  const ProviderSearchResult({
    required this.items,
    this.total = 0,
    this.page = 1,
  });

  static const empty = ProviderSearchResult(items: [], total: 0, page: 1);
}

/// A third-party stock-media provider the picker can browse and license from,
/// implemented by an opt-in provider module (e.g. Shutterstock); this package
/// stays provider-agnostic.
///
/// [search] returns watermarked previews. [import] licenses the chosen item,
/// stores it as a local asset, and returns the new local asset id — from there
/// the picked value is an ordinary asset and nothing downstream changes.
abstract class ExternalAssetProvider {
  /// Stable key, e.g. `'shutterstock'`.
  String get id;

  /// Tab label, e.g. `'Shutterstock'`.
  String get label;

  IconData get icon;

  /// Whether the editor picks a size at import time (vs. the module licensing a
  /// fixed/auto size). Drives whether the import flow shows a size chooser.
  bool get choosesSize;

  Future<ProviderSearchResult> search({
    String? query,
    int page = 1,
    ProviderFilters filters = const ProviderFilters(),
  });

  /// Licensable sizes for [item]. Consulted only when [choosesSize] is true.
  Future<List<ProviderSize>> sizesFor(ProviderItem item);

  /// Licenses [item] (at [size] when chosen), stores it, and returns the local
  /// asset id — the id the library knows it by.
  Future<String> import(ProviderItem item, {ProviderSize? size});
}

/// Provides the external providers available to the asset picker. Absent or
/// empty ⇒ the picker shows only the local library (no provider tabs).
class ExternalProviderScope extends InheritedWidget {
  final List<ExternalAssetProvider> providers;

  const ExternalProviderScope({
    super.key,
    required this.providers,
    required super.child,
  });

  static List<ExternalAssetProvider> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ExternalProviderScope>()
          ?.providers ??
      const [];

  @override
  bool updateShouldNotify(ExternalProviderScope old) =>
      !listEquals(providers, old.providers);
}
