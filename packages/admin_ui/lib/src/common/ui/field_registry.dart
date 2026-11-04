import 'dart:async';

import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'command_palette.dart' show PaletteItem;
import 'command_registry.dart';

/// One registered form field — enough for the palette to list it and jump to it.
class FormFieldEntry {
  final String id;
  final String label;

  /// Focuses + scrolls the field into view. Focusing a text input scrolls
  /// only its caret into view; [reveal] shows the whole field.
  final VoidCallback focus;

  /// Where the field is on screen now, in global coordinates; null when it
  /// is not shown (on a tab in the background, not laid out yet). The
  /// registry lists its fields in reading order by it.
  final Rect? Function()? bounds;

  /// The direction the field reads in: fields side by side are listed from
  /// its start edge, the left one when it is not known.
  final TextDirection? textDirection;

  const FormFieldEntry({
    required this.id,
    required this.label,
    required this.focus,
    this.bounds,
    this.textDirection,
  });

  /// Focuses the field ([focus]), then brings all of it into view: the
  /// vertical scroll view around the focused control moves just enough to
  /// show the field's [bounds], from its label to its message,
  /// [AdminSpacing.lg] clear of the view's edges, taking over the scroll
  /// the focus started (which brings only a text input's caret in). A
  /// message under an input near the bottom thus clears a save bar docked
  /// under the view. A field taller than the view shows its top.
  ///
  /// It does no more than [focus] when the field has no [bounds], or focus
  /// did not land inside it: a field with nothing to focus is scrolled in
  /// whole by [focus] already. A scroll the user starts while it moves the
  /// view is theirs: the reveal stops there.
  ///
  /// A text input it focuses shows no selection handles, which a touch
  /// platform otherwise puts under the caret of a field with text in it,
  /// over the message.
  void reveal() {
    focus();
    // Focus lands in a microtask and asks, from the next frame's callbacks,
    // for its caret to be scrolled in: once those callbacks have run, that
    // scroll is under way and this one takes over from it.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => scheduleMicrotask(_revealWhole))
      ..scheduleFrame();
  }

  static void _afterFrame(VoidCallback then) => WidgetsBinding.instance
    ..addPostFrameCallback((_) => then())
    ..scheduleFrame();

  /// Moves the view so the whole field shows, then checks once more when
  /// that scroll, or one another widget started after it, has ended, unless
  /// the user has scrolled since.
  void _revealWhole([int checks = 2]) {
    final focused = FocusManager.instance.primaryFocus?.context;
    final field = bounds?.call();
    if (focused == null || field == null || !focused.mounted) return;
    final control = focused.findRenderObject();
    if (control is! RenderBox || !control.attached || !control.hasSize) return;
    final centre = control.localToGlobal(control.size.center(Offset.zero));
    if (!field.contains(centre)) return;
    focused.findAncestorStateOfType<EditableTextState>()?.hideToolbar();
    final scrollable = _verticalScrollableAround(focused);
    final view = scrollable?.context.findRenderObject();
    if (scrollable == null || view is! RenderBox || !view.hasSize) return;
    final position = scrollable.position;
    final visible = view.localToGlobal(Offset.zero) & view.size;
    const gutter = AdminSpacing.lg;
    // How far the field moves up the screen.
    var shift = 0.0;
    if (field.bottom + gutter > visible.bottom) {
      shift = field.bottom + gutter - visible.bottom;
    }
    if (field.top - shift - gutter < visible.top) {
      shift = field.top - gutter - visible.top;
    }
    final down = scrollable.axisDirection == AxisDirection.down;
    final target = (position.pixels + (down ? shift : -shift)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    // A drag, a fling or a wheel sets the user's direction as it moves the
    // view.
    var userScrolled = false;
    void watch() {
      if (position.userScrollDirection != ScrollDirection.idle) {
        userScrolled = true;
      }
    }

    position.addListener(watch);
    void checkAgain() {
      final scrolling = position.isScrollingNotifier;
      if (checks > 0 && !userScrolled && scrolling.value) {
        void ended() {
          if (scrolling.value) return;
          scrolling.removeListener(ended);
          position.removeListener(watch);
          if (!userScrolled) _revealWhole(checks - 1);
        }

        scrolling.addListener(ended);
        return;
      }
      position.removeListener(watch);
      // Still, and short of where this scroll was going: a finger held down
      // stopped it, without moving the view or starting a scroll of its own.
      final held = (position.pixels - target).abs() >= 0.5;
      if (checks > 0 && !userScrolled && !held) _revealWhole(checks - 1);
    }

    if ((target - position.pixels).abs() < 0.5) return checkAgain();
    final motion = scrollable.context.motion;
    if (motion.fast == Duration.zero) {
      position.jumpTo(target);
      _afterFrame(checkAgain);
    } else {
      position
          .animateTo(target, duration: motion.fast, curve: motion.standard)
          .then((_) => checkAgain());
    }
  }

  /// The nearest vertical [Scrollable] above [context], skipping horizontal
  /// ones (a row of tabs, a carousel).
  static ScrollableState? _verticalScrollableAround(BuildContext context) {
    var scrollable = context.findAncestorStateOfType<ScrollableState>();
    while (scrollable != null &&
        axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      scrollable = scrollable.context
          .findAncestorStateOfType<ScrollableState>();
    }
    return scrollable;
  }
}

/// The fields present in the current form. Field shells register on mount and
/// unregister on dispose; [FormFieldCommands] reads [entries] lazily, so no
/// notification (and no mid-build rebuild) is needed.
class FormFieldRegistry {
  final _entries = <String, FormFieldEntry>{};

