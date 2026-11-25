/// @docImport 'authenticator_setup_view.dart';
/// @docImport 'one_time_code_form.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/input_field.dart';
import '../../l10n/admin_ui_localizations.dart';

/// The code field of [OneTimeCodeForm] and [AuthenticatorSetupView]: a
/// one-time code of [length] digits, or a recovery code of any length when
/// [length] is null.
///
/// It owns its text and checks only that it is whole: a submit with the
/// field empty marks it required, one short of [length] digits says how
/// many a code has, and the mark follows the typing until it is met. The
/// code reads left to right in the theme's monospace font, whatever the
/// page's direction.
///
/// [errorText] is about the code the field held when it came: it shows
/// while that is unchanged, and goes while a submit runs, so the one that
/// ends with it, the same one again included, takes focus back to the
/// field with the code selected, for the next one to replace it.
@internal
class CodeInput extends StatefulWidget {
  /// The digits of a code; null for a recovery code, any text.
  final int? length;

  /// Submits once [length] digits are in, typed or pasted.
  final bool autoSubmit;

  final String label;
  final String? description;
  final String? errorText;
  final bool submitting;
  final bool autofocus;

  /// Called with the trimmed code once it is whole.
  final ValueChanged<String> onSubmit;

  /// The key of the input, to find it by in a test.
  final Key? fieldKey;

  const CodeInput({
    super.key,
    required this.length,
    this.autoSubmit = false,
    required this.label,
    this.description,
    this.errorText,
    this.submitting = false,
    this.autofocus = false,
    required this.onSubmit,
    this.fieldKey,
  });

  @override
  State<CodeInput> createState() => CodeInputState();
}

/// The state of a [CodeInput]: [submit] checks the code and hands it on,
/// [focus] moves focus to the field.
@internal
class CodeInputState extends State<CodeInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode(debugLabel: 'Code');

  /// Set by a submit with the code not whole; from then on the field says
  /// what is missing.
  bool _attempted = false;

  /// The code [CodeInput.errorText] is about.
  late String? _refused = _shownError(widget) == null ? null : '';

  /// The last whole code [CodeInput.autoSubmit] submitted, so that moving
  /// the cursor through it does not submit it again.
  String? _autoSubmitted;

  static String? _shownError(CodeInput input) =>
      input.submitting ? null : input.errorText;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = _shownError(widget);
    if (error != _shownError(oldWidget)) {
      _refused = error == null ? null : _controller.text;
    }
    if (error == null || !oldWidget.submitting || widget.submitting) return;
    // Once the field is enabled again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_attempted || _refused != null) setState(() {});
    final text = _controller.text;
    if (text == _autoSubmitted) return;
    _autoSubmitted = null;
    final length = widget.length;
    if (widget.autoSubmit && length != null && text.length == length) {
      _autoSubmitted = text;
      submit();
    }
  }

  /// Moves focus to the field.
  void focus() => _focus.requestFocus();

  /// Hands the code to [CodeInput.onSubmit] when it is whole, and otherwise
  /// marks what is missing and focuses the field.
  void submit() {
    if (widget.submitting) return;
    final code = _controller.text.trim();
    if (_missing(code) != null) {
      setState(() => _attempted = true);
      _focus.requestFocus();
      return;
    }
    widget.onSubmit(code);
  }

  /// What a submit of [code] would be refused for here, if anything.
  String? _missing(String code) {
    final length = widget.length;
    final shell = context.adminL10n.shell;
    if (code.isEmpty) return shell.isRequired(widget.label);
    if (length != null && code.length < length) {
      return shell.codeIncomplete(length);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.length;
    final text = _controller.text;
    return InputField(
      key: widget.fieldKey,
      label: widget.label,
      description: widget.description,
      controller: _controller,
      focusNode: _focus,
      errorText:
          (_attempted ? _missing(text.trim()) : null) ??
          (text == _refused ? _shownError(widget) : null),
      enabled: !widget.submitting,
      autofocus: widget.autofocus,
      monospace: true,
      // Physical: a code reads left to right in every language.
      textDirection: TextDirection.ltr,
      keyboardType: length == null ? TextInputType.text : TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: length == null ? null : const [AutofillHints.oneTimeCode],
      inputFormatters: length == null
          ? null
          : [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(length),
            ],
      onSubmitted: (_) => submit(),
    );
  }
}
