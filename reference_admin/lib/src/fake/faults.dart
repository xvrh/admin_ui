import 'dart:async';

import '../api/shop_api.dart';

/// How long the fake takes to answer each kind of call. Applied as
/// `Future.delayed`, which is fake time under scenarios and real time in the
/// app.
class Latency {
  final Duration read;
  final Duration list;
  final Duration search;
  final Duration write;
  final Duration refund;

  const Latency({
    required this.read,
    required this.list,
    required this.search,
    required this.write,
    required this.refund,
  });

  /// Answers at once: the layout sweep and unit tests.
  static const none = Latency(
    read: Duration.zero,
    list: Duration.zero,
    search: Duration.zero,
    write: Duration.zero,
    refund: Duration.zero,
  );

  /// What a shop on a decent connection feels like: the app and scenarios.
  static const realistic = Latency(
    read: Duration(milliseconds: 300),
    list: Duration(milliseconds: 350),
    search: Duration(milliseconds: 200),
    write: Duration(milliseconds: 600),
    refund: Duration(milliseconds: 700),
  );

  /// [realistic] scaled so a list takes [listMs].
  factory Latency.scaled(int listMs) {
    final factor = listMs / realistic.list.inMilliseconds;
    Duration scale(Duration d) =>
        Duration(microseconds: (d.inMicroseconds * factor).round());
    return Latency(
      read: scale(realistic.read),
      list: scale(realistic.list),
      search: scale(realistic.search),
      write: scale(realistic.write),
      refund: scale(realistic.refund),
    );
  }

  Duration of(CallKind kind) => switch (kind) {
    CallKind.read => read,
    CallKind.list => list,
    CallKind.search => search,
    CallKind.write => write,
    CallKind.refund => refund,
  };
}

/// Holds the next call of an endpoint until [release]: how a scenario
/// photographs a loading state whatever the latency.
class Gate {
  final _opened = Completer<void>();

  bool get isReleased => _opened.isCompleted;
  Future<void> get opened => _opened.future;

  void release() {
    if (!_opened.isCompleted) _opened.complete();
  }
}

/// Failures and holds armed on the fake, per [Endpoint].
class FaultPlan {
  final _once = <Endpoint, List<ShopError>>{};
  final _always = <Endpoint, ShopError>{};
  final _holds = <Endpoint, List<Gate>>{};
  final void Function(bool online) _onConnectivity;
  bool _offline = false;

  FaultPlan(this._onConnectivity);

  bool get isOffline => _offline;

  /// The next [times] calls of [endpoint] fail with [error].
  void failNext(Endpoint endpoint, ShopError error, {int times = 1}) {
    (_once[endpoint] ??= []).addAll(List.filled(times, error));
  }

  /// Every call of [endpoint] fails with [error] until [clear].
  void failAlways(Endpoint endpoint, ShopError error) =>
      _always[endpoint] = error;

  /// The next call of [endpoint] waits until the returned gate is released.
  Gate hold(Endpoint endpoint) {
    final gate = Gate();
    (_holds[endpoint] ??= []).add(gate);
    return gate;
  }

  /// Every call fails with `ShopError.offline` until [goOnline].
  void goOffline() {
    if (_offline) return;
    _offline = true;
    _onConnectivity(false);
  }

  void goOnline() {
    if (!_offline) return;
    _offline = false;
    _onConnectivity(true);
  }

  /// Forgets every armed failure and releases every hold. Connectivity is
  /// left as it is.
  void clear() {
    _once.clear();
    _always.clear();
    for (final gates in _holds.values) {
      for (final gate in gates) {
        gate.release();
      }
    }
    _holds.clear();
  }

  /// The gate the call about to run must wait on, taken off the plan.
  Gate? takeHold(Endpoint endpoint) {
    final gates = _holds[endpoint];
    if (gates == null || gates.isEmpty) return null;
    return gates.removeAt(0);
  }

  /// The error the call about to run must fail with, if any.
  ShopError? takeFailure(Endpoint endpoint) {
    if (_offline) return const ShopError.offline();
    final queued = _once[endpoint];
    if (queued != null && queued.isNotEmpty) return queued.removeAt(0);
    return _always[endpoint];
  }
}

/// One call the fake answered.
class CallRecord {
  final Endpoint endpoint;
  final Map<String, Object?> args;

  /// Null when the call succeeded.
  final ShopError? error;

  const CallRecord(this.endpoint, this.args, this.error);

  bool get ok => error == null;
  int get status => error?.status ?? 200;

  @override
  String toString() =>
      '${endpoint.path}${ok ? '' : ' → $error'}${args.isEmpty ? '' : ' $args'}';
}

/// Every call the fake answered, in the order they finished.
///
/// A screenshot cannot show that opening a list asked once rather than
/// fifteen times, or that a refused save never reached the shop; this can.
/// [onCall] is how the scenario harness files each call on the step it
/// happened in.
class CallLog {
  final _records = <CallRecord>[];

  void Function(CallRecord record)? onCall;

  List<CallRecord> get all => List.unmodifiable(_records);

  /// The calls as `orders.bulkSetStatus`, in order.
  List<String> get paths => [for (final r in _records) r.endpoint.path];

  int countOf(Endpoint endpoint) =>
      _records.where((r) => r.endpoint == endpoint).length;

  /// The calls of [endpoint] that failed.
  int failuresOf(Endpoint endpoint) =>
      _records.where((r) => r.endpoint == endpoint && !r.ok).length;

  void record(CallRecord record) {
    _records.add(record);
    onCall?.call(record);
  }

  void clear() => _records.clear();

  @override
  String toString() => _records.join('\n');
}
