import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/labeled_field.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// A small default palette. Editors usually pick from a brand set; custom hex is
/// the escape hatch.
const _defaultPalette = [
  '#15181D',
  '#6B7280',
  '#D24B3E',
  '#CF8A00',
  '#2F9E63',
  '#5B5BD6',
  '#9333A8',
  '#0F9D8F',
  '#4EABFB',
  '#FFFFFF',
];

/// The side of a palette swatch: five to a row of the popover.
const _swatch = 32.0;

/// The bare colour control — a swatch + hex label that opens a popover with a
/// preset palette and (optionally) a hex input. No label or capability chrome,
/// so it sits inside a [FieldShell] or one lane of a translatable field. The
/// value is an uppercase `#RRGGBB` string.
///
/// A null [onChanged] renders the control read-only: the value at full
/// contrast, focusable, no chevron, nothing opens (see [FieldState]).
/// [enabled] false, or a disabled [FieldStateScope], disables it.
class ColorBody extends StatelessWidget {
  final String? value;
  final ValueChanged<String>? onChanged;

  /// Preset swatches offered in the popover.
  final List<String> palette;

  /// Show the free-form hex input below the palette.
  final bool allowCustomHex;

  /// Placeholder shown when [value] is null; null reads "Pick a color…" in
  /// the app's language.
  final String? hint;

  final bool enabled;

