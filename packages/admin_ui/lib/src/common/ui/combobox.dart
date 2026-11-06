/// @docImport 'date_range_picker.dart';
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../fuzzy.dart';
import 'button.dart';
import 'clear_button.dart';
import 'field_chrome.dart';
import 'input_decoration.dart';
import 'labeled_field.dart';
import 'listbox.dart';
import 'popover.dart';
import 'popover_menu.dart';
import 'spinner.dart';

/// One choice in a [Combobox].
class ComboboxOption<T> {
  final T value;
  final String label;
  final String? description;
  final IconData? icon;

  /// The key of the row built for this option, to find it by in a test.
  final Key? key;

  const ComboboxOption(
    this.value,
    this.label, {
    this.key,
    this.description,
    this.icon,
  });
}

/// A searchable single-select: a text field that filters [options] into a
/// dropdown as you type.
///
/// By default it filters [options] locally (fuzzy). Pass [onSearch] to fetch
/// matches asynchronously instead — the View stays pure; the Screen wires the
/// callback to a fetcher. The picked option is kept, so its label survives a
/// search that no longer returns it; [labelFor] names a [value] the widget
/// has never seen (one set before any search ran).
///
/// **Keyboard.** Focus stays in the field while the list is open (the
/// active-descendant pattern of a [ListboxController]). Typing, a click,
/// ArrowDown or Alt+ArrowDown open the list — tabbing in does not. The list
/// opens on every option with the selected one highlighted and scrolled into
/// view; typing filters it and highlights the first match. ArrowUp/ArrowDown,
/// Home/End and PageUp/PageDown move the highlight, Enter picks it (while a
/// search is in flight Enter waits for its results and picks the first),
/// Escape or Alt+ArrowUp close the list and restore the selected label, and
/// focus leaving the field closes it too. After a pick focus stays in the
/// field.
///
/// **State.** A null [onChanged], or [readOnly], shows the value read-only:
/// focusable and selectable at full contrast, with no chevron or clear, never
/// opening. [enabled] false — or a disabled [FieldStateScope] — disables it.
/// An invalid [FieldStateScope] draws the error outline.
///
/// The dropdown is at least as wide as the field, opens below it or above
/// when the room below is short, and stays on screen, aligned to the field's
/// start edge.
class Combobox<T> extends StatefulWidget {
  final List<ComboboxOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;

  /// The placeholder; the localized "Select…" when null.
  final String? hint;

  /// Shows a × that clears the selection back to null while there is one,
  /// just before the chevron — on by default, as on a [DateRangePicker].
  final bool clearable;

  /// Fixed width; null stretches to the parent's constraints.
  final double? width;

  /// Async matcher. When set, replaces local filtering and shows a spinner in
  /// the field while in flight. Latest query wins (out-of-order responses are
  /// dropped); a failed search shows [errorText] with a retry.
  final Future<List<ComboboxOption<T>>> Function(String query)? onSearch;

  /// The label of a [value] found neither in [options] nor among the options
  /// picked or fetched so far — needed when [onSearch] is the only source.
  final String Function(T value)? labelFor;

  /// Shown when nothing matches: the localized "No matches" when null, or
  /// "No results" for an [onSearch].
  final String? emptyText;

  /// Shown when [onSearch] fails, beside a retry; the localized "Couldn’t
  /// load results" when null.
  final String? errorText;

  final ControlSize size;

  /// False disables the field; see [Combobox].
  final bool enabled;

  /// Shows the value without editing it; see [Combobox].
  final bool readOnly;

  final FocusNode? focusNode;
  final bool autofocus;

  /// The field's accessible name. When null, a [LabeledField] around the
  /// combobox names it, or else the [hint] does.
  final String? semanticLabel;

