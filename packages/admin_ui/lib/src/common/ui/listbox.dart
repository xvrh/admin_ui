/// @docImport '../../theme/palette.dart';
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_chrome.dart';
import 'input_decoration.dart';
import 'popover.dart';
import 'popover_menu.dart';
import 'tappable.dart';

/// The keyboard model of a listbox — a combobox's dropdown, a select's option
/// list: how many options there are, which one is highlighted (the active
/// option the keyboard acts on) and which one is selected.
///
/// Focus never moves onto the options. Whoever holds it — a combobox's text
/// field, a select's filter box, the list itself — passes its key events to
/// [handleKey], and the highlighted [ListboxOption] reads as focused to
/// assistive technology (the active-descendant pattern). A [Listbox] scrolls
/// the highlight into view as the keyboard moves it.
///
/// The keys: ArrowDown/ArrowUp move the highlight and wrap, Home/End jump to
/// the first/last option, PageDown/PageUp move by [pageSize] without
/// wrapping, Enter (and Space, outside a text field) activate the highlighted
/// option through [onActivate], and letters typed within a second of each
/// other jump to the option whose label starts with them — Radix's typeahead,
/// also outside a text field only. Options that [reset]'s `enabledOf` rules
/// out are skipped.
class ListboxController extends ChangeNotifier {
  ListboxController({this.onActivate, this.pageSize = 10});

  /// Called with the highlighted option's index on Enter, or Space.
  ValueChanged<int>? onActivate;

  /// How far PageDown and PageUp move the highlight.
  final int pageSize;

  static const _typeaheadWindow = Duration(seconds: 1);

  int _count = 0;
  int? _highlighted;
  int? _selected;
  String Function(int index)? _labelOf;
  bool Function(int index)? _enabledOf;

  int? _revealIndex;
  bool _revealCenter = false;
  bool _fromKeyboard = false;

  String _typed = '';
  Timer? _typedReset;

  /// The number of options.
  int get count => _count;

  /// The option the keyboard acts on, or null when there is none.
  int? get highlighted => _highlighted;

  /// The selected option, where the highlight starts; null when none is.
  int? get selected => _selected;

  /// Whether the last highlight move came from a key rather than the pointer.
  bool get highlightFromKeyboard => _fromKeyboard;

  /// Takes a new set of options — on open, or as a query changes them — with
  /// the highlight on [highlight], else on [selected], else on the first
  /// enabled option, scrolled into view. [labelOf] feeds the typeahead.
  void reset(
    int count, {
    int? selected,
    int? highlight,
    String Function(int index)? labelOf,
    bool Function(int index)? enabledOf,
  }) {
    _count = count;
    _selected = _valid(selected);
    _labelOf = labelOf;
    _enabledOf = enabledOf;
    _typed = '';
    final start = _valid(highlight) ?? _selected ?? _step(-1, 1);
    _highlighted = start != null && _enabled(start) ? start : _step(-1, 1);
    _fromKeyboard = false;
    _requestReveal(center: true);
    notifyListeners();
  }

  /// Updates the options in place — a toggled check, a cap reached — keeping
  /// the highlight where it is while it stays valid.
  void update(
    int count, {
    int? selected,
    String Function(int index)? labelOf,
    bool Function(int index)? enabledOf,
  }) {
    _count = count;
    _selected = _valid(selected);
    _labelOf = labelOf;
    _enabledOf = enabledOf;
    final h = _valid(_highlighted);
    _highlighted = h != null && _enabled(h) ? h : _step(-1, 1);
    notifyListeners();
  }

  /// Moves the highlight to [index] — from the pointer unless [keyboard],
  /// which also scrolls it into view.
  void highlight(int? index, {bool keyboard = false}) {
    final next = _valid(index);
    if (next != null && !_enabled(next)) return;
    if (next == _highlighted && !keyboard) return;
    _highlighted = next;
    _fromKeyboard = keyboard;
    if (keyboard) _requestReveal(center: false);
    notifyListeners();
  }

  /// Moves the highlight [delta] enabled options along, wrapping at the ends.
  void moveBy(int delta) {
    if (_count == 0) return;
    var at = _highlighted;
    for (var i = 0; i < delta.abs(); i++) {
      at = _step(at, delta.sign) ?? at;
    }
    if (at != null) highlight(at, keyboard: true);
  }

  /// Highlights the first enabled option.
  void first() => highlight(_step(-1, 1), keyboard: true);

  /// Highlights the last enabled option.
  void last() => highlight(_step(_count, -1), keyboard: true);

