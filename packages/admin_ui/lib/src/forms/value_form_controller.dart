/// @docImport 'form_shortcuts.dart';
/// @docImport 'value_fields.dart';
/// @docImport 'value_form.dart';
library;

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:collection/collection.dart' show DeepCollectionEquality;
import 'package:flutter/foundation.dart';

import '../assets/ui/image_cropper.dart' show CropValue;
import '../l10n/admin_ui_localizations.dart';
import 'cell.dart';
import 'form_controller.dart';
import 'validation.dart';

/// A [FormController] over plain values: a dialog, a settings page, a record
/// loaded over RPC and saved back whole. It hands out the cells the fields
/// bind to, knows which differ from the value the form started from, checks
/// them against declared rules, and submits the value.
///
/// `read` builds a `T` from the cells and `write` sets the cells from one,
/// both through typed handles over [scope] — the controller's own
/// [LocalScope] unless one is given. The controller tracks every cell it
/// hands out, whatever backs it, so nothing is registered by hand:
///
/// ```dart
/// final form = ValueFormController<Contact>(
///   read: (s) => ContactFields(s).toDto(),
///   write: (s, dto) => ContactFields(s).fill(dto),
///   rules: (s) => [
///     FieldRules(ContactFields(s).name, validators: [Validators.required()]),
///   ],
///   onSubmit: api.save,
/// );
/// ```
///
/// **Dirty.** The form is dirty while any cell differs from the baseline:
/// the value it was [seed]ed with (or `initial`, or the cells as they were),
/// rebased on each successful [submit]. Rows of a record list count by
/// position, so rows removed and added back with the same values, as a
/// [reset] through `write` does, are clean. A cell first read after seeding
/// joins the baseline as it is then.
///
/// **Validation.** `rules` is asked again whenever a record list changes
/// shape, so per-row rules follow the rows. Each field's message is in
/// [allErrors]; [errors], which the fields and the save bar show, holds the
/// ones [mode] reveals, and every one after a submit attempt. Messages are
/// worded in [localizations], which a [ValueForm] sets from the app.
///
/// **Submit.** [submit] reveals every message and, when all pass, awaits any
/// async check still running, then calls `onSubmit` with [value]. A
/// [FormSubmitException] it throws puts its messages under their fields and
/// in [submitError]; anything else reads as the generic failure, and is
/// reported to [FlutterError.onError].
///
/// Notifies only when something a listener can see changes: the status, the
/// dirty flag, the shown errors, the pending checks, which fields have rules
/// or are hidden or required, or a [revealRequest].
class ValueFormController<T> extends FormController {
  ValueFormController({
    FormScope? scope,
    required this._read,
    required this._write,
    T? initial,
    this._onSubmit,
    this._rules,
    this.mode = ValidationMode.onEdit,
    this.requireChanges = true,
  }) : _owned = scope == null ? LocalScope() : null {
    _tracker = _Tracker(_onValue, _onStructure);
    _scope = _TrackedScope(scope ?? _owned!, _tracker.root, '', _tracker);
    if (initial != null) {
      _writing(() => _write(_scope, initial));
      _base = initial;
    } else {
      _base = _read(_scope);
    }
    _rebase();
    _validateAll();
    _notified = _observe();
  }

  /// When each field's message shows.
  final ValidationMode mode;

  /// Whether submitting needs an edit first. False for a form whose starting
  /// value is itself worth submitting, as a create dialog's defaults.
  final bool requireChanges;

  /// Builds the value from the cells, through typed handles over the scope.
  final T Function(FormScope scope) _read;

  /// Sets the cells from a value.
  final void Function(FormScope scope, T value) _write;

  /// Persists a submitted value; see [FormSubmitException].
  final Future<void> Function(T value)? _onSubmit;

  /// The validation rules, built over the scope.
  final Iterable<ValidationRule> Function(FormScope scope)? _rules;
  final LocalScope? _owned;
  late final _Tracker _tracker;
  late final _TrackedScope _scope;
  late T _base;

  /// The baseline, by index path (`phones[0].label`, `phones[]` for a
  /// list's length).
  Map<String, Object?> _baseline = {};
  int _writeDepth = 0;
  bool _disposed = false;

  FormStatus _status = FormStatus.clean;
  bool _dirty = false;
  String? _submitError;
  bool _submitAttempted = false;
  int _revealRequest = 0;
  Future<void>? _submitting;

  final _states = <String, _FieldState>{};
  final _ruleListeners = <(Listenable, VoidCallback)>[];
  final _touched = <String>{};
  final _validated = <String>{};
  final _serverErrors = <String, String>{};

  Map<String, String> _allErrors = const {};
  Map<String, String> _shown = const {};
  Set<String> _pending = const {};
  Set<String> _hidden = const {};
  Set<String> _required = const {};
  Set<String> _ruleFields = const {};
  late _Observed _notified;

