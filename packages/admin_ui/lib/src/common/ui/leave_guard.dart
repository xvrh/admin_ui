/// @docImport 'admin_scope.dart';
library;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../before_unload.dart';

/// One place that would lose work if the user left: [blocks] says whether
/// it does now, and [confirm] asks the user whether to leave anyway.
class LeaveGuardEntry {
  final bool Function() blocks;

  /// Asks whether to leave, resolving true to leave. [context] is the one
  /// the leave was asked from.
  final Future<bool> Function(BuildContext context) confirm;

  /// Notifies as [blocks] may have changed, for the registry to turn the
  /// browser's own prompt on and off in step. Null when [blocks] never
  /// changes while the entry is registered.
  final Listenable? listenable;

  const LeaveGuardEntry({
    required this.blocks,
    required this.confirm,
    this.listenable,
  });
}

/// How many registries hold the browser's prompt on.
int _unloadHolds = 0;

void _holdUnloadGuard(bool on) {
  _unloadHolds += on ? 1 : -1;
  setBeforeUnloadGuard(_unloadHolds > 0);
}

/// The [LeaveGuardEntry]s of an app, which navigation consults before it
/// leaves a page: [confirmLeave] asks the user when an entry [blocks].
///
/// On the web it also keeps the browser's own "Leave site?" prompt on while
/// an entry blocks, so reloading or closing the tab asks first too. It
/// re-reads [blocks] as each entry's [LeaveGuardEntry.listenable] notifies,
/// and notifies its own listeners when [blocks] flips.
class LeaveGuardRegistry extends ChangeNotifier {
  LeaveGuardRegistry() : _setUnloadGuard = _holdUnloadGuard;

  /// A registry that calls [setUnloadGuard] where it would turn the
  /// browser's prompt on or off, for a test to watch.
  @visibleForTesting
  LeaveGuardRegistry.withUnloadGuard(void Function(bool on) setUnloadGuard)
    : _setUnloadGuard = setUnloadGuard;

  final void Function(bool on) _setUnloadGuard;
  final _entries = <LeaveGuardEntry>[];
  bool _blocking = false;
  bool _disposed = false;
  Future<bool>? _prompt;

  /// Adds [entry], and returns the call that removes it again: make that
  /// call when the place [entry] guards goes away.
  VoidCallback register(LeaveGuardEntry entry) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _entries.add(entry);
    entry.listenable?.addListener(_update);
    _update();
    var registered = true;
    return () {
      if (!registered || _disposed) return;
      registered = false;
      _entries.remove(entry);
      entry.listenable?.removeListener(_update);
      _update();
    };
  }

  /// Whether leaving now would lose work: whether any entry blocks.
  bool get blocks => _entries.any((entry) => entry.blocks());

  /// Whether to go ahead and leave. True at once when nothing [blocks];
  /// otherwise the first blocking entry asks the user, and only that one: a
  /// single prompt answers for every entry. A call while that prompt is open
  /// shares its answer rather than opening another.
  Future<bool> confirmLeave(BuildContext context) {
    if (_prompt case final prompt?) return prompt;
    for (final entry in _entries) {
      if (!entry.blocks()) continue;
      final prompt = _prompt = entry.confirm(context);
      void settle() {
        if (identical(_prompt, prompt)) _prompt = null;
      }

      prompt.then((_) => settle(), onError: (Object _) => settle());
      return prompt;
    }
    return Future.value(true);
  }

  void _update() {
    if (_disposed) return;
    final blocking = blocks;
    if (blocking == _blocking) return;
    _blocking = blocking;
    _setUnloadGuard(blocking);
    // A guard registers as it mounts, and the scope above it cannot be
    // marked to rebuild in the middle of that frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final entry in _entries) {
      entry.listenable?.removeListener(_update);
    }
    _entries.clear();
    if (_blocking) {
      _blocking = false;
      _setUnloadGuard(false);
    }
    super.dispose();
  }
}

/// Provides a [LeaveGuardRegistry] to the guards and the navigation beneath
/// it; [AdminScope] mounts one.
///
/// A guard, such as the forms layer's `UnsavedChangesGuard`, registers with
/// the nearest one, and navigation that leaves the page, such as a
/// `Sidebar` item or an app's router, first awaits [confirmLeave].
class LeaveGuardScope extends InheritedNotifier<LeaveGuardRegistry> {
  const LeaveGuardScope({
    super.key,
    required LeaveGuardRegistry registry,
    required super.child,
  }) : super(notifier: registry);

  /// The nearest registry, or null with none above. [context] rebuilds as
  /// the registry's [LeaveGuardRegistry.blocks] flips.
  static LeaveGuardRegistry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LeaveGuardScope>()?.notifier;

  /// Whether to go ahead and leave the page: the nearest registry's
  /// [LeaveGuardRegistry.confirmLeave], or true with none above. Call it
  /// before switching pages, and switch only on true.
  static Future<bool> confirmLeave(BuildContext context) {
    final registry = context
        .getInheritedWidgetOfExactType<LeaveGuardScope>()
        ?.notifier;
    return registry?.confirmLeave(context) ?? Future.value(true);
  }
}
