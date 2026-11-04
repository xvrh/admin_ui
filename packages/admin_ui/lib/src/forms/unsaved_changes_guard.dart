import 'package:material_ui/material_ui.dart';

import '../common/ui/leave_guard.dart';
import '../common/ui/modal.dart';
import '../common/ui/modal_anchor.dart';
import '../l10n/admin_ui_localizations.dart';
import 'form_controller.dart';

/// Asks the user to confirm leaving while [controller] has unsaved changes,
/// or while a save is still in flight.
///
/// It intercepts a pop (OS/browser back): on web — the admin's primary
/// target — this catches the browser back button. Confirming pops the
/// route; cancelling keeps it.
///
/// While mounted it also registers with the nearest [LeaveGuardScope]
/// (`AdminScope` mounts one), so leaving the page any other way asks too:
/// a `Sidebar` item, or an app's router, awaits
/// [LeaveGuardScope.confirmLeave] before it switches pages and switches only
/// on a confirm. On the web the registry also turns on the browser's own
/// prompt while the form blocks, for reloading or closing the tab. One
/// prompt answers for every guard on the page.
///
/// Mid-save the prompt says so ([savingTitle], [savingMessage]): if the save
/// fails after the page is gone, the edits go with it.
///
/// Every text is an override: a null one reads the kit's own, in the app's
/// language, and the prompt's cancel is Material's.
///
/// [enabled] should be `false` when the backing store auto-persists (a live
/// collaborative draft): there is nothing to lose, so the prompt is suppressed
/// and the guard does not register.
class UnsavedChangesGuard extends StatefulWidget {
  final FormController controller;
  final bool enabled;
  final Widget child;

  /// The prompt's title: "Discard changes?".
  final String? title;

  /// The prompt's message: the unsaved changes will be lost.
  final String? message;

  /// The confirm button: "Discard".
  final String? confirmLabel;

  /// The prompt's title while a save is in flight.
  final String? savingTitle;

  /// The prompt's message while a save is in flight.
  final String? savingMessage;

  /// The confirm button while a save is in flight: "Leave".
  final String? savingConfirmLabel;

  const UnsavedChangesGuard({
    super.key,
    required this.controller,
    required this.child,
    this.enabled = true,
    this.title,
    this.message,
    this.confirmLabel,
    this.savingTitle,
    this.savingMessage,
    this.savingConfirmLabel,
  });

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  /// The nearest registry, registered with only while [widget] is enabled.
  LeaveGuardRegistry? _scope;
  LeaveGuardRegistry? _registry;
  FormController? _registered;
  VoidCallback? _unregister;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = LeaveGuardScope.maybeOf(context);
    _register();
  }

  @override
  void didUpdateWidget(UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register();
  }

  @override
  void dispose() {
    _unregister?.call();
    super.dispose();
  }

  void _register() {
    final registry = widget.enabled ? _scope : null;
    final controller = widget.controller;
    if (registry == _registry && controller == _registered) return;
    _unregister?.call();
    _registry = registry;
    _registered = controller;
    // Unlike the PopScope, this does not stand down for an open portal
    // modal: a back press closes the modal, but leaving the page loses the
    // edits under it. A ⌘K palette's "go to" that asks the registry also
    // runs while the palette is still closing, and would otherwise be let
    // through.
    _unregister = registry?.register(
      LeaveGuardEntry(
        blocks: () => controller.blocksNavigation,
        confirm: (_) => _confirmLeave(context, widget),
        listenable: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    // Outside a route there is no pop to intercept.
    final route = ModalRoute.of(context);
    if (route == null) return child;
    final modals = ModalAnchor.openCountOn(route);
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, modals]),
      builder: (context, _) {
        // While a portal modal is open on this route, the next back belongs
        // to it (its LocalHistoryEntry closes it) — but PopScope vetoes are
        // consulted before local history, so the guard must stand down or
        // back would prompt to discard instead of closing the modal.
        final block =
            widget.enabled && controller.blocksNavigation && modals.value == 0;
        return PopScope<Object?>(
          canPop: !block,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop || !block) return;
            final leave = await _confirmLeave(context, widget);
            if (!leave || !context.mounted) return;
            // `pop`, not `maybePop`: the form is still dirty, so asking the
            // PopScope again would only bring the prompt back.
            if (ModalRoute.of(context)?.isCurrent ?? true) {
              Navigator.of(context).pop(result);
            }
          },
          child: child,
        );
      },
    );
  }
}

/// Asks whether to leave [guard]'s unsaved edits, in the words for a save in
/// flight while there is one. Resolves true to leave.
Future<bool> _confirmLeave(BuildContext context, UnsavedChangesGuard guard) {
  final saving = guard.controller.status == FormStatus.submitting;
  final shell = context.adminL10n.shell;
  return showConfirmDialog(
    context,
    title: saving
        ? guard.savingTitle ?? shell.leaveWhileSavingTitle
        : guard.title ?? shell.discardChangesTitle,
    message: saving
        ? guard.savingMessage ?? shell.leaveWhileSavingMessage
        : guard.message ?? shell.discardChangesMessage,
    confirmLabel: saving
        ? guard.savingConfirmLabel ?? shell.leave
        : guard.confirmLabel ?? shell.discard,
    cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
    danger: true,
  );
}
