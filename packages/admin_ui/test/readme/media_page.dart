// The sample under "A media page" in README.md, verbatim below the
// imports. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A media page over [source], below the app's `LangScope`: search, the
/// type filter and an "Unused" filter of the app's, a page at a time, and
/// each asset's details with a Crop of the app's.
class MediaPage extends StatefulWidget {
  const MediaPage({super.key, required this.source});

  final AssetSource source;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  late final _library = AssetLibraryController(source: widget.source);
  bool _unused = false;

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  void _showUnused(bool unused) {
    setState(() => _unused = unused);
    // The source answers 'inUse' where the assets are: the grid still pages.
    _library.where = [if (unused) const BoolFilter('inUse', false)];
  }

  void _open(Asset asset) => showAssetDetail(
    ModalAnchor.of(context),
    // AdminScope's anchor is above this page: the sheet takes the page's
    // LangScope, for the alt text, from here.
    context: context,
    asset: asset,
    onSaveAlt: (alt) async {
      final saved = await widget.source.updateAlt(asset.id, alt);
      if (saved != null) _library.replace(saved);
      return saved;
    },
    footerActions: [
      if (asset.thumbnail case final image?)
        Button(
          'Crop',
          icon: Icons.crop_rounded,
          variant: ButtonVariant.secondary,
          onPressed: () => showCropDialog(
            context,
            image: image,
            imageAspect: (asset.width ?? 1) / (asset.height ?? 1),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AssetLibrary.connected(
      controller: _library,
      onOpen: _open,
      toolbarActions: [
        FilterMenuButton<bool>(
          value: _unused,
          tooltip: 'Usage',
          onChanged: _showUnused,
          options: const [
            FilterMenuOption(false, 'All assets'),
            FilterMenuOption(true, 'Unused', icon: Icons.link_off_rounded),
          ],
        ),
      ],
    );
  }
}
