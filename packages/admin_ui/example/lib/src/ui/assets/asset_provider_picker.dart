import 'dart:typed_data';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_fixtures.dart';
import '../demo_kit.dart';

/// A fake stock-image provider for the catalog — no network. Search returns a
/// swatch-backed set (a couple flagged editorial), [sizesFor] offers a few
/// licensable sizes, and [import] pretends to license + materialise, returning a
/// new local asset id after a short delay.
class _FakeStockProvider implements ExternalAssetProvider {
  @override
  String get id => 'fakestock';
  @override
  String get label => 'Stockly';
  @override
  IconData get icon => Icons.collections_outlined;
  @override
  bool get choosesSize => true;

  int _nextId = 9000;

  static const _subjects = [
    'mountain sunrise',
    'team meeting',
    'fresh produce',
    'city skyline',
    'minimal desk',
    'forest path',
    'coffee shop',
    'ocean waves',
    'abstract gradient',
    'happy dog',
    'office building',
    'street market',
  ];

  @override
  Future<ProviderSearchResult> search({
    String? query,
    int page = 1,
    ProviderFilters filters = const ProviderFilters(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final q = (query ?? '').trim().toLowerCase();
    final items = <ProviderItem>[];
    for (var i = 0; i < _subjects.length; i++) {
      final subject = _subjects[i];
      if (q.isNotEmpty && !subject.contains(q)) continue;
      items.add(
        ProviderItem(
          id: 'sk_${1000 + i}',
          title: subject,
          swatch: demoPalette[i % demoPalette.length],
          width: 4000,
          height: filters.orientation == ProviderOrientation.vertical
              ? 6000
              : 2667,
          contributor: 'Contributor ${i + 1}',
        ),
      );
    }
    return ProviderSearchResult(items: items, total: items.length);
  }

  @override
  Future<List<ProviderSize>> sizesFor(ProviderItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      ProviderSize(
        id: 'small',
        label: 'Small',
        width: 500,
        height: 333,
        format: 'jpg',
      ),
      ProviderSize(
        id: 'medium',
        label: 'Medium',
        width: 1000,
        height: 667,
        format: 'jpg',
      ),
      ProviderSize(
        id: 'large',
        label: 'Large',
        width: 4000,
        height: 2667,
        format: 'jpg',
      ),
    ];
  }

  @override
  Future<String> import(ProviderItem item, {ProviderSize? size}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return '${_nextId++}';
  }
}

/// A minimal in-memory library source so the picker's Library tab has content
/// alongside the provider tab.
class _DemoAssetSource implements AssetSource {
  final List<Asset> _assets = [
    for (var i = 0; i < 8; i++)
      Asset(
        id: '$i',
        name: 'in_library_$i.jpg',
        type: AssetType.image,
        bytes: 1024 * (220 + i * 90),
        swatch: demoPalette[i % demoPalette.length],
        width: 1200,
        height: 800,
      ),
  ];