  AdminLocalizations _l10n = AdminLocalizations.lookup(const Locale('en'));

  /// The scope the fields' typed handles are built over. Every cell it hands
  /// out is tracked; its `dispose` does nothing, as the controller (or
  /// whoever gave it the scope) owns the cells.
  FormScope get scope => _scope;

  /// The form's current value, read from the cells.
  T get value => _read(_scope);

  /// Writes [value] into the cells and makes it the baseline: the form is
  /// clean, nothing is revealed, and earlier server errors are gone.
  void seed(T value) {
    _cancelChecks();
    _writing(() => _write(_scope, value));
    _base = value;
    _rebase();
    _status = FormStatus.clean;
    _submitError = null;
    _validateAll();
    _notifyIfChanged();
  }

  @override
  FormStatus get status => _status;

  /// Whether any cell differs from the baseline, submitting or not.
  bool get isDirty => _dirty;

  /// Whether [submit] ran since the last seed, reset or successful submit;
  /// every message shows until then.
  bool get submitAttempted => _submitAttempted;

  /// The messages shown: each field's that [mode] reveals, and every one
  /// after a submit attempt, in the order of the rules. The fields and the
  /// save bar read these.
  @override
  Map<String, String> get errors => _shown;

  /// Every field's message, shown or not, in the order of the rules.
  Map<String, String> get allErrors => _allErrors;

  /// The fields whose async checks are waiting out their debounce or
  /// running. A pending field carries no async message yet.
  Set<String> get pendingFields => _pending;

  /// Whether any async check is pending.
  bool get isValidating => _pending.isNotEmpty;

  /// The fields the rules are filed under, hidden or not: those that can
  /// have a message before a server gives one.
  Set<String> get ruleFields => _ruleFields;

  /// The fields a rule's `visibleWhen` hides.
  Set<String> get hiddenFields => _hidden;

  /// The visible fields whose rules hold a [Validators.required].
  Set<String> get requiredFields => _required;

  /// False while a rule's `visibleWhen` hides [id].
  bool isVisible(String id) => !_hidden.contains(id);

  /// Whether [id] is visible and its rules hold a [Validators.required].
  bool isRequired(String id) => _required.contains(id);

  /// The first field with a message, shown or not, in the order of the
  /// rules; null when every field passes.
  String? get firstInvalidField => _allErrors.keys.firstOrNull;

  /// Goes up each time a submit is refused for invalid fields: a [ValueForm]
  /// then takes focus to the first one shown.
  int get revealRequest => _revealRequest;

  @override
  String? get submitError => _submitError;

  /// The strings the built-in messages are worded in; English until a
  /// [ValueForm] sets the app's. Setting it asks `rules` again, so a
  /// message the app words itself (a `ListRules.message`) follows the
  /// language too, rewords [errors] at once, and notifies in a microtask:
  /// the [ValueForm] sets it as it builds, when a save bar beside it cannot
  /// be marked to rebuild.
  AdminLocalizations get localizations => _l10n;
  set localizations(AdminLocalizations value) {
    if (identical(value, _l10n)) return;
    _l10n = value;
    if (_disposed) return;
    _rebuildRules();
    _validateAll();
    scheduleMicrotask(_notifyIfChanged);
  }

  /// A clean form submits only when [requireChanges] is off; a form showing
  /// messages does not submit until they are fixed.
  @override
  bool get canSubmit =>
      _status != FormStatus.submitting &&
      _shown.isEmpty &&
      (!requireChanges || _dirty || _status == FormStatus.error);

  /// Server-side messages, keyed by field id: each shows under its field
  /// until the field is next edited. A null message clears its field's.
  void setErrors(Map<String, String?> errors) {
    for (final MapEntry(:key, :value) in errors.entries) {
      if (value == null) {
        _serverErrors.remove(key);
      } else {
        _serverErrors[key] = value;
      }
    }
    _validateAll();
    _notifyIfChanged();
  }

  /// Reveals the messages of [fields] (every field when null), runs their
  /// async checks at once and waits for them. True when none of them has a
  /// message. A multi-step form checks a step's fields with it.
  Future<bool> validate({Iterable<String>? fields}) async {
    final ids = fields?.toSet() ?? {..._states.keys, ..._serverErrors.keys};
    _validated.addAll(ids);
    await _settle(ids);
    if (_disposed) return false;
    _notifyIfChanged();
    return !ids.any(_allErrors.containsKey);
  }

  /// Validates and reveals every field, and when they pass, awaits the async
  /// checks still pending (running those waiting out their debounce at once)
  /// and calls `onSubmit` with [value]. A refusal for invalid fields bumps
  /// [revealRequest] and leaves the status as it was. On success the value
  /// submitted becomes the baseline.
  @override
  Future<void> submit() {
    final running = _submitting;
    if (running != null) return running;
    final future = _submit();
    _submitting = future;
    return future.whenComplete(() => _submitting = null);
  }