  const ColorBody({
    super.key,
    this.value,
    this.onChanged,
    this.palette = _defaultPalette,
    this.allowCustomHex = true,
    this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _Picker(
      value: value,
      palette: palette,
      allowCustomHex: allowCustomHex,
      hint: hint ?? context.adminL10n.fields.pickColor,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

/// Parse `#RGB` / `#RRGGBB` (with or without the hash) to a [Color]; null if it
/// isn't a valid hex colour.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length != 6) return null;
  var v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(0xFF000000 | v);
}

/// Normalise loose input to canonical `#RRGGBB`, or null if invalid.
String? normalizeHex(String hex) {
  var c = parseHexColor(hex);
  if (c == null) return null;
  var rgb = (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '#${rgb.toUpperCase()}';
}

class _Picker extends StatefulWidget {
  final String? value;
  final List<String> palette;
  final bool allowCustomHex;
  final String hint;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const _Picker({
    required this.value,
    required this.palette,
    required this.allowCustomHex,
    required this.hint,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final _hexController = TextEditingController();
  bool _wasOpen = false;

  /// Why the typed hex was refused, until it is edited.
  String? _hexError;

  /// The popover's content, whose first stop a keyboard open focuses.
  final _content = FocusNode(canRequestFocus: false, skipTraversal: true);

  /// The selected swatch, focused ahead of the first one.
  final _selectedSwatch = FocusNode();

  @override
  void dispose() {
    _hexController.dispose();
    _content.dispose();
    _selectedSwatch.dispose();
    super.dispose();
  }

  void _focusMenu() {
    if (_selectedSwatch.context != null) {
      _selectedSwatch.requestFocus();
    } else {
      _content.traversalDescendants.firstOrNull?.requestFocus();
    }
  }

  void _syncOpen(bool open) {
    if (open == _wasOpen) return;
    _wasOpen = open;
    if (open) {
      _hexController.text = (widget.value ?? '').replaceFirst('#', '');
      _hexError = null;
    }
  }

  void _pick(String hex, PopoverController controller) {
    final norm = normalizeHex(hex);
    if (norm == null) return;
    widget.onChanged?.call(norm);
    controller.close();
  }

  void _submitHex(PopoverController controller) {
    if (normalizeHex(_hexController.text) == null) {
      setState(() => _hexError = context.adminL10n.fields.hexDigitsError);
      return;
    }
    _pick(_hexController.text, controller);
  }

  @override
  Widget build(BuildContext context) {
    return Popover(
      side: PopoverSide.bottom,
      align: PopoverAlign.start,
      autofocus: false,
      closeOnFocusOut: true,
      anchor: (context, controller) {
        _syncOpen(controller.isOpen);
        return _trigger(controller);
      },
      content: (context, controller) =>
          Focus(focusNode: _content, child: _menu(controller)),
    );
  }

  Widget _trigger(PopoverController controller) {
    final color = parseHexColor(widget.value);
    return FieldTrigger(
      controller: controller,
      enabled: widget.enabled,
      readOnly: widget.onChanged == null,
      chevron: true,
      onKeyboardOpen: _focusMenu,
      child: Builder(
        builder: (context) {
          final sizes = context.sizes;
          return Row(
            children: [
              // The swatch is centred on the column a field's leading glyph
              // takes, so the value lines up with the text of fields that
              // lead with one.
              SizedBox(
                width: sizes.fieldIcon,
                height: IconActionSize.inline.box,
                child: OverflowBox(
                  maxWidth: _Swatch.triggerSize,
                  child: _Swatch(color: color, size: _Swatch.triggerSize),
                ),
              ),
              Gap(sizes.fieldIconGap),
              // Sized to its text, so a hex value laid out left to right
              // still sits beside the swatch in a right-to-left field.
              Flexible(
                child: Text(
                  color == null ? widget.hint : widget.value!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Physical: a hex code reads left to right, '#' first.
                  textDirection: color == null ? null : TextDirection.ltr,
                  style: color == null
                      ? context.type.fieldText.copyWith(
                          color: FieldStateScope.of(context).enabled
                              ? context.colors.placeholder
                              : context.colors.foregroundSubtle,
                        )
                      : fieldTextStyle(context).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menu(PopoverController controller) {
    return PopoverMenuSurface(
      width: 248,
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AdminSpacing.md,
              runSpacing: AdminSpacing.md,
              children: [
                for (final hex in widget.palette)
                  _paletteSwatch(hex, controller),
              ],
            ),
            if (widget.allowCustomHex) ...[
              const Gap(AdminSpacing.lg),
              Divider(height: 1, color: context.colors.borderSubtle),
              const Gap(AdminSpacing.lg),
              _hexInput(controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paletteSwatch(String hex, PopoverController controller) {
    final color = parseHexColor(hex);
    final selected =
        color != null && normalizeHex(hex) == normalizeHex(widget.value ?? '');
    final radius = context.radii.radiusSmall;
    return Tappable(
      onTap: () => _pick(hex, controller),
      focusNode: selected ? _selectedSwatch : null,
      semanticLabel: normalizeHex(hex) ?? hex,
      selected: selected,
      focusRadius: radius,
      child: Container(
        width: _swatch,
        height: _swatch,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: color != null && selected
            ? Icon(
                Icons.check_rounded,
                size: context.iconSizes.md,
                color: context.colors.foregroundOn(color),
              )
            : null,
      ),
    );
  }

  Widget _hexInput(PopoverController controller) {
    final error = _hexError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              // The field's own state — an error, a host that draws its
              // chrome — is not the box's.
              child: FieldStateScope(
                child: ChromelessFieldScope.reset(
                  child: Builder(
                    builder: (context) => TextField(
                      controller: _hexController,
                      autofocus: false,
                      inputFormatters: const [_HexFormatter()],
                      onChanged: (_) {
                        if (_hexError != null) setState(() => _hexError = null);
                      },
                      onSubmitted: (_) => _submitHex(controller),
                      style: fieldTextStyle(context).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      // The glyph is the one '#': the text is the digits
                      // alone.
                      decoration: fieldInputDecoration(
                        context,
                        hint: '5B5BD6',
                        leadingIcon: Icons.tag_rounded,
                        invalid: error != null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(AdminSpacing.md),
            Button(
              context.adminL10n.fields.setColor,
              variant: ButtonVariant.primary,
              onPressed: () => _submitHex(controller),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AdminSpacing.md),
            child: FieldMessage(error: error),
          ),
      ],
    );
  }
}

/// Keeps the hex digits of what is typed or pasted — a leading '#' and
/// anything else dropped — uppercase, at most six.
class _HexFormatter extends TextInputFormatter {
  const _HexFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp('[^0-9a-fA-F]'), '');
    text = text.toUpperCase();
    if (text.length > 6) text = text.substring(0, 6);
    if (text == newValue.text) return newValue;
    final removed = newValue.text.length - text.length;
    final caret = (newValue.selection.end - removed).clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color? color;
  final double size;

  const _Swatch({required this.color, required this.size});

  /// The trigger's swatch: a 16px glyph's column plus 2px either side.
  static const triggerSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final decoration = BoxDecoration(
      color: color ?? colors.background,
      borderRadius: BorderRadius.circular(context.radii.radiusCheck),
      border: Border.all(color: colors.border),
    );
    return Container(
      width: size,
      height: size,
      decoration: decoration,
      // Empty: a hollow tile with a dropper, so it reads as "unset".
      child: color == null
          ? Icon(
              Icons.colorize_rounded,
              size: size * 0.6,
              color: colors.foregroundMuted,
            )
          : null,
    );
  }
}