  @override
  Future<Asset?> resolve(String id) async =>
      _assets.where((a) => a.id == id).firstOrNull;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async {
    final q = (query ?? '').trim().toLowerCase();
    final hits = _assets
        .where((a) => q.isEmpty || a.name.toLowerCase().contains(q))
        .toList();
    return AssetBrowseResult(hits, hits.length);
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

final _provider = _FakeStockProvider();

final _items = <ProviderItem>[
  for (var i = 0; i < 8; i++)
    ProviderItem(
      id: 'sk_$i',
      title: _FakeStockProvider._subjects[i],
      swatch: demoPalette[i % demoPalette.length],
      width: 4000,
      height: 2667,
      contributor: 'Contributor ${i + 1}',
    ),
];

class AssetProviderPickerDemo extends StatefulWidget {
  @Preview(name: 'External provider picker', wrapper: adminUiPreview)
  const AssetProviderPickerDemo({super.key});

  @override
  State<AssetProviderPickerDemo> createState() =>
      _AssetProviderPickerDemoState();
}

class _AssetProviderPickerDemoState extends State<AssetProviderPickerDemo> {
  final _source = _DemoAssetSource();
  final _modals = ModalAnchorController();
  String? _selectedId = 'sk_0';
  ProviderFilters _filters = const ProviderFilters();

  Future<void> _openPicker() async {
    final id = await showAssetPicker(
      context,
      modals: _modals,
      source: _source,
      providers: [_provider],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          id == null ? 'Dismissed' : 'Picked / imported asset #$id',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalAnchor(
      controller: _modals,
      child: DemoPage(
        maxWidth: 900,
        children: [
          const DemoSection('Picker with a provider tab'),
          Text(
            'The picker grows a tab per registered ExternalAssetProvider. The '
            'Library tab browses local assets; the provider tab searches the '
            'third party, and confirming licenses + imports it — the picker '
            'returns an ordinary local asset id.',
            style: context.type.body.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
          const Gap(AdminSpacing.lg),
          Button.primary('Open media picker', onPressed: _openPicker),
          const Gap(AdminSpacing.xxxl),

          const DemoSection('Provider browser — populated'),
          SizedBox(
            height: 480,
            child: _Framed(
              child: ProviderBrowser(
                providerLabel: 'Stockly',
                items: _items,
                filters: _filters,
                onFiltersChanged: (f) => setState(() => _filters = f),
                selectedId: _selectedId,
                onSelect: (it) => setState(
                  () => _selectedId = _selectedId == it.id ? null : it.id,
                ),
                onCancel: () {},
                onConfirm: () {},
              ),
            ),
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Searching'),
          SizedBox(
            height: 280,
            child: _Framed(
              child: ProviderBrowser(
                providerLabel: 'Stockly',
                items: const [],
                loading: true,
              ),
            ),
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Empty — before searching'),
          SizedBox(
            height: 360,
            child: _Framed(
              child: ProviderBrowser(providerLabel: 'Stockly', items: const []),
            ),
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Error'),
          SizedBox(
            height: 360,
            child: _Framed(
              child: ProviderBrowser(
                providerLabel: 'Stockly',
                items: const [],
                query: 'mountain',
                error: 'Provider rate limit reached',
                onRetry: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The media picker pinned open on its library tab, with a provider tab
/// beside the upload one.
class AssetPickerOpenDemo extends StatefulWidget {
  @Preview(name: 'Media picker (open)', wrapper: adminUiPreview)
  const AssetPickerOpenDemo({super.key});

  @override
  State<AssetPickerOpenDemo> createState() => _AssetPickerOpenDemoState();
}

class _AssetPickerOpenDemoState extends State<AssetPickerOpenDemo> {
  final _source = _DemoAssetSource();
  final _modals = ModalAnchorController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  void _open() => showAssetPicker(
    context,
    modals: _modals,
    source: _source,
    providers: [_provider],
  );

  @override
  Widget build(BuildContext context) => ModalAnchor(
    controller: _modals,
    child: DemoPage(children: [Button('Open media picker', onPressed: _open)]),
  );
}

/// The license sheet a provider pick opens, pinned open: the size chooser, or
/// with [sizesFail] the error its load ends in.
class ProviderImportSheetDemo extends StatefulWidget {
  final bool sizesFail;

  @Preview(name: 'Provider import sheet', wrapper: adminUiPreview)
  const ProviderImportSheetDemo({super.key}) : sizesFail = false;

  @Preview(
    name: 'Provider import sheet — sizes failed',
    wrapper: adminUiPreview,
  )
  const ProviderImportSheetDemo.sizesFailed({super.key}) : sizesFail = true;

  @override
  State<ProviderImportSheetDemo> createState() =>
      _ProviderImportSheetDemoState();
}

class _ProviderImportSheetDemoState extends State<ProviderImportSheetDemo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  void _open() => showProviderImport(
    context,
    item: _items.first,
    providerLabel: 'Stockly',
    choosesSize: true,
    loadSizes: () async {
      if (widget.sizesFail) throw Exception('HTTP 503 Service Unavailable');
      return _provider.sizesFor(_items.first);
    },
    onImport: (size) => _provider.import(_items.first, size: size),
  );

  @override
  Widget build(BuildContext context) =>
      DemoPage(children: [Button('License an image', onPressed: _open)]);
}

/// The picker's surface chrome, so a standalone browser reads like it does
/// inside the dialog.
class _Framed extends StatelessWidget {
  final Widget child;
  const _Framed({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        child: child,
      ),
    );
  }
}
