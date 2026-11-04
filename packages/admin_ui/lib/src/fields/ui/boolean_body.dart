import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/checkbox.dart';
import '../../common/ui/control_label.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/focus_ring.dart';
import '../../common/ui/segmented.dart';
import '../../common/ui/toggle.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// How the on/off control renders.
enum BooleanAppearance {
  /// A switch followed by explanatory text. The default.
  toggle,

  /// A compact checkbox followed by explanatory text — for minor flags.
  checkbox,

  /// A pair of pills (on / off) — for a prominent either/or choice.
  segmented,
}

/// The bare on/off control — no label, no capabilities, no focus plumbing. A
/// value and a change callback, nothing more, so the same body can sit inside a
/// [FieldShell] (a real `bool`) or one lane of a translatable field (one entry
/// of a `Translated<bool>`).
///
/// A null [onChanged] renders the control read-only: the switch or box and
/// its text at full contrast, a Tab stop announced read-only with its state,
/// no hover, and nothing toggles (see [FieldState]). [enabled] false, or a
/// disabled [FieldStateScope], disables it.
class BooleanBody extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final BooleanAppearance appearance;

  /// The human meaning of the toggle, shown beside the switch/checkbox. Falls
  /// back to [onText]/[offText] when omitted. Unused by
  /// [BooleanAppearance.segmented], whose pills already carry the on/off text.
  final String? description;

  /// On/off text — the inline state word for [BooleanAppearance.toggle] and
  /// [BooleanAppearance.checkbox], the pill captions for
  /// [BooleanAppearance.segmented]. Null reads "On" and "Off" in the app's
  /// language.
  final String? onText;
  final String? offText;

  final bool enabled;

  const BooleanBody({
    super.key,
    required this.value,
    this.onChanged,
    this.appearance = BooleanAppearance.toggle,
    this.description,
    this.onText,
    this.offText,
    this.enabled = true,
  });

  @override
  State<BooleanBody> createState() => _BooleanBodyState();
}

class _BooleanBodyState extends State<BooleanBody> {
  /// Shared by the row and the control drawn in it, so the control shows the
  /// row's hover and keyboard focus.
  final _states = WidgetStatesController();

  /// Whether a read-only row shows the keyboard focus highlight.
  bool _readOnlyFocus = false;

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  String _onText(BuildContext context) =>
      widget.onText ?? context.adminL10n.fields.onLabel;

  String _offText(BuildContext context) =>
      widget.offText ?? context.adminL10n.fields.offLabel;

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: widget.onChanged == null,
      builder: (context) => widget.appearance == BooleanAppearance.segmented
          ? _segmented(context)
          : _boxed(context),
    );
  }

  /// Toggle and checkbox share a bordered row, the control height on one
  /// line: the control at the start, the text after it. The whole row is the
  /// target — one Tab stop announced as the switch or checkbox, named by the
  /// text.
  Widget _boxed(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    final value = widget.value;
    final onChanged = widget.onChanged;
    final checkbox = widget.appearance == BooleanAppearance.checkbox;
    final colors = context.colors;
    final sizes = context.sizes;
    final text =
        widget.description ?? (value ? _onText(context) : _offText(context));
    final style = context.type.fieldText.copyWith(
      color: !state.enabled
          ? colors.foregroundSubtle
          : (value ? colors.foreground : colors.foregroundMuted),
    );
    // Read-only draws the control as it is, at full contrast; only disabled
    // dims it.
    final ValueChanged<bool>? drawn = state.enabled ? (_) {} : null;

    // Drawn only: the row around it takes the pointer, focus and semantics.
    final control = IgnorePointer(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: checkbox
              ? Check(value: value, onChanged: drawn, statesController: _states)
              : Toggle(
                  value: value,
                  onChanged: drawn,
                  statesController: _states,
                ),
        ),
      ),
    );

    final line = style.fontSize! * (style.height ?? 1);
    final radius = context.radii.radiusField;
    final rest = context.stroke.control;
    // One line centred in the control height, inside a control-wide edge.
    final vertical = math.max(0.0, (sizes.medium - 2 * rest - line) / 2);
    Widget box({bool hovered = false}) => FieldChrome(
      hovered: hovered,
      padding: EdgeInsets.symmetric(
        horizontal: sizes.fieldPaddingX - rest,
        vertical: vertical,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          onFirstLine(context, control, text, style),
          const Gap(AdminSpacing.md),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );

    if (state.readOnly && state.enabled) {
      // One node: the focus flags of the detector merge into it.
      return Semantics(
        container: true,
        readOnly: true,
        checked: checkbox ? value : null,
        toggled: checkbox ? null : value,
        label: text,
        child: FocusableActionDetector(
          onShowFocusHighlight: (shown) {
            if (shown != _readOnlyFocus) {
              setState(() => _readOnlyFocus = shown);
            }
          },
          child: ExcludeSemantics(
            child: FocusRing(
              focused: _readOnlyFocus,
              radius: radius,
              child: box(),
            ),
          ),
        ),
      );
    }

    return Tappable.states(
      onTap: editable ? () => onChanged!(!value) : null,
      checked: checkbox ? value : null,
      toggled: checkbox ? null : value,
      statesController: _states,
      showFocusRing: false,
      builder: (context, states) =>
          box(hovered: states.contains(WidgetState.hovered)),
    );
  }

  Widget _segmented(BuildContext context) {
    final state = FieldStateScope.of(context);
    final colors = context.colors;
    final onText = _onText(context);
    final offText = _offText(context);
    final segments = [
      SegmentOption(true, onText),
      SegmentOption(false, offText),
    ];
    final pills = Segmented<bool>(
      value: widget.value,
      onChanged: state.enabled ? widget.onChanged : null,
      readOnly: state.readOnly && state.enabled,
      segments: segments,
    );
    final description = widget.description;
    if (description == null) return pills;
    return Row(
      children: [
        pills,
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Text(
            description,
            style: context.type.fieldText.copyWith(
              color: state.enabled
                  ? colors.foregroundMuted
                  : colors.foregroundSubtle,
            ),
          ),
        ),
      ],
    );
  }
}
