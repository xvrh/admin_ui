import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'command_palette.dart' show PaletteItem;

/// A live registry of palette commands. Both global commands and a screen's
/// contextual commands are registered via [contribute], which returns a handle
/// the caller disposes when its commands no longer apply. [active] flattens all
/// contributors, calling each builder fresh so contextual commands reflect
/// current state.
class CommandRegistry extends ChangeNotifier {
  final _contributors = <_Contributor>[];

  /// Registers a command [builder]; dispose the returned handle to withdraw it.
  /// Global commands register once and keep the handle for the app's lifetime;
  /// contextual ones dispose it on unmount.
  CommandSubscription contribute(List<PaletteItem> Function() builder) {
    final c = _Contributor(builder);
    _contributors.add(c);
    _notify();
    return CommandSubscription._(this, c);
  }

  List<PaletteItem> active() => [for (final c in _contributors) ...c.builder()];

  void _remove(_Contributor c) {
    if (_contributors.remove(c)) {
      _notify();
    }
  }

  /// Notifies dependents, but never mid-frame: a subscription disposed while a
  /// widget unmounts (tree locked) would otherwise try to mark [CommandScope]
  /// dirty and throw. Defer to the next frame when that happens.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }
}

class _Contributor {
  final List<PaletteItem> Function() builder;
  _Contributor(this.builder);
}

/// Handle to a contribution; call [dispose] to withdraw it from the registry.
class CommandSubscription {
  final CommandRegistry _registry;
  final _Contributor _contributor;
  bool _disposed = false;

  CommandSubscription._(this._registry, this._contributor);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _registry._remove(_contributor);
  }
}

/// Provides a [CommandRegistry] to descendants and rebuilds dependents when the
/// set of contributors changes.
class CommandScope extends InheritedNotifier<CommandRegistry> {
  const CommandScope({
    super.key,
    required CommandRegistry registry,
    required super.child,
  }) : super(notifier: registry);

  static CommandRegistry of(BuildContext context) {
    final registry = maybeOf(context);
    if (registry == null) {
      throw FlutterError(
        'CommandScope.of() was called with a context that has no CommandScope '
        'above it.\n'
        'Mount a CommandScope with the app\'s CommandRegistry above the '
        'widgets that contribute commands and the palette that lists them, '
        'or use CommandScope.maybeOf where there may be none.',
      );
    }
    return registry;
  }

  static CommandRegistry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommandScope>()?.notifier;
}
