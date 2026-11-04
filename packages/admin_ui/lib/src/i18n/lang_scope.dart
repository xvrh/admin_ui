import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:material_ui/material_ui.dart';

import 'locale_status.dart';

/// The language chrome source: the [locales] a form edits, the
/// [visibleLocales] in view, and the [sourceLocale] and [activeLocale],
/// adapted from the app's own language settings. Locale status is
/// presentation-only here.
class LangScope extends InheritedWidget {
  final List<LocaleInfo> locales;

  /// The codes of the locales in view.
  final Set<String> visibleLocales;

  /// The code of the locale the others translate from.
  final String sourceLocale;

  /// The code of the locale being edited.
  final String activeLocale;

  /// Reports a new set of locales in view, picked in a language pill.
  final ValueChanged<Set<String>> onVisibleLocalesChanged;

  const LangScope({
    super.key,
    required this.locales,
    required this.visibleLocales,
    required this.sourceLocale,
    required this.activeLocale,
    required this.onVisibleLocalesChanged,
    required super.child,
  });

  /// The nearest scope; throws when there is none. Translatable fields read
  /// it, so a form with translatable fields mounts one above them.
  static LangScope of(BuildContext c) {
    final scope = maybeOf(c);
    if (scope == null) {
      throw FlutterError(
        'LangScope.of() was called with a context that has no LangScope '
        'above it.\n'
        'Translatable fields read their locales and the source and active '
        'language from the nearest LangScope: mount one above the form, or '
        'use LangScope.maybeOf where there may be none.',
      );
    }
    return scope;
  }

  static LangScope? maybeOf(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<LangScope>();

  /// A new [locales] list — a lane's status changed — or a new
  /// [sourceLocale] rebuilds the lanes, as a new [visibleLocales] set or
  /// [activeLocale] does.
  @override
  bool updateShouldNotify(LangScope o) =>
      !setEquals(visibleLocales, o.visibleLocales) ||
      activeLocale != o.activeLocale ||
      sourceLocale != o.sourceLocale ||
      !listEquals(locales, o.locales);
}
