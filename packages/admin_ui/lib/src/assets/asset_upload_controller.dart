/// @docImport '../fields/ui/media_body.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../common/ui/error_text.dart';
import '../fields/ui/media_body.dart' show MediaItem, MediaStatus;
import '../l10n/admin_ui_localizations.dart';
import 'asset_source.dart';
import 'ui/asset_drop_target.dart' show DroppedAsset;

/// What a source that answered null, rather than throwing, failed with,
/// worded in the app's language when shown.
const _incomplete = _Incomplete();

class _Incomplete {
  const _Incomplete();
}

class _Upload {
  final String localId;
  final Uint8List bytes;
  final String mime;
  final String name;
  double progress = 0;
  MediaStatus status = MediaStatus.uploading;

  /// The raw failure, worded when shown.
  Object? error;

  /// Completes when the upload is removed, so the source can abort it.
  final cancel = Completer<void>();

  _Upload({
    required this.localId,
    required this.bytes,
    required this.mime,
    required this.name,
  });

  bool get cancelled => cancel.isCompleted;
}

/// Holds in-flight uploads for one asset field and runs them against an
/// [AssetSource]. Each completed upload fires `onUploaded(assetId)` (which the
/// field attaches to its cell) and then drops out of the queue — the committed
/// thumbnail takes over. Failures linger as retryable rows.
///
/// An upload [remove] takes out mid-flight is cancelled: the source is told
/// through [AssetSource.upload]'s `cancelled`, and whatever it answers
/// afterwards is ignored — `onUploaded` never fires for it, so nothing
/// attaches a file the person took back. Disposing the controller cancels
/// every upload still in flight the same way: its host — a picker closed
/// mid-upload, a slot torn down — is gone, and with it anything that would
/// show the file or take it, so it would only land as an orphan.
///
/// [busyItems] are merged into the field's [MediaBody] so progress/error render
/// inline, the same shape the standalone Assets screen builds by hand.
class AssetUploadController extends ChangeNotifier {
  final _uploads = <_Upload>[];
  int _seq = 0;

  /// A source may still answer after [dispose]; nothing notifies then.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final upload in _uploads) {
      if (!upload.cancelled) upload.cancel.complete();
    }
    _uploads.clear();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// The queue as media items, a failure worded through
  /// [ErrorTextScope.describe] — so call it from `build`.
  List<MediaItem> busyItems(BuildContext context) => [
    for (final u in _uploads)
      MediaItem(
        id: u.localId,
        name: u.name,
        bytes: u.bytes.length,
        status: u.status,
        progress: u.progress,
        errorText: switch (u.error) {
          null => null,
          _Incomplete() => context.adminL10n.assets.uploadIncomplete,
          final error => ErrorTextScope.describe(context, error),
        },
      ),
  ];

  bool get isEmpty => _uploads.isEmpty;

  /// How many uploads are queued, in flight or failed.
  int get length => _uploads.length;

  void enqueue(
    List<DroppedAsset> files,
    AssetSource source, {
    required void Function(String assetId) onUploaded,
  }) {
    for (final f in files) {
      final upload = _Upload(
        localId: 'up${_seq++}',
        bytes: f.bytes,
        mime: f.mime,
        name: f.name,
      );
      _uploads.add(upload);
      _run(upload, source, onUploaded);
    }
    notifyListeners();
  }

  void retry(
    String localId,
    AssetSource source,
    void Function(String assetId) onUploaded,
  ) {
    final u = _uploads.where((e) => e.localId == localId).firstOrNull;
    if (u == null || u.status != MediaStatus.error) return;
    u
      ..status = MediaStatus.uploading
      ..progress = 0
      ..error = null;
    notifyListeners();
    _run(u, source, onUploaded);
  }

  /// Drops [localId] from the queue, cancelling it if it is still in flight.
  void remove(String localId) {
    final u = _uploads.where((e) => e.localId == localId).firstOrNull;
    if (u == null) return;
    _uploads.remove(u);
    if (!u.cancelled) u.cancel.complete();
    notifyListeners();
  }

  Future<void> _run(
    _Upload upload,
    AssetSource source,
    void Function(String assetId) onUploaded,
  ) async {
    Object? error;
    String? id;
    try {
      final asset = await source.upload(
        upload.bytes,
        mime: upload.mime,
        filename: upload.name,
        onProgress: (p) {
          if (upload.cancelled) return;
          upload.progress = p;
          _notify();
        },
        cancelled: upload.cancel.future,
      );
      id = asset?.id;
    } catch (e) {
      error = e;
    }
    if (upload.cancelled) return;
    if (id == null) {
      upload
        ..status = MediaStatus.error
        ..error = error ?? _incomplete;
      _notify();
      return;
    }
    _uploads.remove(upload);
    onUploaded(id);
    _notify();
  }
}