  Future<void> _submit() async {
    if (_status == FormStatus.submitting) return;
    if (requireChanges && !_dirty && _status != FormStatus.error) return;
    _submitAttempted = true;
    _validateAll();
    if (_allErrors.isEmpty) await _settle(null);
    if (_disposed) return;
    if (_allErrors.isNotEmpty) {
      _revealRequest++;
      _notifyIfChanged();
      return;
    }
    final value = _read(_scope);
    final snapshot = _tracker.snapshot();
    final sent = _Sent(_tracker, _states.values);
    _status = FormStatus.submitting;
    _submitError = null;
    _notifyIfChanged();
    try {
      await _onSubmit?.call(value);
      if (_disposed) return;
      _base = value;
      _baseline = snapshot;
      _settleBaseline(sent);
      _submitAttempted = false;
      _serverErrors.clear();
      _dirty = _diff();
      _status = _dirty ? FormStatus.dirty : FormStatus.submitted;
    } on FormSubmitException catch (e) {
      if (_disposed) return;
      _status = FormStatus.error;
      _submitError = e.message;
      _serverErrors.addAll(e.fieldErrors);
      if (e.fieldErrors.isNotEmpty) _revealRequest++;
    } catch (error, stack) {
      // Read as the generic failure, but a bug in the save is still one.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'admin_ui forms',
          context: ErrorDescription('while submitting a form'),
        ),
      );
      if (_disposed) return;
      _status = FormStatus.error;
    }
    _validateAll();
    _notifyIfChanged();
  }

  /// Writes the baseline back through `write`, restores any other cell that
  /// differs, and returns to clean: nothing revealed, no server errors.
  @override
  void reset() {
    _cancelChecks();
    _writing(() {
      _write(_scope, _base);
      _restore();
    });
    _rebase();
    _status = FormStatus.clean;
    _submitError = null;
    _validateAll();
    _notifyIfChanged();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelChecks();
    _unlistenRules();
    _tracker.dispose();
    _owned?.dispose();
    super.dispose();
  }

  // ── Tracking ────────────────────────────────────────────────────────────

  void _writing(void Function() write) {
    _writeDepth++;
    try {
      write();
    } finally {
      _writeDepth--;
    }
  }

  void _onValue(_Entry entry) {
    if (_writeDepth > 0 || _disposed) return;
    for (final id in entry.owners) {
      if (!_same(entry.last, entry.base)) _touched.add(id);
      _serverErrors.remove(id);
    }
    _refresh(edited: true, changed: entry.cell);
  }

  /// [dropped] are the ids of the removed rows' cells: their server
  /// messages go with them.
  void _onStructure(_ListEntry list, Set<String> dropped) {
    if (_writeDepth > 0 || _disposed) return;
    _serverErrors.remove(list.cell.id);
    dropped.forEach(_serverErrors.remove);
    _touched.removeAll(dropped);
    _rebuildRules();
    _refresh(edited: true);
  }

  /// Whether any tracked cell differs from the baseline; a key the baseline
  /// has not seen joins it.
  bool _diff() {
    var dirty = false;
    _tracker.walk((key, entry, value, first) {
      final Object? base;
      if (_baseline.containsKey(key)) {
        base = _baseline[key];
      } else {
        base = _baseline[key] = first;
      }
      if (!dirty && !_same(base, value)) dirty = true;
    });
    return dirty;
  }

  /// Sets each tracked cell that differs from the baseline back to it.
  void _restore() {
    _tracker.walk((key, entry, value, _) {
      if (entry == null || !_baseline.containsKey(key)) return;
      final base = _baseline[key];
      if (!_same(base, value)) entry.cell.set(base);
    });
  }

  /// Makes the cells as they are the baseline, and forgets what was
  /// revealed, touched or said by the server.
  void _rebase() {
    _rebuildRules();
    _baseline = _tracker.snapshot();
    _settleBaseline();
    _dirty = false;
    _submitAttempted = false;
    _serverErrors.clear();
  }

  /// Makes the values [sent] (or, when null, the cells as they are) what
  /// each edit is compared to and what the async checks take as checked,
  /// and forgets what was revealed or touched. A field edited since [sent]
  /// was taken stays touched, and its check runs for its new values.
  void _settleBaseline([_Sent? sent]) {
    _touched.clear();
    _validated.clear();
    for (final entry in _tracker.entries) {
      if (sent == null) {
        entry.first = entry.base = entry.last;
      } else if (sent.values.containsKey(entry)) {
        entry.first = entry.base = sent.values[entry];
      }
      if (!_same(entry.last, entry.base)) _touched.addAll(entry.owners);
    }
    for (final state in _states.values) {
      state.values = state.read();
      if (sent == null) {
        state.accepted = state.values;
      } else if (sent.checks[state] case final checked?) {
        state.accepted = checked;
      }
      if (!_same(state.values, state.accepted)) continue;
      state
        ..cancel()
        ..checkedFor = null
        ..asyncMessage = null;
    }
  }

  // ── Rules ───────────────────────────────────────────────────────────────

  void _rebuildRules() {
    final rules = _rules?.call(_scope).toList() ?? const <ValidationRule>[];
    final previous = Map.of(_states);
    _states.clear();
    for (final rule in rules) {
      final id = rule.fieldId;
      final state = _states[id] ??= switch (previous.remove(id)) {
        final known? => known..clearRules(),
        null => _FieldState(),
      };
      switch (rule) {
        case FieldRules():
          state.rules.add(rule);
        case ListRules():
          state.listRules.add(rule);
        case FormRule():
          state.formRules.add(rule);
      }
    }
    for (final dropped in previous.values) {
      dropped.cancel();
    }
    _ruleFields = Set.unmodifiable(_states.keys);
    for (final state in _states.values) {
      if (!state.seen) {
        state
          ..seen = true
          ..values = state.read()
          ..accepted = state.values;
      }
    }
    _listenRules(rules);
  }

  void _listenRules(List<ValidationRule> rules) {
    _unlistenRules();
    final seen = Set<Listenable>.identity();
    void listen(Listenable listenable) {
      if (_tracker.cells.contains(listenable) || !seen.add(listenable)) return;
      void changed() => _refresh(changed: listenable);
      listenable.addListener(changed);
      _ruleListeners.add((listenable, changed));
    }

    for (final rule in rules) {
      switch (rule) {
        case FieldRules(:final dependsOn):
          dependsOn.forEach(listen);
        case ListRules(:final cell):
          if (cell case final Listenable listenable) listen(listenable);
        case FormRule(:final watch):
          for (final cell in watch) {
            if (cell case final Listenable listenable) listen(listenable);
          }
      }
    }
  }

  void _unlistenRules() {
    for (final (listenable, listener) in _ruleListeners) {
      listenable.removeListener(listener);
    }
    _ruleListeners.clear();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  void _refresh({bool edited = false, Object? changed}) {
    if (_disposed || _writeDepth > 0) return;
    if (edited) {
      _dirty = _diff();
      if (_status != FormStatus.submitting) {
        _status = _dirty ? FormStatus.dirty : FormStatus.clean;
      }
    }
    _validateAll(changed: changed);
    _notifyIfChanged();
  }

  /// Runs every visible field's rules, schedules the async checks a new
  /// value needs, and runs at once those of [now] (every field's when
  /// [now] is null and [nowAll]).
  void _validateAll({Object? changed, Set<String>? now, bool nowAll = false}) {
    final all = <String, String>{};
    final hidden = <String>{};
    final required = <String>{};
    final pending = <String>{};
    for (final MapEntry(key: id, value: state) in _states.entries) {
      if (!state.visible(changed)) {
        hidden.add(id);
        state.cancel();
        continue;
      }
      if (state.isRequired) required.add(id);
      state.values = state.read();
      if (!_same(state.values, state.accepted)) _touched.add(id);
      final sync = state.validate(_l10n);
      String? async;
      if (sync != null) {
        state.cancel();
      } else {
        async = _checkAsync(
          state,
          immediately: nowAll || (now?.contains(id) ?? false),
        );
      }
      if (state.pending) pending.add(id);
      if (sync ?? _serverErrors[id] ?? async case final message?) {
        all[id] = message;
      }
    }
    for (final MapEntry(key: id, value: message) in _serverErrors.entries) {
      if (!hidden.contains(id)) all.putIfAbsent(id, () => message);
    }
    _allErrors = Map.unmodifiable(all);
    _shown = Map.unmodifiable({
      for (final MapEntry(key: id, value: message) in all.entries)
        if (_revealed(id)) id: message,
    });
    _hidden = Set.unmodifiable(hidden);
    _required = Set.unmodifiable(required);
    _pending = Set.unmodifiable(pending);
  }

  bool _revealed(String id) =>
      _serverErrors.containsKey(id) ||
      switch (mode) {
        ValidationMode.always => true,
        ValidationMode.onSubmit => _submitAttempted || _validated.contains(id),
        ValidationMode.onEdit =>
          _submitAttempted || _validated.contains(id) || _touched.contains(id),
      };

  /// The async message of [state]'s current values: none while a check is
  /// pending, and a new check scheduled when they changed. A value the form
  /// was seeded with, or last submitted, is taken as checked.
  String? _checkAsync(_FieldState state, {bool immediately = false}) {
    if (!state.hasAsync) return null;
    final values = state.values;
    if (_same(values, state.accepted)) {
      state.cancel();
      return null;
    }
    if (!_same(values, state.checkedFor)) {
      _schedule(state, values, immediately: immediately);
      return null;
    }
    if (state.pending) {
      if (immediately) state.fire?.call();
      return null;
    }
    return state.asyncMessage;
  }

  void _schedule(
    _FieldState state,
    List<Object?> values, {
    required bool immediately,
  }) {
    state.timer?.cancel();
    final serial = ++state.serial;
    final rules = List.of(state.rules);
    state
      ..checkedFor = values
      ..asyncMessage = null
      ..pending = true
      ..settled ??= Completer<void>();
    void fire() {
      state
        ..timer?.cancel()
        ..timer = null
        ..fire = null;
      unawaited(_runChecks(state, serial, rules, values));
    }

    state.fire = fire;
    final debounce = state.debounce;
    if (immediately || debounce == Duration.zero) {
      fire();
    } else {
      state.timer = Timer(debounce, fire);
    }
  }

  Future<void> _runChecks(
    _FieldState state,
    int serial,
    List<FieldRules> rules,
    List<Object?> values,
  ) async {
    String? message;
    for (final (i, rule) in rules.indexed) {
      if (!rule.hasAsync) continue;
      message = await rule.validateAsync(values[i]! as List);
      if (_disposed || serial != state.serial) return;
      if (message != null) break;
    }
    if (_disposed || serial != state.serial) return;
    state
      ..asyncMessage = message
      ..pending = false
      ..settle();
    _validateAll();
    _notifyIfChanged();
  }

  /// Runs the pending and stale checks of [ids] (all when null) at once and
  /// waits until none is pending, then validates again.
  Future<void> _settle(Set<String>? ids) async {
    while (!_disposed) {
      _validateAll(now: ids, nowAll: ids == null);
      final waits = [
        for (final MapEntry(key: id, value: state) in _states.entries)
          if (state.pending && (ids == null || ids.contains(id)))
            state.settled!.future,
      ];
      if (waits.isEmpty) return;
      _notifyIfChanged();
      await Future.wait(waits);
    }
  }

  void _cancelChecks() {
    for (final state in _states.values) {
      state.cancel();
    }
  }

  // ── Notification ────────────────────────────────────────────────────────

  _Observed _observe() => _Observed(
    status: _status,
    dirty: _dirty,
    errors: _shown,
    pending: _pending,
    hidden: _hidden,
    required: _required,
    ruleFields: _ruleFields,
    submitError: _submitError,
    revealRequest: _revealRequest,
    submitAttempted: _submitAttempted,
  );

  void _notifyIfChanged() {
    if (_disposed) return;
    final now = _observe();
    if (now.same(_notified)) return;
    _notified = now;
    notifyListeners();
  }
}

