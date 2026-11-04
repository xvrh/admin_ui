/// @docImport 'validation_summary.dart';
library;

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../common/ui/button.dart';
import '../common/ui/field_registry.dart';
import '../common/ui/steps.dart';
import '../common/ui/tabs.dart' show TabScope, TabSelection;
import '../l10n/admin_ui_localizations.dart';
import '../theme/breakpoints.dart';
import '../theme/spacing.dart';
import '../theme/tokens.dart';
import 'cell.dart';
import 'form_controller.dart';
import 'validation_summary.dart' show ValidationSummary, revealedByCheck;
import 'value_form.dart';
import 'value_form_controller.dart';

/// One step of a [FormWizard]: its [title] (and [subtitle]) in the steps
/// indicator, the [fields] it validates before the wizard moves on, and the
/// [builder] of its form.
class FormWizardStep {
  final String title;
  final String? subtitle;

  /// The cells whose rules must pass before the wizard leaves this step;
  /// those a rule hides are skipped. A step with none always passes. A
  /// record list is one: its `ListRules` count its rows.
  final List<Cell> fields;

  final WidgetBuilder builder;

  const FormWizardStep({
    required this.title,
    this.subtitle,
    required this.fields,
    required this.builder,
  });
}

/// A form split into [steps] over one [controller]: each step's fields are
/// validated before the next step shows, and the last step submits.
///
/// The [Steps] indicator sits on top, then the current step's form, then
/// Back and Next at the end of a footer. Next checks the step's fields
/// through [ValueFormController.validate], waiting for any async check of
/// theirs; while one fails the wizard stays, marks the step in error, says
/// how many fields need fixing and focuses the first. The mark clears as
/// soon as those fields pass. Back never validates, and the indicator lets
/// the user jump back to a step before the current one, never forward.
///
/// On the last step Next reads [finishLabel] and submits the controller,
/// spinning while it is in flight. A submit refused for a field of an
/// earlier step marks that step and takes the user back to the field, as a
/// jump to a field from elsewhere (a [ValidationSummary] link) does.
///
/// Every step's form stays mounted, so its values, focus and registered
/// fields survive a move; the steps not shown are left out of focus
/// traversal and of the semantics tree.
///
/// A [summary], typically a [ValidationSummary], sits between the indicator
/// and the step, parted from the step only while it shows.
///
/// It puts a [ValueForm] around itself unless it is inside one of
/// [controller]'s already. Under a bounded height the footer stays at the
/// bottom and the step scrolls; otherwise the wizard is as tall as its
/// current step. [direction] lays the indicator out, vertical when null and
/// the wizard's own width is compact (under `context.breakpoints.medium`).
class FormWizard extends StatefulWidget {
  final ValueFormController controller;
  final List<FormWizardStep> steps;

  /// The step shown first; the steps before it count as complete.
  final int initialStep;

  /// Called with each step the wizard moves to.
  final ValueChanged<int>? onStepChanged;

  /// The last step's submit label; Material's save label when null.
  final String? finishLabel;

  final Axis? direction;

  /// What needs fixing, listed between the indicator and the step: a
  /// `ValidationSummary()`, which shows once a step is refused or a submit
  /// attempted. The wizard parts it from the step while it shows
  /// ([ValidationSummary.showsFor]), and a hidden summary leaves no gap.
  final Widget? summary;

  const FormWizard({
    super.key,
    required this.controller,
    required this.steps,
    this.initialStep = 0,
    this.onStepChanged,
    this.finishLabel,
    this.direction,
    this.summary,
  }) : assert(steps.length > 0, 'A wizard needs a step'),
       assert(
         initialStep >= 0 && initialStep < steps.length,
         'initialStep is one of the steps',
       );

  @override
  State<FormWizard> createState() => _FormWizardState();
}

