import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'shell.dart';

/// The compact frame at a phone's 360px with its navigation drawer open:
/// the sidebar drawn expanded, under a head as tall as the top bar that has
/// the close button where the bar has its menu button and the workspace
/// where the bar has it.
///
/// Rendered on a device with insets (`--device=iphone-16`), the top bar
/// runs under the status bar in its own colour and the drawer paints both
/// insets in the sidebar's. The insets are the device's: a drawer is an
/// overlay, and an overlay reads the screen's insets, not a demo's.
class ShellDrawerDemo extends StatelessWidget {
  @Preview(name: 'Shell (phone, drawer open)', wrapper: adminUiPreview)
  const ShellDrawerDemo({super.key});

  @override
  Widget build(BuildContext context) => const ShellDemo.drawerOpen();
}
