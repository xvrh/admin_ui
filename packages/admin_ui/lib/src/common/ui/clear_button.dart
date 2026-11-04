/// @docImport 'copy_button.dart';
/// @docImport 'menu_button.dart';
library;

import 'package:material_ui/material_ui.dart';

import 'field_chrome.dart';
import 'icon_action.dart';

/// The bare "×" clear/dismiss affordance used inside field triggers, search
/// boxes and chips — a muted [Icons.close_rounded] in an inline [IconAction]:
/// a 16px glyph in a 24px hit box, focusable, announced and tooltipped as
/// [label]. For the bordered circular variant overlaid on tiles use
/// `CircleButton` instead.
///
/// It edits the field it sits in, so under a read-only or disabled
/// [FieldStateScope] it renders nothing. A null [onPressed] shows it
/// disabled.
///
/// It takes no glyph size, unlike [CopyButton.iconSize] and
/// [MenuButton.iconSize]: its glyph is the inline [IconAction]'s, so it lines
/// up with a field's other inline affordances.
class ClearButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final Color? color;

  /// The accessible name and tooltip; the localized "Clear text" when null.
  final String? label;

  const ClearButton({super.key, this.onPressed, this.color, this.label});

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context);
    if (!state.enabled || state.readOnly) return const SizedBox.shrink();
    return IconAction(
      Icons.close_rounded,
      label: label ?? MaterialLocalizations.of(context).clearButtonTooltip,
      onPressed: onPressed,
      size: IconActionSize.inline,
      color: color,
    );
  }
}
