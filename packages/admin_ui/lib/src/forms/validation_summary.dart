/// @docImport 'form_wizard.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, internal, setEquals;
import 'package:material_ui/material_ui.dart';

import '../common/text_metrics.dart';
import '../common/ui/field_registry.dart';
import '../common/ui/severity.dart';
import '../common/ui/text_link.dart';
import '../l10n/admin_ui_localizations.dart';
import '../theme/spacing.dart';
import '../theme/tokens.dart';
import 'value_form.dart';
import 'value_form_controller.dart';

/// Lists the fields of a form that need fixing, each a link that takes
/// focus to its field; [controller] is the nearest [ValueForm]'s when null.
///
/// Nothing shows until the user is told the form is wrong: after a submit
/// attempt, or a [FormWizard] step refused. It is then a danger alert,
/// titled with how many fields need fixing, listing each field's message as
/// "Label: message" in the order the fields appear, underlined as the link
/// it is, and hides again once they all pass. Each field is found in the
/// ambient [FormFieldScope], which a [ValueForm] provides; a message filed
/// under an id no field registered is listed without a link.
///
/// While hidden it takes no room, and its [margin] with it: a host spaces it
/// from what follows with the margin, not a gap of its own, so a valid form
/// keeps no empty band. [showsFor] tells a host that lays out around it
/// whether it shows.
///
/// It is a polite live region: a screen reader hears its title when it
/// shows and as the count changes.
class ValidationSummary extends StatefulWidget {
  final ValueFormController? controller;

  /// Replaces the count in the title: "2 fields need fixing" in the app's
  /// language when null.
  final String? title;

  /// Lists this many messages at most, the rest behind a "Show N more" link;
  /// all of them when null.
  final int? maxItems;

  /// Space around the summary while it shows, such as
  /// `EdgeInsets.only(bottom: AdminSpacing.xl)` to part it from the fields
  /// below; none while it is hidden.
  final EdgeInsetsGeometry margin;

  const ValidationSummary({
    super.key,
    this.controller,
    this.title,
    this.maxItems,
    this.margin = EdgeInsets.zero,
  }) : assert(maxItems == null || maxItems > 0, 'maxItems lists one at least');

  /// Whether a summary over [controller] shows: once the user has been told
  /// the form is wrong (a submit attempt, a [FormWizard] step refused) and
  /// while a field still has a message. It notifies as that changes, for a
  /// host that places or spaces something by it.
  static ValueListenable<bool> showsFor(ValueFormController controller) =>
      _Shows.of(controller);

  @override
  State<ValidationSummary> createState() => _ValidationSummaryState();
}

/// Set while a check its user asked for (a [FormWizard] refusing a step)
/// shows [controller]'s messages, so a [ValidationSummary] lists them as it
/// does after a submit attempt.
@internal
ValueNotifier<bool> revealedByCheck(ValueFormController controller) =>
    _revealedByCheck[controller] ??= ValueNotifier(false);

final _revealedByCheck = Expando<ValueNotifier<bool>>('revealedByCheck');

/// [ValidationSummary.showsFor]: follows the controller and the wizard's
/// reveal only while it has listeners, and notifies when the answer changes.
class _Shows extends ChangeNotifier implements ValueListenable<bool> {
  _Shows(this._controller) : _revealed = revealedByCheck(_controller);

  static _Shows of(ValueFormController controller) =>
      _all[controller] ??= _Shows(controller);

  static final _all = Expando<_Shows>('ValidationSummary.showsFor');

  final ValueFormController _controller;
  final ValueNotifier<bool> _revealed;
  bool _last = false;

  @override
  bool get value =>
      _controller.errors.isNotEmpty &&
      (_controller.submitAttempted || _revealed.value);

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _last = value;
      _controller.addListener(_changed);
      _revealed.addListener(_changed);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (hasListeners) return;
    _controller.removeListener(_changed);
    _revealed.removeListener(_changed);
  }

  void _changed() {
    final now = value;
    if (now == _last) return;
    _last = now;
    notifyListeners();
  }
}

typedef _Row = ({String? label, String message, VoidCallback? focus});

class _ValidationSummaryState extends State<ValidationSummary> {
  bool _expanded = false;

  /// The ids last listed without a field, looked up once more after the
  /// frame in which a field may register.
  Set<String> _unmatched = const {};

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? ValueFormScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final registry = FormFieldScope.maybeOf(context);
    final shows = _Shows.of(controller);
    return ListenableBuilder(
      listenable: Listenable.merge([controller, shows._revealed]),
      builder: (context, _) {
        final show = shows.value;
        if (!show) _expanded = false;
        // Kept in the tree while hidden, so the region is there to announce
        // its first appearance.
        return Padding(
          padding: show ? widget.margin : EdgeInsets.zero,
          child: Semantics(
            container: true,
            liveRegion: true,
            child: show
                ? _summary(context, _rows(controller.errors, registry))
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  /// The messages in the order their fields registered, the order they
  /// appear, then any whose field is not in [registry].
  List<_Row> _rows(Map<String, String> errors, FormFieldRegistry? registry) {
    final rows = <_Row>[];
    final listed = <String>{};
    for (final field in registry?.entries ?? const <FormFieldEntry>[]) {
      final message = errors[field.id];
      if (message == null) continue;
      rows.add((label: field.label, message: message, focus: field.reveal));
      listed.add(field.id);
    }
    final unmatched = {
      for (final id in errors.keys)
        if (!listed.contains(id)) id,
    };
    for (final id in unmatched) {
      rows.add((label: null, message: errors[id]!, focus: null));
    }
    // A field shown in this frame registers after a summary above it has
    // built.
    if (unmatched.isNotEmpty && !setEquals(unmatched, _unmatched)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    _unmatched = unmatched;
    return rows;
  }

  /// An [Alert]'s anatomy in the danger tone, the messages under its title.
  Widget _summary(BuildContext context, List<_Row> rows) {
    final l10n = context.adminL10n;
    final style = severityStyleOf(context, Severity.danger);
    final iconSize = context.iconSizes.lg;
    final firstLine = lineHeightOf(context, context.type.bodyStrong);
    final limit = _expanded
        ? rows.length
        : math.min(rows.length, widget.maxItems ?? rows.length);
    final links = [
      for (final row in rows.take(limit)) _link(context, row, style.foreground),
      if (limit < rows.length)
        TextLink(
          l10n.display.showMore(rows.length - limit),
          color: style.foreground,
          expanded: false,
          onPressed: () => setState(() => _expanded = true),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(context.radii.radius),
        border: Border.all(color: style.border),
      ),
      // The icon centres on the title's line, as an alert's does.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: math.max(0, (firstLine - iconSize) / 2),
            ),
            child: Icon(style.icon, size: iconSize, color: style.foreground),
          ),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: math.max(0, (iconSize - firstLine) / 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ??
                        l10n.fields.validationSummaryTitle(rows.length),
                    style: context.type.bodyStrong,
                  ),
                  for (final link in links) ...[
                    const Gap(AdminSpacing.xs),
                    link,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, _Row row, Color color) {
    final l10n = context.adminL10n;
    final label = row.label;
    if (label == null) {
      return Text(
        row.message,
        style: context.type.caption.copyWith(color: color),
      );
    }
    return TextLink(
      l10n.fields.fieldMessage(label, row.message),
      color: color,
      underlined: true,
      semanticLabel: l10n.display.joinParts([
        l10n.fields.jumpToField(label),
        row.message,
      ]),
      onPressed: row.focus,
    );
  }
}
