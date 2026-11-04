import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mime/mime.dart';

import '../../common/ui/severity.dart';
import '../../common/ui/toast.dart';
import '../../fields/ui/media_body.dart' show MediaKind;
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/sections/assets_messages.dart';

/// A file read off a drop, in memory and ready to upload.
class DroppedAsset {
  final String name;
  final String mime;
  final Uint8List bytes;
  const DroppedAsset({
    required this.name,
    required this.mime,
    required this.bytes,
  });
}

typedef DropChildBuilder = Widget Function(BuildContext context, bool dragOver);

/// Why [AssetAccept] turned a file away.
enum AssetRefusalReason {
  /// Neither its MIME type nor its extension is accepted.
  type,

  /// Larger than [AssetAccept.maxBytes].
  size,

  /// A folder, not a file.
  folder,
}

/// One file an asset control would not take, and why.
@immutable
class AssetRefusal {
  final String name;
  final AssetRefusalReason reason;

  const AssetRefusal(this.name, this.reason);

  @override
  bool operator ==(Object other) =>
      other is AssetRefusal && other.name == name && other.reason == reason;

  @override
  int get hashCode => Object.hash(name, reason);

  @override
  String toString() => 'AssetRefusal($name, ${reason.name})';
}

/// What an asset control takes: MIME types, exact (`application/pdf`) or a
/// family (`image/*`), and file extensions (`docx`), plus an optional size
/// cap. A file qualifies when either its type or its extension is listed;
/// with neither listed, any file does. The same spec governs what may be
/// dropped and what the file browser offers, so the two never disagree.
///
/// Refusals are worded by [describeRefusals] — in the app's language
/// ([AssetsMessages]) unless [refusalText] words them.
@immutable
class AssetAccept {
  /// Accepted MIME types; `type/*` accepts the whole family.
  final Set<String> mimeTypes;

  /// Accepted file extensions, without the dot, in any case.
  final Set<String> extensions;

  /// The largest file accepted, in bytes; null is no limit.
  final int? maxBytes;

  /// Words the refusals of one drop or browse, replacing the default.
  final String Function(List<AssetRefusal> refused)? refusalText;

  const AssetAccept({
    this.mimeTypes = const {},
    this.extensions = const {},
    this.maxBytes,
    this.refusalText,
  });

  /// Any file, of any size.
  static const any = AssetAccept();

  /// Images of any format.
  static const images = AssetAccept(mimeTypes: {'image/*'});

  /// What a media control of [kind] takes unless told otherwise: images for
  /// an image field, any file for a file field.
  static AssetAccept forKind(MediaKind kind) =>
      kind == MediaKind.image ? images : any;

  /// Whether every file type qualifies (a size cap may still apply).
  bool get anyType => mimeTypes.isEmpty && extensions.isEmpty;

  /// Whether [mimeTypes] accepts only images.
  bool get imagesOnly =>
      extensions.isEmpty &&
      mimeTypes.isNotEmpty &&
      mimeTypes.every((m) => m.startsWith('image/'));

  AssetAccept copyWith({
    Set<String>? mimeTypes,
    Set<String>? extensions,
    int? Function()? maxBytes,
    String Function(List<AssetRefusal> refused)? Function()? refusalText,
  }) => AssetAccept(
    mimeTypes: mimeTypes ?? this.mimeTypes,
    extensions: extensions ?? this.extensions,
    maxBytes: maxBytes != null ? maxBytes() : this.maxBytes,
    refusalText: refusalText != null ? refusalText() : this.refusalText,
  );

  /// Whether a file named [name], of type [mime] when known, qualifies by
  /// type.
  bool acceptsType(String name, [String? mime]) {
    if (anyType) return true;
    final type = (mime ?? lookupMimeType(name))?.toLowerCase();
    if (type != null) {
      for (final accepted in mimeTypes) {
        final a = accepted.toLowerCase();
        if (a == type) return true;
        if (a.endsWith('/*') && type.startsWith(a.substring(0, a.length - 1))) {
          return true;
        }
      }
    }
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    final ext = name.substring(dot + 1).toLowerCase();
    return extensions.any((e) => e.toLowerCase() == ext);
  }

