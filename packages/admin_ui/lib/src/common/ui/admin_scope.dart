import 'package:material_ui/material_ui.dart';

import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'command_registry.dart';
import 'leave_guard.dart';
import 'modal_anchor.dart';
import 'toast.dart';

/// The scopes the kit's widgets reach for, mounted in one widget: the kit's
/// theme, a [ToastScope], a [LeaveGuardScope], a [CommandScope] and a
/// [ModalAnchor].
///
/// Place it inside the home route, around the shell:
///
/// ```dart
/// MaterialApp(
///   theme: buildAppTheme(tokens),
///   localizationsDelegates: AdminLocalizations.localizationsDelegates,
///   supportedLocales: AdminLocalizations.supportedLocales,
///   home: const AdminScope(child: HomePage()),
/// )
/// ```
///
/// There the anchor sits inside a route, so back closes an open modal before
/// it leaves the page, and a modal sees every scope above the anchor: the
/// compact `Shell`'s navigation drawer opens there too, so its items ask the
/// page's guards before they leave.
///
/// A route pushed on the Navigator is not below the home route, so it sees
/// none of the scopes mounted here. An app with routes keeps one page on its
/// Navigator for the signed-in app, one frame under one scope whose body the
/// route swaps (the README's "Routing"). A page that is pushed all the same
/// is wrapped in an [AdminScope] of its own, passing the same [commands] and
/// [leaveGuards] to share them, and the app is themed with `buildAppTheme`
/// rather than through [tokens]. From the outside in, it mounts:
///
/// - a material_ui [Theme] of `buildAppTheme(tokens)`, only when [tokens] is
///   given, for a material_ui app whose own theme `buildAppTheme` did not
///   build. It themes the subtree below this scope, and the dialogs opened
///   from it, but not a pushed route. It cannot stand in for
///   material_ui's `MaterialApp`: under the `MaterialApp` of
///   package:flutter/material.dart the kit's dialogs find no material_ui
///   `MaterialLocalizations`, so that app is not supported;
/// - a [ToastScope], unless one is above it already. A toast paints over a
///   route's dialog only from a scope above the Navigator, so an app that
///   raises toasts from dialogs mounts its own in `MaterialApp.builder`, and
///   this one is left out;
/// - a [LeaveGuardScope] over [leaveGuards], or over the registry of one
///   above it, or else over a registry of its own, which it disposes. The
///   forms' `UnsavedChangesGuard`s register there, so that while one holds
///   unsaved edits a `Sidebar` item asks before it leaves the page, and on
///   the web so does reloading or closing the tab;
/// - a [CommandScope] over [commands], or over a registry of its own, which
///   it disposes;
/// - a [ModalAnchor] opened through [modals], or through `ModalAnchor.of`.
///
/// Each of those scopes stays public, for an app that mounts them where it
/// wants them.
class AdminScope extends StatefulWidget {
  /// The kit's theme below this scope, as `buildAppTheme(tokens)`. Null keeps
  /// the enclosing theme. Routes pushed above the home route are outside the
  /// scope and keep the app's theme.
  final AdminTokens? tokens;

  /// The registry the [CommandScope] provides. Null gives the scope a
  /// registry of its own.
  final CommandRegistry? commands;

  /// The handle for opening modals on the [ModalAnchor]; see
  /// [ModalAnchor.controller].
  final ModalAnchorController? modals;

  /// The registry the [LeaveGuardScope] provides. Null uses the one of a
  /// scope above, or gives this scope a registry of its own.
  final LeaveGuardRegistry? leaveGuards;

  final Widget child;

  const AdminScope({
    super.key,
    this.tokens,
    this.commands,
    this.modals,
    this.leaveGuards,
    required this.child,
  });

  @override
  State<AdminScope> createState() => _AdminScopeState();
}

class _AdminScopeState extends State<AdminScope> {
  CommandRegistry? _ownCommands;
  LeaveGuardRegistry? _ownLeaveGuards;

  /// The theme built for [AdminScope.tokens], kept while they stay equal.
  ThemeData? _theme;
  AdminTokens? _themeTokens;

  CommandRegistry get _commands =>
      widget.commands ?? (_ownCommands ??= CommandRegistry());

  @override
  void didUpdateWidget(AdminScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.commands != null && _ownCommands != null) {
      _ownCommands!.dispose();
      _ownCommands = null;
    }
    if (widget.leaveGuards != null && _ownLeaveGuards != null) {
      _ownLeaveGuards!.dispose();
      _ownLeaveGuards = null;
    }
  }

  @override
  void dispose() {
    _ownCommands?.dispose();
    _ownLeaveGuards?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ModalAnchor(controller: widget.modals, child: widget.child);
    child = CommandScope(registry: _commands, child: child);
    // Mounted whichever registry it is, so the page keeps its state when
    // [AdminScope.leaveGuards] or a scope above comes or goes. A registry
    // of its own, once made, stays: its guards registered there.
    final leaveGuards =
        widget.leaveGuards ??
        _ownLeaveGuards ??
        LeaveGuardScope.maybeOf(context) ??
        (_ownLeaveGuards = LeaveGuardRegistry());
    child = LeaveGuardScope(registry: leaveGuards, child: child);
    if (ToastScope.maybeOf(context) == null) {
      child = ToastScope(child: child);
    }
    final tokens = widget.tokens;
    if (tokens != null) {
      if (tokens != _themeTokens) {
        _theme = buildAppTheme(tokens);
        _themeTokens = tokens;
      }
      child = Theme(data: _theme!, child: child);
    }
    return child;
  }
}
