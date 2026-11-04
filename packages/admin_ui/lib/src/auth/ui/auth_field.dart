import 'package:material_ui/material_ui.dart';

import '../../common/ui/labeled_field.dart';

/// A labelled field row used inside the auth forms: a [label] (with an optional
/// [trailing] affordance like a "forgot password?" link) above the input.
///
/// The auth-form spelling of [LabeledField], for a control that takes no label
/// of its own; an `InputField` or `PasswordField` takes its `label` directly.
class AuthField extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final Widget child;

  const AuthField({
    super.key,
    required this.label,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LabeledField(label: label, trailing: trailing, child: child);
  }
}

/// A red caption under a field for inline validation messages.
class AuthFieldError extends StatelessWidget {
  final String message;

  const AuthFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => FieldErrorText(message);
}