  const Combobox({
    super.key,
    this.options = const [],
    required this.value,
    required this.onChanged,
    this.hint,
    this.clearable = true,
    this.width,
    this.onSearch,
    this.labelFor,
    this.emptyText,
    this.errorText,
    this.size = ControlSize.medium,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  @override
  State<Combobox<T>> createState() => _ComboboxState<T>();
}

class _ComboboxState<T> extends State<Combobox<T>> {
  /// Keeps the plain arrows moving the caret: the popover's anchor maps them
  /// to menu traversal.
  static const _caretShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(
      LogicalKeyboardKey.arrowLeft,
    ): ExtendSelectionByCharacterIntent(
      forward: false,
      collapseSelection: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowRight,
    ): ExtendSelectionByCharacterIntent(
      forward: true,
      collapseSelection: true,
    ),
  };

  final _controller = TextEditingController();
  late final _listbox = ListboxController(onActivate: _pickAt);
  FocusNode? _ownFocus;
  PopoverController? _popover;

  bool _open = false;
  bool _editable = true;
  List<ComboboxOption<T>> _results = const [];

  /// The last option picked here, so its label outlives the search results.
  ComboboxOption<T>? _picked;

  /// The text as last seen, so a selection or composing change is no edit.
  String _lastText = '';

  /// Whether the user has typed since the list opened.
  bool _dirty = false;

  int _searchId = 0;
  bool _loading = false;
  bool _failed = false;

  /// Enter pressed while a search was in flight: picks its first result.
  bool _pendingEnter = false;

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'Combobox'));

  @override
  void initState() {
    super.initState();
    _setText(_labelOf(widget.value));
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(Combobox<T> old) {
    super.didUpdateWidget(old);
    if (widget.focusNode != old.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    // A parent rebuilding with an equal list, written inline, changes nothing.
    final optionsChanged = !_sameOptions(widget.options, old.options);
    if (widget.value != old.value ||
        optionsChanged ||
        widget.labelFor != old.labelFor) {
      if (!_dirty) _setText(_labelOf(widget.value));
      if (_open && !_dirty && optionsChanged && widget.onSearch == null) {
        _replaceOptions();
      }
    }
  }

  bool _sameOptions(List<ComboboxOption<T>> a, List<ComboboxOption<T>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.value != y.value ||
          x.label != y.label ||
          x.description != y.description ||
          x.icon != y.icon) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _searchId++;
    _focus.removeListener(_onFocus);
    _controller.dispose();
    _ownFocus?.dispose();
    _listbox.dispose();
    super.dispose();
  }

  String _labelOf(T? value) {
    if (value == null) return '';
    for (final o in widget.options) {
      if (o.value == value) return o.label;
    }
    final picked = _picked;
    if (picked != null && picked.value == value) return picked.label;
    final named = widget.labelFor?.call(value);
    if (named != null) return named;
    for (final o in _results) {
      if (o.value == value) return o.label;
    }
    return '';
  }

  void _setText(String text) {
    _lastText = text;
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onText() {
    final text = _controller.text;
    if (text == _lastText) return;
    _lastText = text;
    if (!_editable) return;
    _dirty = true;
    _pendingEnter = false;
    if (_open) {
      _refresh();
    } else {
      _popover?.open();
    }
  }

  void _onFocus() {
    if (!_focus.hasFocus && _open) _popover?.close();
  }

  void _onOpenChanged(bool open) {
    if (!mounted) return;
    if (open) {
      setState(() => _open = true);
      _refresh();
      return;
    }
    // A search still in flight answers nothing now.
    _searchId++;
    _pendingEnter = false;
    setState(() {
      _open = false;
      _loading = false;
      _failed = false;
    });
    if (_dirty) {
      _dirty = false;
      _setText(_labelOf(widget.value));
    }
  }

  void _openList() {
    if (_editable && !_open) _popover?.open();
  }

  /// Fills the list for the current text: every option until the user types.
  void _refresh() {
    final query = _dirty ? _controller.text : '';
    if (widget.onSearch != null) {
      _search(query);
    } else {
      _show(_filterLocal(query));
    }
  }

  void _show(List<ComboboxOption<T>> results) {
    setState(() {
      _results = results;
      _failed = false;
    });
    final selected = results.indexWhere((o) => o.value == widget.value);
    _listbox.reset(
      results.length,
      selected: selected < 0 ? null : selected,
      highlight: _dirty ? 0 : null,
      labelOf: (i) => results[i].label,
    );
  }

  /// Shows new [Combobox.options] in the open, untyped list, keeping the
  /// highlight on the option it was on while that one is still offered.
  void _replaceOptions() {
    final at = _listbox.highlighted;
    final highlighted = at != null && at < _results.length
        ? _results[at]
        : null;
    final results = widget.options;
    final kept = highlighted == null
        ? -1
        : results.indexWhere((o) => o.value == highlighted.value);
    if (kept < 0) {
      _show(results);
      return;
    }
    setState(() {
      _results = results;
      _failed = false;
    });
    final selected = results.indexWhere((o) => o.value == widget.value);
    _listbox
      ..update(
        results.length,
        selected: selected < 0 ? null : selected,
        labelOf: (i) => results[i].label,
      )
      ..highlight(kept, keyboard: _listbox.highlightFromKeyboard);
  }

  Future<void> _search(String query) async {
    final id = ++_searchId;
    setState(() {
      _loading = true;
      _failed = false;
    });
    List<ComboboxOption<T>> results;
    try {
      results = await widget.onSearch!(query);
    } catch (_) {
      if (!mounted || id != _searchId) return;
      setState(() {
        _loading = false;
        _failed = true;
        _results = const [];
        _pendingEnter = false;
      });
      _listbox.reset(0);
      return;
    }
    if (!mounted || id != _searchId) return;
    setState(() => _loading = false);
    _show(results);
    if (_pendingEnter) {
      _pendingEnter = false;
      if (_open && results.isNotEmpty) _pick(results.first);
    }
  }

  List<ComboboxOption<T>> _filterLocal(String q) {
    if (q.isEmpty) return widget.options;
    final scored = <(int, ComboboxOption<T>)>[];
    for (final o in widget.options) {
      final m = fuzzyMatch(q, o.label);
      if (m != null) scored.add((m.score, o));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final s in scored) s.$2];
  }

  void _pickAt(int index) {
    if (index < _results.length) _pick(_results[index]);
  }

  void _pick(ComboboxOption<T> option) {
    _picked = option;
    _dirty = false;
    _pendingEnter = false;
    _setText(option.label);
    widget.onChanged?.call(option.value);
    _popover?.close();
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  void _clear() {
    _picked = null;
    _dirty = false;
    _setText('');
    widget.onChanged?.call(null);
    _focus.requestFocus();
    if (_open) _refresh();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_editable || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final vertical =
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp;
    if (!_open) {
      if (vertical) {
        _openList();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (alt && vertical) {
      if (key == LogicalKeyboardKey.arrowUp) _popover?.close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) {
        if (_loading) {
          _pendingEnter = true;
        } else if (_failed) {
          _refresh();
        } else {
          _listbox.handleKey(event, textInput: true);
        }
      }
      // Kept from the field while open, which would end editing on it.
      return KeyEventResult.handled;
    }
    return _listbox.handleKey(event, textInput: true);
  }

  @override
  Widget build(BuildContext context) {
    final outer = FieldStateScope.of(context);
    return FieldStateScope(
      enabled: widget.enabled,
      readOnly: widget.readOnly || widget.onChanged == null,
      invalid: outer.invalid,
      child: Popover(
        autofocus: false,
        onOpenChanged: _onOpenChanged,
        anchor: (context, controller) {
          _popover = controller;
          return _field(context);
        },
        content: _panel,
      ),
    );
  }

  Widget _field(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    if (editable != _editable) {
      _editable = editable;
      if (!editable && _open) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _popover?.close());
      }
    }
    // The chevron always shows, as on every field trigger; the spinner takes
    // its place while a search runs, and a clear sits just before it.
    final suffix = _loading
        ? Spinner(size: context.sizes.fieldIcon, announce: false)
        : const FieldChevron();
    final clear = widget.clearable && widget.value != null && editable
        ? ClearButton(
            onPressed: _clear,
            label: context.adminL10n.clearSelection,
          )
        : null;
    final hint = widget.hint ?? context.adminL10n.selectPlaceholder;
    Widget field = TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      readOnly: state.readOnly,
      style: fieldTextStyle(context),
      onTap: _openList,
      decoration: fieldInputDecoration(
        context,
        hint: hint,
        size: widget.size,
        suffix: suffix,
        trailing: clear,
      ),
    );
    field = Shortcuts(
      shortcuts: _caretShortcuts,
      includeSemantics: false,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: field,
      ),
    );
    final labelled =
        context.findAncestorWidgetOfExactType<LabeledField>() != null;
    return SizedBox(
      width: widget.width,
      child: Semantics(
        textField: true,
        expanded: editable ? _open : null,
        label: widget.semanticLabel ?? (labelled ? null : hint),
        child: field,
      ),
    );
  }

  Widget _panel(BuildContext context, PopoverController controller) {
    final anchor =
        controller.anchorWidth ?? widget.width ?? ListboxMenu.minWidth;
    final l10n = context.adminL10n;
    final Widget body;
    if (_failed) {
      body = _ErrorRow(
        text: widget.errorText ?? l10n.inputs.couldNotLoadResults,
        onRetry: _refresh,
      );
    } else if (_results.isEmpty) {
      body = _loading
          ? const _LoadingRow()
          : _MessageRow(
              text:
                  widget.emptyText ??
                  (widget.onSearch == null ? l10n.noMatches : l10n.noResults),
            );
    } else {
      body = Listbox(
        controller: _listbox,
        itemCount: _results.length,
        itemBuilder: (context, i) {
          final o = _results[i];
          return ListboxOption(
            key: o.key,
            controller: _listbox,
            index: i,
            label: o.label,
            description: o.description,
            leading: o.icon == null
                ? null
                : Icon(
                    o.icon,
                    size: context.sizes.fieldIcon,
                    color: context.colors.foregroundMuted,
                  ),
            selected: o.value == widget.value,
            onTap: () => _pick(o),
          );
        },
      );
    }
    // Taps in the list count as inside the field, which keeps its focus;
    // nothing in it takes focus from the field.
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: PopoverMenuSurface(
          width: math.max(anchor, ListboxMenu.minWidth),
          maxHeight: _listMaxHeight,
          fitAvailableHeight: true,
          child: body,
        ),
      ),
    );
  }
}

