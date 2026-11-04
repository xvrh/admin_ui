/// @docImport '../common/ui/admin_scope.dart';
/// @docImport 'asset_list_field.dart';
/// @docImport 'asset_ref_field.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../assets/asset_source.dart';
import '../assets/external_provider.dart';
import '../assets/ui/asset_drop_target.dart';
import '../assets/ui/asset_library.dart' show Asset, AssetType;
import '../assets/ui/asset_picker.dart';
import '../assets/ui/image_cropper.dart';
import '../common/ui/button.dart';
import '../common/ui/error_text.dart';
import '../common/ui/field_presence.dart';
import '../common/ui/modal.dart';
import '../common/ui/modal_anchor.dart';
import '../common/ui/spinner.dart';
import '../common/ui/thumbnail_image.dart';
import '../i18n/lang_scope.dart';
import '../l10n/admin_ui_localizations.dart';
import '../theme/sizes.dart';
import '../theme/spacing.dart';
import '../theme/tokens.dart';
import 'cell.dart';
import 'field_binder.dart';
import 'relayed_scopes.dart';
import 'value_fields.dart' show Field;

/// The shared asset editor — one dialog assembling every per-asset option:
/// preview, Replace (library picker), Remove, translated alt text, and crop &
/// focal (a sub-dialog). Used by both the single [AssetRefField] and each
/// gallery item, so the two stay aligned. Operates on one [AssetRefCell].
///
/// Titled [title], else "Edit [label]" in the app's language, with [label]
/// placed as given. [accept] is what Replace and a drop onto the preview
/// take.
///
/// Opens on the nearest [ModalAnchor], which may sit above the page's own
/// scopes, as [AdminScope]'s does around the whole frame. The editor, and
/// the picker its Replace opens, see the [AssetSourceScope],
/// [ExternalProviderScope], [LangScope], [FieldPresenceScope] and
/// [FieldBinderScope] that [context] sees: those the anchor does not provide
/// are taken from [context] and provided again inside, so a page needs no
/// anchor of its own below them. A language shown or hidden in the alt
/// lanes goes to the page's [LangScope], which the editor then follows.
Future<void> showAssetEditor(
  BuildContext context,
  AssetRefCell cell, {
  required String label,
  String? title,
  AssetAccept accept = AssetAccept.images,
}) {
  final modals = ModalAnchor.of(context);
  final opener = OpenerScopes.of(context);
  return modals.show<void>(
    builder: (_) => RelayedScopes(
      opener: opener,
      child: _AssetEditorDialog(
        cell: cell,
        label: label,
        title: title,
        accept: accept,
        modals: modals,
      ),
    ),
  );
}

/// Where the editor's preview stands.
enum _Preview { none, loading, ready, missing, failed }

class _AssetEditorDialog extends StatefulWidget {
  final AssetRefCell cell;
  final String label;
  final String? title;
  final AssetAccept accept;

  /// The anchor this dialog is shown on — its close handle.
  final ModalAnchorController modals;

  const _AssetEditorDialog({
    required this.cell,
    required this.label,
    required this.title,
    required this.accept,
    required this.modals,
  });

  @override
  State<_AssetEditorDialog> createState() => _AssetEditorDialogState();
}

class _AssetEditorDialogState extends State<_AssetEditorDialog> {
  /// The picker opens *over* this dialog, so it needs its own anchor — the
  /// outer one (showing this dialog) is busy.
  final _pickerModals = ModalAnchorController();

  Asset? _resolved;
  var _phase = _Preview.none;
  int _reqId = 0;
  bool _uploading = false;

  /// The raw upload failure, worded in build.
  Object? _uploadError;

  /// The source answered an upload with no asset and no error.
  bool _uploadIncomplete = false;

  AssetRefCell get _cell => widget.cell;

