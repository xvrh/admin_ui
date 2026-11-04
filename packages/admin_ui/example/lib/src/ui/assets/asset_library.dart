import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_fixtures.dart';
import '../demo_kit.dart';

final _assets = <Asset>[
  _img('hero_banner.jpg', 0, 2400, 1350, uses: 3),
  _img('product_front.png', 1, 1200, 1200, uses: 1),
  _img('product_side.png', 2, 1200, 1200, uses: 1),
  _img('team_offsite.jpg', 3, 4000, 2667, uses: 0),
  _img('founder_portrait.jpg', 4, 1600, 2000, uses: 2),
  _img('texture_bg.webp', 5, 1920, 1080, uses: 0),
  Asset(
    id: 'intro.mp4',
    name: 'intro.mp4',
    type: AssetType.video,
    bytes: 18 * 1024 * 1024,
    width: 1920,
    height: 1080,
    usageCount: 1,
  ),
  const Asset(
    id: 'jingle.mp3',
    name: 'jingle.mp3',
    type: AssetType.audio,
    bytes: 3 * 1024 * 1024,
    usageCount: 0,
  ),
  const Asset(
    id: 'whitepaper.pdf',
    name: 'whitepaper.pdf',
    type: AssetType.document,
    bytes: 820 * 1024,
    usageCount: 4,
  ),
  const Asset(
    id: 'price_list.pdf',
    name: 'price_list.pdf',
    type: AssetType.document,
    bytes: 240 * 1024,
    usageCount: 2,
  ),
  _img('og_card.png', 6, 1200, 630, uses: 5),
  _img('icon_512.png', 7, 512, 512, uses: 1),
  const Asset(
    id: 'data_export.csv',
    name: 'data_export.csv',
    type: AssetType.other,
    bytes: 64 * 1024,
    usageCount: 0,
  ),
  _img('gallery_01.jpg', 8, 2000, 1333, uses: 1),
];

Asset _img(String name, int swatch, int w, int h, {int uses = 0}) => Asset(
  id: name,
  name: name,
  type: AssetType.image,
  bytes: (w * h / 3).round(),
  swatch: demoPalette[swatch % demoPalette.length],
  width: w,
  height: h,
  usageCount: uses,
);

class AssetLibraryDemo extends StatelessWidget {
  @Preview(name: 'Library / picker', wrapper: adminUiPreview)
  const AssetLibraryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final pick = context.knobs.bool('Picker (multi-select)', true);
    final withUpload = context.knobs.bool('Upload tab', true);

    return DemoPage(
      maxWidth: 880,
      children: [
        const DemoSection('Library'),
        SizedBox(
          height: 560,
          child: _Live(picker: pick, withUpload: withUpload),
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Picked — list view'),
        SizedBox(
          height: 300,
          child: AssetLibrary(
            assets: _assets.take(4).toList(),
            view: AssetView.list,
            selectionMode: AssetSelectionMode.multiple,
            selected: const {'hero_banner.jpg', 'product_side.png'},
            onToggle: (_) {},
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Loading'),
        SizedBox(
          height: 280,
          child: AssetLibrary(assets: const [], loading: true),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Empty — nothing uploaded yet'),
        SizedBox(height: 320, child: AssetLibrary(assets: const [])),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Error'),
        SizedBox(
          height: 320,
          child: AssetLibrary(
            assets: const [],
            error: 'Network timeout',
            onRetry: () {},
          ),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final bool picker;
  final bool withUpload;

  const _Live({required this.picker, required this.withUpload});

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  AssetView _view = AssetView.grid;
  String _query = '';
  AssetType? _filter;
  final _selected = {'hero_banner.jpg', 'team_offsite.jpg'};

  List<Asset> get _filtered => _assets.where((a) {
    if (_filter != null && a.type != _filter) return false;
    if (_query.isNotEmpty &&
        !a.name.toLowerCase().contains(_query.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return AssetLibrary(
      assets: _filtered,
      view: _view,
      onViewChanged: (v) => setState(() => _view = v),
      query: _query,
      onQueryChanged: (q) => setState(() => _query = q),
      filter: _filter,
      onFilterChanged: (f) => setState(() => _filter = f),
      selectionMode: widget.picker
          ? AssetSelectionMode.multiple
          : AssetSelectionMode.none,
      selected: _selected,
      onToggle: (id) => setState(() {
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
      }),
      onOpen: (a) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Open ${a.name}'),
          duration: const Duration(seconds: 1),
        ),
      ),
      onConfirm: widget.picker ? () {} : null,
      onCancel: widget.picker ? () => setState(_selected.clear) : null,
      confirmLabel: 'Insert',
      uploadTab: widget.withUpload
          ? UploadZone(
              accept: 'PNG, JPG, PDF · up to 25 MB',
              items: const [
                UploadItem(
                  id: 'new_shot.jpg',
                  name: 'new_shot.jpg',
                  status: UploadStatus.uploading,
                  progress: 0.45,
                  bytes: 1240 * 1024,
                ),
              ],
              onClearCompleted: () {},
            )
          : null,
    );
  }
}
