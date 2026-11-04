import 'package:flutter/widgets.dart';

import '../i18n/locale_status.dart' show LocaleInfo, LocaleStatus;
import 'cell.dart';

/// An ambient hook into `bind`, the one place every field preset renders
/// through: a host layer takes over how a cell is edited (a review or
/// translation lens, say) and feeds the multi-lane body its per-lane status
/// and actions, without the kit knowing its workflow.
///
/// Mount one with a [FieldBinderScope] above the form. Each method's default
/// is the kit's own behaviour, so a binder overrides only what it changes,
/// and a form with no scope renders exactly as it would without the hook.
///
/// It is also how a kind of cell of the host's own, one that implements
/// [Cell] but neither [ValueCell] nor [TranslatedCell], gets rendered: its
/// binder's [bind] takes it, and returns null for the cells it leaves to the
/// kit.
abstract class FieldBinder {
  const FieldBinder();

  /// The widget that edits [cell] in place of the kit's field, or null for
  /// the kit's. [binding] carries what the preset asked `bind` for: its
  /// label and options, and the body that edits one lane.
  Widget? bind<V>(
    BuildContext context,
    Cell<V> cell,
    FieldBinding<V> binding,
  ) => null;

  /// The status of [cell]'s [lang] lane in the multi-lane body, or null to
  /// keep the one its [LocaleInfo] declares. An [LocaleStatus.outdated] lane
  /// says so under its body.
  LocaleStatus? laneStatus<V>(
    BuildContext context,
    TranslatedCell<V> cell,
    String lang,
  ) => null;

  /// The action that re-translates [cell]'s [lang] lane from the source,
  /// offered under the lane while it is outdated. Null offers none, and the
  /// lane only says that its source changed.
  VoidCallback? retranslate<V>(
    BuildContext context,
    TranslatedCell<V> cell,
    String lang,
  ) => null;
}

/// What a field preset asks `bind` for, as one value: a [FieldBinder] that
/// takes a cell over renders from it.
///
/// [errorText] is the resolved message: the preset's own, or else the one the
/// ambient `FieldErrorsScope` holds for the cell. [required] is resolved the
/// same way: the preset's flag, or a required rule of the enclosing
/// `ValueForm`. [body] edits one lane's cell; [laneBody], when set, edits a
/// language lane knowing its code.
///
/// Visibility is not the binder's concern: while the form's rules hide the
/// cell, `bind` folds away whatever the binder rendered.
class FieldBinding<V> {
  final String label;
  final Widget? help;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;
  final bool mergeSemantics;
  final Widget Function(ValueCell<V> lane) body;
  final Widget Function(ValueCell<V> lane, String lang)? laneBody;

  const FieldBinding({
    required this.label,
    required this.body,
    this.help,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
    this.mergeSemantics = false,
    this.laneBody,
  });
}

/// Provides a [FieldBinder] to every field beneath it.
class FieldBinderScope extends InheritedWidget {
  final FieldBinder binder;

  const FieldBinderScope({
    super.key,
    required this.binder,
    required super.child,
  });

  /// The nearest scope's binder; throws when there is none.
  static FieldBinder of(BuildContext context) {
    final binder = maybeOf(context);
    if (binder == null) {
      throw FlutterError(
        'FieldBinderScope.of() was called with a context that has no '
        'FieldBinderScope above it.\n'
        'A FieldBinder is optional: fields read it with '
        'FieldBinderScope.maybeOf. Mount a FieldBinderScope above the form '
        'to provide one.',
      );
    }
    return binder;
  }

  /// The nearest scope's binder, or null when fields render the kit's way.
  static FieldBinder? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FieldBinderScope>()?.binder;

  @override
  bool updateShouldNotify(FieldBinderScope old) => binder != old.binder;
}
