import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/dashed_border.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/progress_bar.dart';
import '../../common/ui/spinner.dart';
import '../../common/ui/thumbnail_image.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// Whether the field holds pictures (square thumbnails) or arbitrary files
/// (icon + name + size rows). Same chrome, different tile body.
enum MediaKind { image, file }

/// Lifecycle of one uploaded item. [MediaItem.progress] is only meaningful
/// while [uploading], and [MediaItem.errorText] only while [error].
enum MediaStatus { queued, uploading, processing, ready, error }

/// One asset in a media field. View-only: no bytes are fetched here — an image
/// thumbnail is stood in by [swatch] so the demo needs no network.
class MediaItem {
  final String id;
  final String name;
  final int? bytes;
  final MediaStatus status;

  /// 0..1, drawn as a progress bar while [MediaStatus.uploading].
  final double progress;

  /// The real preview for an image item, rendered cover-fit when present.
  final ImageProvider? thumbnail;

  /// Placeholder thumbnail tint when [thumbnail] is absent (view stand-in).
  final Color? swatch;

  /// Glyph for a file item (defaulting by extension), or the stand-in glyph
  /// of an image item without a [thumbnail].
  final IconData? icon;

  /// Why the item failed, shown while [MediaStatus.error]; null reads the
  /// kit's "Upload failed".
  final String? errorText;

  const MediaItem({
    required this.id,
    required this.name,
    this.bytes,
    this.status = MediaStatus.ready,
    this.progress = 0,
    this.thumbnail,
    this.swatch,
    this.icon,
    this.errorText,
  });

  bool get isBusy =>
      status == MediaStatus.queued ||
      status == MediaStatus.uploading ||
      status == MediaStatus.processing;

  /// Progress guarded to 0..1 for display (a caller may report raw
  /// bytes/total).
  double get clampedProgress => progress.clamp(0, 1).toDouble();
}

/// The bare media control — the grid / file list / drop-zone, no label or
/// capability chrome. Drag-and-drop and the picker are wired by the host; here
/// [dragOver] is just the drop-target highlight and [onAddRequested] fires when
/// the add affordance is used.
///
/// Like [BooleanBody], this is chrome-free so the same body can sit inside a
/// [FieldShell] (one asset list) or one lane of a translatable field (one entry
/// of a per-locale `Translated<media>`).
///
/// [readOnly], or a read-only [FieldStateScope], shows the items with no add,
/// remove, retry or reorder; with none, the field box shows "No media".
///
/// Sizes and progress are in the app's locale ([AdminFormats]).
/// [enabled] false, or a disabled [FieldStateScope], also dims them. An
/// invalid scope turns the drop zone's and the add tile's dashes red.
class MediaBody extends StatelessWidget {
  final MediaKind kind;

  /// Cap on how many items may be held. `null` = unlimited, `1` = a single
  /// asset (no reorder, replace-in-place). The add affordance hides at the cap.
  final int? maxItems;

  final List<MediaItem> items;

  /// Badge the first image as the cover/hero (image galleries only).
  final bool cover;

  /// Drop-target highlight. The host flips this on real drag-enter/leave.
  final bool dragOver;

  final bool readOnly;

  final bool enabled;

  /// Accept hint shown in the empty drop zone, e.g. 'PNG, JPG · up to 10 MB'.
  final String? accept;

  final VoidCallback? onAddRequested;

  /// Removes an item by id; on an item still uploading, cancels the upload.
  /// Busy items offer the cancel only when this is set.
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onRetry;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final ValueChanged<MediaItem>? onTap;

  const MediaBody({
    super.key,
    this.kind = MediaKind.image,
    this.maxItems,
    this.items = const [],
    this.cover = false,
    this.dragOver = false,
    this.readOnly = false,
    this.enabled = true,
    this.accept,
    this.onAddRequested,
    this.onRemove,
    this.onRetry,
    this.onReorder,
    this.onTap,
  });

