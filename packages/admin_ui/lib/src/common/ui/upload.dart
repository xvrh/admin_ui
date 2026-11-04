import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'dashed_border.dart';
import 'icon_action.dart';
import 'progress_bar.dart';
import 'severity.dart';
import 'tappable.dart';

/// Lifecycle of one queued upload. [UploadItem.progress] is only meaningful
/// while [uploading]; [UploadItem.errorText] only while [UploadStatus.error].
enum UploadStatus { queued, uploading, done, error }

/// One file in an [UploadZone] queue. This is the *transient* upload record —
/// distinct from the stored file it becomes; the host promotes it once its
/// [status] is [UploadStatus.done]. View-only: no bytes are read here.
class UploadItem {
  final String id;
  final String name;
  final int? bytes;
  final UploadStatus status;

  /// 0..1, drawn while [UploadStatus.uploading].
  final double progress;

  /// Why the upload failed, shown while [UploadStatus.error]; a generic
  /// "Upload failed" when null.
  final String? errorText;

  /// Glyph; defaults by extension when null.
  final IconData? icon;

  const UploadItem({
    required this.id,
    required this.name,
    this.bytes,
    this.status = UploadStatus.queued,
    this.progress = 0,
    this.errorText,
    this.icon,
  });

  double get clampedProgress => progress.clamp(0, 1).toDouble();
}

/// [bytes] as [AdminFormats.bytes] writes them in [locale] ('320 kB',
/// '1.4 MB'), or '' for null. The units are SI, 1 kB being 1000 bytes.
/// [locale] defaults to intl's current locale; inside a widget,
/// `context.adminFormats.bytes` follows the app's.
String formatBytes(int? bytes, {String? locale}) {
  if (bytes == null) return '';
  final name = locale ?? Intl.getCurrentLocale();
  return AdminFormats(
    name,
    messages: AdminLocalizations.lookup(Locale(Intl.shortLocale(name))),
  ).bytes(bytes);
}

/// A field-independent upload surface: a drop target plus a live queue of files
/// being uploaded. Unlike the media field's drop zone (which yields settled
/// assets), this is the transient ingest panel — used as the asset library's
/// "Upload" tab and as a stand-alone drop modal.
///
/// View-pure: drag/drop and the file picker are wired by the host. [dragOver]
/// lights the target; [onBrowse] fires when the affordance is tapped, or
/// activated with Enter or Space once it has keyboard focus; the queue reports
/// [onCancel] / [onRetry] / [onRemove] by item id, from row actions labelled
/// "Cancel upload", "Retry upload" and "Remove file".
class UploadZone extends StatelessWidget {
  final List<UploadItem> items;

  /// Drop-target highlight; the host flips this on real drag-enter/leave.
  final bool dragOver;

  /// Plural copy + multi-file affordance hint.
  final bool multiple;

  /// Accept hint, e.g. 'PNG, JPG, PDF · up to 25 MB'.
  final String? accept;

  final VoidCallback? onBrowse;

  /// Cancel an in-flight or queued upload.
  final ValueChanged<String>? onCancel;

  /// Re-attempt a failed upload.
  final ValueChanged<String>? onRetry;

  /// Drop a finished/failed row from the queue.
  final ValueChanged<String>? onRemove;

  /// Clear every settled (done/error) row at once. Hidden when none qualify.
  final VoidCallback? onClearCompleted;

  /// Reports, and can seed, the drop target's hovered, pressed and focused
  /// states — e.g. to pin one in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  const UploadZone({
    super.key,
    this.items = const [],
    this.dragOver = false,
    this.multiple = true,
    this.accept,
    this.onBrowse,
    this.onCancel,
    this.onRetry,
    this.onRemove,
    this.onClearCompleted,
    this.statesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Target(
          dragOver: dragOver,
          multiple: multiple,
          accept: accept,
          onTap: onBrowse,
          statesController: statesController,
        ),
        if (items.isNotEmpty) ...[
          const Gap(AdminSpacing.xl),
          _Header(items: items, onClearCompleted: onClearCompleted),
          const Gap(AdminSpacing.lg),
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const Gap(AdminSpacing.md),
            _Row(
              item: item,
              onCancel: onCancel,
              onRetry: onRetry,
              onRemove: onRemove,
            ),
          ],
        ],
      ],
    );
  }
}

