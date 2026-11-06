import 'package:material_ui/material_ui.dart';

import '../common/ui/field_registry.dart';
import '../l10n/admin_ui_localizations.dart';
import '../shell/ui/save_bar.dart';
import 'form_controller.dart';
import 'form_shortcuts.dart';

/// Maps the backing-agnostic [FormStatus] onto the presentational [SaveState].
SaveState saveStateFor(FormStatus status) => switch (status) {
  FormStatus.clean => SaveState.clean,
  FormStatus.dirty => SaveState.unsaved,
  FormStatus.submitting => SaveState.saving,
  FormStatus.submitted => SaveState.saved,
  FormStatus.error => SaveState.error,
};

/// A [SaveBar] driven by a [FormController]: the indicator, the disabled/spinning
/// states, and the commit, which submits the form, are all derived from the
/// controller's status, so screens never hand-track save state.
///
/// Unsaved edits with validation errors say so in the status ("2 fields need
/// attention", from [FormController.errorCount]), which focuses the first
/// invalid field among [fields] — each showing its message when the form
/// sits in a `FormErrorsScope` of the same controller; a failed submit shows
/// [FormController.submitError]. Cmd+S / Ctrl+S saves from anywhere on the
/// page (see [FormShortcuts]).
class FormSaveBar extends StatelessWidget {
  final FormController controller;
  final Widget? leading;
  final Widget? status;

  /// The submit's label. When null it follows [flow]: "Publish" in the
  /// app's language under [SaveFlow.publish], whose submit makes the edits
  /// live, and Material's save label under [SaveFlow.save].
  final String? commitLabel;

  final String? savedLabel;

  /// The error status when the controller has no [FormController.submitError];
  /// "Couldn’t save" when null.
  final String? errorLabel;

  /// Discard's label; "Discard" in the app's language when null.
  final String? discardLabel;

  /// Secondary controls placed inside the bar (history, mode toggle, …).
  final List<Widget> actions;

  /// Less-common actions collapsed into a ⋯ overflow menu inside the bar.
  final List<SaveBarAction> overflowActions;

  /// Alternatives under a split submit button (Schedule, Unpublish…).
  final List<SaveBarAction> commitMenu;

  /// Tooltip on the submit disabled for want of changes. When null, "No
  /// changes to publish" under [SaveFlow.publish]'s default label, else "No
  /// changes", in the app's language.
  final String? commitDisabledHint;

  /// Discard handler; defaults to [FormController.reset].
  final VoidCallback? onDiscard;

  /// Shows Discard — disabled while there is nothing to discard.
  final bool showDiscard;

  /// The form's fields, among which the first invalid one is revealed; the
  /// ambient [FormFieldScope] when null.
  final FormFieldRegistry? fields;

  /// Whether Cmd+S / Ctrl+S saves the form (see [FormShortcuts]; under
  /// [SaveFlow.publish] the shortcut never publishes) while the bar is
  /// mounted.
  final bool saveShortcut;

  /// Where the bar sits — drives which edge its hairline draws on.
  final SaveBarPlacement placement;

  /// See [SaveBar.flow].
  final SaveFlow flow;

  /// The key of the commit button, to find it by in a test.
  final Key? commitKey;

  /// The key of the Discard button, or of its row when a narrow bar folds it
  /// into its menu, to find it by in a test.
  final Key? discardKey;

  const FormSaveBar({
    super.key,
    required this.controller,
    this.leading,
    this.status,
    this.commitLabel,
    this.savedLabel,
    this.errorLabel,
    this.discardLabel,
    this.actions = const [],
    this.overflowActions = const [],
    this.commitMenu = const [],
    this.commitDisabledHint,
    this.onDiscard,
    this.showDiscard = false,
    this.fields,
    this.saveShortcut = true,
    this.placement = SaveBarPlacement.top,
    this.flow = SaveFlow.save,
    this.commitKey,
    this.discardKey,
  });

  @override
  Widget build(BuildContext context) {
    final fields = this.fields ?? FormFieldScope.maybeOf(context);
    final publish = flow == SaveFlow.publish;
    final bar = ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SaveBar(
        leading: leading,
        status: status,
        state: saveStateFor(controller.status),
        savedLabel: savedLabel,
        errorLabel: controller.submitError ?? errorLabel,
        invalidCount: controller.errorCount,
        onShowInvalid: fields == null
            ? null
            : () => FormShortcuts.revealFirstInvalid(controller, fields),
        actions: actions,
        overflowActions: overflowActions,
        commitMenu: commitMenu,
        onDiscard: showDiscard ? (onDiscard ?? controller.reset) : null,
        discardLabel: discardLabel,
        onCommit: controller.requestSubmit,
        commitKey: commitKey,
        discardKey: discardKey,
        commitEnabled: controller.canSubmit,
        commitDisabledHint:
            commitDisabledHint ??
            (commitLabel == null && publish
                ? context.adminL10n.shell.noChangesToPublish
                : context.adminL10n.shell.noChanges),
        committing: controller.status == FormStatus.submitting,
        commitLabel:
            commitLabel ??
            (publish
                ? null
                : MaterialLocalizations.of(context).saveButtonLabel),
        placement: placement,
        flow: flow,
      ),
    );
    if (!saveShortcut) return bar;
    return FormShortcuts(
      controller: controller,
      fields: fields,
      flow: flow,
      child: bar,
    );
  }
}
