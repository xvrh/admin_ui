/// @docImport '../common/ui/labeled_field.dart';
/// @docImport '../fields/ui/field_group.dart';
/// @docImport '../fields/ui/field_shell.dart';
/// @docImport '../fields/ui/form_grid.dart';
/// @docImport 'validation.dart';
library;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../common/ui/field_chrome.dart';
import '../common/ui/field_feedback_scope.dart';
import '../common/ui/field_registry.dart';
import '../l10n/admin_ui_localizations.dart';
import 'form_shortcuts.dart';
import 'value_fields.dart';
import 'value_form_controller.dart';

/// Puts a [ValueFormController] around a form: the fields beneath show its
/// messages, its pending checks and its required marks, and take focus when
/// a submit is refused.
///
/// From the outside in, it mounts:
/// - a [FormFieldScope] over [fields], or over the registry of one above,
///   or over one of its own, so the fields register where a refused submit
///   can find the first invalid one;
/// - a [ValueFormScope], which `bind()` reads each field's visibility and
///   requiredness from;
/// - a [FormErrorsScope] of the controller's shown errors;
/// - a [FieldFeedbackScope] that reserves each field's message line
///   ([reserveErrorLine]), carries the pending checks and lets the fields
///   the rules validate be marked optional when they are not required;
/// - a [FieldStateScope] of [enabled] and [readOnly]: a user without the
///   permission to edit sees the whole form read-only.
///
/// It words the controller's messages in the app's language, and after each
/// refused submit ([ValueFormController.revealRequest]) brings the first
/// invalid field into view and focuses it.
///
/// The save bar or submit button reads the controller directly; put it
/// inside the form when it should reach the fields.
class ValueForm extends StatefulWidget {
  final ValueFormController controller;

  /// The fields' registry; the one of a [FormFieldScope] above, or one of
  /// the form's own, when null.
  final FormFieldRegistry? fields;

  /// False disables every field.
  final bool enabled;

  /// Shows every field's value without letting it change.
  final bool readOnly;

  /// Keeps each field's message line while it has none, so a message
  /// appearing does not move the fields below. Every field keeps it, one no
  /// rule names too, so the fields are evenly spaced whichever are checked;
  /// a [FormGrid] or [FieldGroup] beneath spaces its rows for that line.
  final bool reserveErrorLine;

  final Widget child;

  const ValueForm({
    super.key,
    required this.controller,
    this.fields,
    this.enabled = true,
    this.readOnly = false,
    this.reserveErrorLine = true,
    required this.child,
  });

  @override
  State<ValueForm> createState() => _ValueFormState();
}

class _ValueFormState extends State<ValueForm> {
  FormFieldRegistry? _own;
  FormFieldRegistry? _above;
  late int _reveals;

  FormFieldRegistry get _registry =>
      widget.fields ?? _above ?? (_own ??= FormFieldRegistry());

  @override
  void initState() {
    super.initState();
    _reveals = widget.controller.revealRequest;
    widget.controller.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _above = FormFieldScope.maybeOf(context);
    widget.controller.localizations = context.adminL10n;
  }

  @override
  void didUpdateWidget(ValueForm old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    old.controller.removeListener(_onChanged);
    widget.controller
      ..addListener(_onChanged)
      ..localizations = context.adminL10n;
    _reveals = widget.controller.revealRequest;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final controller = widget.controller;
    if (controller.revealRequest == _reveals) return;
    _reveals = controller.revealRequest;
    // After the frame that shows the messages, so the field is built and
    // registered by then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FormShortcuts.revealFirstInvalid(controller, _registry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final form = ListenableBuilder(
      listenable: controller,
      builder: (context, child) => ValueFormScope(
        controller: controller,
        child: FormErrorsScope(
          controller: controller,
          child: FieldFeedbackScope(
            reserveErrorLine: widget.reserveErrorLine,
            validated: controller.ruleFields,
            pending: controller.pendingFields,
            markOptional: true,
            child: child!,
          ),
        ),
      ),
      child: FieldStateScope(
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        child: widget.child,
      ),
    );
    // Mounted whichever registry it is, so the fields keep their state as
    // [ValueForm.fields] or a scope above changes.
    return FormFieldScope(registry: _registry, child: form);
  }
}

/// The [ValueFormController] of the nearest [ValueForm], and which of its
/// fields are hidden or required, keyed by field id: a field whose own
/// visibility or requiredness changed rebuilds, and the others do not.
class ValueFormScope extends InheritedModel<String> {
  final ValueFormController controller;
  final Set<String> _hidden;
  final Set<String> _required;

  /// Takes [controller]'s hidden and required fields as they are now; a
  /// [ValueForm] mounts it again as they change.
  ValueFormScope({super.key, required this.controller, required super.child})
    : _hidden = controller.hiddenFields,
      _required = controller.requiredFields;

  /// The nearest form's controller, or null outside any. The caller
  /// rebuilds when any field's visibility or requiredness changes.
  static ValueFormController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ValueFormScope>()?.controller;

  /// False while the nearest form's rules hide the field [id]; true outside
  /// any form.
  static bool isVisible(BuildContext context, String id) =>
      !(InheritedModel.inheritFrom<ValueFormScope>(
            context,
            aspect: id,
          )?._hidden.contains(id) ??
          false);

  /// Whether the nearest form's rules require the field [id]; false outside
  /// any form.
  static bool isRequired(BuildContext context, String id) =>
      InheritedModel.inheritFrom<ValueFormScope>(
        context,
        aspect: id,
      )?._required.contains(id) ??
      false;

  @override
  bool updateShouldNotify(ValueFormScope old) =>
      controller != old.controller ||
      !setEquals(_hidden, old._hidden) ||
      !setEquals(_required, old._required);

  @override
  bool updateShouldNotifyDependent(
    ValueFormScope old,
    Set<String> dependencies,
  ) =>
      controller != old.controller ||
      dependencies.any(
        (id) =>
            _hidden.contains(id) != old._hidden.contains(id) ||
            _required.contains(id) != old._required.contains(id),
      );
}
