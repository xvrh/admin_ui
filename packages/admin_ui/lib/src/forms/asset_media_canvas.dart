/// @docImport 'asset_list_field.dart';
/// @docImport 'asset_ref_field.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../assets/asset_source.dart';
import '../assets/asset_upload_controller.dart';
import '../assets/ui/asset_drop_target.dart';
import '../assets/ui/asset_library.dart' show Asset, AssetType;
import '../assets/ui/asset_picker.dart';
import '../common/ui/error_text.dart';
import '../common/ui/field_chrome.dart';
import '../fields/ui/change_scope.dart';
import '../fields/ui/field_shell.dart';
import '../fields/ui/media_body.dart';
import '../i18n/lang_scope.dart';
import '../i18n/locale_status.dart' show modifiedLocalesDetail;
import '../l10n/admin_ui_localizations.dart';
import 'asset_editor.dart';
import 'cell.dart';
import 'value_fields.dart' show CommentsScope, FieldErrorsScope;

/// The shared asset surface behind both the single [AssetRefField] and the
/// gallery [AssetListField]: a [MediaBody] grid wrapped in a [FieldShell] and a
/// per-field file drop target, with one upload queue. Committed [cells] resolve
/// to thumbnails; in-flight uploads render busy tiles merged after them. Tap a
/// committed tile to open the shared editor; drop or use the add tile to upload
/// / pick.
///
/// A reference the source no longer knows shows as 'Asset not found': tap it
/// to replace it, or × to remove it. One whose preview failed to load shows
/// as an error tile that retries. [accept] (by default what [kind] implies)
/// governs drops and the picker alike.
///
/// The two fields differ only in how a picked/uploaded asset attaches: single
/// sets its one cell ([onAdd] = set, [onRemoveAt] = clear), gallery appends a
/// record ([onAdd] = add+set, [onRemoveAt] = removeAt, [onReorder] = move).
///
/// Like a bound field, it shows the [FieldErrorsScope] message for [fieldId],
/// and takes no drop, pick or removal under a read-only or disabled
/// [FieldStateScope].
class AssetMediaCanvas extends StatefulWidget {
  final String label;
  final String fieldId;
  final Widget? help;
  final bool required;
  final List<AssetRefCell> cells;
  final int? maxItems;
  final bool cover;
  final MediaKind kind;
  final AssetAccept? accept;
  final void Function(String assetId) onAdd;
  final void Function(int index) onRemoveAt;
  final void Function(int from, int to)? onReorder;

  const AssetMediaCanvas({
    super.key,
    required this.label,
    required this.fieldId,
    required this.cells,
    required this.onAdd,
    required this.onRemoveAt,
    this.onReorder,
    this.help,
    this.required = false,
    this.maxItems,
    this.cover = false,
    this.kind = MediaKind.image,
    this.accept,
  });

  @override
  State<AssetMediaCanvas> createState() => _AssetMediaCanvasState();
}

class _AssetMediaCanvasState extends State<AssetMediaCanvas> {
  final _uploads = AssetUploadController();
  AssetSource? _source;
  final _assets = <String, Asset>{};

  /// Ids the source answered null for: deleted since they were attached.
  final _missing = <String>{};

  /// Ids whose resolve threw, with the raw error.
  final _failed = <String, Object>{};
  final _resolving = <String>{};
  final _subs = <ValueListenable<String?>, VoidCallback>{};

  AssetAccept get _accept => widget.accept ?? AssetAccept.forKind(widget.kind);

  @override
  void initState() {
    super.initState();
    _uploads.addListener(_onChange);
    _resync();
  }

  @override
  void didUpdateWidget(AssetMediaCanvas old) {
    super.didUpdateWidget(old);
    _resync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final source = AssetSourceScope.maybeOf(context);
    if (!identical(source, _source)) {
      _source = source;
      _assets.clear();
      _missing.clear();
      _failed.clear();
      _resolving.clear();
    }
    _resolveMissing();
  }