  /// Moves the highlight [pages] times [pageSize] options, stopping at the
  /// ends rather than wrapping.
  void page(int pages) {
    if (_count == 0) return;
    final target = ((_highlighted ?? -1) + pages * pageSize).clamp(
      0,
      _count - 1,
    );
    var at = target;
    // The nearest enabled option at or before the target, going the way the
    // page moved.
    while (at >= 0 && at < _count && !_enabled(at)) {
      at -= pages.sign;
    }
    if (at < 0 || at >= _count) {
      at = pages > 0 ? (_step(_count, -1) ?? -1) : (_step(-1, 1) ?? -1);
    }
    if (at >= 0) highlight(at, keyboard: true);
  }

  /// Drives the model from a key event; see [ListboxController]. With
  /// [textInput] focus is in a text field, which keeps Space and letters for
  /// itself.
  KeyEventResult handleKey(KeyEvent event, {bool textInput = false}) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final modified =
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed;
    if (modified) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown) {
      moveBy(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      moveBy(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      first();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      last();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      page(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      page(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return _activate(event);
    }
    if (textInput) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.space && _typed.isEmpty) {
      return _activate(event);
    }
    final char = event.character;
    if (char != null &&
        char.length == 1 &&
        (char.trim().isNotEmpty || _typed.isNotEmpty)) {
      typeahead(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Radix's typeahead: characters typed within a second of each other build
  /// a prefix; a repeated single letter cycles through the options starting
  /// with it.
  void typeahead(String char) {
    _typedReset?.cancel();
    _typedReset = Timer(_typeaheadWindow, () => _typed = '');
    _typed += char.toLowerCase();
    final labelOf = _labelOf;
    if (labelOf == null || _count == 0) return;
    final repeated = _typed.split('').every((c) => c == _typed[0]);
    final search = repeated ? _typed[0] : _typed;
    final current = _highlighted;
    final start = current ?? 0;
    for (var k = 0; k < _count; k++) {
      final i = (start + k) % _count;
      // One letter looks past the current option, so repeating it cycles.
      if (search.length == 1 && i == current) continue;
      if (_enabled(i) && labelOf(i).toLowerCase().startsWith(search)) {
        highlight(i, keyboard: true);
        return;
      }
    }
  }

  /// Activates the highlighted option once per press: a held key's repeats
  /// are swallowed.
  KeyEventResult _activate(KeyEvent event) {
    final index = _highlighted;
    final onActivate = this.onActivate;
    if (index == null || onActivate == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) onActivate(index);
    return KeyEventResult.handled;
  }

  /// The pending scroll target, handed to the [Listbox] once.
  (int, bool)? _takeReveal() {
    final index = _revealIndex;
    if (index == null) return null;
    _revealIndex = null;
    return (index, _revealCenter);
  }

  void _requestReveal({required bool center}) {
    _revealIndex = _highlighted;
    _revealCenter = center;
  }

  int? _valid(int? index) =>
      index != null && index >= 0 && index < _count ? index : null;

  bool _enabled(int index) => _enabledOf?.call(index) ?? true;

  /// The next enabled option after [from] going [direction], wrapping; null
  /// when none is enabled.
  int? _step(int? from, int direction) {
    if (_count == 0) return null;
    var at = from ?? (direction > 0 ? -1 : _count);
    for (var k = 0; k < _count; k++) {
      at = (at + direction) % _count;
      if (at < 0) at += _count;
      if (_enabled(at)) return at;
    }
    return null;
  }

  @override
  void dispose() {
    _typedReset?.cancel();
    super.dispose();
  }
}

/// The scrolling list of a listbox: builds [itemCount] rows lazily (usually
/// [ListboxOption]s) and scrolls the [controller]'s highlight into view —
/// centred when a new set of options opens on it, just into view as the
/// keyboard moves it — keeping the list's [padding] clear at either end.
///
/// With a [focusNode] the list is itself the focus target — a select without
/// a filter box — and drives [controller] from the keys it receives, after
/// [onKeyEvent] passes on them. Without one it takes no focus; the control
/// that holds it calls [ListboxController.handleKey].
///
/// As the keyboard moves the highlight, the new option is announced ("Banana,
/// 2 of 3") while a screen reader is on, since focus stays where it is.
class Listbox extends StatefulWidget {
  final ListboxController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  /// Makes the list the focus target; see [Listbox].
  final FocusNode? focusNode;

  /// Sees the list's keys first, when it has a [focusNode].
  final FocusOnKeyEventCallback? onKeyEvent;

  /// Names the list for assistive technology.
  final String? semanticLabel;

  const Listbox({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(AdminSpacing.xs),
    this.focusNode,
    this.onKeyEvent,
    this.semanticLabel,
  });

  @override
  State<Listbox> createState() => _ListboxState();
}

class _ListboxState extends State<Listbox> {
  late final ScrollController _scroll;
  final _rows = <int, GlobalKey>{};
  int? _announced;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    widget.controller.addListener(_onChange);
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(Listbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
    _rows.removeWhere((index, _) => index >= widget.itemCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    _scheduleReveal();
    _announce();
  }

  void _scheduleReveal() {
    final reveal = widget.controller._takeReveal();
    if (reveal == null) return;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _reveal(reveal.$1, center: reveal.$2),
    );
  }

  /// Scrolls row [index] into view. A row the lazy list has not built yet is
  /// first brought near by an estimate, then aligned once it is.
  void _reveal(int index, {required bool center, int attempt = 0}) {
    if (!mounted || !_scroll.hasClients || index >= widget.itemCount) return;
    final position = _scroll.position;
    final box = _rows[index]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) {
      if (attempt > 3 || widget.itemCount == 0) return;
      final padding = _padding.vertical;
      final extent =
          (position.maxScrollExtent + position.viewportDimension - padding) /
          widget.itemCount;
      position.jumpTo(
        (_padding.top +
                extent * index -
                (position.viewportDimension - extent) / 2)
            .clamp(position.minScrollExtent, position.maxScrollExtent),
      );
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _reveal(index, center: center, attempt: attempt + 1),
      );
      return;
    }
    final viewport = RenderAbstractViewport.of(box);
    final top = viewport.getOffsetToReveal(box, 0).offset - _padding.top;
    final bottom = viewport.getOffsetToReveal(box, 1).offset + _padding.bottom;
    var target = position.pixels;
    if (target > top || target < bottom) {
      target = center
          ? viewport.getOffsetToReveal(box, 0.5).offset
          : (target > top ? top : bottom);
    }
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) position.jumpTo(target);
  }

  void _announce() {
    final controller = widget.controller;
    final index = controller.highlighted;
    final announce =
        controller.highlightFromKeyboard &&
        index != null &&
        index != _announced &&
        SemanticsBinding.instance.semanticsEnabled;
    _announced = index;
    final label = index == null ? null : controller._labelOf?.call(index);
    if (!announce || label == null) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.adminL10n.inputs.optionOf(label, index + 1, controller.count),
      Directionality.of(context),
    );
  }

  GlobalKey _keyFor(int index) => _rows[index] ??= GlobalKey();

  /// [Listbox.padding] in the ambient direction.
  EdgeInsets get _padding => widget.padding.resolve(Directionality.of(context));

  @override
  Widget build(BuildContext context) {
    Widget list = ListView.builder(
      controller: _scroll,
      shrinkWrap: true,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => KeyedSubtree(
        key: _keyFor(index),
        child: widget.itemBuilder(context, index),
      ),
    );
    list = Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: list,
    );
    final focusNode = widget.focusNode;
    if (focusNode == null) return list;
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        final own = widget.onKeyEvent?.call(node, event);
        if (own != null && own != KeyEventResult.ignored) return own;
        return widget.controller.handleKey(event);
      },
      child: list,
    );
  }
}

