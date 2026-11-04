import 'dart:typed_data';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_fixtures.dart';
import '../demo_kit.dart';

/// An in-memory [AssetSource] for the catalog — no network: previews stand in
/// with [demoPalette] swatches, and the picker browses this fixed set. Any
/// other id resolves to null (a deleted asset), except [unreachable], whose
/// resolve fails.
class _DemoAssetSource implements AssetSource {
  static const unreachable = 'unreachable';

  final List<Asset> _assets = [
    for (var i = 0; i < 12; i++)
      Asset(
        id: '$i',
        name: 'photo_$i.jpg',
        type: AssetType.image,
        bytes: 1024 * (220 + i * 90),
        swatch: demoPalette[i % demoPalette.length],
        width: 1200,
        height: 800,
      ),
  ];

  @override
  Future<Asset?> resolve(String id) async {
    if (id == unreachable) {
      throw Exception('ClientException: Failed to fetch');
    }
    return _assets.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async {
    final hits = _assets.where((a) {
      final q = (query ?? '').trim().toLowerCase();
      return (q.isEmpty || a.name.toLowerCase().contains(q)) &&
          (filter == null || a.type == filter);
    }).toList();
    return AssetBrowseResult(hits, hits.length);
  }

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async {
    onProgress?.call(1);
    final id = '${_assets.length}';
    final asset = Asset(
      id: id,
      name: filename ?? 'upload_$id.jpg',
      type: AssetType.image,
      bytes: bytes.length,
      swatch: demoPalette[_assets.length % demoPalette.length],
      width: 1200,
      height: 800,
    );
    _assets.add(asset);
    return asset;
  }

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

class AssetFieldDemo extends StatefulWidget {
  @Preview(name: 'Field (single + picker)', wrapper: adminUiPreview)
  const AssetFieldDemo({super.key});

  @override
  State<AssetFieldDemo> createState() => _AssetFieldDemoState();
}

class _AssetFieldDemoState extends State<AssetFieldDemo> {
  final _source = _DemoAssetSource();
  final _scope = LocalScope();

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _scope.numberOrNull('empty');
    final filled = _scope.numberOrNull('filled')..set(2);
    // An id the library no longer has — deleted since it was picked.
    final missing = _scope.numberOrNull('missing')..set(404);
    final refSet = _scope.assetRef('refSet')..assetId.set('5');
    final refMissing = _scope.assetRef('refMissing')..assetId.set('gone');
    final refFailed = _scope.assetRef('refFailed')
      ..assetId.set(_DemoAssetSource.unreachable);
    return AssetSourceScope(
      source: _source,
      child: ModalAnchor(
        child: DemoPage(
          maxWidth: 480,
          children: [
            DemoVariant(
              'Single asset — empty (tap to pick from the library)',
              AssetField(empty, label: 'Hero image'),
            ),
            DemoVariant(
              'Single asset — set (tap to replace, × to clear)',
              AssetField(filled, label: 'Hero image'),
            ),
            DemoVariant(
              'Missing — the asset was deleted; replace or clear it',
              AssetField(missing, label: 'Hero image'),
            ),
            const DemoVariant(
              'Read-only (no onChanged)',
              FieldShell(
                label: 'Hero image',
                child: AssetBody(value: '3'),
              ),
            ),
            DemoVariant(
              'Disabled',
              FieldShell(
                label: 'Hero image',
                enabled: false,
                child: AssetBody(value: '3', onChanged: (_) {}),
              ),
            ),
            DemoVariant(
              'Validation error — empty: the drop zone turns red',
              FieldShell(
                label: 'Hero image',
                errorText: 'A hero image is required before publishing.',
                child: AssetBody(value: null, onChanged: (_) {}),
              ),
            ),
            const DemoSection('Asset reference (alt + crop per usage)'),
            DemoVariant(
              'Set — tap to edit alt, crop and focal point',
              AssetRefField(refSet, label: 'Hero image'),
            ),
            DemoVariant(
              'Missing — tap to replace, × to remove',
              AssetRefField(refMissing, label: 'Hero image'),
            ),
            DemoVariant(
              'Preview failed to load — tap to retry',
              AssetRefField(refFailed, label: 'Hero image'),
            ),
            const SizedBox(height: 8),
            Text(
              'AssetField stores an integer key; the kit’s AssetBody and '
              'AssetRefField take the asset’s string id. Both preview through '
              'the ambient AssetSource and open the shared media picker.',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.foregroundMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
