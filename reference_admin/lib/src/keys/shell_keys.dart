import 'package:flutter/foundation.dart';

/// The navigation destinations, in sidebar order.
enum Nav { dashboard, orders, customers, products, media, team, settings }

/// Keys of the frame's controls, as `ValueKey('shell.<thing>')`. Scenarios
/// target these, never English words.
abstract final class ShellKeys {
  /// The sidebar's row for [nav], in the rail and the phone's drawer too.
  static ValueKey<String> nav(Nav nav) => ValueKey('shell.nav.${nav.name}');

  static const frame = ValueKey('shell.frame');
  static const menu = ValueKey('shell.menu');
  static const drawer = ValueKey('shell.drawer');
  static const search = ValueKey('shell.search');
  static const modeToggle = ValueKey('shell.modeToggle');
  static const bell = ValueKey('shell.bell');
  static const userMenu = ValueKey('shell.userMenu');
  static const offline = ValueKey('shell.offline');
  static const progress = ValueKey('shell.progress');
  static const forbidden = ValueKey('shell.forbidden');
  static const notFound = ValueKey('shell.notFound');
  static const backToDashboard = ValueKey('shell.backToDashboard');
  static const stub = ValueKey('shell.stub');
}
