import 'package:flutter/widgets.dart';

import '../assets/ui/asset_drop_target.dart' show AssetAccept;
import 'asset_media_canvas.dart';
import 'cell.dart';
import 'value_fields.dart' show foldWhenHidden;
import 'value_form.dart';

/// A connected gallery field: an owned-record list whose elements each carry an
/// [AssetRefCell], rendered through the shared [AssetMediaCanvas] as one media
/// grid (drop to upload · add tile to pick · × to remove · drag to reorder ·
/// tap to edit). [image] projects each element handle [H] to its asset-ref
/// cell. Single and gallery thus share one surface and one editor. [accept]
/// is what drops and the picker take. The picker and the editor open on the
/// nearest `ModalAnchor` and see the scopes this field sees, wherever that
/// anchor is (see `showAssetEditor`). In a [ValueForm] it follows the rules
/// for the list's id, as a bound field does: required, its message, or folded
/// away while hidden; `ListRules` count its items.
class AssetListField<H> extends StatelessWidget {
  final RecordListCell<H> cell;
  final String label;
  final AssetRefCell Function(H element) image;
  final Widget? help;
  final bool cover;
  final int? maxItems;
  final AssetAccept accept;
  final bool required;

  const AssetListField(
    this.cell, {
    super.key,
    required this.label,
    required this.image,
    this.help,
    this.cover = false,
    this.maxItems,
    this.accept = AssetAccept.images,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final required =
        this.required || ValueFormScope.isRequired(context, cell.id);
    final field = ListenableBuilder(
      listenable: cell,
      builder: (context, _) {
        final cells = [for (final e in cell.elements) image(e)];
        return AssetMediaCanvas(
          label: label,
          fieldId: cell.id,
          help: help,
          required: required,
          cells: cells,
          cover: cover,
          maxItems: maxItems,
          accept: accept,
          onAdd: (assetId) {
            cell.add();
            final els = cell.elements;
            if (els.isNotEmpty) image(els.last).assetId.set(assetId);
          },
          onRemoveAt: cell.removeAt,
          onReorder: cell.move,
        );
      },
    );
    return foldWhenHidden(context, cell.id, field);
  }
}
