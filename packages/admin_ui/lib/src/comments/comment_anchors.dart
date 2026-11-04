/// A pending text-range comment target: where the composer is anchored and the
/// selection [preview] it shows; [materialize] creates the backing annotation
/// only when the comment is actually posted.
class CommentSelectionAnchor {
  final String fieldPath;
  final String preview;
  final String Function() materialize;

  const CommentSelectionAnchor({
    required this.fieldPath,
    required this.preview,
    required this.materialize,
  });
}

/// Live annotation removers keyed by body lane path (`body/fr`), registered by
/// mounted body editors — so deleting a text-range thread can remove its
/// backing annotation from the right language's document. Removers rather than
/// store accessors, so this stays free of the block editor's types.
class CommentAnnotationRegistry {
  final _removers = <String, void Function(String annotationId)>{};

  void register(String fieldPath, void Function(String annotationId) remove) =>
      _removers[fieldPath] = remove;

  void unregister(String fieldPath, void Function(String annotationId) remove) {
    if (_removers[fieldPath] == remove) _removers.remove(fieldPath);
  }

  /// No-op when the lane's editor isn't mounted — the annotation then lingers
  /// in the doc, harmless (nothing references it once the thread is gone).
  void removeAnnotation(String? fieldPath, String annotationId) {
    if (fieldPath == null) return;
    _removers[fieldPath]?.call(annotationId);
  }
}