/// One row of a [Listbox]: [label] with an optional [description] line and
/// [leading] glyph, at least the medium control height, on the theme's small
/// radius. The [controller]'s highlight fills it with
/// [AdminPalette.listHighlight]; the pointer moving over it moves the highlight
/// there. A [selected] row shows a trailing check — or, with [checkbox] (a
/// multi-select), [leading] is the checkbox and there is none.
///
/// Announced as a button with its selected (or checked) state, "n of m" as
/// its hint, and as focused while highlighted, since focus itself stays in
/// the control that drives the list. A disabled row takes neither the
/// highlight nor taps.
class ListboxOption extends StatelessWidget {
  final ListboxController controller;
  final int index;
  final String label;
  final String? description;
  final Widget? leading;
  final bool selected;
  final bool enabled;

  /// A multi-select row: [leading] shows the check, announced as checked.
  final bool checkbox;

  /// Replaces [label]'s text — styled content such as a "Create …" row — while
  /// [label] still names the row.
  final Widget? title;

  final VoidCallback? onTap;

  const ListboxOption({
    super.key,
    required this.controller,
    required this.index,
    required this.label,
    this.description,
    this.leading,
    this.selected = false,
    this.enabled = true,
    this.checkbox = false,
    this.title,
    this.onTap,
  });