const _deep = DeepCollectionEquality();
bool _same(Object? a, Object? b) => _deep.equals(a, b);

/// What a listener of a [ValueFormController] can see, as last notified.
class _Observed {
  final FormStatus status;
  final bool dirty;
  final Map<String, String> errors;
  final Set<String> pending;
  final Set<String> hidden;
  final Set<String> required;
  final Set<String> ruleFields;
  final String? submitError;
  final int revealRequest;
  final bool submitAttempted;

  const _Observed({
    required this.status,
    required this.dirty,
    required this.errors,
    required this.pending,
    required this.hidden,
    required this.required,
    required this.ruleFields,
    required this.submitError,
    required this.revealRequest,
    required this.submitAttempted,
  });

  bool same(_Observed o) =>
      status == o.status &&
      dirty == o.dirty &&
      submitError == o.submitError &&
      revealRequest == o.revealRequest &&
      submitAttempted == o.submitAttempted &&
      mapEquals(errors, o.errors) &&
      setEquals(pending, o.pending) &&
      setEquals(hidden, o.hidden) &&
      setEquals(required, o.required) &&
      setEquals(ruleFields, o.ruleFields);
}

/// What a submit sent: each tracked cell's value and each field's rule
/// values as the submit read them.
class _Sent {
  _Sent(_Tracker tracker, Iterable<_FieldState> states)
    : values = Map.identity()
        ..addEntries([
          for (final e in tracker.entries) MapEntry(e, e.cell.value),
        ]),
      checks = Map.identity()
        ..addEntries([for (final s in states) MapEntry(s, s.read())]);

