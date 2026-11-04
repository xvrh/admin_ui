import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/choice.dart';
import '../../common/ui/labeled_field.dart';
import '../../common/ui/segmented.dart';
import '../../common/ui/swatch_row.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/appearance.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/table_metrics.dart';
import '../../theme/themes.dart';
import '../../theme/tokens.dart';

/// Edits an [AdminAppearance]: the theme, light, dark or the device's mode,
/// a brand accent, and the table density, each a labelled row that applies
/// as it is picked, by handing [onChanged] a copy of [value].
///
/// - **Theme**: a radio list of [themes] ([adminThemes] when null), by name.
///   A theme's name is a name, the same in every language.
/// - **Mode**: Light, Dark and System.
/// - **Accent colour**: a [SwatchRow] led by the theme's own primary, which
///   clears the accent, then [accents]; the picked one's name is written
///   after the row. Each swatch is announced by its name, in the app's
///   language for those of [adminAccents] (see `InputsMessages.accentName`).
/// - **Table density**, unless [showDensity] is false: Compact, Standard
///   and Comfortable.
///
/// The mode and the density are a [Segmented] of [size] while its whole
/// labels fit the picker's width, and a radio list where they would not, so
/// no label is ever cut, in any language.
///
/// Each group is one Tab stop the arrow keys move within, named by its
/// label, except the swatches, which are a Tab stop each. The rows stack
/// [AdminSpacing.xl] apart, a form's field rhythm, and hug their controls
/// from the start edge.
///
/// It holds no state: keep [value] where the app keeps its look, and build
/// the app's themes from it (see [AdminAppearance]). A settings page adds
/// its own rows, such as a language, beside or under it.
class AppearancePicker extends StatelessWidget {
  final AdminAppearance value;

  /// Takes the edited copy of [value]. Null disables the picker.
  final ValueChanged<AdminAppearance>? onChanged;

  /// The themes to choose from; [adminThemes] when null.
  final List<AdminTheme>? themes;

  /// The accents after the theme's own, by name.
  final Map<String, Color> accents;

  /// Whether to show the table density row.
  final bool showDensity;

  /// The height of the mode and density segments.
  final ControlSize size;

  /// False disables the picker and dims its labels.
  final bool enabled;

