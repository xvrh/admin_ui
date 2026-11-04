import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';
import '../editor/demo_asset_source.dart';

const _locales = [
  LocaleInfo(code: 'en', status: LocaleStatus.source),
  LocaleInfo(code: 'fr', status: LocaleStatus.translated),
];

/// The scopes the asset editor reads, a source with the bundled image and
/// the languages its alt lanes follow, under the app's anchor, as
/// `AdminScope` mounts it around a page's own scopes: the editor takes
/// them from the field that opens it.
class _EditorHost extends StatefulWidget {
  final Widget child;
  const _EditorHost({required this.child});

  @override
  State<_EditorHost> createState() => _EditorHostState();
}

class _EditorHostState extends State<_EditorHost> {
  final _source = DemoAssetSource();
  Set<String> _visible = const {'en'};

  @override
  Widget build(BuildContext context) {
    return ModalAnchor(
      child: AssetSourceScope(
        source: _source,
        child: LangScope(
          locales: _locales,
          visibleLocales: _visible,
          sourceLocale: 'en',
          activeLocale: 'en',
          onVisibleLocalesChanged: (visible) =>
              setState(() => _visible = visible),
          child: widget.child,
        ),
      ),
    );
  }
}

/// The shared asset editor, opened over a reference field: the preview (a
/// drop target), Replace / Edit crop / Remove, and the per-usage alt text.
class AssetEditorDemo extends StatelessWidget {
  @Preview(name: 'Asset editor', wrapper: adminUiPreview)
  const AssetEditorDemo({super.key});

  @override
  Widget build(BuildContext context) => const _EditorHost(child: _OpenEditor());
}

class _OpenEditor extends StatefulWidget {
  const _OpenEditor();

  @override
  State<_OpenEditor> createState() => _OpenEditorState();
}

class _OpenEditorState extends State<_OpenEditor> {
  final _scope = LocalScope();
  late final _hero = _scope.assetRef('hero')..assetId.set('1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _open() => showAssetEditor(context, _hero, label: 'Hero image');

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 480,
      children: [
        AssetRefField(_hero, label: 'Hero image'),
        const Gap(AdminSpacing.lg),
        Button('Open the editor', onPressed: _open),
      ],
    );
  }
}

/// The crop & focal dialog the editor's "Edit crop" opens, on a crop saved
/// at 16:9: that preset starts chosen and locks the corner handles, and each
/// other ratio reshapes the crop to itself.
class AssetCropDialogDemo extends StatefulWidget {
  @Preview(name: 'Crop dialog (ratio presets)', wrapper: adminUiPreview)
  const AssetCropDialogDemo({super.key});

  @override
  State<AssetCropDialogDemo> createState() => _AssetCropDialogDemoState();
}

class _AssetCropDialogDemoState extends State<AssetCropDialogDemo> {
  /// 16:9 over the 4:3 sample: the full width, 3/4 of the height.
  CropValue _crop = const CropValue(rect: Rect.fromLTWH(0, 0.125, 1, 0.75));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  Future<void> _open() async {
    final result = await showCropDialog(
      context,
      image: const AssetImage('assets/sample.jpg'),
      imageAspect: 800 / 600,
      initial: _crop,
    );
    if (result != null && mounted) setState(() => _crop = result);
  }

  @override
  Widget build(BuildContext context) {
    final r = _crop.rect;
    return DemoPage(
      children: [
        Text(
          'Crop ${r.left.toStringAsFixed(2)}, ${r.top.toStringAsFixed(2)} · '
          '${r.width.toStringAsFixed(2)} × ${r.height.toStringAsFixed(2)}',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        Button('Edit crop', onPressed: _open),
      ],
    );
  }
}
