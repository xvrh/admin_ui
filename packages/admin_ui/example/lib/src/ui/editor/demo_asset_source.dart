import 'dart:typed_data';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widgets.dart';

/// One bundled image so the asset picker/cropper work offline in the catalog.
class DemoAssetSource implements AssetSource {
  static const _asset = Asset(
    id: '1',
    name: 'sample.jpg',
    type: AssetType.image,
    bytes: 49028,
    width: 800,
    height: 600,
    thumbnail: AssetImage('assets/sample.jpg'),
  );

  @override
  Future<Asset?> resolve(String id) async => id == _asset.id ? _asset : null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => const AssetBrowseResult([_asset], 1);

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async {
    onProgress?.call(1);
    return _asset;
  }

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}