  /// The inset a row's content keeps from its highlight's edge, so under a
  /// [Listbox]'s default padding its text lines up with a field trigger's —
  /// the popover's hairline border is painted over its content, not around
  /// it.
  static double contentInset(BuildContext context) =>
      math.max(0, context.sizes.fieldPaddingX - AdminSpacing.xs);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context, controller.highlighted == index),
    );
  }

  Widget _build(BuildContext context, bool highlighted) {
    final colors = context.colors;
    final sizes = context.sizes;
    final type = context.type;
    final live = enabled && onTap != null;
    final fill = highlighted && enabled ? colors.listHighlight : null;
    final labelStyle =
        (selected && !checkbox
                ? type.weighted(type.fieldText, type.spec.strong)
                : type.fieldText)
            .copyWith(
              color: enabled ? colors.foreground : colors.foregroundSubtle,
            );
    final line = (labelStyle.fontSize ?? 13) * (labelStyle.height ?? 1.5);
    final inset = contentInset(context);

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          SizedBox(
            height: line,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: sizes.fieldIcon),
              child: Center(child: leading),
            ),
          ),
          Gap(sizes.fieldIconGap),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              title ??
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
              if (description != null)
                Text(
                  description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.caption.copyWith(
                    color: enabled
                        ? colors.readableOn(
                            colors.foregroundMuted,
                            surfaces: [colors.surface, colors.listHighlight],
                          )
                        : colors.foregroundSubtle,
                  ),
                ),
            ],
          ),
        ),
        if (selected && !checkbox) ...[
          Gap(sizes.fieldIconGap),
          SizedBox(
            height: line,
            child: Icon(
              Icons.check_rounded,
              size: sizes.fieldIcon,
              color: enabled ? colors.primaryText : colors.foregroundSubtle,
            ),
          ),
        ],
      ],
    );

    content = Container(
      constraints: BoxConstraints(minHeight: sizes.medium),
      padding: EdgeInsets.symmetric(
        horizontal: inset,
        vertical: AdminSpacing.sm,
      ),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      child: content,
    );

    return Semantics(
      container: true,
      button: checkbox ? null : true,
      selected: checkbox ? null : selected,
      checked: checkbox ? selected : null,
      enabled: live,
      focused: highlighted,
      label: description == null ? label : '$label\n$description',
      hint: context.adminL10n.countOf(index + 1, controller.count),
      onTap: live ? onTap : null,
      excludeSemantics: true,
      child: CursorRegion(
        cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
        // Movement, not entry: a row the list scrolls under a still pointer
        // must not take the highlight from the keyboard.
        onHover: (_) {
          if (enabled && !highlighted) controller.highlight(index);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: live ? onTap : null,
          child: content,
        ),
      ),
    );
  }
}

/// A field dropdown's content — a select's, a multi-select's: a [Listbox]
/// under an optional filter box, with [emptyText] when there are no rows and
/// an optional [footer] line, on a [PopoverMenuSurface] as wide as the
/// trigger ([anchorWidth]) but at least [minWidth] — and the focus model
/// around it.
///
/// As it opens, focus moves into it: onto the filter box when there is one
/// ([onFilterChanged] set), whose ArrowUp/ArrowDown, Home/End,
/// PageUp/PageDown and Enter drive the [controller]; otherwise onto the list
/// itself, which also takes Space and typeahead. Tab closes the popover and
/// moves on from its trigger (Shift+Tab back), and Escape returns focus to
/// the trigger.
class ListboxMenu extends StatefulWidget {
  /// The narrowest the menu gets, beside a narrower trigger.
  static const minWidth = 200.0;

  final ListboxController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// The trigger's width, from [PopoverController.anchorWidth].
  final double? anchorWidth;
  final double maxHeight;

  /// Called with the option Enter (or Space) activates. With [closeOnSelect]
  /// the popover then closes and hands focus back to its trigger.
  final ValueChanged<int> onSelect;
  final bool closeOnSelect;

  /// Shows the filter box and reports its text as it changes.
  final ValueChanged<String>? onFilterChanged;

  /// The filter box's text, for a host that clears it itself; the menu keeps
  /// its own, fresh on every open, when null.
  final TextEditingController? filterController;

  /// The filter box's placeholder; the localized "Filter…" when null.
  final String? filterHint;

  /// Shown in place of the list while [itemCount] is 0; the localized "No
  /// matches" when null.
  final String? emptyText;

  /// A caption line below the list, after a separator — "12 of 500" — with
  /// an optional leading [footerIcon].
  final String? footer;
  final IconData? footerIcon;

  /// Names the list for assistive technology.
  final String? semanticLabel;

