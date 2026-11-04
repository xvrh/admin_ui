/// @docImport 'asset_editor.dart';
library;

import 'package:flutter/widgets.dart';

import '../assets/ui/asset_drop_target.dart' show AssetAccept;
import 'asset_media_canvas.dart';
import 'cell.dart';
import 'value_fields.dart' show foldWhenHidden;
import 'value_form.dart';

/// A first-class asset-reference field — the picker plus the per-usage metadata
/// a real `AssetRef` unlocks over a bare id: a translated alt and a
/// non-destructive crop + focal point, each its own CRDT key so they merge
/// independently. Renders as a single-slot media tile (drop a file to upload,
/// the add tile to pick); tapping the image opens the shared [showAssetEditor]
/// dialog where alt and crop live — aligned with each gallery item. [accept]
/// is what drops and the picker take. The picker and the editor open on the
/// nearest `ModalAnchor` and see the scopes this field sees, its
/// `AssetSourceScope` and `LangScope` among them, wherever that anchor is.
///
/// In a [ValueForm], rules filed under the ref's id
/// (`FieldRules(ref.assetId, …, id: ref.id)`) mark it required, show their
/// message and fold it away while `visibleWhen` hides it.
class AssetRefField extends StatelessWidget {
  final AssetRefCell cell;
  final String label;
  final Widget? help;
  final AssetAccept accept;
  final bool required;

  const AssetRefField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.accept = AssetAccept.images,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final required =
        this.required || ValueFormScope.isRequired(context, cell.id);
    final field = ValueListenableBuilder<String?>(
      valueListenable: cell.assetId,
      builder: (context, id, _) => AssetMediaCanvas(
        label: label,
        fieldId: cell.id,
        help: help,
        required: required,
        cells: id == null ? const [] : [cell],
        maxItems: 1,
        accept: accept,
        onAdd: (assetId) => cell.assetId.set(assetId),
        onRemoveAt: (_) => cell.assetId.set(null),
      ),
    );
    return foldWhenHidden(context, cell.id, field);
  }
}
