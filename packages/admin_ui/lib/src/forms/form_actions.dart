/// @docImport '../shell/ui/page_header.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../common/ui/error_text.dart';
import '../common/ui/field_registry.dart';
import '../l10n/admin_ui_localizations.dart';
import '../shell/ui/save_bar.dart';
import '../shell/ui/save_cluster.dart';
import 'form_controller.dart';
import 'form_save_bar.dart';
import 'form_shortcuts.dart';

/// The save/publish cluster as a compact row, driven by a [FormController] — the
/// "header with save in it" layout. A [SaveCluster] with the same logic as
/// [FormSaveBar] (live status, Discard, a split commit, the invalid-fields
/// hint, Cmd+S / Ctrl+S) but with no full-width strip, so it drops into a
/// [PageHeader]'s `actions`. Place secondary [actions] (history, a mode toggle)
/// before the save controls.
class FormActions extends StatelessWidget {
  final FormController controller;

  /// The submit's label. When null it follows [flow]: "Publish" in the
  /// app's language under [SaveFlow.publish], whose submit makes the edits
  /// live, and Material's save label under [SaveFlow.save].
  final String? commitLabel;

  final String? savedLabel;

  /// The error status when the controller has neither a
  /// [FormController.submitError] nor a [FormController.submitFailure] to
  /// word; "Couldn’t save" when null.
  final String? errorLabel;

  /// Discard's label; "Discard" in the app's language when null.
  final String? discardLabel;

  /// See [SaveBar.flow].
  final SaveFlow flow;

  /// Secondary controls placed before the save controls.
  final List<Widget> actions;

  /// Less-common actions (version history, duplicate…) collapsed into a ⋯ "more
  /// actions" menu placed before the primary buttons.
  final List<SaveBarAction> overflowActions;

  /// Alternatives under a split submit button (Schedule, Unpublish…).
  final List<SaveBarAction> commitMenu;

  /// Discard handler; defaults to [FormController.reset].
  final VoidCallback? onDiscard;

  /// Shows Discard — disabled while there is nothing to discard.
  final bool showDiscard;

  /// Tooltip on the submit disabled for want of changes. When null, "No
  /// changes to publish" under [SaveFlow.publish]'s default label, else "No
  /// changes", in the app's language.
  final String? commitDisabledHint;

  /// The form's fields, among which the first invalid one is revealed; the
  /// ambient [FormFieldScope] when null. A header sits above the form's body,
  /// so pass the registry the body's scope provides.
  final FormFieldRegistry? fields;

  /// Whether Cmd+S / Ctrl+S saves the form (see [FormShortcuts]; under
  /// [SaveFlow.publish] the shortcut never publishes) while this is mounted.
  final bool saveShortcut;

  /// The key of the commit button, to find it by in a test.
  final Key? commitKey;

  /// The key of the Discard button, to find it by in a test.
  final Key? discardKey;

  const FormActions({
    super.key,
    required this.controller,
    this.commitLabel,
    this.savedLabel,
    this.errorLabel,
    this.discardLabel,
    this.flow = SaveFlow.save,
    this.actions = const [],
    this.overflowActions = const [],
    this.commitMenu = const [],
    this.onDiscard,
    this.showDiscard = false,
    this.commitDisabledHint,
    this.fields,
    this.saveShortcut = true,
    this.commitKey,
    this.discardKey,
  });

  @override
  Widget build(BuildContext context) {
    final fields = this.fields ?? FormFieldScope.maybeOf(context);
    final publish = flow == SaveFlow.publish;
    final cluster = ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SaveCluster(
        state: saveStateFor(controller.status),
        savedLabel: savedLabel,
        errorLabel:
            controller.submitError ??
            switch (controller.submitFailure) {
              final failure? => ErrorTextScope.describe(context, failure),
              null => errorLabel,
            },
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
        flow: flow,
      ),
    );
    if (!saveShortcut) return cluster;
    return FormShortcuts(
      controller: controller,
      fields: fields,
      flow: flow,
      child: cluster,
    );
  }
}
