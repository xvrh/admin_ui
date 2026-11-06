import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'save_bar.dart';

/// The save controls of an edit screen, in one row: the save status, the
/// secondary [actions], a ⋯ overflow menu, and Discard / Save / the commit,
/// the primary action, which reads "Publish" unless given a [commitLabel].
///
/// Everything follows from [state] (with [committing] and [invalidCount]):
/// what the status says, which actions are live, what spins. [SaveBar] draws
/// it inside its strip, and `FormActions` is one bound to a form controller —
/// for a page header's actions.
///
/// - Discard, Save and the commit are shown whenever their callback is set,
///   and disabled rather than hidden when there is nothing to act on, so the
///   row never shifts under the pointer as the state changes.
/// - Save is live only with something to save ([SaveState.unsaved] or
///   [SaveState.error]); the commit while [commitEnabled].
/// - In flight, only the acting button spins, at its resting width and in its
///   own tone; the status reads "Saving…", and the rest of the row waits.
/// - With [invalidCount] fields in error the edits cannot be saved: the status
///   reads [invalidLabel] in the danger text, as a button calling
///   [onShowInvalid] (e.g. to focus the first invalid field), and a disabled
///   Save or commit gives the same reason as its tooltip. A split commit's
///   alternatives wait with it, so it reads as one disabled control.
///
/// The status is a live region, so a screen reader hears it change.
/// [compact] (a narrow bar) folds Discard into the overflow menu and keeps
/// the status's glyph alone, its message moving to a tooltip; [foldActions]
/// (a phone's) folds the icon actions and the commit's alternatives there
/// too. Given less width than it needs even so, the status's message
/// ellipsises rather than the row overflowing, or in a compact row, Save's
/// label (else the commit's).
class SaveCluster extends StatelessWidget {
  final SaveState state;

  /// Appended to the "Saved" message, e.g. `'2m ago'` → "Saved · 2m ago".
  final String? savedLabel;

  /// Overrides the default "Couldn’t save" error message.
  final String? errorLabel;

  /// How many fields are in error. Above zero, unsaved edits are invalid.
  final int invalidCount;

  /// The status (and disabled-action hint) for [invalidCount] invalid fields;
  /// "1 field needs attention", "2 fields need attention" in the app's
  /// language when null.
  final String Function(int count)? invalidLabel;

  /// Called from the invalid status — e.g. to focus the first invalid field.
  final VoidCallback? onShowInvalid;

  final VoidCallback? onDiscard;
  final VoidCallback? onSave;

  /// The primary action: publishes a draft, or saves an explicit-save form
  /// (see [flow]). Shown whenever it is set.
  final VoidCallback? onCommit;

  /// Discard's label; "Discard" in the app's language when null.
  final String? discardLabel;

  /// Save's label; Material's save label when null.
  final String? saveLabel;

  /// The commit's label; "Publish" in the app's language when null, whatever
  /// the [flow].
  final String? commitLabel;

  /// The accessible name and tooltip of a split commit's caret; "More
  /// publish options" in the app's language when null.
  final String? commitMenuLabel;

  /// The accessible name and tooltip of the ⋯ overflow menu; "More actions"
  /// in the app's language when null.
  final String? moreLabel;

  /// The commit in flight — spins its button and disables the rest.
  final bool committing;

  /// Whether the commit is actionable. When `false` the button is shown
  /// disabled rather than hidden — presence is declared by [onCommit], its
  /// availability by this flag.
  final bool commitEnabled;

  /// Secondary controls between the status and the primary actions: history,
  /// a mode toggle, comments… Separated from the primary actions by a
  /// hairline.
  final List<Widget> actions;

  /// Less-common actions collapsed into a single ⋯ overflow menu, after
  /// [actions]. Disabled entries (null `onPressed`) still show, greyed.
  final List<SaveBarAction> overflowActions;

  /// Alternatives under a split commit button (Schedule, Unpublish…).
  final List<SaveBarAction> commitMenu;