  /// Holds more than one asset — drives reorder + plural copy.
  bool get _multiple => maxItems == null || maxItems! > 1;

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: enabled,
      readOnly: readOnly,
      builder: (context) {
        final state = FieldStateScope.of(context);
        final editable = state.enabled && !state.readOnly;
        if (items.isEmpty) {
          return editable
              ? _DropZone(
                  kind: kind,
                  multiple: _multiple,
                  accept: accept,
                  dragOver: dragOver,
                  invalid: state.invalid,
                  onTap: onAddRequested,
                )
              : readOnlyEmpty(context, context.adminL10n.fields.noMedia);
        }
        final canAdd =
            editable && (maxItems == null || items.length < maxItems!);
        final body = kind == MediaKind.image
            ? _imageGrid(editable, canAdd, state.invalid)
            : _fileList(context, editable, canAdd);
        return state.enabled
            ? body
            : Opacity(
                opacity: context.colors.stateLayer.disabledContent,
                child: body,
              );
      },
    );
  }

  Widget _imageGrid(bool editable, bool canAdd, bool invalid) {
    final readOnly = !editable;
    return _DragHighlight(
      on: dragOver,
      child: _ReorderableTileWrap(
        itemCount: items.length,
        enabled: _multiple && !readOnly && items.length > 1,
        onReorder: (from, to) => onReorder?.call(from, to),
        footer: canAdd
            ? _AddTile(kind: kind, invalid: invalid, onTap: onAddRequested)
            : null,
        itemBuilder: (i) => _ImageTile(
          key: ValueKey(items[i].id),
          item: items[i],
          readOnly: readOnly,
          isCover: cover && _multiple && i == 0 && items.length > 1,
          onRemove: onRemove,
          onRetry: onRetry,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _fileList(BuildContext context, bool editable, bool canAdd) {
    final readOnly = !editable;
    final last = items.length - 1;
    return _DragHighlight(
      on: dragOver,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            onReorderItem: (oldIndex, newIndex) =>
                onReorder?.call(oldIndex, newIndex),
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  key: ValueKey(items[i].id),
                  padding: EdgeInsets.only(
                    bottom: i == last ? 0 : AdminSpacing.md,
                  ),
                  child: _FileRow(
                    item: items[i],
                    index: i,
                    readOnly: readOnly,
                    // Drag from the handle only (its own ReorderableDragStartListener).
                    reorderable: _multiple && !readOnly && items.length > 1,
                    onRemove: onRemove,
                    onRetry: onRetry,
                    onTap: onTap,
                  ),
                ),
            ],
          ),
          if (canAdd) ...[
            const Gap(AdminSpacing.md),
            AddRowButton(
              label: context.adminL10n.fields.addFile,
              onPressed: onAddRequested,
            ),
          ],
        ],
      ),
    );
  }
}

// ── reorderable wrapping grid (rolled by hand — no SDK ReorderableWrap) ───────

/// A [Wrap] of equal tiles you can drag to reorder. Each tile is a
/// [DragTarget] hosting a [Draggable]; dropping onto tile *i* inserts the
/// dragged tile before it (an end zone covers "move to last"). A primary gap
/// opens at the hovered slot. [footer] (e.g. the add tile) is a drop-inert
/// trailing child. When [enabled] is false it degrades to a plain wrap.
///
/// `onReorder(from, to)` reports indices in the post-removal list, matching the
/// `removeAt(from); insert(to)` host contract used by the file list.
class _ReorderableTileWrap extends StatefulWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final void Function(int from, int to) onReorder;
  final Widget? footer;
  final bool enabled;

  static const _spacing = AdminSpacing.md;

  const _ReorderableTileWrap({
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.footer,
    this.enabled = true,
  });

  @override
  State<_ReorderableTileWrap> createState() => _ReorderableTileWrapState();
}

class _ReorderableTileWrapState extends State<_ReorderableTileWrap> {
  /// Per-instance identity so a tile can only be dropped back into its own
  /// grid — a sibling media field's `DragTarget` rejects this group.
  final Object _group = Object();

  int? _dragging;
  int? _hover; // insertion slot, 0..itemCount

