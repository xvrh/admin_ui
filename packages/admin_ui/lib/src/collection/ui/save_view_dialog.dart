/// @docImport '../saved_views_controller.dart';
/// @docImport 'saved_views_bar.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/choice.dart';
import '../../common/ui/input_field.dart';
import '../../common/ui/labeled_field.dart';
import '../../common/ui/modal.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../saved_view.dart';

/// Asks for a saved view's name and, when [askScope], who sees it: the
/// dialog a [SavedViewsBar] opens itself for its `onCreate` and `onRenamed`,
/// for a screen that saves views from elsewhere too.
///
/// A new view's dialog is titled "Save view" and confirms with Save; with
/// [rename] it is "Rename view", confirms with Rename, and starts with
/// [initialName] selected, so typing replaces it. The scope starts at
/// [initialScope], personal by default.
///
/// The name is trimmed, and an empty one is refused with an error under the
/// field rather than a disabled button. Enter in the field confirms, and
/// Escape, the scrim or Cancel close the dialog with null.
Future<({String name, SavedViewScope scope})?> showSaveViewDialog(
  BuildContext context, {
  String? initialName,
  SavedViewScope? initialScope,
  bool askScope = true,
  bool rename = false,
}) => showModal<({String name, SavedViewScope scope})>(
  context,
  builder: (context) => _SaveViewDialog(
    initialName: initialName ?? '',
    initialScope: initialScope ?? SavedViewScope.personal,
    askScope: askScope,
    rename: rename,
  ),
);

class _SaveViewDialog extends StatefulWidget {
  final String initialName;
  final SavedViewScope initialScope;
  final bool askScope;
  final bool rename;

  const _SaveViewDialog({
    required this.initialName,
    required this.initialScope,
    required this.askScope,
    required this.rename,
  });

  @override
  State<_SaveViewDialog> createState() => _SaveViewDialogState();
}

class _SaveViewDialogState extends State<_SaveViewDialog> {
  late final _name = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );
  late var _scope = widget.initialScope;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(_clearError);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null && _name.text.trim().isNotEmpty) {
      setState(() => _error = null);
    }
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.adminL10n.collection.viewNameRequired);
      return;
    }
    Navigator.of(context).pop((name: name, scope: _scope));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.collection;
    final material = MaterialLocalizations.of(context);
    return Modal(
      title: widget.rename ? strings.renameViewTitle : strings.saveViewTitle,
      description: widget.rename ? null : strings.saveViewDescription,
      size: ModalSize.small,
      onDismiss: () => Navigator.of(context).maybePop(),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputField(
            label: strings.viewName,
            controller: _name,
            autofocus: true,
            errorText: _error,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (widget.askScope) ...[
            const Gap(AdminSpacing.xl),
            LabeledField(
              label: strings.viewScope,
              child: Choice<SavedViewScope>(
                style: ChoiceStyle.card,
                value: _scope,
                onChanged: (scope) => setState(() => _scope = scope),
                options: [
                  ChoiceOption(
                    SavedViewScope.personal,
                    strings.personalView,
                    description: strings.personalViewDescription,
                    icon: Icons.person_outline,
                  ),
                  ChoiceOption(
                    SavedViewScope.shared,
                    strings.sharedView,
                    description: strings.sharedViewDescription,
                    icon: Icons.group_outlined,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        Button.ghost(
          material.cancelButtonLabel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        Button.primary(
          widget.rename ? strings.rename : material.saveButtonLabel,
          onPressed: _submit,
        ),
      ],
    );
  }
}