  final Map<_Entry, Object?> values;
  final Map<_FieldState, List<Object?>> checks;
}

/// One field id's rules and the state of its async checks.
class _FieldState {
  final rules = <FieldRules>[];
  final listRules = <ListRules>[];
  final formRules = <FormRule>[];

  /// The last answer of each rule's `visibleWhen`, for the rules asked only
  /// when one of their `dependsOn` notifies.
  final _visibility = Map<FieldRules, bool>.identity();

  /// Whether the rules were read once, which fixes [accepted].
  bool seen = false;

  /// Each field rule's values, then each list rule's count, as last read.
  List<Object?> values = const [];

  /// The values the form was seeded with or last submitted: checked, as far
  /// as the async checks go.
  Object? accepted;

  /// The values the pending or last async check is about.
  Object? checkedFor;
  String? asyncMessage;
  bool pending = false;
  int serial = 0;
  Timer? timer;
  VoidCallback? fire;
  Completer<void>? settled;

  bool get hasAsync => rules.any((r) => r.hasAsync);

  bool get isRequired =>
      rules.any((r) => r.isRequired) || listRules.any((r) => r.isRequired);

  Duration get debounce => rules.firstWhere((r) => r.hasAsync).debounce;

  List<Object?> read() => [
    for (final rule in rules) rule.readValues(),
    for (final rule in listRules) rule.count(),
  ];