  @override
  void initState() {
    super.initState();
    _cell.assetId.addListener(_onAsset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void dispose() {
    _cell.assetId.removeListener(_onAsset);
    super.dispose();
  }

  void _onAsset() {
    _resolve();
    if (mounted) setState(() {});
  }

  Future<void> _resolve() async {
    final id = _cell.assetId.value;
    final req = ++_reqId;
    final source = AssetSourceScope.maybeOf(context);
    if (id == null || source == null) {
      setState(() {
        _resolved = null;
        _phase = _Preview.none;
      });
      return;
    }
    setState(() => _phase = _Preview.loading);
    Asset? asset;
    try {
      asset = await source.resolve(id);
    } catch (_) {
      if (mounted && req == _reqId) setState(() => _phase = _Preview.failed);
      return;
    }
    if (!mounted || req != _reqId) return;
    setState(() {
      _resolved = asset;
      _phase = asset == null ? _Preview.missing : _Preview.ready;
    });
  }

  Future<void> _replace() async {
    final source = AssetSourceScope.maybeOf(context);
    if (source == null) return;
    final id = await showAssetPicker(
      context,
      modals: _pickerModals,
      source: source,
      initialFilter: widget.accept.imagesOnly ? AssetType.image : null,
      accept: widget.accept,
    );
    if (id != null) _swap(id);
  }

  /// A crop is geometry of the previous image; alt usually still applies.
  void _swap(String id) {
    _cell.assetId.set(id);
    _cell.crop.set(null);
  }

  Future<void> _onDropped(List<DroppedAsset> files) async {
    final source = AssetSourceScope.maybeOf(context);
    if (source == null || files.isEmpty || _uploading) return;
    final file = files.first;
    setState(() {
      _uploading = true;
      _uploadError = null;
      _uploadIncomplete = false;
    });
    Object? error;
    String? id;
    try {
      final asset = await source.upload(
        file.bytes,
        mime: file.mime,
        filename: file.name,
      );
      id = asset?.id;
    } catch (e) {
      error = e;
    }
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (id == null) {
        _uploadError = error;
        _uploadIncomplete = error == null;
      }
    });
    if (id != null) _swap(id);
  }

  Future<void> _editCrop() async {
    final asset = _resolved;
    final image = asset?.thumbnail;
    if (asset == null || image == null) return;
    final aspect =
        (asset.width != null && asset.height != null && asset.height! > 0)
        ? asset.width! / asset.height!
        : 1.0;
    final result = await showCropDialog(
      context,
      image: image,
      imageAspect: aspect,
      initial: _cell.crop.value ?? CropValue.full,
    );
    if (result != null) _cell.crop.set(result);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    final uploadError = switch (_uploadError) {
      final error? => ErrorTextScope.describe(context, error),
      null when _uploadIncomplete => strings.uploadIncomplete,
      null => null,
    };
    return ModalAnchor(
      controller: _pickerModals,
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Modal(
          title: widget.title ?? strings.editItem(widget.label),
          onDismiss: () => Navigator.of(context).maybePop(),
          maxWidth: 520,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _preview(context),
              if (uploadError != null) ...[
                const Gap(AdminSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    uploadError,
                    style: context.type.caption.copyWith(
                      color: context.colors.dangerText,
                    ),
                  ),
                ),
              ],
              const Gap(AdminSpacing.lg),
              _actions(context),
              const Gap(AdminSpacing.lg),
              // Empty lanes ghost the asset's library default; a typed value
              // is this usage's override.
              Field(
                _cell.alt,
                label: strings.altText,
                laneHints: _resolved?.alt,
              ),
            ],
          ),
          actions: [
            Button.primary(
              strings.done,
              onPressed: () => widget.modals.close(),
            ),
          ],
        ),
      ),
    );
  }

  /// The preview doubles as a drop target: dropping an image uploads it and
  /// replaces the asset in place.
  Widget _preview(BuildContext context) {
    final colors = context.colors;
    final strings = context.adminL10n;
    final thumb = _resolved?.thumbnail;
    final swatch = _resolved?.swatch ?? colors.surfaceMuted;
    final radius = BorderRadius.circular(context.radii.radius);
    return AssetDropTarget(
      accept: widget.accept,
      enabled: AssetSourceScope.maybeOf(context) != null,
      onFiles: _onDropped,
      builder: (context, dragOver) => ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              switch (_phase) {
                _Preview.ready when thumb != null => ThumbnailImage(
                  image: thumb,
                  borderRadius: radius,
                  semanticLabel: _resolved?.name,
                ),
                _Preview.missing => _status(
                  context,
                  Icons.broken_image_outlined,
                  strings.assetNotFound,
                ),
                _Preview.failed => _status(
                  context,
                  Icons.error_outline,
                  strings.assets.couldNotLoadPreview,
                  action: Button(
                    strings.retry,
                    variant: ButtonVariant.secondary,
                    size: ControlSize.small,
                    onPressed: _resolve,
                  ),
                ),
                _ => Container(
                  color: swatch,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    // token-literal: a glyph drawn over a colour swatch
                    color: colors.foregroundOn(swatch).withValues(alpha: 0.7),
                    size: 32,
                  ),
                ),
              },
              if (_uploading)
                ColoredBox(
                  color: colors.imageScrim,
                  child: Center(
                    child: Spinner(
                      size: context.iconSizes.xl,
                      color: colors.onImage,
                      semanticLabel: strings.assets.uploading,
                    ),
                  ),
                ),
              if (dragOver)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: colors.stateLayer.tintHover,
                      ),
                      border: Border.all(
                        color: colors.primary,
                        width: context.stroke.indicator,
                      ),
                      borderRadius: radius,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(
    BuildContext context,
    IconData icon,
    String message, {
    Widget? action,
  }) {
    final colors = context.colors;
    final text = colors.readableOn(
      colors.foregroundMuted,
      surfaces: [colors.surfaceMuted],
    );
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: text),
            const Gap(AdminSpacing.sm),
            Text(message, style: context.type.body.copyWith(color: text)),
            if (action != null) ...[const Gap(AdminSpacing.md), action],
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final strings = context.adminL10n;
    final hasAsset = _cell.assetId.value != null;
    final canCrop = _phase == _Preview.ready && _resolved?.thumbnail != null;
    return Row(
      children: [
        Button(
          hasAsset ? strings.assets.replace : strings.assets.choose,
          variant: ButtonVariant.secondary,
          size: ControlSize.small,
          onPressed: _replace,
        ),
        if (hasAsset) ...[
          const Gap(AdminSpacing.md),
          Button(
            strings.assets.editCrop,
            variant: ButtonVariant.secondary,
            size: ControlSize.small,
            onPressed: canCrop ? _editCrop : null,
          ),
        ],
        const Spacer(),
        if (hasAsset)
          Button(
            strings.remove,
            variant: ButtonVariant.ghost,
            size: ControlSize.small,
            onPressed: () => _cell.assetId.set(null),
          ),
      ],
    );
  }
}