  /// Why a file named [name] would be refused, or null when it is accepted.
  AssetRefusalReason? refusalFor(String name, {String? mime, int? bytes}) {
    if (!acceptsType(name, mime)) return AssetRefusalReason.type;
    if (maxBytes != null && bytes != null && bytes > maxBytes!) {
      return AssetRefusalReason.size;
    }
    return null;
  }

  /// A short line naming what is accepted, for a drop zone — 'Images only',
  /// 'PDF, DOCX', '… · up to 10 MB' — or null when anything goes, in
  /// [context]'s language, its size limit in the app's locale.
  String? hintOf(BuildContext context) =>
      _hint(context.adminL10n.assets, context.adminFormats);

  String? _hint(AssetsMessages strings, AdminFormats formats) {
    final parts = [
      if (imagesOnly && mimeTypes.contains('image/*'))
        strings.imagesOnly
      else if (!anyType)
        [
          for (final m in mimeTypes) _typeLabel(strings, m),
          for (final e in extensions) e.toUpperCase(),
        ].join(strings.listSeparator),
      if (maxBytes case final max?) strings.upTo(formats.bytes(max)),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  /// The refusals of one drop or browse as one sentence: [refusalText]'s,
  /// else in [context]'s language, and in English without a [context].
  String describeRefusals(List<AssetRefusal> refused, [BuildContext? context]) {
    final custom = refusalText;
    if (custom != null) return custom(refused);
    final strings = context == null
        ? const AssetsMessagesEn()
        : context.adminL10n.assets;
    final formats = context == null ? _english : context.adminFormats;
    final limit = formats.bytes(maxBytes ?? 0);
    final images = imagesOnly && mimeTypes.contains('image/*');
    final reasons = {for (final r in refused) r.reason};
    if (reasons.length == 1) {
      final names = refused.map((r) => r.name).join(strings.listSeparator);
      final count = refused.length;
      return switch (reasons.single) {
        AssetRefusalReason.type when images => strings.refusedNotImage(
          names,
          count,
        ),
        AssetRefusalReason.type => strings.refusedNotSupported(names, count),
        AssetRefusalReason.size => strings.refusedTooLarge(names, count, limit),
        AssetRefusalReason.folder => strings.refusedFolder(names, count),
      };
    }
    final each = [
      for (final r in refused)
        switch (r.reason) {
          AssetRefusalReason.type when images => strings.refusedItemNotImage(
            r.name,
          ),
          AssetRefusalReason.type => strings.refusedItemNotSupported(r.name),
          AssetRefusalReason.size => strings.refusedItemTooLarge(r.name, limit),
          AssetRefusalReason.folder => strings.refusedItemFolder(r.name),
        },
    ];
    return strings.refusedMixed(each.join(strings.listSeparator));
  }

  static final _english = AdminFormats('en');

  static String _typeLabel(AssetsMessages strings, String mime) {
    final m = mime.toLowerCase();
    if (m.endsWith('/*')) {
      final family = m.substring(0, m.length - 2);
      return switch (family) {
        'image' => strings.typeImages,
        'video' => strings.typeVideos,
        'audio' => strings.typeAudio,
        'text' => strings.typeText,
        _ => strings.familyFiles(family),
      };
    }
    return (extensionFromMime(m) ?? m.split('/').last).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is AssetAccept &&
      setEquals(other.mimeTypes, mimeTypes) &&
      setEquals(other.extensions, extensions) &&
      other.maxBytes == maxBytes &&
      other.refusalText == refusalText;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(mimeTypes),
    Object.hashAllUnordered(extensions),
    maxBytes,
    refusalText,
  );
}

/// Tells the person which files [accept] turned away, as a warning toast on
/// the nearest [ToastScope] (none mounted, it only logs in debug builds).
void showAssetRefusals(
  BuildContext context,
  AssetAccept accept,
  List<AssetRefusal> refused,
) {
  if (refused.isEmpty) return;
  final message = accept.describeRefusals(refused, context);
  final toasts = context.findAncestorStateOfType<ToastScopeState>();
  if (toasts == null) {
    debugPrint('AssetDropTarget: no ToastScope to report "$message"');
    return;
  }
  toasts.show(Toast(message, severity: Severity.warning));
}

/// Per-widget OS-file drop target. Reads dropped files into memory and hands
/// them to [onFiles]; [builder] rebuilds with a `dragOver` flag so the host can
/// light its drop highlight.
///
/// A drop belongs to the target a tap at that point would reach: two asset
/// fields on one form each catch only their own drop, and a field under an open
/// dialog catches nothing. The platform only reveals what is being dragged once
/// it is dropped, so a file [accept] turns away is refused then, with a toast
/// naming it ([showAssetRefusals]), rather than while it hovers. A file over
/// [AssetAccept.maxBytes] is refused before it is read.
class AssetDropTarget extends StatefulWidget {
  final AssetAccept accept;
  final bool enabled;
  final ValueChanged<List<DroppedAsset>> onFiles;
  final DropChildBuilder builder;

  const AssetDropTarget({
    super.key,
    this.accept = AssetAccept.any,
    this.enabled = true,
    required this.onFiles,
    required this.builder,
  });

  @override
  State<AssetDropTarget> createState() => _AssetDropTargetState();
}

class _AssetDropTargetState extends State<AssetDropTarget> {
  final _probe = GlobalKey();
  bool _over = false;

  /// Whether this is the innermost drop target a pointer at [globalPosition]
  /// would reach. `DropTarget` alone only checks its own bounds, so every
  /// target under the point — covered or nested — would take the drop.
  bool _owns(Offset globalPosition) {
    final probe = _probe.currentContext?.findRenderObject();
    if (probe == null || !probe.attached) return false;
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      globalPosition,
      View.of(context).viewId,
    );
    final innermost = result.path
        .map((entry) => entry.target)
        .whereType<_RenderDropProbe>()
        .firstOrNull;
    return identical(innermost, probe);
  }

  void _setOver(bool over) {
    if (over != _over) setState(() => _over = over);
  }

  Future<void> _onDragDone(DropDoneDetails details) async {
    _setOver(false);
    if (!_owns(details.globalPosition)) return;

    final accept = widget.accept;
    final dropped = <DroppedAsset>[];
    final refused = <AssetRefusal>[];
    for (final file in details.files) {
      if (file is DropItemDirectory) {
        refused.add(AssetRefusal(file.name, AssetRefusalReason.folder));
        continue;
      }
      final mime = lookupMimeType(file.name) ?? file.mimeType;
      final bytes = accept.maxBytes == null ? null : await file.length();
      final reason = accept.refusalFor(file.name, mime: mime, bytes: bytes);
      if (reason != null) {
        refused.add(AssetRefusal(file.name, reason));
        continue;
      }
      dropped.add(
        DroppedAsset(
          name: file.name,
          mime: mime ?? 'application/octet-stream',
          bytes: await file.readAsBytes(),
        ),
      );
    }
    if (!mounted) return;
    if (dropped.isNotEmpty) widget.onFiles(dropped);
    showAssetRefusals(context, accept, refused);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.builder(context, false);
    return DropTarget(
      onDragEntered: (details) => _setOver(_owns(details.globalPosition)),
      onDragUpdated: (details) => _setOver(_owns(details.globalPosition)),
      onDragExited: (_) => _setOver(false),
      onDragDone: _onDragDone,
      child: _DropProbe(key: _probe, child: widget.builder(context, _over)),
    );
  }
}

/// Marks a target's area in hit testing without taking part in it: a pointer
/// over it still reaches whatever it would have.
class _DropProbe extends SingleChildRenderObjectWidget {
  const _DropProbe({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDropProbe();
}

class _RenderDropProbe extends RenderProxyBoxWithHitTestBehavior {
  _RenderDropProbe() : super(behavior: HitTestBehavior.translucent);
}
