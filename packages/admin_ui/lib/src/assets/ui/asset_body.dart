/// @docImport '../../common/ui/field_chrome.dart';
/// @docImport '../../fields/ui/field_shell.dart';
/// @docImport '../../fields/ui/media_body.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/error_text.dart';
import '../../fields/ui/media_body.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../asset_source.dart';
import 'asset_drop_target.dart' show AssetAccept;
import 'asset_library.dart' show Asset, AssetType;
import 'asset_picker.dart';

/// The bare single-asset control — a thumbnail tile that opens the shared
/// [showAssetPicker] to choose/replace, and clears on remove. Chrome-free (like
/// [MediaBody]) so it sits inside a [FieldShell] (the `AssetField` preset) or a
/// record row (a gallery item) unchanged.
///
/// [value] is the stored asset id (null = unset); editing reports the new id
/// (or null) through [onChanged]. Previews resolve through the ambient
/// [AssetSourceScope], again whenever the scope's source or [value] changes;
/// an id the source no longer knows shows as 'Asset not found', which a tap
/// replaces and × clears, and one that fails to load offers a retry. With no
/// scope it degrades to a read-only placeholder.
///
/// [accept] — by default what [kind] implies — is what the picker takes, and
/// its [AssetAccept.hintOf] line is shown in the empty drop zone.
///
/// A null [onChanged] renders it read-only (see [FieldState]). [enabled]
/// false, or a disabled [FieldStateScope], disables it.
class AssetBody extends StatefulWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final MediaKind kind;
  final AssetAccept? accept;

  final bool enabled;

  const AssetBody({
    super.key,
    required this.value,
    this.onChanged,
    this.kind = MediaKind.image,
    this.accept,
    this.enabled = true,
  });

  @override
  State<AssetBody> createState() => _AssetBodyState();
}

enum _Resolve { none, loading, ready, missing, failed }

class _AssetBodyState extends State<AssetBody> {
  AssetSource? _source;
  Asset? _resolved;
  var _phase = _Resolve.none;
  int _reqId = 0;

  /// Why the last resolve failed, worded in build.
  Object? _error;

  AssetAccept get _accept => widget.accept ?? AssetAccept.forKind(widget.kind);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The scope is read here, never in initState: this runs before the first
    // build and again whenever the scope above changes.
    final source = AssetSourceScope.maybeOf(context);
    if (identical(source, _source) && _phase != _Resolve.none) return;
    _source = source;
    _resolve();
  }

  @override
  void didUpdateWidget(AssetBody old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _resolve();
  }

  Future<void> _resolve() async {
    final id = widget.value;
    final source = _source;
    final req = ++_reqId;
    if (id == null || source == null) {
      _set(null, id == null ? _Resolve.none : _Resolve.loading);
      return;
    }
    _set(null, _Resolve.loading);
    Asset? asset;
    try {
      asset = await source.resolve(id);
    } catch (e) {
      if (mounted && req == _reqId) {
        _error = e;
        _set(null, _Resolve.failed);
      }
      return;
    }
    if (!mounted || req != _reqId) return;
    _set(asset, asset == null ? _Resolve.missing : _Resolve.ready);
  }

  void _set(Asset? asset, _Resolve phase) {
    // Called from didChangeDependencies before the first build too, where the
    // element is already dirty.
    setState(() {
      _resolved = asset;
      _phase = phase;
    });
  }

  Future<void> _pick() async {
    final source = AssetSourceScope.maybeOf(context);
    final onChanged = widget.onChanged;
    if (source == null || onChanged == null) return;
    final accept = _accept;
    final id = await showAssetPicker(
      context,
      source: source,
      initialFilter: accept.imagesOnly ? AssetType.image : null,
      accept: accept,
    );
    if (id != null) onChanged(id);
  }

  MediaItem _item(String id) {
    final asset = _resolved;
    final l10n = context.adminL10n;
    return switch (_phase) {
      _Resolve.ready when asset != null => MediaItem(
        id: id,
        name: asset.name,
        bytes: asset.bytes,
        thumbnail: asset.thumbnail,
        swatch: asset.swatch,
      ),
      _Resolve.missing => MediaItem(
        id: id,
        name: l10n.assetNotFound,
        icon: Icons.broken_image_outlined,
      ),
      _Resolve.failed => MediaItem(
        id: id,
        name: l10n.assetPreview,
        status: MediaStatus.error,
        errorText: _error == null
            ? null
            : ErrorTextScope.describe(context, _error!),
      ),
      _ => MediaItem(
        id: id,
        name: l10n.loading,
        status: MediaStatus.processing,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasSource = AssetSourceScope.maybeOf(context) != null;
    final value = widget.value;
    return MediaBody(
      kind: widget.kind,
      maxItems: 1,
      items: [if (value != null) _item(value)],
      readOnly: !hasSource || widget.onChanged == null,
      enabled: widget.enabled,
      accept: _accept.hintOf(context),
      onAddRequested: _pick,
      onTap: (_) => _pick(),
      onRetry: (_) => _resolve(),
      onRemove: (_) => widget.onChanged?.call(null),
    );
  }
}