  const ListboxMenu({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.anchorWidth,
    required this.onSelect,
    this.closeOnSelect = true,
    this.maxHeight = 360,
    this.onFilterChanged,
    this.filterController,
    this.filterHint,
    this.emptyText,
    this.footer,
    this.footerIcon,
    this.semanticLabel,
  });

  @override
  State<ListboxMenu> createState() => _ListboxMenuState();
}

class _ListboxMenuState extends State<ListboxMenu> {
  final _ownFilter = TextEditingController();
  final _filterNode = FocusNode(debugLabel: 'Listbox filter');
  final _listNode = FocusNode(debugLabel: 'Listbox', skipTraversal: true);

  bool get _filtered => widget.onFilterChanged != null;

  @override
  void initState() {
    super.initState();
    widget.controller.onActivate = _select;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (_filtered ? _filterNode : _listNode).requestFocus();
    });
  }

  @override
  void didUpdateWidget(ListboxMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.onActivate = _select;
  }

  void _select(int index) {
    widget.onSelect(index);
    if (widget.closeOnSelect && mounted) Popover.dismiss(context);
  }

  @override
  void dispose() {
    if (widget.controller.onActivate == _select) {
      widget.controller.onActivate = null;
    }
    _ownFilter.dispose();
    _filterNode.dispose();
    _listNode.dispose();
    super.dispose();
  }

  /// Tab leaves the menu the way it would have left the trigger.
  KeyEventResult _onTab(KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      final forward = !HardwareKeyboard.instance.isShiftPressed;
      Popover.dismiss(context);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final trigger = FocusManager.instance.primaryFocus;
        forward ? trigger?.nextFocus() : trigger?.previousFocus();
      });
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _onFilterKey(FocusNode node, KeyEvent event) {
    final tab = _onTab(event);
    if (tab != KeyEventResult.ignored) return tab;
    final result = widget.controller.handleKey(event, textInput: true);
    final enter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    // Enter with nothing to pick stays in the box rather than ending editing.
    return enter ? KeyEventResult.handled : result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget list = widget.itemCount == 0
        ? _MenuMessage(widget.emptyText ?? context.adminL10n.noMatches)
        : Listbox(
            controller: widget.controller,
            itemCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
            focusNode: _filtered ? null : _listNode,
            onKeyEvent: (_, event) => _onTab(event),
            semanticLabel: widget.semanticLabel,
          );
    final anchor = widget.anchorWidth;
    return PopoverMenuSurface(
      width: anchor == null || !anchor.isFinite
          ? ListboxMenu.minWidth
          : math.max(anchor, ListboxMenu.minWidth),
      maxHeight: widget.maxHeight,
      fitAvailableHeight: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_filtered) ...[
            Padding(
              padding: const EdgeInsets.all(AdminSpacing.sm),
              // The field's own state — an error, a host that draws its
              // chrome — is not the box's.
              child: FieldStateScope(
                child: ChromelessFieldScope.reset(
                  child: Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: _onFilterKey,
                    child: Builder(
                      builder: (context) => TextField(
                        controller: widget.filterController ?? _ownFilter,
                        focusNode: _filterNode,
                        onChanged: widget.onFilterChanged,
                        style: fieldTextStyle(context),
                        decoration: fieldInputDecoration(
                          context,
                          hint:
                              widget.filterHint ??
                              context.adminL10n.filterPlaceholder,
                          size: ControlSize.small,
                          leadingIcon: Icons.search_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Divider(
              height: context.stroke.hairline,
              thickness: context.stroke.hairline,
              color: colors.separator,
            ),
          ],
          // A menu with no filter box still needs a focus target while empty.
          Flexible(
            child: widget.itemCount == 0 && !_filtered
                ? Focus(
                    focusNode: _listNode,
                    onKeyEvent: (_, event) => _onTab(event),
                    child: list,
                  )
                : list,
          ),
          if (widget.footer != null) ...[
            Divider(
              height: context.stroke.hairline,
              thickness: context.stroke.hairline,
              color: colors.separator,
            ),
            _MenuFooter(widget.footer!, icon: widget.footerIcon),
          ],
        ],
      ),
    );
  }
}

class _MenuMessage extends StatelessWidget {
  final String text;

  const _MenuMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AdminSpacing.xl,
        horizontal: AdminSpacing.lg,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.type.bodySmall.copyWith(
          color: context.colors.foregroundMuted,
        ),
      ),
    );
  }
}

class _MenuFooter extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _MenuFooter(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.type.caption.copyWith(color: colors.foregroundMuted);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ListboxOption.contentInset(context) + AdminSpacing.xs,
        vertical: AdminSpacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: style.fontSize, color: colors.foregroundMuted),
            const Gap(AdminSpacing.sm),
          ],
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