  bool _mine((Object, int) data) => identical(data.$1, _group);

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Wrap(
        spacing: _ReorderableTileWrap._spacing,
        runSpacing: _ReorderableTileWrap._spacing,
        children: [
          for (var i = 0; i < widget.itemCount; i++) widget.itemBuilder(i),
          ?widget.footer,
        ],
      );
    }
    return Wrap(
      spacing: _ReorderableTileWrap._spacing,
      runSpacing: _ReorderableTileWrap._spacing,
      children: [
        for (var i = 0; i < widget.itemCount; i++) _slot(i),
        _endSlot(),
      ],
    );
  }

  Widget _slot(int i) {
    var tile = widget.itemBuilder(i);
    return DragTarget<(Object, int)>(
      onWillAcceptWithDetails: (d) {
        if (!_mine(d.data) || d.data.$2 == i) return false;
        setState(() => _hover = i);
        return true;
      },
      onLeave: (_) => setState(() => _hover = _hover == i ? null : _hover),
      onAcceptWithDetails: (d) => _drop(d.data.$2, i),
      builder: (context, _, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gap(_hover == i),
          Draggable<(Object, int)>(
            data: (_group, i),
            feedback: _feedback(tile),
            childWhenDragging: Opacity(opacity: 0.25, child: tile),
            onDragStarted: () => setState(() => _dragging = i),
            onDragEnd: (_) => setState(() {
              _dragging = null;
              _hover = null;
            }),
            child: tile,
          ),
        ],
      ),
    );
  }

  Widget _endSlot() {
    var target = widget.itemCount;
    var child =
        widget.footer ??
        (_dragging != null
            ? const SizedBox(width: 56, height: _ImageTile._size)
            : const SizedBox.shrink());
    return DragTarget<(Object, int)>(
      onWillAcceptWithDetails: (d) {
        if (!_mine(d.data)) return false;
        setState(() => _hover = target);
        return true;
      },
      onLeave: (_) => setState(() => _hover = _hover == target ? null : _hover),
      onAcceptWithDetails: (d) => _drop(d.data.$2, target),
      builder: (context, _, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [_gap(_hover == target), child],
      ),
    );
  }

  Widget _gap(bool active) {
    final motion = context.motion;
    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      width: active ? AdminSpacing.xs : 0,
      height: _ImageTile._size,
      margin: EdgeInsetsDirectional.only(
        end: active ? _ReorderableTileWrap._spacing : 0,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
    );
  }

  Widget _feedback(Widget tile) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      // token-literal: the lifted tile's shadow
      shadowColor: context.colors.shadow.withValues(alpha: 0.26),
      borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      child: tile,
    );
  }

  void _drop(int from, int target) {
    setState(() {
      _hover = null;
      _dragging = null;
    });
    var to = from < target ? target - 1 : target;
    if (to != from) widget.onReorder(from, to);
  }
}

// ── empty state: dashed drop zone ───────────────────────────────────────────

class _DropZone extends StatelessWidget {
  final MediaKind kind;
  final bool multiple;
  final String? accept;
  final bool dragOver;
  final bool invalid;
  final VoidCallback? onTap;