  @override
  void dispose() {
    _uploads.removeListener(_onChange);
    _uploads.dispose();
    for (final e in _subs.entries) {
      e.key.removeListener(e.value);
    }
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  /// One listener per committed cell's assetId (stable identity) so a
  /// replace/collab edit rebuilds; drop dead subscriptions.
  void _resync() {
    final live = <ValueListenable<String?>>{};
    for (final cell in widget.cells) {
      final aid = cell.assetId;
      live.add(aid);
      _subs.putIfAbsent(aid, () {
        void cb() {
          _resolveMissing();
          if (mounted) setState(() {});
        }

        aid.addListener(cb);
        return cb;
      });
    }
    for (final aid in _subs.keys.toList()) {
      if (!live.contains(aid)) aid.removeListener(_subs.remove(aid)!);
    }
  }

  void _resolveMissing() {
    final source = _source;
    if (source == null) return;
    for (final cell in widget.cells) {
      final id = cell.assetId.value;
      if (id == null ||
          _assets.containsKey(id) ||
          _missing.contains(id) ||
          _failed.containsKey(id) ||
          _resolving.contains(id)) {
        continue;
      }
      _resolving.add(id);
      source
          .resolve(id)
          .then(
            (asset) {
              if (!mounted || !identical(source, _source)) return;
              setState(() {
                _resolving.remove(id);
                if (asset == null) {
                  _missing.add(id);
                } else {
                  _assets[id] = asset;
                }
              });
            },
            onError: (Object error) {
              if (!mounted || !identical(source, _source)) return;
              setState(() {
                _resolving.remove(id);
                _failed[id] = error;
              });
            },
          );
    }
  }

  MediaItem _committedItem(int index, AssetRefCell cell) {
    final id = cell.assetId.value;
    final asset = id == null ? null : _assets[id];
    if (asset != null) {
      return MediaItem(
        id: '$index',
        name: asset.name,
        bytes: asset.bytes,
        thumbnail: asset.thumbnail,
        swatch: asset.swatch,
      );
    }
    final strings = context.adminL10n;
    if (id == null) {
      return MediaItem(id: '$index', name: strings.assets.kindImage);
    }
    if (_missing.contains(id)) {
      return MediaItem(
        id: '$index',
        name: strings.assetNotFound,
        icon: Icons.broken_image_outlined,
      );
    }
    if (_failed[id] case final error?) {
      return MediaItem(
        id: '$index',
        name: strings.assetPreview,
        status: MediaStatus.error,
        errorText: ErrorTextScope.describe(context, error),
      );
    }
    return MediaItem(
      id: '$index',
      name: strings.loading,
      status: MediaStatus.processing,
    );
  }

  Future<String?> _pickOne() {
    final source = _source!;
    final accept = _accept;
    return showAssetPicker(
      context,
      source: source,
      initialFilter: accept.imagesOnly ? AssetType.image : null,
      accept: accept,
    );
  }

  Future<void> _pick() async {
    if (_source == null) return;
    final id = await _pickOne();
    if (id != null) widget.onAdd(id);
  }

  /// Points [cell] at another asset. A crop is geometry of the previous
  /// image; alt usually still applies.
  Future<void> _replace(AssetRefCell cell) async {
    if (_source == null) return;
    final id = await _pickOne();
    if (id == null) return;
    cell.assetId.set(id);
    cell.crop.set(null);
  }

  void _onDropped(List<DroppedAsset> files) {
    final source = _source;
    if (source == null) return;
    final allowed = widget.maxItems == 1
        ? files.take(1)
        : widget.maxItems == null
        ? files
        : files.take(math.max(0, widget.maxItems! - widget.cells.length));
    _uploads.enqueue(allowed.toList(), source, onUploaded: widget.onAdd);
  }

  AssetRefCell? _cellAt(String itemId) {
    final i = int.tryParse(itemId);
    return i != null && i < widget.cells.length ? widget.cells[i] : null;
  }

  void _onRemove(String id) {
    final i = int.tryParse(id);
    if (i != null && i < widget.cells.length) {
      widget.onRemoveAt(i);
    } else {
      _uploads.remove(id);
    }
  }

  void _onRetry(String itemId) {
    final cell = _cellAt(itemId);
    if (cell != null) {
      final id = cell.assetId.value;
      if (id != null) setState(() => _failed.remove(id));
      _resolveMissing();
    } else if (_source case final source?) {
      _uploads.retry(itemId, source, widget.onAdd);
    }
  }

  void _onTap(MediaItem item) {
    final cell = _cellAt(item.id);
    if (cell == null) return;
    if (_missing.contains(cell.assetId.value)) {
      _replace(cell);
    } else {
      showAssetEditor(context, cell, label: widget.label, accept: _accept);
    }
  }

  @override
  Widget build(BuildContext context) {
    _resolveMissing();
    final hasSource = _source != null;
    final state = FieldStateScope.of(context);
    final committed = [
      for (var i = 0; i < widget.cells.length; i++)
        _committedItem(i, widget.cells[i]),
    ];
    final items = [...committed, ..._uploads.busyItems(context)];
    // Reorder only makes sense over committed tiles; suppress it while uploads
    // are in flight (busy tiles sit at the tail and would skew indices).
    final canReorder = widget.onReorder != null && _uploads.isEmpty;
    final summary = ChangeScope.summaryOf(context, widget.fieldId);
    final lang = LangScope.maybeOf(context);
    return FieldShell(
      label: widget.label,
      fieldId: widget.fieldId,
      help: widget.help,
      required: widget.required,
      errorText: FieldErrorsScope.errorOf(context, widget.fieldId),
      comments: CommentsScope.maybeOf(context)?.buttonFor(widget.fieldId),
      modified: summary.modified,
      modifiedDetail: lang == null
          ? null
          : modifiedLocalesDetail(lang.locales, summary.lanes),
      child: AssetDropTarget(
        accept: _accept,
        enabled: hasSource && state.enabled && !state.readOnly,
        onFiles: _onDropped,
        builder: (context, dragOver) => MediaBody(
          kind: widget.kind,
          items: items,
          maxItems: widget.maxItems,
          cover: widget.cover,
          dragOver: dragOver,
          readOnly: !hasSource,
          accept: _accept.hintOf(context),
          onAddRequested: _pick,
          onRemove: _onRemove,
          onRetry: _onRetry,
          onReorder: canReorder ? widget.onReorder : null,
          onTap: _onTap,
        ),
      ),
    );
  }
}
