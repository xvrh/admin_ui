/// @docImport '../../common/ui/admin_scope.dart';
/// @docImport '../../common/ui/leave_guard.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, internal;
import 'package:material_ui/material_ui.dart';

import '../../common/ui/icon_action.dart';
import '../../common/ui/modal_anchor.dart';
import '../../common/ui/side_sheet.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'shell.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// Opens [sidebar] as a navigation drawer: a modal sheet from the start
/// edge, [width] wide at most, over a scrim. For a frame of the app's own; a
/// [Shell] opens its drawer itself, from its [TopBar]'s menu button or
/// [Shell.openDrawer].
///
/// The drawer opens on the nearest [ModalAnchor] ([AdminScope] mounts one),
/// so it sees every scope above that anchor: a [Sidebar] item in it asks the
/// page's [LeaveGuardScope] before it leaves, as it does in the rail. The
/// sidebar is drawn expanded and as wide as the drawer, under a band as tall
/// as the top bar that holds a close button and [leading] (the logo the top
/// bar starts with), each where the bar has its menu button and logo. It
/// paints the device's insets in its own colour. Opening an item closes the
/// drawer first, once the page lets it go. The scrim, Escape and back close
/// it too. It slides in from the right in a right-to-left layout.
///
/// Resolves when the drawer has closed.
Future<void> showNavigationDrawer(
  BuildContext context, {
  required Widget sidebar,
  Widget? leading,
  double width = Shell.drawerWidth,
}) async {
  final content = ValueNotifier((sidebar: sidebar, leading: leading));
  try {
    await showShellDrawer(
      ModalAnchor.of(context),
      content: content,
      width: width,
    );
  } finally {
    content.dispose();
  }
}

/// What a navigation drawer holds: the sidebar, and what its head band
/// shows after the close button.
@internal
typedef NavigationDrawerContent = ({Widget sidebar, Widget? leading});

/// Opens the navigation drawer on [anchor], following [content] as it
/// changes.
@internal
Future<void> showShellDrawer(
  ModalAnchorController anchor, {
  required ValueListenable<NavigationDrawerContent> content,
  double width = Shell.drawerWidth,
}) => anchor.showSheet<void>(
  side: SideSheetSide.start,
  width: width,
  builder: (context) => ValueListenableBuilder(
    valueListenable: content,
    builder: (context, content, _) => _Drawer(
      sidebar: content.sidebar,
      leading: content.leading,
      width: math.min(width, MediaQuery.sizeOf(context).width),
      onClose: anchor.close,
    ),
  ),
);

/// The drawer's surface: a start-edge [SideSheet] leaving the device's
/// insets to the sidebar, which paints them in its own colour.
class _Drawer extends StatelessWidget {
  final Widget sidebar;
  final Widget? leading;
  final double width;
  final VoidCallback onClose;

  const _Drawer({
    required this.sidebar,
    required this.leading,
    required this.width,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SideSheet(
      side: SideSheetSide.start,
      safeArea: false,
      semanticLabel: MaterialLocalizations.of(context).drawerLabel,
      child: NavigationDrawerScope(
        width: width,
        close: onClose,
        head: _DrawerHead(leading: leading, onClose: onClose),
        child: sidebar,
      ),
    );
  }
}

/// Tells a [Sidebar] it is the navigation drawer: to draw expanded and
/// [width] wide under [head], and to [close] the drawer as an item opens.
@internal
class NavigationDrawerScope extends InheritedWidget {
  final double width;
  final VoidCallback close;
  final Widget head;

  const NavigationDrawerScope({
    super.key,
    required this.width,
    required this.close,
    required this.head,
    required super.child,
  });

  /// The drawer [context] is in, or null outside one.
  static NavigationDrawerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationDrawerScope>();

  @override
  bool updateShouldNotify(NavigationDrawerScope old) =>
      width != old.width || close != old.close || head != old.head;
}

/// The drawer's head: a band as tall as the top bar, with a hairline under
/// it as the bar has, holding the close button where the bar has its menu
/// button and [leading] where the bar has its own.
class _DrawerHead extends StatelessWidget {
  final Widget? leading;
  final VoidCallback onClose;

  const _DrawerHead({required this.leading, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    return Container(
      height: context.shellStyle.topBarHeight,
      padding: EdgeInsetsDirectional.only(
        start: TopBar.menuButtonStartOf(context),
        end: AdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          IconAction(
            Icons.close_rounded,
            label: context.adminL10n.shell.closeNavigation,
            onPressed: onClose,
          ),
          if (leading != null) ...[
            const Gap(TopBar.menuButtonGap),
            Flexible(child: leading),
          ],
        ],
      ),
    );
  }
}

/// The button that opens the [Shell]'s navigation drawer: a menu
/// [IconAction] named "Open navigation" in the app's language. A [TopBar]
/// leads with one while the shell has a drawer ([Shell.hasDrawer]); pass one
/// as [TopBar.menuButton] to key it.
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconAction(
      Icons.menu_rounded,
      label: context.adminL10n.shell.openNavigation,
      onPressed: () => Shell.openDrawer(context),
    );
  }
}
