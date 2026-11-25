import 'package:flutter/foundation.dart' show internal;
import 'package:material_ui/material_ui.dart';

import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';

/// Draws [child] in [palette] in place of the page's, for a part of the
/// screen a theme draws in another scheme (Carbon's g100 header, Ant's dark
/// sider, an M3 snackbar) or on a fill of its own (an overlay, in
/// [AdminPalette.withSurface]'s palette): the enclosing kit theme rebuilt
/// with that palette, its type colours following. Only the theme changes,
/// so the commands, toasts and modal anchor below stay the app's.
///
/// Given the page's own palette it changes nothing: the theme above is
/// passed on as it is.
@internal
class ChromeTheme extends StatefulWidget {
  final AdminPalette palette;
  final Widget child;

  const ChromeTheme({super.key, required this.palette, required this.child});

  /// [context], or the context above the outermost [ChromeTheme] around
  /// it: the page's. A route takes on the themes around the context that
  /// opens it, and a modal or a sheet opened from chrome (the sidebar's
  /// account menu) is the page's all the same, so it opens from here.
  static BuildContext pageOf(BuildContext context) {
    var page = context;
    context.visitAncestorElements((element) {
      if (element.widget is ChromeTheme) page = element;
      return true;
    });
    return page;
  }

  @override
  State<ChromeTheme> createState() => _ChromeThemeState();
}

/// The themes built for a set of tokens, by palette: every overlay of a
/// page asks for the same one or two, on every open.
final _themes = Expando<Map<AdminPalette, ThemeData>>('ChromeTheme themes');

class _ChromeThemeState extends State<ChromeTheme> {
  /// The theme built for [_tokens] with [_palette], kept while both stay
  /// the same.
  ThemeData? _theme;
  AdminTokens? _tokens;
  AdminPalette? _palette;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    final palette = widget.palette;
    final ThemeData theme;
    if (palette == tokens.palette) {
      // The theme above as its [Theme] holds it, not as [Theme.of] returns
      // it localized: handed on, that copy would be localized again, and
      // each such copy takes one of the five places in Flutter's cache of
      // localized themes.
      theme =
          context.findAncestorWidgetOfExactType<Theme>()?.data ??
          Theme.of(context);
    } else {
      if (!identical(tokens, _tokens) || !identical(palette, _palette)) {
        _theme = (_themes[tokens] ??= {})[palette] ??= buildAppTheme(
          tokens.copyWith(palette: palette),
        );
        _tokens = tokens;
        _palette = palette;
      }
      theme = _theme!;
    }
    return Theme(
      data: theme,
      // Text that sets no colour of its own reads on the chrome, not in the
      // page's ink the enclosing Material set.
      child: DefaultTextStyle.merge(
        style: TextStyle(color: palette.foreground),
        child: widget.child,
      ),
    );
  }
}