/// The results list's height cap, shorter than a menu's (shadcn's command
/// list stops at 300): the field stays in view above the results.
const _listMaxHeight = 300.0;

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return _MessageRow(
      leading: Spinner(size: context.sizes.fieldIcon, announce: false),
      text: context.adminL10n.searching,
    );
  }
}

class _MessageRow extends StatelessWidget {
  final Widget? leading;
  final String text;
  final Widget? trailing;
  final Color? color;

  const _MessageRow({
    this.leading,
    required this.text,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return Container(
      constraints: BoxConstraints(
        minHeight: sizes.medium + 2 * AdminSpacing.xs,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: sizes.fieldPaddingX,
        vertical: AdminSpacing.xs,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, Gap(sizes.fieldIconGap)],
          Expanded(
            child: Text(
              text,
              style: context.type.fieldText.copyWith(
                color: color ?? context.colors.foregroundMuted,
              ),
            ),
          ),
          if (trailing != null) ...[Gap(sizes.fieldIconGap), trailing!],
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorRow({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: _MessageRow(
        leading: Icon(
          Icons.error_outline_rounded,
          size: context.sizes.fieldIcon,
          color: colors.dangerText,
        ),
        text: text,
        color: colors.foregroundSecondary,
        trailing: Button(
          context.adminL10n.retry,
          onPressed: onRetry,
          size: ControlSize.small,
          variant: ButtonVariant.ghost,
        ),
      ),
    );
  }
}