  const _DropZone({
    required this.kind,
    required this.multiple,
    required this.accept,
    required this.dragOver,
    required this.invalid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = context.adminL10n.dropPrompt(
      multiple: multiple,
      images: kind == MediaKind.image,
    );
    return Tappable(
      onTap: onTap,
      focusRadius: context.radii.radius,
      child: DashedBorder(
        color: dragOver
            ? context.colors.primary
            : invalid
            ? context.colors.danger
            : DashedBorder.restingColor(context),
        radius: context.radii.radius,
        child: Container(
          decoration: BoxDecoration(
            color: dragOver
                ? context.colors.primarySubtle
                : context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(context.radii.radius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AdminSpacing.xxl,
            horizontal: AdminSpacing.xl,
          ),
          child: Column(
            children: [
              Icon(
                kind == MediaKind.image
                    ? Icons.add_photo_alternate_outlined
                    : Icons.upload_file_outlined,
                size: context.iconSizes.xl,
                color: dragOver
                    ? context.colors.primaryText
                    : context.colors.foregroundMuted,
              ),
              const Gap(AdminSpacing.md),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: prompt.before),
                    TextSpan(
                      text: prompt.link,
                      style: context.type.weighted(
                        context.type.bodySmall.copyWith(
                          color: context.colors.primaryText,
                        ),
                        FontWeight.w700,
                      ),
                    ),
                    if (prompt.after.isNotEmpty) TextSpan(text: prompt.after),
                  ],
                  style: context.type.bodySmall.copyWith(
                    color: context.colors.foregroundMutedOnTint,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              if (accept != null) ...[
                const Gap(AdminSpacing.xs),
                Text(
                  accept!,
                  style: context.type.caption.copyWith(
                    color: context.colors.foregroundMutedOnTint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── image tile ──────────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final MediaItem item;
  final bool readOnly;
  final bool isCover;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onRetry;
  final ValueChanged<MediaItem>? onTap;

  const _ImageTile({
    super.key,
    required this.item,
    required this.readOnly,
    this.isCover = false,
    this.onRemove,
    this.onRetry,
    this.onTap,
  });

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    var error = item.status == MediaStatus.error;
    var ready = !readOnly && item.status == MediaStatus.ready;
    final l10n = context.adminL10n;
    // The whole tile opens a settled asset, or retries a failed one; the ring
    // is drawn outside the clip, and the close button sits beside the tile's
    // target rather than inside it.
    VoidCallback? action;
    if (error && !readOnly) {
      action = () => onRetry?.call(item.id);
    } else if (ready) {
      action = () => onTap?.call(item);
    }
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Tappable(
            onTap: action,
            semanticLabel: error ? l10n.fields.retryItem(item.name) : item.name,
            excludeSemantics: true,
            focusRadius: context.radii.radiusSmall,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _thumb(context),
                  if (error)
                    const _ErrorScrim()
                  else if (item.isBusy)
                    _BusyScrim(item: item),
                ],
              ),
            ),
          ),
          // A busy tile's × cancels its upload.
          if (!readOnly && (!item.isBusy || onRemove != null))
            PositionedDirectional(
              top: AdminSpacing.xxs,
              end: AdminSpacing.xxs,
              child: CircleButton(
                icon: Icons.close,
                label: item.isBusy
                    ? l10n.fields.cancelUpload(item.name)
                    : l10n.removeItem(item.name),
                onTap: () => onRemove?.call(item.id),
              ),
            ),
          if (isCover && item.status == MediaStatus.ready)
            const PositionedDirectional(
              bottom: AdminSpacing.xs,
              start: AdminSpacing.xs,
              child: _CoverBadge(),
            ),
        ],
      ),
    );
  }

  Widget _thumb(BuildContext context) {
    if (item.thumbnail != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        ),
        position: DecorationPosition.foreground,
        child: ThumbnailImage(image: item.thumbnail!),
      );
    }
    final icon = item.icon;
    if (item.swatch == null && icon != null && !item.isBusy) {
      // No picture to stand in for (a missing asset): the glyph and the
      // name on the background, so the tile says what it is, in as many of
      // two lines as the tile has room for at the platform's text size.
      final colors = context.colors;
      final style = context.type.caption.copyWith(
        color: colors.foregroundMuted,
      );
      final glyph = context.iconSizes.xl;
      final room = _size - 2 * AdminSpacing.sm - glyph - AdminSpacing.xs;
      final lines = math.min(2, room ~/ lineHeightOf(context, style));
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: glyph, color: colors.foregroundMuted),
              if (lines > 0) ...[
                const Gap(AdminSpacing.xs),
                Text(
                  item.name,
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ],
            ],
          ),
        ),
      );
    }
    var c = item.swatch ?? context.colors.foregroundFaint;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          // token-literal: a swatch's lighter corner
          colors: [c.withValues(alpha: 0.85), c],
        ),
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      // A scrim (busy / error) carries its own glyph; the stand-in icon would
      // show through it.
      child: item.isBusy || item.status == MediaStatus.error
          ? null
          : Center(
              child: Icon(
                item.icon ?? Icons.image_outlined,
                size: context.iconSizes.xl,
                color: context.colors.foregroundOn(c),
              ),
            ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();

  @override
  Widget build(BuildContext context) {
    final onImage = context.colors.onImage;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.imageScrim,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: context.iconSizes.xs, color: onImage),
          const Gap(AdminSpacing.xs),
          Text(
            context.adminL10n.fields.cover,
            style: context.type
                .weighted(context.type.micro, FontWeight.w700)
                .copyWith(color: onImage),
          ),
        ],
      ),
    );
  }
}

