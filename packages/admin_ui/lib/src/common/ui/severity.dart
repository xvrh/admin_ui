import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// The tone shared by feedback surfaces ([Alert], [Toast]) — picks the accent
/// colour, soft background and leading icon.
enum Severity { info, success, warning, danger }

/// The colours and icon a [Severity] takes under the active theme, from
/// [severityStyleOf] — for a feedback surface the kit does not ship.
class SeverityStyle {
  /// The raw status colour: solid fills, dots, accent bars.
  final Color accent;

  /// Soft tinted fill for inline surfaces.
  final Color surface;

  /// Text-safe version of [accent] for text and small icons, on [surface] or
  /// the page (4.5:1).
  final Color foreground;

  /// Border for a [surface] panel, a step stronger than the fill.
  final Color border;

  /// Content colour on an [accent] fill (a solid badge, a filled icon).
  final Color onAccent;

  final IconData icon;

  const SeverityStyle({
    required this.accent,
    required this.surface,
    required this.foreground,
    required this.border,
    required this.onAccent,
    required this.icon,
  });
}

/// Resolves the [SeverityStyle] for the active theme. The accent comes from the
/// palette status colours; the soft surface and border are derived from it
/// via `statusFill` / `statusBorder`, and the foreground and on-accent colours
/// are the palette's text-safe and on-fill roles, so every tone tracks the
/// theme (and dark mode) instead of hardcoding.
SeverityStyle severityStyleOf(BuildContext context, Severity severity) {
  final c = context.colors;
  final (
    Color accent,
    Color foreground,
    Color onAccent,
    IconData icon,
  ) = switch (severity) {
    Severity.info => (c.info, c.infoText, c.onInfo, Icons.info_outline_rounded),
    Severity.success => (
      c.success,
      c.successText,
      c.onSuccess,
      Icons.check_circle_outline_rounded,
    ),
    Severity.warning => (
      c.warning,
      c.warningText,
      c.onWarning,
      Icons.warning_amber_rounded,
    ),
    Severity.danger => (
      c.danger,
      c.dangerText,
      c.onDanger,
      Icons.error_outline_rounded,
    ),
  };
  return SeverityStyle(
    accent: accent,
    surface: c.statusFill(accent),
    foreground: foreground,
    border: c.statusBorder(accent),
    onAccent: onAccent,
    icon: icon,
  );
}