  void clearRules() {
    rules.clear();
    listRules.clear();
    formRules.clear();
    _visibility.clear();
  }

  /// Whether every rule's `visibleWhen` holds. A rule with `dependsOn` is
  /// asked again only when [changed] is one of them.
  bool visible(Object? changed) {
    var visible = true;
    for (final rule in rules) {
      final when = rule.visibleWhen;
      if (when == null) continue;
      final ask =
          rule.dependsOn.isEmpty ||
          !_visibility.containsKey(rule) ||
          (changed != null && rule.dependsOn.contains(changed));
      final shown = ask ? (_visibility[rule] = when()) : _visibility[rule]!;
      visible = visible && shown;
    }
    return visible;
  }

  String? validate(AdminLocalizations l10n) {
    for (final (i, rule) in rules.indexed) {
      if (rule.validate(values[i]! as List, l10n) case final message?) {
        return message;
      }
    }
    for (final (i, rule) in listRules.indexed) {
      final count = values[rules.length + i]! as int;
      if (rule.check(count, l10n) case final message?) return message;
    }
    for (final rule in formRules) {
      if (rule.check(l10n) case final message?) return message;
    }
    return null;
  }

  /// Drops the check in flight or waiting, if any; its answer will not
  /// count.
  void cancel() {
    timer?.cancel();
    timer = null;
    fire = null;
    serial++;
    if (pending) {
      pending = false;
      checkedFor = null;
    }
    settle();
  }

  void settle() {
    settled?.complete();
    settled = null;
  }
}

// ── The tracked scope ──────────────────────────────────────────────────────

/// The cells handed out under one scope, record element or sub-scope, keyed
/// by their path within it.
class _Node {
  final values = <String, _Entry>{};
  final lists = <String, _ListEntry>{};
  final translated = <String, Object>{};
  final assetRefs = <String, AssetRefCell>{};
}

/// A tracked value cell. [owners] are the field ids an edit of it touches:
/// its own, a translated field's for a lane, an asset reference's for a
/// part.
class _Entry {
  _Entry(this.cell, this.owners)
    : first = cell.value,
      base = cell.value,
      last = cell.value;

  final ValueCell<Object?> cell;
  final List<String> owners;

  /// The value when first handed out, which the baseline takes for a key it
  /// has not seen.
  Object? first;

  /// The value at the last rebase, which an edit is compared to.
  Object? base;

  /// The value as last seen, so a notification that changed nothing (a
  /// caret moving in a text lane) is ignored.
  Object? last;

  late final VoidCallback listener;
}

/// A tracked record list and the nodes of its elements, by element id.
class _ListEntry {
  late final RecordListCell<Object?> cell;
  late final VoidCallback listener;

  /// The length when first handed out, which the baseline takes for a list
  /// it has not seen.
  int? first;

  final elements = <String, _Node>{};
  List<String>? _collecting;

  _Node nodeFor(String id) => elements.putIfAbsent(id, _Node.new);

  void collect(String id) => _collecting?.add(id);

  /// The element ids in order, read through the tracked `build`; a slot is
  /// null when the list was built elsewhere and its ids cannot be read.
  List<String?> orderedIds() {
    final ids = <String>[];
    _collecting = ids;
    final int length;
    try {
      length = cell.elements.length;
    } finally {
      _collecting = null;
    }
    return ids.length == length ? ids : List.filled(length, null);
  }
}

/// Visits one tracked value, or a list's length (with no [entry]), under
/// its index path, with the value it had when first handed out.
typedef _Visit = void Function(
  String key,
  _Entry? entry,
  Object? value,
  Object? first,
);

class _Tracker {
  _Tracker(this._onValue, this._onStructure);