  /// Tooltip shown on a disabled commit (e.g. "No changes to publish").
  final String? commitDisabledHint;

  /// See [SaveBar.flow].
  final SaveFlow flow;

  /// Folds Discard into the overflow menu and shortens the status to its
  /// glyph, for a narrow bar.
  final bool compact;

  /// Folds the labelled [IconAction]s among [actions] into the ⋯ menu, ahead
  /// of its other entries, and a split commit's [commitMenu] after Discard,
  /// leaving the commit a plain button: for a phone-width bar. Only
  /// plain commands fold: an [IconAction] that is [IconAction.selected] or
  /// discloses something ([IconAction.expanded] set) stays in the row, where
  /// its state shows and a popup anchored to it has an anchor, as does any
  /// other widget among [actions].
  final bool foldActions;

  /// The key of the Save button, to find it by in a test.
  final Key? saveKey;

  /// The key of the commit button, to find it by in a test.
  final Key? commitKey;

  /// The key of the Discard button, or of its row when a narrow bar folds it
  /// into its menu, to find it by in a test.
  final Key? discardKey;

  const SaveCluster({
    super.key,
    this.state = SaveState.clean,
    this.savedLabel,
    this.errorLabel,
    this.invalidCount = 0,
    this.invalidLabel,
    this.onShowInvalid,
    this.onDiscard,
    this.onSave,
    this.onCommit,
    this.discardLabel,
    this.saveLabel,
    this.commitLabel,
    this.commitMenuLabel,
    this.moreLabel,
    this.committing = false,
    this.commitEnabled = true,
    this.actions = const [],
    this.overflowActions = const [],
    this.commitMenu = const [],
    this.commitDisabledHint,
    this.flow = SaveFlow.save,
    this.compact = false,
    this.foldActions = false,
    this.saveKey,
    this.commitKey,
    this.discardKey,
  });

