import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Regions the pointer is over, on the web, that open a menu of their own on
/// a right-click: the browser's context menu is off while there is one.
var _held = 0;

/// The browser's own context menu turned off while the pointer is over a
/// region that opens a menu of its own, and back on once it is over none of
/// them, so it still opens everywhere else. Off the web it does nothing.
///
/// One per region: setting [over] twice the same way counts once.
@internal
final class BrowserMenuHold {
  bool _over = false;

  /// Whether the pointer is over the region. Set it false when the region
  /// goes, or stops opening a menu.
  bool get over => _over;

  set over(bool over) {
    if (!kIsWeb || over == _over) return;
    _over = over;
    if (over) {
      if (_held++ == 0) unawaited(BrowserContextMenu.disableContextMenu());
    } else if (--_held == 0) {
      unawaited(BrowserContextMenu.enableContextMenu());
    }
  }
}
