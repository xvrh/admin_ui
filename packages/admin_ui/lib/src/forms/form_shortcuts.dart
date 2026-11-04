/// @docImport 'form_actions.dart';
/// @docImport 'form_save_bar.dart';
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../common/ui/field_registry.dart';
import '../shell/ui/save_bar.dart';
import 'form_controller.dart';

/// Cmd+S / Ctrl+S saves [controller], wherever focus is on the page.
///
/// While this is mounted and its route is the current one, the shortcut
/// submits the form when it can ([FormController.canSubmit]); a form with
/// unsaved but invalid edits instead brings its first invalid field into view
/// and focuses it ([revealFirstInvalid]). A clean form does nothing. The key is
/// consumed either way, so a web build never opens the browser's "Save page"
/// dialog over an edit screen.
///
/// A form under [SaveFlow.publish] (a draft-backed editor, whose submit is a
/// publish) already keeps its edits, so there the shortcut only reveals an
/// invalid field and never publishes.
///
/// [FormSaveBar] and [FormActions] carry one already; wrap a custom editing
/// surface that has neither. With several on screen, the one holding focus
/// wins, then the most recently mounted; two for one controller act once.
class FormShortcuts extends StatefulWidget {
  final FormController controller;

  /// The fields to reveal an invalid one among; the ambient [FormFieldScope]
  /// when null.
  final FormFieldRegistry? fields;

  /// Under [SaveFlow.publish] the form keeps its edits itself and its submit
  /// publishes: the shortcut submits nothing.
  final SaveFlow flow;

  final Widget child;

  const FormShortcuts({
    super.key,
    required this.controller,
    this.fields,
    this.flow = SaveFlow.save,
    required this.child,
  });

  /// Focuses the first field of [fields] that [controller] reports an error
  /// for, in reading order, and brings the whole of it into view, its
  /// message too ([FormFieldEntry.reveal]): a field at the bottom of the
  /// page shows its message above a bottom [FormSaveBar]. Returns whether
  /// there was one to reveal.
  static bool revealFirstInvalid(
    FormController controller,
    FormFieldRegistry? fields,
  ) {
    if (fields == null) return false;
    final errors = controller.errors;
    for (final field in fields.entries) {
      if (errors[field.id] != null) {
        field.reveal();
        return true;
      }
    }
    return false;
  }

  /// Submits [controller] if it can be (unless under [SaveFlow.publish]), or
  /// reveals its first invalid field if its unsaved edits are invalid — what
  /// the shortcut does.
  static void save(
    FormController controller,
    FormFieldRegistry? fields, {
    SaveFlow flow = SaveFlow.save,
  }) {
    final publish = flow == SaveFlow.publish;
    if (controller.canSubmit) {
      if (!publish) controller.requestSubmit();
    } else if (controller.hasUnsavedChanges && !controller.isValid) {
      revealFirstInvalid(controller, fields);
    }
  }

  @override
  State<FormShortcuts> createState() => _FormShortcutsState();
}

class _FormShortcutsState extends State<FormShortcuts> {
  final _focus = FocusNode(
    debugLabel: 'FormShortcuts',
    canRequestFocus: false,
    skipTraversal: true,
  );
  ModalRoute<Object?>? _route;
  FormFieldRegistry? _scopeFields;
  bool _ticking = true;

  @override
  void initState() {
    super.initState();
    _SaveKey.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _scopeFields = FormFieldScope.maybeOf(context);
    _ticking = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    _SaveKey.remove(this);
    _focus.dispose();
    super.dispose();
  }

  /// Mounted in the route on top, and not offstage.
  bool get _live => mounted && _ticking && (_route?.isCurrent ?? true);

  bool get _holdsFocus => _focus.hasFocus;

  void _save() => FormShortcuts.save(
    widget.controller,
    widget.fields ?? _scopeFields,
    flow: widget.flow,
  );

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _focus, includeSemantics: false, child: widget.child);
}

/// The one [HardwareKeyboard] handler behind every mounted [FormShortcuts],
/// installed while there is at least one.
abstract final class _SaveKey {
  static final _targets = <_FormShortcutsState>[];

  static void add(_FormShortcutsState target) {
    if (_targets.isEmpty) HardwareKeyboard.instance.addHandler(_handle);
    _targets.add(target);
  }

  static void remove(_FormShortcutsState target) {
    _targets.remove(target);
    if (_targets.isEmpty) HardwareKeyboard.instance.removeHandler(_handle);
  }

  static bool _handle(KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.keyS) return false;
    final keyboard = HardwareKeyboard.instance;
    if (!(keyboard.isMetaPressed || keyboard.isControlPressed) ||
        keyboard.isShiftPressed ||
        keyboard.isAltPressed) {
      return false;
    }
    final live = _targets.where((t) => t._live).toList();
    if (live.isEmpty) return false;
    if (event is KeyDownEvent) {
      final target = live.lastWhere(
        (t) => t._holdsFocus,
        orElse: () => live.last,
      );
      target._save();
    }
    // The repeat and release of a handled press are consumed with it.
    return true;
  }
}