/// Opens the crop & focal-point editor over [image] ([imageAspect] is its
/// pixel width / height), starting from [initial], and resolves the chosen
/// [CropValue] — null when cancelled. The ratio presets lock the crop: the
/// one a saved crop already matches starts chosen. The asset editor's
/// "Edit crop" opens it.
Future<CropValue?> showCropDialog(
  BuildContext context, {
  required ImageProvider image,
  required double imageAspect,
  CropValue initial = CropValue.full,
}) {
  return showModal<CropValue>(
    context,
    builder: (_) =>
        _CropDialog(image: image, aspect: imageAspect, initial: initial),
  );
}

/// The crop dialog on the kit [Modal]: the chosen [AspectPreset] is kept
/// and passed back to the cropper as its locked ratio.
class _CropDialog extends StatefulWidget {
  final ImageProvider image;
  final double aspect;
  final CropValue initial;
  const _CropDialog({
    required this.image,
    required this.aspect,
    required this.initial,
  });

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  late CropValue _value = widget.initial;
  late AspectPreset _preset = _presetOf(widget.initial);

  /// The preset a saved crop already has the shape of, else Free.
  AspectPreset _presetOf(CropValue value) {
    if (value.rect == CropValue.full.rect) return AspectPreset.free;
    final shown = value.quarterTurns.isOdd ? 1 / widget.aspect : widget.aspect;
    final ratio = value.rect.width / value.rect.height * shown;
    for (final p in AspectPreset.defaults) {
      final r = p.ratio;
      if (r != null && (ratio - r).abs() / r < 0.01) return p;
    }
    return AspectPreset.free;
  }

  @override
  Widget build(BuildContext context) {
    final height = math.min(
      440.0,
      math.max(240.0, MediaQuery.sizeOf(context).height - 320),
    );
    return Modal(
      title: context.adminL10n.assets.cropAndFocalPoint,
      onDismiss: () => Navigator.of(context).maybePop(),
      size: ModalSize.large,
      body: SizedBox(
        height: height,
        child: ImageCropper(
          image: widget.image,
          imageAspect: widget.aspect,
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          showFocalPoint: true,
          lockedAspect: _preset.ratio,
          aspectPresets: AspectPreset.defaults,
          onAspectChanged: (p) => setState(() => _preset = p),
          allowRotate: true,
          allowFlip: true,
          allowReset: true,
          allowStraighten: true,
        ),
      ),
      actions: [
        Button(
          MaterialLocalizations.of(context).cancelButtonLabel,
          variant: ButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        Button.primary(
          context.adminL10n.apply,
          onPressed: () => Navigator.of(context).pop(_value),
        ),
      ],
    );
  }
}
