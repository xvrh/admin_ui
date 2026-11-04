import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_fixtures.dart';
import '../demo_kit.dart';

const _photo = AssetImage('assets/sample.jpg');
const _missing = AssetImage('assets/missing.jpg');

Asset _asset(int i) {
  final kinds = AssetType.values;
  final type = i % 5 == 4 ? kinds[1 + i % 3] : AssetType.image;
  return Asset(
    id: 'asset_$i',
    name: type == AssetType.image
        ? 'photo_${i.toString().padLeft(3, '0')}.jpg'
        : 'file_${i.toString().padLeft(3, '0')}.${_extension(type)}',
    type: type,
    bytes: 180 * 1024 + i * 7919,
    thumbnail: type == AssetType.image && i.isEven ? _photo : null,
    swatch: demoPalette[i % demoPalette.length],
    width: type == AssetType.image ? 2400 : null,
    height: type == AssetType.image ? 1600 : null,
  );
}

/// A brochure no entry uses: the list sample's rows, which its "Documents"
/// and "Not used anywhere" filters leave.
Asset _unusedBrochure(int i) => Asset(
  id: 'brochure_$i',
  name: 'brochure_${i.toString().padLeft(3, '0')}.pdf',
  type: AssetType.document,
  bytes: 240 * 1024 + i * 7919,
  swatch: demoPalette[i % demoPalette.length],
);

String _extension(AssetType type) => switch (type) {
  AssetType.video => 'mp4',
  AssetType.audio => 'mp3',
  AssetType.document => 'pdf',
  _ => 'bin',
};

/// Every state of a [MediaTile] over an opaque photo, pinned: the ring is
/// drawn over the picture, so it has to read on one. Also over a fill in the
/// ring's own colour, where only the band of page between them keeps it
/// apart, and the list form's states.
class MediaTileStatesDemo extends StatefulWidget {
  @Preview(name: 'Media tile — states', wrapper: adminUiPreview)
  const MediaTileStatesDemo({super.key});

  @override
  State<MediaTileStatesDemo> createState() => _MediaTileStatesDemoState();
}

class _MediaTileStatesDemoState extends State<MediaTileStatesDemo> {
  final _hovered = WidgetStatesController({WidgetState.hovered});
  final _selectedHovered = WidgetStatesController({WidgetState.hovered});
  final _pressed = WidgetStatesController({WidgetState.pressed});
  final _focused = WidgetStatesController({WidgetState.focused});
  final _selectedFocused = WidgetStatesController({WidgetState.focused});
  final _rowHovered = WidgetStatesController({WidgetState.hovered});
  final _rowFocused = WidgetStatesController({WidgetState.focused});

  @override
  void dispose() {
    for (final states in [
      _hovered,
      _selectedHovered,
      _pressed,
      _focused,
      _selectedFocused,
      _rowHovered,
      _rowFocused,
    ]) {
      states.dispose();
    }
    super.dispose();
  }