  final void Function(_Entry) _onValue;
  final void Function(_ListEntry, Set<String> dropped) _onStructure;
  final root = _Node();
  final entries = <_Entry>[];
  final lists = <_ListEntry>[];

  /// Every cell and list tracked, by identity.
  final cells = Set<Object>.identity();

  ValueCell<X> value<X>(
    _Node node,
    String key,
    ValueCell<X> cell,
    List<String> owners,
  ) {
    final known = node.values[key];
    if (known != null && identical(known.cell, cell)) return cell;
    if (known != null) _drop(known);
    final entry = _Entry(cell, owners);
    entry.listener = () {
      final value = entry.cell.value;
      if (_same(value, entry.last)) return;
      entry.last = value;
      _onValue(entry);
    };
    cell.addListener(entry.listener);
    node.values[key] = entry;
    entries.add(entry);
    cells.add(cell);
    return cell;
  }

  TranslatedCell<X> translated<X>(
    _Node node,
    String key,
    TranslatedCell<X> cell, [
    List<String> owners = const [],
  ]) {
    if (node.translated[key] case final _TrackedTranslatedCell<X> known
        when identical(known.inner, cell)) {
      return known;
    }
    final tracked = _TrackedTranslatedCell<X>(
      cell,
      (lang, lane) => value(node, '$key/$lang', lane, [cell.id, ...owners]),
    );
    node.translated[key] = tracked;
    return tracked;
  }

  AssetRefCell assetRef(_Node node, String key, AssetRefCell cell) {
    if (node.assetRefs[key] case final _TrackedAssetRef known
        when identical(known.inner, cell)) {
      return known;
    }
    return node.assetRefs[key] = _TrackedAssetRef(
      cell,
      assetId: value(node, '$key.assetId', cell.assetId, [
        cell.assetId.id,
        cell.id,
      ]),
      crop: value(node, '$key.crop', cell.crop, [cell.crop.id, cell.id]),
      alt: translated(node, '$key.alt', cell.alt, [cell.id]),
    );
  }

  RecordListCell<H> recordList<H>(
    _Node node,
    String key,
    RecordListCell<H> Function(H Function(RecordScope) build) create,
    H Function(RecordScope) build,
  ) {
    if (node.lists[key] case final known?) {
      return known.cell as RecordListCell<H>;
    }
    final entry = _ListEntry();
    final cell = create((element) {
      entry.collect(element.id);
      return build(_TrackedRecordScope(element, entry, this));
    });
    entry
      ..cell = cell
      ..listener = (() => _onStructure(entry, _prune(entry)))
      ..first = entry.orderedIds().length;
    cell.addListener(entry.listener);
    node.lists[key] = entry;
    lists.add(entry);
    cells.add(cell);
    return cell;
  }

  /// Stops tracking the rows [list] no longer has, and returns the ids of
  /// their cells: a removed row's cells may live on in their scope, but no
  /// longer belong to the form.
  Set<String> _prune(_ListEntry list) {
    final ids = list.orderedIds().toSet();
    final dropped = <String>{};
    if (ids.contains(null)) return dropped;
    list.elements.removeWhere((id, node) {
      if (ids.contains(id)) return false;
      _dropNode(node, dropped);
      return true;
    });
    return dropped;
  }

  void _dropNode(_Node node, Set<String> dropped) {
    for (final entry in node.values.values) {
      _drop(entry);
      dropped.addAll(entry.owners);
    }
    for (final list in node.lists.values) {
      list.cell.removeListener(list.listener);
      lists.remove(list);
      cells.remove(list.cell);
      dropped.add(list.cell.id);
      for (final element in list.elements.values) {
        _dropNode(element, dropped);
      }
    }
  }

  void _drop(_Entry entry) {
    entry.cell.removeListener(entry.listener);
    entries.remove(entry);
    cells.remove(entry.cell);
  }

  /// Visits every tracked value by index path, and each list's length under
  /// `<path>[]`, with the entry of a value.
  void walk(_Visit visit) => _walk(root, '', visit);

  void _walk(_Node node, String prefix, _Visit visit) {
    for (final MapEntry(:key, value: entry) in node.values.entries) {
      visit('$prefix$key', entry, entry.cell.value, entry.first);
    }
    for (final MapEntry(:key, value: list) in node.lists.entries) {
      final ids = list.orderedIds();
      visit('$prefix$key[]', null, ids.length, list.first ?? ids.length);
      for (final (i, id) in ids.indexed) {
        if (list.elements[id] case final element?) {
          _walk(element, '$prefix$key[$i].', visit);
        }
      }
    }
  }

  Map<String, Object?> snapshot() {
    final out = <String, Object?>{};
    walk((key, _, value, _) => out[key] = value);
    return out;
  }

