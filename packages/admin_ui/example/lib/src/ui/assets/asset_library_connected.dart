import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_fixtures.dart';
import '../demo_kit.dart';

/// [AssetLibrary.connected] over an [AssetLibraryController]: a media page
/// with no paging state of its own. A usage filter of the app's sits in the
/// toolbar beside the type filter, and the source answers it where the
/// assets are, so the library still pages.
class AssetLibraryConnectedDemo extends StatefulWidget {
  final bool _fails;

  @Preview(name: 'Library — connected', wrapper: adminUiPreview)
  const AssetLibraryConnectedDemo({super.key}) : _fails = false;

  /// The first page fails: the error in words, with a Retry.
  @Preview(name: 'Library — connected, error', wrapper: adminUiPreview)
  const AssetLibraryConnectedDemo.error({super.key}) : _fails = true;

  @override
  State<AssetLibraryConnectedDemo> createState() =>
      _AssetLibraryConnectedDemoState();
}

class _AssetLibraryConnectedDemoState extends State<AssetLibraryConnectedDemo> {
  late final _library = AssetLibraryController(
    source: _DemoLibrarySource(fails: widget._fails),
  );
  _Usage _usage = _Usage.all;

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  void _setUsage(_Usage usage) {
    setState(() => _usage = usage);
    _library.where = [
      if (usage != _Usage.all) BoolFilter(_inUse, usage == _Usage.inUse),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 880,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      children: [
        DemoSection(
          widget._fails ? 'Could not load' : 'Over an AssetSource, paged',
        ),
        SizedBox(
          height: widget._fails ? 320 : 560,
          child: AssetLibrary.connected(
            controller: _library,
            onOpen: (_) {},
            toolbarActions: [
              FilterMenuButton<_Usage>(
                value: _usage,
                tooltip: 'Usage',
                icon: Icons.link_rounded,
                onChanged: _setUsage,
                options: const [
                  FilterMenuOption(_Usage.all, 'All assets'),
                  FilterMenuOption(
                    _Usage.inUse,
                    'In use',
                    icon: Icons.link_rounded,
                  ),
                  FilterMenuOption(
                    _Usage.unused,
                    'Unused',
                    icon: Icons.link_off_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Usage { all, inUse, unused }

/// The condition's field: whether an entry uses the asset.
const _inUse = 'inUse';

const _photo = AssetImage('assets/sample.jpg');

Asset _asset(int i) {
  final type = i % 7 == 6 ? AssetType.document : AssetType.image;
  return Asset(
    id: 'asset_$i',
    name: type == AssetType.image
        ? 'photo_${i.toString().padLeft(3, '0')}.jpg'
        : 'brochure_${i.toString().padLeft(3, '0')}.pdf',
    type: type,
    bytes: 180 * 1024 + i * 7919,
    thumbnail: type == AssetType.image && i.isEven ? _photo : null,
    swatch: demoPalette[i % demoPalette.length],
    width: type == AssetType.image ? 2400 : null,
    height: type == AssetType.image ? 1600 : null,
    usageCount: i % 4 == 1 ? 0 : i % 3 + 1,
  );
}

/// Sixty assets, a page at a time, answered at once so the preview settles
/// on its first frame. It reads [_inUse] from `where`, as a server would.
class _DemoLibrarySource implements AssetSource {
  final bool fails;

  _DemoLibrarySource({required this.fails});

  static final _assets = [for (var i = 0; i < 60; i++) _asset(i)];

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) {
    if (fails) {
      return Future.error(Exception('ClientException: Failed host lookup'));
    }
    final q = (query ?? '').trim().toLowerCase();
    final hits = [
      for (final asset in _assets)
        if (asset.name.contains(q) &&
            (filter == null || asset.type == filter) &&
            where.every(
              (c) => switch (c) {
                BoolFilter(field: _inUse, :final value) =>
                  (asset.usageCount > 0) == value,
                _ => true,
              },
            ))
          asset,
    ];
    return SynchronousFuture(
      AssetBrowseResult(hits.skip(index).take(size).toList(), hits.length),
    );
  }

  @override
  Future<Asset?> resolve(String id) async {
    for (final asset in _assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}