  Widget _tile(
    String caption, {
    bool selected = false,
    WidgetStatesController? states,
    Widget thumbnail = const MediaThumb(image: _photo),
    MediaTileCheck check = MediaTileCheck.always,
  }) {
    return SizedBox(
      width: 150,
      child: MediaTile(
        thumbnail: thumbnail,
        title: caption,
        subtitle: '2400 × 1600',
        selected: selected,
        check: check,
        statesController: states,
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = ColoredBox(color: context.colors.primary);
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 880,
        children: [
          const DemoSection('Over a photo'),
          Wrap(
            spacing: MediaGrid.gap,
            runSpacing: AdminSpacing.xl,
            children: [
              _tile('Rest'),
              _tile('Hovered', states: _hovered),
              _tile('Pressed', states: _pressed),
              _tile('Focused', states: _focused),
              _tile('Selected', selected: true),
              _tile(
                'Selected, hovered',
                selected: true,
                states: _selectedHovered,
              ),
              _tile(
                'Selected, focused',
                selected: true,
                states: _selectedFocused,
              ),
            ],
          ),
          const Gap(AdminSpacing.xxl),
          const DemoSection(
            'Over the ring’s own colour, and without a picture',
          ),
          Wrap(
            spacing: MediaGrid.gap,
            runSpacing: AdminSpacing.xl,
            children: [
              _tile('Primary fill', thumbnail: primary),
              _tile('Primary fill', thumbnail: primary, selected: true),
              _tile(
                'Swatch',
                selected: true,
                check: MediaTileCheck.selected,
                thumbnail: MediaThumb(swatch: demoPalette[3]),
              ),
              _tile(
                'Document',
                thumbnail: MediaThumb(icon: assetGlyph(AssetType.document)),
              ),
              _tile(
                'Failed to load',
                thumbnail: const MediaThumb(image: _missing),
              ),
            ],
          ),
          const Gap(AdminSpacing.xxl),
          const DemoSection('List form'),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.border),
              borderRadius: BorderRadius.circular(context.radii.radiusLarge),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.radii.radiusLarge),
              child: Column(
                children: [
                  for (final (caption, selected, states) in [
                    ('Rest', false, null),
                    ('Hovered', false, _rowHovered),
                    ('Selected', true, null),
                    ('Focused', false, _rowFocused),
                  ]) ...[
                    MediaListTile(
                      thumbnail: const MediaThumb(image: _photo, iconSize: 18),
                      title: caption,
                      subtitle: '1.2 MB · 2400 × 1600',
                      selected: selected,
                      check: MediaTileCheck.always,
                      statesController: states,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: context.colors.borderSubtle),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The library at a phone-ish 400px: the search takes a row of its own, the
/// filters and the view toggle share the next, and the grid is two-up. The
/// list view's toolbar carries a filter of the app's, which wraps under the
/// type filter once the two outgrow their row.
class AssetLibraryNarrowDemo extends StatelessWidget {
  @Preview(name: 'Library — narrow', wrapper: adminUiPreview)
  const AssetLibraryNarrowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 400,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      children: [
        const DemoSection('Picker at 376px'),
        SizedBox(
          height: 620,
          child: AssetLibrary(
            assets: [for (var i = 0; i < 9; i++) _asset(i)],
            selectionMode: AssetSelectionMode.multiple,
            selected: const {'asset_0', 'asset_3'},
            onToggle: (_) {},
            onConfirm: () {},
            onCancel: () {},
            filter: AssetType.image,
            onFilterChanged: (_) {},
            onViewChanged: (_) {},
            confirmLabel: 'Insert',
          ),
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('List view, with a filter of the app’s'),
        SizedBox(
          height: 400,
          child: AssetLibrary(
            assets: [for (var i = 0; i < 6; i++) _unusedBrochure(i)],
            view: AssetView.list,
            onViewChanged: (_) {},
            filter: AssetType.document,
            onFilterChanged: (_) {},
            onOpen: (_) {},
            toolbarActions: [
              FilterMenuButton<bool?>(
                value: false,
                tooltip: 'Usage',
                icon: Icons.link_rounded,
                onChanged: (_) {},
                options: const [
                  FilterMenuOption(null, 'All assets'),
                  FilterMenuOption(true, 'In use', icon: Icons.link_rounded),
                  FilterMenuOption(
                    false,
                    'Not used anywhere',
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

/// A library that pages: the bar under the grid counts what is shown
/// against the total, a "Load more" button (and scrolling near the end)
/// fetches the next page, and a spinner stands in while it lands.
class AssetLibraryPagedDemo extends StatefulWidget {
  @Preview(name: 'Library — paginated', wrapper: adminUiPreview)
  const AssetLibraryPagedDemo({super.key});

  @override
  State<AssetLibraryPagedDemo> createState() => _AssetLibraryPagedDemoState();
}

class _AssetLibraryPagedDemoState extends State<AssetLibraryPagedDemo> {
  static const _total = 120;
  static const _page = 12;

  final _assets = [for (var i = 0; i < _page; i++) _asset(i)];
  bool _loadingMore = false;
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  void _loadMore() {
    setState(() => _loadingMore = true);
    _pending = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        final start = _assets.length;
        _assets.addAll([
          for (var i = start; i < start + _page && i < _total; i++) _asset(i),
        ]);
        _loadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 880,
      children: [
        const DemoSection('More to load'),
        SizedBox(
          height: 560,
          child: AssetLibrary(
            assets: _assets,
            total: _total,
            hasMore: _assets.length < _total,
            loadingMore: _loadingMore,
            onLoadMore: _loadMore,
            onOpen: (_) {},
            onViewChanged: (_) {},
            onFilterChanged: (_) {},
          ),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Loading the next page'),
        SizedBox(
          height: 300,
          child: AssetLibrary(
            assets: [for (var i = 0; i < 12; i++) _asset(i)],
            total: _total,
            hasMore: true,
            loadingMore: true,
            onLoadMore: () {},
            onOpen: (_) {},
          ),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Could not load — the error in words'),
        SizedBox(
          height: 300,
          child: AssetLibrary(
            assets: const [],
            error: Exception('ClientException: Failed host lookup'),
            onRetry: () {},
          ),
        ),
      ],
    );
  }
}

/// [AssetDetailView], as [showAssetDetail] opens it in a side sheet: a
/// photo with the app's Crop in the footer and a download in the header,
/// and an image whose file is missing, with Delete alone.
class AssetDetailDemo extends StatelessWidget {
  @Preview(name: 'Asset detail', wrapper: adminUiPreview)
  const AssetDetailDemo({super.key});

  @override
  Widget build(BuildContext context) {
    Widget sheet(Asset asset, {bool actions = false}) => SizedBox(
      width: 420,
      height: 640,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
        ),
        child: AssetDetailView(
          asset: asset,
          onDismiss: () {},
          onDelete: () {},
          actions: [
            if (actions)
              IconAction(
                Icons.download_rounded,
                label: 'Download',
                size: IconActionSize.small,
                onPressed: () {},
              ),
          ],
          footerActions: [
            if (actions)
              Button(
                'Crop',
                icon: Icons.crop_rounded,
                variant: ButtonVariant.secondary,
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Wrap(
          spacing: AdminSpacing.xxl,
          runSpacing: AdminSpacing.xxl,
          children: [
            sheet(
              const Asset(
                id: '42',
                name: 'harbour_at_dusk.jpg',
                bytes: 1840 * 1024,
                thumbnail: _photo,
                url: 'https://cdn.example.com/assets/harbour_at_dusk.jpg',
                width: 2400,
                height: 1600,
                usageCount: 3,
                alt: {'en': 'A harbour at dusk', 'fr': 'Un port au crépuscule'},
              ),
              actions: true,
            ),
            sheet(
              const Asset(
                id: '43',
                name: 'deleted_upload.png',
                bytes: 96 * 1024,
                thumbnail: _missing,
                width: 800,
                height: 800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
