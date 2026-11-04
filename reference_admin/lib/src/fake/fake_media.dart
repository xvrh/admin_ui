import 'dart:async';
import 'dart:typed_data';

import 'package:admin_ui/assets.dart';
import 'package:admin_ui/collection.dart';
import 'package:flutter/widgets.dart' show MemoryImage;

import '../api/shop_api.dart';
import 'seed.dart';

/// Runs one call the way every fake endpoint runs: latency, faults, holds,
/// the call log and the in-flight count.
typedef FakeCall = Future<T> Function<T>(
  Endpoint endpoint,
  Map<String, Object?> args,
  FutureOr<T> Function() body,
);

/// The media library over the fake shop's assets.
///
/// [browse] answers `where` as a server would, before it pages: a
/// [BoolFilter] on `inUse` keeps the assets a product uses, or those none
/// does. It refuses a condition it does not know.
class FakeAssetSource implements AssetSource {
  final FakeShopDb _db;
  final FakeCall _call;
  final void Function(Permission permission) _require;

  FakeAssetSource(this._db, this._call, this._require);

  @override
  Future<Asset?> resolve(String id) =>
      _call(Endpoint.resolveAsset, {'id': id}, () {
        for (final asset in _db.assets) {
          if (asset.id == id) return asset;
        }
        return null;
      });

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) => _call(
    Endpoint.browseAssets,
    {
      'index': index,
      'size': size,
      'query': ?query,
      'filter': ?filter?.name,
      if (where.isNotEmpty) 'where': [for (final c in where) c.toJson()],
    },
    () {
      final q = (query ?? '').trim().toLowerCase();
      final hits = [
        for (final asset in _db.assets.reversed)
          if ((q.isEmpty ||
                  asset.name.toLowerCase().contains(q) ||
                  asset.alt.values.any((a) => a.toLowerCase().contains(q))) &&
              (filter == null || asset.type == filter) &&
              where.every((c) => _matches(asset, c)))
            asset,
      ];
      return AssetBrowseResult(
        hits.skip(index).take(size).toList(),
        hits.length,
      );
    },
  );

  static bool _matches(Asset asset, FilterCondition condition) =>
      switch (condition) {
        BoolFilter(field: 'inUse', :final value) =>
          (asset.usageCount > 0) == value,
        _ => throw ArgumentError.value(
          condition.field,
          'where',
          'the media library has no such condition',
        ),
      };

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) => _call(
    Endpoint.uploadAsset,
    {'mime': mime, 'filename': ?filename, 'bytes': bytes.length},
    () {
      _require(Permission.editCatalogue);
      onProgress?.call(1);
      final id = 'm-${_db.nextId++}';
      final asset = Asset(
        id: id,
        name: filename ?? '$id.png',
        bytes: bytes.length,
        thumbnail: mime.startsWith('image/') ? MemoryImage(bytes) : null,
        type: mime.startsWith('image/') ? AssetType.image : AssetType.document,
      );
      _db.assets.add(asset);
      return asset;
    },
  );

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) =>
      _call(Endpoint.updateAlt, {'id': id, 'alt': alt}, () {
        _require(Permission.editCatalogue);
        final i = _db.assets.indexWhere((a) => a.id == id);
        if (i < 0) throw const ShopError.notFound();
        final old = _db.assets[i];
        // FRICTION(F-025): Asset has no copyWith; every field is carried
        // over by hand.
        final updated = Asset(
          id: old.id,
          name: old.name,
          type: old.type,
          bytes: old.bytes,
          thumbnail: old.thumbnail,
          url: old.url,
          swatch: old.swatch,
          width: old.width,
          height: old.height,
          usageCount: old.usageCount,
          // FRICTION(F-406): the kit sends the whole alt text, leaving
          // cleared languages out, so it replaces what was stored.
          alt: {...alt}..removeWhere((_, v) => v.trim().isEmpty),
        );
        _db.assets[i] = updated;
        return updated;
      });
}

/// Saved views per collection key, in the fake shop.
class FakeSavedViews implements SavedViewsStore {
  final FakeShopDb _db;
  final FakeCall _call;

  FakeSavedViews(this._db, this._call);

  List<SavedView> _bucket(String key) => _db.savedViews[key] ??= [];

  @override
  Future<List<SavedView>> list(String collectionKey) =>
      _call(Endpoint.listViews, {'collection': collectionKey}, () {
        return [..._bucket(collectionKey)]
          ..sort((a, b) => a.position.compareTo(b.position));
      });

  @override
  Future<SavedView> create(String collectionKey, SavedView view) => _call(
    Endpoint.createView,
    {'collection': collectionKey, 'name': view.name},
    () {
      final bucket = _bucket(collectionKey);
      final created = view.copyWith(
        id: '$collectionKey-view-${_db.nextId++}',
        position: bucket.length,
      );
      bucket.add(created);
      return created;
    },
  );

  @override
  Future<void> update(String collectionKey, SavedView view) => _call(
    Endpoint.updateView,
    {'collection': collectionKey, 'id': view.id},
    () {
      final bucket = _bucket(collectionKey);
      final i = bucket.indexWhere((v) => v.id == view.id);
      if (i < 0) throw const ShopError.notFound();
      bucket[i] = view;
    },
  );

  @override
  Future<void> delete(String collectionKey, String id) => _call(
    Endpoint.deleteView,
    {'collection': collectionKey, 'id': id},
    () => _bucket(collectionKey).removeWhere((v) => v.id == id),
  );

  @override
  Future<void> setDefault(String collectionKey, String id) => _call(
    Endpoint.setDefaultView,
    {'collection': collectionKey, 'id': id},
    () {
      final bucket = _bucket(collectionKey);
      for (var i = 0; i < bucket.length; i++) {
        bucket[i] = bucket[i].copyWith(isDefault: bucket[i].id == id);
      }
    },
  );

  @override
  Future<void> reorder(String collectionKey, List<String> ids) => _call(
    Endpoint.reorderViews,
    {'collection': collectionKey, 'ids': ids},
    () {
      final bucket = _bucket(collectionKey);
      for (var i = 0; i < bucket.length; i++) {
        final position = ids.indexOf(bucket[i].id);
        if (position >= 0) bucket[i] = bucket[i].copyWith(position: position);
      }
    },
  );
}