class _FormWizardState extends State<FormWizard>
    with SingleTickerProviderStateMixin {
  late int _current = widget.initialStep;

  /// The steps shown in error: refused by Next, or holding a field a submit
  /// was refused for.
  final _refused = <int>{};

  /// Next is waiting for the step's checks.
  bool _checking = false;

  bool _forward = true;
  late final _selection = _StepSelection(_current, _jumpBack);

  /// Plays the step moved to in; at rest at 1.
  late final _entrance = AnimationController(vsync: this, value: 1);

  final _backFocus = FocusNode(debugLabel: 'FormWizard back');
  final _nextFocus = FocusNode(debugLabel: 'FormWizard next');

  /// Keeps the steps' state when the body moves in or out of its scroll
  /// view, as the height turns bounded or not.
  final _bodyKey = GlobalKey(debugLabel: 'FormWizard body');

  FormFieldRegistry? _own;
  FormFieldRegistry? _registry;

  ValueFormController get _controller => widget.controller;

  bool get _busy => _checking || _controller.status == FormStatus.submitting;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onFormChanged);
  }

  @override
  void didUpdateWidget(FormWizard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onFormChanged);
      widget.controller.addListener(_onFormChanged);
    }
    final count = widget.steps.length;
    _refused.removeWhere((step) => step >= count);
    if (_current >= count) {
      _current = count - 1;
      _selection.show(_current);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onFormChanged);
    _entrance.dispose();
    _backFocus.dispose();
    _nextFocus.dispose();
    _selection.dispose();
    super.dispose();
  }

  Set<String> _idsOf(int step) => {
    for (final cell in widget.steps[step].fields) cell.id,
  };

  /// Whether none of [step]'s fields has a message or a check pending.
  bool _passes(int step) {
    final errors = _controller.allErrors;
    final pending = _controller.pendingFields;
    return !_idsOf(step)
        .any((id) => errors.containsKey(id) || pending.contains(id));
  }

  void _onFormChanged() {
    final cleared = _refused.where(_passes).toSet();
    if (cleared.isEmpty) return;
    if (cleared.contains(_current)) revealedByCheck(_controller).value = false;
    setState(() => _refused.removeAll(cleared));
  }

  Future<void> _next() async {
    if (_busy) return;
    final step = _current;
    final ids = _idsOf(step);
    setState(() => _checking = true);
    final passed = await _controller.validate(fields: ids);
    if (!mounted) return;
    setState(() => _checking = false);
    if (step != _current) return;
    if (!passed) {
      _refuse(step, ids);
      return;
    }
    setState(() => _refused.remove(step));
    if (step < widget.steps.length - 1) {
      _goTo(step + 1);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    await _controller.submit();
    if (!mounted) return;
    final errors = _controller.errors;
    final refused = {
      for (var i = 0; i < widget.steps.length; i++)
        if (_idsOf(i).any(errors.containsKey)) i,
    };
    if (refused.isNotEmpty) setState(() => _refused.addAll(refused));
  }

  /// Keeps the user on [step]: marks it, says how many of its fields need
  /// fixing and, once their messages are built, focuses the first.
  void _refuse(int step, Set<String> ids) {
    final count = ids.where(_controller.allErrors.containsKey).length;
    setState(() => _refused.add(step));
    revealedByCheck(_controller).value = true;
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.adminL10n.fields.wizardStepBlocked(count),
      Directionality.of(context),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || step != _current) return;
      final shown = _controller.errors;
      for (final field in _registry?.entries ?? const <FormFieldEntry>[]) {
        if (ids.contains(field.id) && shown.containsKey(field.id)) {
          field.reveal();
          return;
        }
      }
    });
  }

  /// Moves to a step before the current one: picked in the indicator, or
  /// holding a field being revealed.
  void _jumpBack(int step) {
    if (_busy || step >= _current) return;
    _goTo(step);
  }

  void _goTo(int step) {
    final backHadFocus = _backFocus.hasFocus;
    setState(() {
      _forward = step > _current;
      _current = step;
    });
    _selection.show(step);
    revealedByCheck(_controller).value = false;
    final duration = context.motion.medium;
    if (duration == Duration.zero) {
      _entrance.value = 1;
    } else {
      _entrance
        ..duration = duration
        ..forward(from: 0);
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.adminL10n.display.stepOf(
        step + 1,
        widget.steps.length,
        widget.steps[step].title,
      ),
      Directionality.of(context),
    );
    // Back goes on the first step; focus stays in the footer.
    if (step == 0 && backHadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nextFocus.requestFocus();
      });
    }
    widget.onStepChanged?.call(step);
  }

  @override
  Widget build(BuildContext context) {
    final above = FormFieldScope.maybeOf(context);
    final registry = _registry = above ?? (_own ??= FormFieldRegistry());
    Widget wizard = LayoutBuilder(builder: _layout);
    final form = context.getInheritedWidgetOfExactType<ValueFormScope>();
    if (form?.controller != _controller) {
      wizard = ValueForm(
        controller: _controller,
        fields: above == null ? registry : null,
        child: wizard,
      );
    }
    return wizard;
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final compact = AdminBreakpoint.forWidth(
      constraints.maxWidth,
      context.breakpoints,
    ).isCompact;
    final direction =
        widget.direction ?? (compact ? Axis.vertical : Axis.horizontal);
    final bounded = constraints.hasBoundedHeight;
    final body = KeyedSubtree(key: _bodyKey, child: _body(context));
    final summary = widget.summary;
    return Column(
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Steps(
          steps: [
            for (final step in widget.steps)
              StepItem(step.title, subtitle: step.subtitle),
          ],
          current: _current,
          direction: direction,
          errorSteps: _refused,
          onChanged: _jumpBack,
        ),
        const Gap(AdminSpacing.xxl),
        if (summary != null)
          ValueListenableBuilder<bool>(
            valueListenable: ValidationSummary.showsFor(_controller),
            builder: (context, shows, summary) => Padding(
              padding: EdgeInsets.only(bottom: shows ? AdminSpacing.xl : 0),
              child: summary,
            ),
            child: summary,
          ),
        if (bounded)
          Expanded(child: SingleChildScrollView(child: body))
        else
          body,
        const Gap(AdminSpacing.xl),
        ListenableBuilder(listenable: _controller, builder: _footer),
      ],
    );
  }

  /// Every step's form, the current one shown and played in: from the end
  /// side moving forward, from the start side moving back.
  Widget _body(BuildContext context) {
    final steps = widget.steps;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = context.motion.enter.transform(_entrance.value);
        final side = (_forward ? 1 : -1) * (rtl ? -1 : 1);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(side * AdminSpacing.xxl * (1 - t), 0),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepBody(
              key: ValueKey(i),
              id: '$i',
              shown: i == _current,
              selection: _selection,
              builder: steps[i].builder,
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, Widget? _) {
    final l10n = context.adminL10n;
    final controller = _controller;
    final last = _current == widget.steps.length - 1;
    final busy = _busy;
    // A form that submits only edits has nothing to finish while clean.
    final nothingToSubmit =
        last &&
        controller.requireChanges &&
        !controller.isDirty &&
        controller.status != FormStatus.error;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_current > 0) ...[
          Flexible(
            key: const ValueKey('back'),
            child: Button(
              l10n.fields.wizardBack,
              focusNode: _backFocus,
              onPressed: busy ? null : () => _goTo(_current - 1),
            ),
          ),
          const Gap(AdminSpacing.md, key: ValueKey('gap')),
        ],
        Flexible(
          key: const ValueKey('next'),
          child: Button.primary(
            last
                ? widget.finishLabel ??
                      MaterialLocalizations.of(context).saveButtonLabel
                : l10n.fields.wizardNext,
            focusNode: _nextFocus,
            loading: busy,
            onPressed: nothingToSubmit ? null : _next,
            disabledHint: nothingToSubmit ? l10n.shell.noChanges : null,
          ),
        ),
      ],
    );
  }
}

/// One step's form, mounted whether shown or not: a step not shown takes no
/// room, paints nothing, takes no focus and has no semantics. It is a
/// [TabScope] over the wizard's steps, so a field revealed on it (a jump to
/// the field, a refused submit) asks the wizard to show it.
class _StepBody extends StatelessWidget {
  final String id;
  final bool shown;
  final TabSelection selection;
  final WidgetBuilder builder;

  const _StepBody({
    super.key,
    required this.id,
    required this.shown,
    required this.selection,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !shown,
      child: ExcludeFocus(
        excluding: !shown,
        child: TickerMode(
          enabled: shown,
          child: TabScope(
            tabId: id,
            selection: selection,
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }
}

/// The step shown, as the [TabScope]s of the steps read it. Selecting a step
/// asks the wizard, which only moves back; the wizard sets the step it shows
/// with [show].
class _StepSelection extends TabSelection {
  final ValueChanged<int> _request;

  _StepSelection(int step, this._request) : super('$step');

  @override
  void select(String id) => _request(int.parse(id));

  void show(int step) => super.select('$step');
}
