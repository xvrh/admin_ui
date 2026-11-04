import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../collection/filter.dart';
import 'ui/asset_library.dart' show Asset, AssetType;

/// One page of a library browse: the [items] for this slice plus the [total]
/// match count (for pagination / counts).
class AssetBrowseResult {
  final List<Asset> items;
  final int total;
  const AssetBrowseResult(this.items, this.total);

  static const empty = AssetBrowseResult([], 0);
}

/// The IO capability an asset field/picker needs, kept abstract so this package
/// stays view-pure: the app supplies a concrete source (over its HTTP client).
/// [resolve] turns a stored asset id into a presentable [Asset] (with a preview
/// URL); [browse] backs the picker's library list.
///
/// Ids are [Asset.id] strings throughout — an integer key, a UUID or a slug
/// alike. A backend keyed by integers parses at its own boundary.
abstract class AssetSource {
  /// The [Asset] for [id], or null if it no longer exists. Implementations
  /// should cache — a field calls this for every reference it previews.
  Future<Asset?> resolve(String id);

  /// A page of the library, optionally narrowed by [query]/[filter] and by
  /// the app's own conditions in [where].
  ///
  /// [where] holds what the kit has no control for: whether a product uses
  /// the asset, its folder, who uploaded it. The app names each condition's
  /// field, puts the control in `AssetLibrary.toolbarActions` and sets the
  /// conditions on `AssetLibraryController.where`; the kit passes them
  /// through untouched. Answer them where the assets are, so [total] counts
  /// the matches and the library still pages: a source that filters a page
  /// after fetching it shows short pages. One that has no such conditions
  /// ignores the parameter.
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  });

  /// Uploads [bytes] (an image or other file) and returns the stored [Asset]
  /// (or null on failure). [onProgress] reports a 0..1 fraction. Implementations
  /// should cache the result so a follow-up [resolve] needs no round-trip.
  ///
  /// [cancelled] completes when the person cancels the upload. A source that
  /// can abort the transfer should — `package:http`'s `abortTrigger` takes it
  /// as it is. Either way the caller ignores what a cancelled upload returns.
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  });

  /// Persists the library-level default alt text for [id] ({lang: text}),
  /// returning the updated [Asset] — or null when the source can't persist
  /// (demos, read-only sources).
  Future<Asset?> updateAlt(String id, Map<String, String> alt);
}

/// Provides the ambient [AssetSource] to asset fields and the block-editor image
/// block. Absent from the tree ⇒ asset fields render read-only placeholders.
class AssetSourceScope extends InheritedWidget {
  final AssetSource source;
  const AssetSourceScope({
    super.key,
    required this.source,
    required super.child,
  });

  static AssetSource? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AssetSourceScope>()?.source;

  static AssetSource of(BuildContext context) {
    final source = maybeOf(context);
    if (source == null) {
      throw FlutterError(
        'AssetSourceScope.of() was called with a context that has no '
        'AssetSourceScope above it.\n'
        'Mount an AssetSourceScope with the app\'s AssetSource above the '
        'asset fields and pickers, or use AssetSourceScope.maybeOf where '
        'there may be none (the fields then show read-only placeholders).',
      );
    }
    return source;
  }

  @override
  bool updateShouldNotify(AssetSourceScope old) => source != old.source;
}
