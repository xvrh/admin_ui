import 'package:flutter/widgets.dart';

import '../../history/change_index.dart';

/// Ambient "what differs from the baseline" for a form tree: a
/// [FieldChangeIndex] derived from the one draft-vs-baseline diff the editor
/// host maintains. Absent from the tree ⇒ no modified chrome anywhere.
///
/// An [InheritedModel] keyed by cell id, so an index tick only rebuilds the
/// fields whose own change summary actually moved — a keystroke in one field
/// leaves every other field's subtree untouched.
class ChangeScope extends InheritedModel<String> {
  final FieldChangeIndex index;

  /// Ticks when [index] is regenerated. For imperative consumers (heavy body
  /// editors) that re-read via [readOf] and must not take a build dependency.
  final Listenable? revision;

  /// Live view of the current index, for [revision] listeners: a tick fires
  /// before this widget is rebuilt, so reading [index] off the widget then
  /// would see the previous generation.
  final FieldChangeIndex Function()? read;

  /// Writes one top-level field's baseline value back into the draft — the
  /// marker popover's "Restore". Null hides the affordance.
  final void Function(String fieldId)? onRevertField;

  const ChangeScope({
    super.key,
    required this.index,
    this.revision,
    this.read,
    this.onRevertField,
    required super.child,
  });

  /// The current index, preferring the live [read] view.
  FieldChangeIndex get current => read?.call() ?? index;

  /// This cell's change summary, rebuilding the caller when it moves.
  static FieldChangeSummary summaryOf(BuildContext context, String id) =>
      InheritedModel.inheritFrom<ChangeScope>(
        context,
        aspect: id,
      )?.index.summaryOf(id) ??
      FieldChangeSummary.none;

  /// The scope without registering a dependency — pair with [revision] to
  /// track ticks manually.
  static ChangeScope? readOf(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<ChangeScope>()?.widget
          as ChangeScope?;

  @override
  bool updateShouldNotify(ChangeScope oldWidget) =>
      !identical(index, oldWidget.index);

  @override
  bool updateShouldNotifyDependent(
    ChangeScope oldWidget,
    Set<String> dependencies,
  ) => dependencies.any(
    (id) => index.summaryOf(id) != oldWidget.index.summaryOf(id),
  );
}

/// Hosts a [ChangeScope] over [child], republishing [index] whenever [revision]
/// ticks. The child instance is stable, so a tick re-evaluates only dependents
/// whose summaries moved.
class ChangeScopeHost extends StatelessWidget {
  final Listenable revision;
  final FieldChangeIndex Function() index;
  final void Function(String fieldId)? onRevertField;
  final Widget child;

  const ChangeScopeHost({
    super.key,
    required this.revision,
    required this.index,
    this.onRevertField,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: revision,
    child: child,
    builder: (context, child) => ChangeScope(
      index: index(),
      read: index,
      revision: revision,
      onRevertField: onRevertField,
      child: child!,
    ),
  );
}