class _BusyScrim extends StatelessWidget {
  final MediaItem item;
  const _BusyScrim({required this.item});

  @override
  Widget build(BuildContext context) {
    var uploading = item.status == MediaStatus.uploading;
    var onImage = context.colors.onImage;
    return Container(
      color: context.colors.imageScrim,
      padding: const EdgeInsets.all(AdminSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (uploading) ...[
            Text(
              context.adminFormats.percent(item.clampedProgress),
              textAlign: TextAlign.center,
              style: context.type
                  .weighted(context.type.bodySmall, FontWeight.w700)
                  .copyWith(color: onImage),
            ),
            const Gap(AdminSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
              child: LinearProgressIndicator(
                value: item.clampedProgress,
                minHeight: 4,
                // token-literal: a progress track over a picture
                backgroundColor: onImage.withValues(alpha: 0.24),
                valueColor: AlwaysStoppedAnimation(onImage),
              ),
            ),
          ] else
            Center(
              child: Spinner(
                size: context.iconSizes.xl,
                color: onImage,
                announce: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorScrim extends StatelessWidget {
  const _ErrorScrim();

  @override
  Widget build(BuildContext context) {
    var onImage = context.colors.onImage;
    // The red lives on the frame; the label sits on the neutral scrim so it
    // reads over any image in any theme.
    return Container(
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: context.colors.danger, width: 2),
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      color: context.colors.imageScrim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: context.iconSizes.xl, color: onImage),
          const Gap(AdminSpacing.xs),
          Text(
            context.adminL10n.retry,
            style: context.type
                .weighted(context.type.caption, FontWeight.w700)
                .copyWith(color: onImage),
          ),
        ],
      ),
    );
  }
}

// ── file row ────────────────────────────────────────────────────────────────

class _FileRow extends StatelessWidget {
  final MediaItem item;
  final int index;
  final bool readOnly;
  final bool reorderable;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onRetry;
  final ValueChanged<MediaItem>? onTap;

  const _FileRow({
    required this.item,
    required this.index,
    required this.readOnly,
    required this.reorderable,
    this.onRemove,
    this.onRetry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var error = item.status == MediaStatus.error;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(
          color: error ? context.colors.danger : context.colors.border,
        ),
        borderRadius: BorderRadius.circular(context.radii.radius),
      ),
      padding: const EdgeInsets.all(AdminSpacing.md),
      child: Row(
        children: [
          if (reorderable)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AdminSpacing.sm),
                child: Icon(
                  Icons.drag_indicator,
                  size: context.iconSizes.md,
                  color: context.colors.foregroundFaint,
                ),
              ),
            ),
          _icon(context),
          const Gap(AdminSpacing.lg),
          Expanded(child: _label(context, error)),
          const Gap(AdminSpacing.md),
          _trailing(context, error),
        ],
      ),
    );
  }

  Widget _icon(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(color: context.colors.border),
      ),
      child: Icon(
        item.icon ?? _iconFor(item.name),
        size: context.iconSizes.lg,
        color: context.colors.foregroundMuted,
      ),
    );
  }

  Widget _label(BuildContext context, bool error) {
    final bytes = item.bytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.type.bodyStrong,
        ),
        const Gap(AdminSpacing.xxs),
        if (item.status == MediaStatus.uploading)
          _inlineProgress(context)
        else
          Text(
            error
                ? (item.errorText ?? context.adminL10n.uploadFailed)
                : item.status == MediaStatus.processing
                ? context.adminL10n.fields.processing
                : bytes == null
                ? ''
                : context.adminFormats.bytes(bytes),
            style: context.type.caption.copyWith(
              color: error
                  ? context.colors.dangerText
                  : context.colors.foregroundMuted,
            ),
          ),
      ],
    );
  }

  Widget _inlineProgress(BuildContext context) {
    return Row(
      children: [
        Expanded(child: ProgressBar(value: item.clampedProgress, thickness: 4)),
        const Gap(AdminSpacing.md),
        Text(
          context.adminFormats.percent(item.clampedProgress),
          style: context.type.caption.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
      ],
    );
  }

  Widget _trailing(BuildContext context, bool error) {
    final l10n = context.adminL10n;
    if (error && !readOnly) {
      return CircleButton(
        icon: Icons.refresh,
        label: l10n.fields.retryItem(item.name),
        onTap: () => onRetry?.call(item.id),
      );
    }
    if (item.isBusy) {
      final spinner = Spinner(size: context.iconSizes.md, announce: false);
      if (readOnly || onRemove == null) return spinner;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const Gap(AdminSpacing.md),
          CircleButton(
            icon: Icons.close,
            label: l10n.fields.cancelUpload(item.name),
            onTap: () => onRemove?.call(item.id),
          ),
        ],
      );
    }
    if (readOnly) return const SizedBox.shrink();
    return CircleButton(
      icon: Icons.close,
      label: l10n.removeItem(item.name),
      onTap: () => onRemove?.call(item.id),
    );
  }

  IconData _iconFor(String name) {
    var ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'zip' || 'gz' || 'tar' => Icons.folder_zip_outlined,
      'mp4' || 'mov' || 'webm' => Icons.movie_outlined,
      'mp3' || 'wav' || 'flac' => Icons.audiotrack_outlined,
      'csv' || 'xlsx' || 'xls' => Icons.table_chart_outlined,
      'doc' || 'docx' || 'txt' || 'md' => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

// ── add affordances ─────────────────────────────────────────────────────────

class _AddTile extends StatelessWidget {
  final MediaKind kind;
  final bool invalid;
  final VoidCallback? onTap;

  const _AddTile({required this.kind, required this.invalid, this.onTap});

  @override
  Widget build(BuildContext context) {
    final messages = context.adminL10n.fields;
    final label = kind == MediaKind.image
        ? messages.addImage
        : messages.addFile;
    return SizedBox(
      width: _ImageTile._size,
      height: _ImageTile._size,
      child: Tip(
        message: label,
        excludeFromSemantics: true,
        child: Tappable.builder(
          onTap: onTap,
          semanticLabel: label,
          excludeSemantics: true,
          focusRadius: context.radii.radiusSmall,
          builder: (context, hovered) => DashedBorder(
            color: invalid
                ? context.colors.danger
                : hovered
                ? context.colors.foregroundMuted
                : DashedBorder.restingColor(context),
            radius: context.radii.radiusSmall,
            child: Center(
              child: Icon(
                Icons.add,
                size: context.iconSizes.xl,
                color: hovered
                    ? context.colors.foregroundSecondary
                    : context.colors.foregroundMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── shared bits ──────────────────────────────────────────────────────────────

/// Iris ring drawn around a populated body while a drag hovers the field.
class _DragHighlight extends StatelessWidget {
  final bool on;
  final Widget child;

  const _DragHighlight({required this.on, required this.child});

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      padding: EdgeInsets.all(on ? AdminSpacing.md : 0),
      decoration: BoxDecoration(
        color: on ? context.colors.primarySubtle : Colors.transparent,
        border: Border.all(
          color: on ? context.colors.primary : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(context.radii.radius),
      ),
      child: child,
    );
  }
}