  bool get _saving => state == SaveState.saving;
  bool get _busy => _saving || committing;
  bool get _dirty => state == SaveState.unsaved || state == SaveState.error;
  bool get _invalid => _dirty && invalidCount > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n;
    final discardLabel = this.discardLabel ?? l10n.shell.discard;
    final invalidText = !_invalid
        ? null
        : (invalidLabel ?? l10n.shell.fieldsNeedAttention)(invalidCount);
    final foldDiscard = compact && onDiscard != null;
    final foldCommitMenu =
        foldActions && onCommit != null && commitMenu.isNotEmpty;
    final discard = _busy || !_dirty ? null : onDiscard;
    final inline = <Widget>[];
    final folded = <SaveBarAction>[];
    for (final action in actions) {
      if (foldActions && action is IconAction && _isCommand(action)) {
        folded.add(
          SaveBarAction(
            key: action.key,
            label: action.label!,
            icon: action.icon,
            onPressed: action.onPressed,
            danger: action.danger,
          ),
        );
      } else {
        inline.add(action);
      }
    }
    final groups = [
      folded,
      if (foldDiscard)
        [
          SaveBarAction(
            key: discardKey,
            label: discardLabel,
            icon: Icons.undo_rounded,
            onPressed: discard,
          ),
        ],
      if (foldCommitMenu)
        [
          for (final a in commitMenu)
            SaveBarAction(
              key: a.key,
              label: a.label,
              icon: a.icon,
              danger: a.danger,
              onPressed: _commitMenuLive ? a.onPressed : null,
            ),
        ],
      overflowActions,
    ].where((group) => group.isNotEmpty);
    final overflow = <SaveBarAction?>[
      for (final (i, group) in groups.indexed) ...[if (i > 0) null, ...group],
    ];
    final secondary = [
      ...inline,
      if (overflow.isNotEmpty)
        _OverflowMenu(
          actions: overflow,
          label: moreLabel ?? l10n.moreActions,
          enabled: !_busy,
        ),
    ];
    final save = onSave == null ? null : _save(context, invalidText);
    final commit = onCommit == null
        ? null
        : _commit(context, invalidText, split: !foldCommitMenu);
    final primary = [
      if (onDiscard != null && !foldDiscard)
        Button.ghost(discardLabel, key: discardKey, onPressed: discard),
      ?save,
      ?commit,
    ];
    final status = _SaveStatus(
      state: state,
      savedLabel: savedLabel,
      errorLabel: errorLabel,
      invalidLabel: invalidText,
      onShowInvalid: onShowInvalid,
      flow: flow,
      compact: compact,
    );
    // The last resort of a row still too wide for its bar: the status's
    // message or, where the status is a glyph alone, Save's label (else the
    // commit's).
    final yielding = compact ? (save ?? commit) : status;
    Widget fit(Widget child) =>
        identical(child, yielding) ? Flexible(child: child) : child;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kept in the row while clean (at no size), so the live region is
        // there to announce the first change.
        fit(status),
        if (state != SaveState.clean &&
            (secondary.isNotEmpty || primary.isNotEmpty))
          Gap(secondary.isEmpty ? AdminSpacing.lg : AdminSpacing.md),
        for (var i = 0; i < secondary.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.md),
          secondary[i],
        ],
        if (secondary.isNotEmpty && primary.isNotEmpty) const _Divider(),
        for (var i = 0; i < primary.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.sm),
          fit(primary[i]),
        ],
      ],
    );
  }

  /// Whether [action] is a plain labelled command, which reads the same as a
  /// menu entry; see [foldActions].
  static bool _isCommand(IconAction action) =>
      action.label != null && !action.selected && action.expanded == null;

  /// A split commit's alternatives wait while anything is in flight or the
  /// edits are invalid.
  bool get _commitMenuLive => !_busy && !_invalid;

  Widget _save(BuildContext context, String? invalidText) {
    // Spinning, Save keeps its callback so it keeps its tone; the spinner
    // blocks the tap.
    final live = _saving || (!_busy && _dirty && invalidText == null);
    return Button(
      saveLabel ?? MaterialLocalizations.of(context).saveButtonLabel,
      key: saveKey,
      onPressed: live ? onSave : null,
      loading: _saving,
      disabledHint: invalidText,
    );
  }

  /// The commit, split when [split] and it has a [commitMenu].
  Widget _commit(
    BuildContext context,
    String? invalidText, {
    required bool split,
  }) {
    final shell = context.adminL10n.shell;
    final commitLabel = this.commitLabel ?? shell.publish;
    final live = committing || (!_busy && commitEnabled && invalidText == null);
    final onPressed = live ? onCommit : null;
    final hint = live
        ? null
        : (invalidText ?? (commitEnabled ? null : commitDisabledHint));
    if (split && commitMenu.isNotEmpty) {
      return SplitButton(
        key: commitKey,
        label: commitLabel,
        onPressed: onPressed,
        loading: committing,
        disabledHint: hint,
        menuSemanticLabel: commitMenuLabel ?? shell.morePublishOptions,
        entries: [
          for (final a in commitMenu)
            MenuItem(
              a.label,
              key: a.key,
              icon: a.icon,
              danger: a.danger,
              onSelect: _commitMenuLive ? a.onPressed : null,
            ),
        ],
      );
    }
    return Button.primary(
      commitLabel,
      key: commitKey,
      onPressed: onPressed,
      loading: committing,
      disabledHint: hint,
    );
  }
}

/// A ⋯ menu collapsing the cluster's overflow actions; a null entry draws a
/// divider.
class _OverflowMenu extends StatelessWidget {
  final List<SaveBarAction?> actions;
  final String label;
  final bool enabled;