  const AppearancePicker({
    super.key,
    required this.value,
    this.onChanged,
    this.themes,
    this.accents = adminAccents,
    this.showDensity = true,
    this.size = ControlSize.medium,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n.inputs;
    final change = enabled ? onChanged : null;
    ValueChanged<T>? edit<T>(AdminAppearance Function(T) copy) =>
        change == null ? null : (choice) => change(copy(choice));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: l10n.appearanceTheme,
          enabled: enabled,
          child: Choice<AdminTheme>(
            value: value.theme,
            onChanged: edit((theme) => value.copyWith(theme: theme)),
            options: [
              for (final theme in themes ?? adminThemes)
                ChoiceOption(theme, theme.name),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        LabeledField(
          label: l10n.appearanceMode,
          enabled: enabled,
          child: _SegmentsOrRadios<ThemeMode>(
            value: value.mode,
            size: size,
            onChanged: edit((mode) => value.copyWith(mode: mode)),
            options: [
              (ThemeMode.light, l10n.modeLight, Icons.light_mode_outlined),
              (ThemeMode.dark, l10n.modeDark, Icons.dark_mode_outlined),
              (
                ThemeMode.system,
                l10n.modeSystem,
                Icons.brightness_auto_outlined,
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        LabeledField(
          label: l10n.accentColour,
          enabled: enabled,
          child: _Accents(value: value, accents: accents, onChanged: change),
        ),
        if (showDensity) ...[
          const Gap(AdminSpacing.xl),
          LabeledField(
            label: l10n.tableDensity,
            enabled: enabled,
            child: _SegmentsOrRadios<TableDensity>(
              value: value.density,
              size: size,
              onChanged: edit((density) => value.copyWith(density: density)),
              options: [
                for (final density in TableDensity.values)
                  (density, l10n.densityName(density), null),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The accent swatches, the theme's own primary first, and the picked one's
/// name after them.
class _Accents extends StatelessWidget {
  final AdminAppearance value;
  final Map<String, Color> accents;
  final ValueChanged<AdminAppearance>? onChanged;

  const _Accents({
    required this.value,
    required this.accents,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n.inputs;
    final theme = value.theme;
    final dark =
        value.resolveBrightness(MediaQuery.platformBrightnessOf(context)) ==
        Brightness.dark;
    final own = dark ? theme.darkPalette ?? theme.palette : theme.palette;
    final options = <SwatchOption<Color?>>[
      SwatchOption(null, own.primary, l10n.themeAccent),
      for (final MapEntry(key: name, value: color) in accents.entries)
        SwatchOption(color, color, l10n.accentName(name)),
    ];
    final picked = options.where((o) => o.value == value.accent).firstOrNull;
    final change = onChanged;
    return Row(
      children: [
        SwatchRow<Color?>(
          options: options,
          value: value.accent,
          onChanged: change == null
              ? null
              : (accent) => change(
                  value.copyWith(accent: accent, clearAccent: accent == null),
                ),
        ),
        if (picked != null) ...[
          const Gap(AdminSpacing.md),
          Flexible(
            // The picked swatch says it is selected; this is for the eye.
            child: ExcludeSemantics(
              child: Text(
                picked.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A few options as a [Segmented] when its whole labels fit the width, and
/// as a [Choice] radio list when they would not.
class _SegmentsOrRadios<T> extends StatefulWidget {
  final T value;
  final ValueChanged<T>? onChanged;
  final ControlSize size;
  final List<(T, String, IconData?)> options;

  const _SegmentsOrRadios({
    required this.value,
    required this.onChanged,
    required this.size,
    required this.options,
  });

  @override
  State<_SegmentsOrRadios<T>> createState() => _SegmentsOrRadiosState<T>();
}

class _SegmentsOrRadiosState<T> extends State<_SegmentsOrRadios<T>> {
  /// Which of the two is live: the layout picks one each frame, and the
  /// other leaves the focus order a frame after.
  bool _segments = true;

  void _onFits(bool fits) {
    if (mounted && fits != _segments) setState(() => _segments = fits);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    return _FitOrFallback(
      onFits: _onFits,
      children: [
        ExcludeFocus(
          excluding: !_segments,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Segmented<T>(
              value: widget.value,
              size: widget.size,
              onChanged: widget.onChanged,
              segments: [
                for (final (value, label, icon) in options)
                  SegmentOption(value, label, icon: icon),
              ],
            ),
          ),
        ),
        ExcludeFocus(
          excluding: _segments,
          child: Choice<T>(
            value: widget.value,
            onChanged: widget.onChanged,
            options: [
              for (final (value, label, icon) in options)
                ChoiceOption(value, label, icon: icon),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows its first child when that child's natural width fits, else its
/// second. Both are laid out, so each keeps a box; only the one shown is
/// painted, hit, read out or found by a test's finder, as an
/// [IndexedStack] shows one. [onFits] hears which after the frame.
class _FitOrFallback extends MultiChildRenderObjectWidget {
  final ValueChanged<bool> onFits;

  const _FitOrFallback({required this.onFits, required super.children})
    : assert(children.length == 2);

  @override
  _FitOrFallbackElement createElement() => _FitOrFallbackElement(this);

  @override
  _RenderFitOrFallback createRenderObject(BuildContext context) =>
      _RenderFitOrFallback(onFits);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFitOrFallback renderObject,
  ) => renderObject.onFits = onFits;
}

class _FitOrFallbackElement extends MultiChildRenderObjectElement {
  _FitOrFallbackElement(_FitOrFallback super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final fits = (renderObject as _RenderFitOrFallback)._fits;
    visitor(fits ? children.first : children.last);
  }
}

class _FitParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFitOrFallback extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitParentData> {
  _RenderFitOrFallback(this.onFits);

  ValueChanged<bool> onFits;

  bool _fits = true;

  /// What [onFits] last heard, or is about to.
  bool? _reported;

  RenderBox get _preferred => firstChild!;
  RenderBox get _fallback => lastChild!;
  RenderBox get _shown => _fits ? _preferred : _fallback;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FitParentData) {
      child.parentData = _FitParentData();
    }
  }

  bool _fitsIn(double width) =>
      _preferred.getMaxIntrinsicWidth(double.infinity) <= width;

  RenderBox _pick(double width) => _fitsIn(width) ? _preferred : _fallback;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _fallback.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _preferred.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _pick(width).getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _pick(width).getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(
        _pick(constraints.maxWidth).getDryLayout(constraints.loosen()),
      );

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _shown.getDistanceToActualBaseline(baseline);

  @override
  void performLayout() {
    _fits = _fitsIn(constraints.maxWidth);
    final loose = constraints.loosen();
    _preferred.layout(loose, parentUsesSize: true);
    _fallback.layout(loose, parentUsesSize: true);
    size = constraints.constrain(_shown.size);
    if (_fits != _reported) {
      _reported = _fits;
      final fits = _fits;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached) onFits(fits);
      });
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(_shown, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _shown.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      visitor(_shown);
}