  /// The fields in reading order: top to bottom by where each is on screen
  /// now ([FormFieldEntry.bounds]), those on one line from their start edge.
  /// A field shown late (a condition met, a column filled in) takes its place
  /// on screen, not the end of the list. Fields not on screen follow, in the
  /// order they registered.
  Iterable<FormFieldEntry> get entries {
    final placed = [
      for (final (i, entry) in _entries.values.indexed)
        (i, entry, entry.bounds?.call()),
    ]..sort(_readingOrder);
    return [for (final (_, entry, _) in placed) entry];
  }

  /// Adds [entry], replacing any registered under its id.
  void register(FormFieldEntry entry) => _entries[entry.id] = entry;

  /// Removes the field [id]; given the [entry] that registered, only while
  /// it is still the one registered, so a duplicate going away leaves the
  /// field that replaced it.
  void unregister(String id, [FormFieldEntry? entry]) {
    if (entry == null || identical(_entries[id], entry)) _entries.remove(id);
  }

  static int _readingOrder(
    (int, FormFieldEntry, Rect?) a,
    (int, FormFieldEntry, Rect?) b,
  ) {
    final (ai, ae, ar) = a;
    final (bi, be, br) = b;
    if (ar == null || br == null) {
      if (ar != null) return -1;
      if (br != null) return 1;
      return ai.compareTo(bi);
    }
    // Whole pixels, so fields a fraction apart still share a line.
    final byTop = ar.top.round().compareTo(br.top.round());
    if (byTop != 0) return byTop;
    final rtl =
        ae.textDirection == TextDirection.rtl &&
        be.textDirection == TextDirection.rtl;
    final byStart = rtl
        ? br.right.round().compareTo(ar.right.round())
        : ar.left.round().compareTo(br.left.round());
    return byStart != 0 ? byStart : ai.compareTo(bi);
  }
}

/// Reports field focus to ambient chrome (the preview pane's block highlight).
/// A field shell with a field id calls [onFocus] with it when a descendant
/// gains focus. Losing focus reports nothing: the highlight stays on the last
/// field focused until another takes over, so a click into the preview or on
/// the page around the form keeps it. Absent from the tree ⇒ no focus
/// reporting. A pure sink — consumers read it imperatively (no rebuild on
/// change).
class FieldFocusScope extends InheritedWidget {
  final void Function(String? fieldId) onFocus;

  const FieldFocusScope({
    super.key,
    required this.onFocus,
    required super.child,
  });

  static FieldFocusScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FieldFocusScope>();

  @override
  bool updateShouldNotify(FieldFocusScope old) => onFocus != old.onFocus;
}

/// Provides a [FormFieldRegistry] to the field shells beneath a form.
class FormFieldScope extends InheritedWidget {
  final FormFieldRegistry registry;

  const FormFieldScope({
    super.key,
    required this.registry,
    required super.child,
  });

  static FormFieldRegistry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormFieldScope>()?.registry;

  @override
  bool updateShouldNotify(FormFieldScope old) => registry != old.registry;
}

/// Bridges the in-scope [FormFieldScope] into the in-scope [CommandScope]: while
/// mounted, the current form's fields appear as a "Fields" group in ⌘K, so
/// search can jump to any field. Contributes a builder that reads the live field
/// set at palette-open, so fields mounting later are still picked up.
class FormFieldCommands extends StatefulWidget {
  /// The group the fields are listed under when [group] is null: a grouping
  /// key for [CommandPaletteController.groupOrder], which the palette shows
  /// as the localized "Fields".
  static const defaultGroup = 'Fields';

  final Widget child;

  /// The palette group the fields are listed under; [defaultGroup] when null.
  final String? group;

  const FormFieldCommands({super.key, required this.child, this.group});

  @override
  State<FormFieldCommands> createState() => _FormFieldCommandsState();
}

class _FormFieldCommandsState extends State<FormFieldCommands> {
  FormFieldRegistry? _fields;
  CommandRegistry? _commands;
  CommandSubscription? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fields = FormFieldScope.maybeOf(context);
    final commands = CommandScope.maybeOf(context);
    if (fields == _fields && commands == _commands) return;
    _fields = fields;
    _commands = commands;
    _sub?.dispose();
    _sub = null;
    if (fields == null || commands == null) return;
    // contribute() notifies the CommandRegistry — defer so we never notify
    // during this build pass.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fields != fields || _commands != commands) return;
      _sub = commands.contribute(
        () => [
          for (final f in fields.entries)
            PaletteItem(
              id: 'field:${f.id}',
              title: f.label,
              icon: Icons.my_location_outlined,
              group: widget.group ?? FormFieldCommands.defaultGroup,
              keywords: const ['field', 'jump to'],
              onSelect: f.reveal,
            ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _sub?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
