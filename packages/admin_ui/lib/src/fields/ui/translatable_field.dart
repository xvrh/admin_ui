import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../i18n/locale_status.dart';
import 'field_shell.dart';
import 'lane_stack.dart';
import 'language_pill.dart';

/// A translatable field — the convenience preset over the one field chrome. It's
/// a thin composition: a [FieldShell] whose label row carries the [LanguagePill]
/// (and field-level capabilities) over a headerless [LaneStack] body. One locale
/// in view edits alone; check more in the pill and the lanes stack.
///
/// With no [laneBuilder] the lanes are the built-in text input, driven by
/// [values]/[onChanged]; supply [laneBuilder] to host any other body per lane
/// (a boolean, a select…) — making the field a `Translated<T>` editor.
class TranslatableField extends StatefulWidget {
  final String label;

  /// Every locale the picker offers.
  final List<LocaleInfo> locales;

  /// Locale codes currently in view (at least one).
  final Set<String> visibleLocales;

  /// The code of the locale the others translate from, its lane first.
  final String sourceLocale;

  /// The code of the locale being edited.
  final String activeLocale;

  /// Current text per locale code (built-in text path).
  final Map<String, String> values;

  /// Locale codes whose draft differs from the baseline.
  final Set<String> modifiedLanes;

  /// Show the per-lane translation status pill. Off where status is meaningless.
  final bool showLaneStatus;

  /// Line bounds for the built-in text input (ignored when [laneBuilder] is set).
  final int? minLines;
  final int? maxLines;

  /// Reports a new set of locales in view, picked in the language pill.
  final ValueChanged<Set<String>> onVisibleLocalesChanged;

  /// Reports the locale whose lane took focus.
  final ValueChanged<String>? onActiveLocaleChanged;

  final void Function(String code, String value)? onChanged;

  /// Field-level capabilities (help, field-level comments) shown by the label.
  final Widget? headerTrailing;

  /// Per-locale capability cluster for a lane (its comments, history).
  final Widget? Function(LocaleInfo lane)? laneTrailing;

  /// The control for one lane; null = built-in text input.
  final Widget Function(LocaleInfo lane)? laneBuilder;

  /// The re-translate action of an outdated lane; see
  /// [LaneStack.retranslate].
  final VoidCallback? Function(LocaleInfo lane)? retranslate;

  /// Field-level validation line under the lanes ([FieldShell.errorText]).
  final String? errorText;
  final String? warning;

  const TranslatableField({
    super.key,
    required this.label,
    required this.locales,
    required this.visibleLocales,
    required this.sourceLocale,
    required this.activeLocale,
    required this.values,
    required this.onVisibleLocalesChanged,
    this.onActiveLocaleChanged,
    this.onChanged,
    this.modifiedLanes = const {},
    this.showLaneStatus = true,
    this.minLines,
    this.maxLines,
    this.headerTrailing,
    this.laneTrailing,
    this.laneBuilder,
    this.retranslate,
    this.errorText,
    this.warning,
  });

  @override
  State<TranslatableField> createState() => _TranslatableFieldState();
}

class _TranslatableFieldState extends State<TranslatableField> {
  final Map<String, TextEditingController> _controllers = {};

  bool get _builtIn => widget.laneBuilder == null;

  @override
  void initState() {
    super.initState();
    if (!_builtIn) return;
    for (final lane in _lanes) {
      _addController(lane.code);
    }
  }

  @override
  void didUpdateWidget(covariant TranslatableField old) {
    super.didUpdateWidget(old);
    if (!_builtIn) return;
    final codes = {for (final l in _lanes) l.code};
    for (final code in codes) {
      if (!_controllers.containsKey(code)) {
        _addController(code);
      } else {
        // Reseed when the value changed outside the field (e.g. a revert);
        // ordinary typing keeps controller and value in sync, so this no-ops.
        final value = widget.values[code] ?? '';
        if (value != _controllers[code]!.text) _controllers[code]!.text = value;
      }
    }
    for (final code in _controllers.keys.toList()) {
      if (!codes.contains(code)) _controllers.remove(code)!.dispose();
    }
  }

  void _addController(String code) {
    final controller = TextEditingController(text: widget.values[code] ?? '');
    controller.addListener(() => widget.onChanged?.call(code, controller.text));
    _controllers[code] = controller;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Visible locales in display order — source first, then declared order.
  List<LocaleInfo> get _lanes {
    final byCode = {for (final l in widget.locales) l.code: l};
    return [
      if (widget.visibleLocales.contains(widget.sourceLocale) &&
          byCode.containsKey(widget.sourceLocale))
        byCode[widget.sourceLocale]!,
      for (final l in widget.locales)
        if (l.code != widget.sourceLocale &&
            widget.visibleLocales.contains(l.code))
          l,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      help: widget.headerTrailing,
      errorText: widget.errorText,
      warning: widget.warning,
      modified: widget.modifiedLanes.isNotEmpty,
      modifiedDetail: modifiedLocalesDetail(
        widget.locales,
        widget.modifiedLanes,
      ),
      language: LanguagePill(
        value: widget.visibleLocales,
        activeLocale: widget.activeLocale,
        locales: widget.locales,
        sourceLocale: widget.sourceLocale,
        onChanged: widget.onVisibleLocalesChanged,
      ),
      child: LaneStack(
        lanes: _lanes,
        activeLocale: widget.activeLocale,
        showLaneStatus: widget.showLaneStatus,
        modifiedLanes: widget.modifiedLanes,
        onActiveLocaleChanged: widget.onActiveLocaleChanged,
        laneTrailing: widget.laneTrailing,
        retranslate: widget.retranslate,
        laneBuilder: widget.laneBuilder ?? _builtInLane,
      ),
    );
  }

  Widget _builtInLane(LocaleInfo lane) {
    return TextField(
      controller: _controllers[lane.code],
      minLines: widget.minLines,
      maxLines: widget.maxLines ?? 1,
      readOnly: FieldStateScope.of(context).readOnly,
      style: fieldTextStyle(context),
      decoration: fieldInputDecoration(context),
    );
  }
}
