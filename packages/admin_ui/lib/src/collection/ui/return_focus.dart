import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Calls [focus] once the focus has settled after this frame, unless a
/// control outside [context] holds it: no focus, a scope's, or that of a
/// widget around [context] is no control's. A `SelectionArea` is one of
/// those: a click anywhere under it gives it the focus, which a page keeps
/// as the one to go back to.
@internal
void focusOnReturn(BuildContext context, VoidCallback focus) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // After the focus manager's update, which this frame scheduled first:
    // the focus a page gives back, or a field's autofocus, has landed.
    scheduleMicrotask(() {
      if (!context.mounted) return;
      final holder = FocusManager.instance.primaryFocus;
      if (holder == null ||
          holder is FocusScopeNode ||
          _isAround(holder.context, context)) {
        focus();
      }
    });
  });
}

bool _isAround(BuildContext? outer, BuildContext inner) {
  if (outer == null) return false;
  var found = false;
  inner.visitAncestorElements((element) {
    found = identical(element, outer);
    return !found;
  });
  return found;
}