  void dispose() {
    for (final entry in entries) {
      entry.cell.removeListener(entry.listener);
    }
    for (final list in lists) {
      list.cell.removeListener(list.listener);
    }
  }
}

/// A [FormScope] that hands out its inner scope's cells and tracks each.
class _TrackedScope implements FormScope {
  _TrackedScope(this._inner, this._fixedNode, this._prefix, this._tracker);

  final FormScope _inner;
  final _Node? _fixedNode;
  final String _prefix;
  final _Tracker _tracker;

  /// Where the cells handed out are tracked.
  _Node get _node => _fixedNode!;

  ValueCell<X> _value<X>(String field, ValueCell<X> cell) =>
      _tracker.value(_node, '$_prefix$field', cell, [cell.id]);

  @override
  TranslatedCell<String> translated(String field) =>
      _tracker.translated(_node, '$_prefix$field', _inner.translated(field));
  @override
  ValueCell<int> number(String field) => _value(field, _inner.number(field));
  @override
  ValueCell<int?> numberOrNull(String field) =>
      _value(field, _inner.numberOrNull(field));
  @override
  ValueCell<String> text(String field) => _value(field, _inner.text(field));
  @override
  ValueCell<String?> textOrNull(String field) =>
      _value(field, _inner.textOrNull(field));
  @override
  ValueCell<bool> boolean(String field) => _value(field, _inner.boolean(field));
  @override
  ValueCell<bool?> booleanOrNull(String field) =>
      _value(field, _inner.booleanOrNull(field));
  @override
  ValueCell<double> decimal(String field) =>
      _value(field, _inner.decimal(field));
  @override
  ValueCell<double?> decimalOrNull(String field) =>
      _value(field, _inner.decimalOrNull(field));
  @override
  ValueCell<DateTime> date(String field) => _value(field, _inner.date(field));
  @override
  ValueCell<DateTime?> dateOrNull(String field) =>
      _value(field, _inner.dateOrNull(field));
  @override
  ValueCell<E> enumCell<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
    required E fallback,
  }) => _value(
    field,
    _inner.enumCell(field, encode: encode, decode: decode, fallback: fallback),
  );
  @override
  ValueCell<E?> enumCellOrNull<E>(
    String field, {
    required String Function(E) encode,
    required E Function(String) decode,
  }) => _value(
    field,
    _inner.enumCellOrNull(field, encode: encode, decode: decode),
  );
  @override
  ValueCell<List<String>> list(String field) =>
      _value(field, _inner.list(field));
  @override
  ValueCell<Map<String, String>> map(String field) =>
      _value(field, _inner.map(field));
  @override
  AssetRefCell assetRef(String field) =>
      _tracker.assetRef(_node, '$_prefix$field', _inner.assetRef(field));
  @override
  RecordListCell<H> recordList<H>(
    String field, {
    required H Function(RecordScope) build,
  }) => _tracker.recordList<H>(
    _node,
    '$_prefix$field',
    (tracked) => _inner.recordList<H>(field, build: tracked),
    build,
  );
  @override
  FormScope sub(String prefix) =>
      _TrackedScope(_inner.sub(prefix), _node, '$_prefix$prefix.', _tracker);

  /// The cells belong to whoever owns the inner scope.
  @override
  void dispose() {}
}

/// One tracked record element: its cells are keyed by position when the
/// baseline is compared, so they live on a node of their own, looked up as
/// each is handed out: a handle kept past its row's removal tracks its
/// cells again if the row comes back.
class _TrackedRecordScope extends _TrackedScope implements RecordScope {
  _TrackedRecordScope(RecordScope element, this._list, _Tracker tracker)
    : _element = element,
      super(element, null, '', tracker);

  final RecordScope _element;
  final _ListEntry _list;

  @override
  _Node get _node => _list.nodeFor(_element.id);

  @override
  String get id => _element.id;

  @override
  void remove() => _element.remove();
}

/// A translated cell whose lanes are tracked as they are handed out.
class _TrackedTranslatedCell<V> extends TranslatedCell<V> {
  _TrackedTranslatedCell(this.inner, this._onLane);

  final TranslatedCell<V> inner;
  final ValueCell<V> Function(String lang, ValueCell<V> lane) _onLane;

  @override
  String get id => inner.id;

  @override
  ValueCell<V> lane(String lang) => _onLane(lang, inner.lane(lang));
}

/// An asset reference whose parts are tracked, each an edit of the
/// reference too.
class _TrackedAssetRef implements AssetRefCell {
  _TrackedAssetRef(
    this.inner, {
    required this.assetId,
    required this.alt,
    required this.crop,
  });

  final AssetRefCell inner;

  @override
  String get id => inner.id;
  @override
  final ValueCell<String?> assetId;
  @override
  final TranslatedCell<String> alt;
  @override
  final ValueCell<CropValue?> crop;
}
