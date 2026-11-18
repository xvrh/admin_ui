import 'package:flutter/foundation.dart' show internal;
import 'package:material_ui/material_ui.dart';

import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';

/// Draws [child] in [palette] in place of the page's, for a part of the
/// screen a theme draws in another scheme (Carbon's g100 header, Ant's dark
/// sider, an M3 snackbar): the enclosing kit theme rebuilt with that
/// palette, its type colours following. Only the theme changes, so the
/// commands, toasts and modal anchor below stay the app's.
@internal
class ChromeTheme extends StatefulWidget {
  final AdminPalette palette;
  final Widget child;

  const ChromeTheme({super.key, required this.palette, required this.child});

  @override
  State<ChromeTheme> createState() => _ChromeThemeState();
}

class _ChromeThemeState extends State<ChromeTheme> {
  /// The theme built for [_tokens] with [_palette], kept while both stay
  /// equal.
  ThemeData? _theme;
  AdminTokens? _tokens;
  AdminPalette? _palette;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    final palette = widget.palette;
    if (tokens != _tokens || palette != _palette) {
      _theme = buildAppTheme(tokens.copyWith(palette: palette));
      _tokens = tokens;
      _palette = palette;
    }
    return Theme(
      data: _theme!,
      // Text that sets no colour of its own reads on the chrome, not in the
      // page's ink the enclosing Material set.
      child: DefaultTextStyle.merge(
        style: TextStyle(color: palette.foreground),
        child: widget.child,
      ),
    );
  }
}