/// The drop target: a dashed outline at least 3:1 against its fill and the
/// page, lit in the primary while hovered, pressed or dragged over.
class _Target extends StatelessWidget {
  final bool dragOver;
  final bool multiple;
  final String? accept;
  final VoidCallback? onTap;
  final WidgetStatesController? statesController;

  const _Target({
    required this.dragOver,
    required this.multiple,
    required this.accept,
    required this.onTap,
    required this.statesController,
  });

  /// Side of the cloud badge.
  static const _badge = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radius;
    final prompt = context.adminL10n.dropPrompt(multiple: multiple);
    return Tappable.states(
      onTap: onTap,
      statesController: statesController,
      focusRadius: radius,
      builder: (context, states) {
        final enabled = !states.contains(WidgetState.disabled);
        final pressed = enabled && states.contains(WidgetState.pressed);
        final hovered = enabled && states.contains(WidgetState.hovered);
        final base = dragOver ? colors.primarySubtle : colors.surfaceMuted;
        final overlay = pressed
            ? colors.pressedOverlay
            : (hovered ? colors.hoverOverlay : null);
        return DashedBorder(
          color: dragOver || hovered || pressed
              ? colors.primary
              : DashedBorder.restingColor(context),
          radius: radius,
          child: Container(
            decoration: BoxDecoration(
              color: overlay == null ? base : Color.alphaBlend(overlay, base),
              borderRadius: BorderRadius.circular(radius),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AdminSpacing.xxxl,
              horizontal: AdminSpacing.xl,
            ),
            child: Column(
              children: [
                Container(
                  width: _badge,
                  height: _badge,
                  decoration: BoxDecoration(
                    color: dragOver ? colors.primary : colors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: context.iconSizes.xl,
                    color: dragOver ? colors.onPrimary : colors.foregroundMuted,
                  ),
                ),
                const Gap(AdminSpacing.lg),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: prompt.before),
                      TextSpan(
                        text: prompt.link,
                        style: context.type.weighted(
                          context.type.body.copyWith(color: colors.primaryText),
                          FontWeight.w700,
                        ),
                      ),
                      if (prompt.after.isNotEmpty) TextSpan(text: prompt.after),
                    ],
                    style: context.type.body.copyWith(
                      color: colors.foregroundMuted,
                    ),
                  ),
                ),
                if (accept != null) ...[
                  const Gap(AdminSpacing.xs),
                  Text(accept!, style: context.type.caption),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final List<UploadItem> items;
  final VoidCallback? onClearCompleted;

  const _Header({required this.items, this.onClearCompleted});

  @override
  Widget build(BuildContext context) {
    var done = items.where((i) => i.status == UploadStatus.done).length;
    var failed = items.where((i) => i.status == UploadStatus.error).length;
    var settled = done + failed;
    var total = items.length;
    var allDone = done == total;
    final strings = context.adminL10n.display;
    final summary = allDone
        ? strings.uploadDone(total)
        : strings.uploadProgress(done, total, failed);

    var overall =
        items.fold<double>(0, (sum, i) {
          return sum +
              switch (i.status) {
                UploadStatus.done => 1.0,
                UploadStatus.uploading => i.clampedProgress,
                _ => 0.0,
              };
        }) /
        total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: context.type.bodyStrong.copyWith(
                  color: failed > 0
                      ? context.colors.dangerText
                      : context.colors.foreground,
                ),
              ),
            ),
            if (onClearCompleted != null && settled > 0)
              Tappable.states(
                onTap: onClearCompleted,
                focusRadius: context.radii.radiusSmall,
                builder: (context, states) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.sm,
                    vertical: AdminSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: states.contains(WidgetState.pressed)
                        ? context.colors.pressedOverlay
                        : states.contains(WidgetState.hovered)
                        ? context.colors.hoverOverlay
                        : null,
                    borderRadius: BorderRadius.circular(
                      context.radii.radiusSmall,
                    ),
                  ),
                  child: Text(
                    strings.clearCompleted,
                    style: context.type.weighted(
                      context.type.caption.copyWith(
                        color: context.colors.primaryText,
                      ),
                      FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Gap(AdminSpacing.md),
        ProgressBar(
          value: overall,
          thickness: 4,
          severity: failed > 0 && allDone
              ? Severity.danger
              : allDone
              ? Severity.success
              : null,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final UploadItem item;
  final ValueChanged<String>? onCancel;
  final ValueChanged<String>? onRetry;
  final ValueChanged<String>? onRemove;

  const _Row({required this.item, this.onCancel, this.onRetry, this.onRemove});

  /// Side of the file-type tile.
  static const _tile = AdminSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    var error = item.status == UploadStatus.error;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(
          color: error ? context.colors.danger : context.colors.border,
        ),
        borderRadius: BorderRadius.circular(context.radii.radius),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        AdminSpacing.md,
        AdminSpacing.sm,
        AdminSpacing.md,
      ),
      child: Row(
        children: [
          _icon(context, error),
          const Gap(AdminSpacing.lg),
          Expanded(child: _body(context, error)),
          const Gap(AdminSpacing.md),
          ..._actions(context, error),
        ],
      ),
    );
  }

  Widget _icon(BuildContext context, bool error) {
    var done = item.status == UploadStatus.done;
    return Container(
      width: _tile,
      height: _tile,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(color: context.colors.border),
      ),
      child: Icon(
        error
            ? Icons.error_outline
            : done
            ? Icons.check_circle_outline
            : (item.icon ?? _iconFor(item.name)),
        size: context.iconSizes.md,
        color: error
            ? context.colors.dangerText
            : done
            ? context.colors.successText
            : context.colors.foregroundMuted,
      ),
    );
  }

  Widget _body(BuildContext context, bool error) {
    final l10n = context.adminL10n;
    final formats = context.adminFormats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.type.weighted(context.type.body, FontWeight.w600),
        ),
        const Gap(AdminSpacing.xs),
        if (item.status == UploadStatus.uploading)
          Row(
            children: [
              Expanded(
                child: ProgressBar(value: item.clampedProgress, thickness: 4),
              ),
              const Gap(AdminSpacing.md),
              Text(
                formats.percent(item.clampedProgress),
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMuted,
                ),
              ),
            ],
          )
        else
          Text(
            error
                ? (item.errorText ?? l10n.uploadFailed)
                : item.status == UploadStatus.queued
                ? l10n.display.queued
                : item.bytes == null
                ? ''
                : formats.bytes(item.bytes!),
            style: context.type.caption.copyWith(
              color: error
                  ? context.colors.dangerText
                  : context.colors.foregroundMuted,
            ),
          ),
      ],
    );
  }

  /// A failed row offers retry and remove, a finished one remove, and a
  /// queued or uploading one cancel — the same ×, named for what it does. An
  /// action the host didn't wire isn't shown.
  List<Widget> _actions(BuildContext context, bool error) {
    Widget action(
      IconData icon,
      String label,
      ValueChanged<String> onTap, {
      Color? color,
    }) => IconAction(
      icon,
      label: label,
      size: IconActionSize.small,
      color: color,
      onPressed: () => onTap(item.id),
    );
    final settled = error || item.status == UploadStatus.done;
    final strings = context.adminL10n.display;
    return [
      if (error && onRetry != null)
        action(
          Icons.refresh_rounded,
          strings.retryUpload,
          onRetry!,
          color: context.colors.primaryText,
        ),
      if (settled && onRemove != null)
        action(Icons.close_rounded, strings.removeFile, onRemove!),
      if (!settled && onCancel != null)
        action(Icons.close_rounded, strings.cancelUpload, onCancel!),
    ];
  }

  IconData _iconFor(String name) {
    var ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => Icons.image_outlined,
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