  const _OverflowMenu({
    required this.actions,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Menu(
      side: PopoverSide.bottom,
      align: PopoverAlign.end,
      entries: [
        for (final a in actions)
          if (a == null)
            const MenuDivider()
          else
            MenuItem(
              a.label,
              key: a.key,
              icon: a.icon,
              danger: a.danger,
              onSelect: a.onPressed,
            ),
      ],
      builder: (context, controller) => IconAction(
        Icons.more_horiz,
        label: label,
        expanded: controller.isOpen,
        onPressed: enabled ? controller.toggle : null,
      ),
    );
  }
}

/// The save status: a glyph and a short message, derived from the state, in
/// a live region. A long message ellipsises (an error's tooltip keeps it
/// whole); [compact] keeps the glyph alone, with the message as its tooltip.
/// With [invalidLabel] the status is that, and a button when [onShowInvalid]
/// is set.
class _SaveStatus extends StatelessWidget {
  final SaveState state;
  final String? savedLabel;
  final String? errorLabel;
  final String? invalidLabel;
  final VoidCallback? onShowInvalid;
  final SaveFlow flow;
  final bool compact;

  const _SaveStatus({
    required this.state,
    required this.savedLabel,
    required this.errorLabel,
    required this.invalidLabel,
    required this.onShowInvalid,
    required this.flow,
    required this.compact,
  });

  static const _maxWidth = 240.0;

  /// The glyph's box, in a compact status.
  static final _glyphBox = IconActionSize.inline.box;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.adminL10n;
    final shell = l10n.shell;
    final publish = flow == SaveFlow.publish;
    final saved = publish ? shell.published : shell.saved;
    final savedLabel = this.savedLabel;
    final invalid = invalidLabel;
    final (Widget? glyph, String text, Color textColor) = invalid != null
        ? (_Dot(colors.danger), invalid, colors.dangerText)
        : switch (state) {
            SaveState.clean => (null, '', colors.foregroundMuted),
            SaveState.unsaved =>
              publish
                  ? (_Dot(colors.warning), l10n.edited, colors.foregroundMuted)
                  : (
                      _Dot(colors.foregroundSubtle),
                      l10n.unsavedChanges,
                      colors.foregroundMuted,
                    ),
            // The acting button carries the spinner; the status just says
            // so.
            SaveState.saving => (
              null,
              publish ? shell.publishing : l10n.saving,
              colors.foregroundMuted,
            ),
            SaveState.saved => (
              Icon(
                Icons.check_rounded,
                size: context.iconSizes.sm,
                color: colors.successText,
              ),
              savedLabel == null
                  ? saved
                  : shell.statusWithDetail(saved, savedLabel),
              colors.foregroundMuted,
            ),
            SaveState.error => (
              _Dot(colors.danger),
              errorLabel ??
                  (publish ? shell.couldNotPublish : shell.couldNotSave),
              colors.dangerText,
            ),
          };

    final Widget content;
    if (text.isEmpty) {
      content = const SizedBox.shrink();
    } else if (compact) {
      content = Tip(
        message: text,
        excludeFromSemantics: true,
        child: SizedBox.square(
          dimension: _glyphBox,
          child: Center(child: glyph),
        ),
      );
    } else {
      content = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[glyph, const Gap(AdminSpacing.xs)],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      );
    }

    final onTap = invalid == null ? null : onShowInvalid;
    if (onTap != null) {
      // One node: the button, named by its text, is the live region.
      return Tappable.builder(
        onTap: onTap,
        semanticLabel: compact ? text : null,
        focusRadius: context.radii.radiusSmall,
        builder: (context, hovered) => Semantics(
          liveRegion: true,
          child: compact ? content : _underlined(content, hovered),
        ),
      );
    }
    return Semantics(
      container: true,
      liveRegion: true,
      label: compact ? text : null,
      child: state == SaveState.error && !compact
          // A server's message may run past the status's width.
          ? Tip(message: text, excludeFromSemantics: true, child: content)
          : content,
    );
  }

  /// The invalid status underlines its text under the pointer, like a link.
  Widget _underlined(Widget content, bool hovered) {
    if (!hovered) return content;
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.underline),
      child: content,
    );
  }
}

/// A short vertical hairline separating the secondary controls from the
/// primary actions.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.stroke.hairline,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
      color: context.colors.border,
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
