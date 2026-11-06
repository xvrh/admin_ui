import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/icon_action.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'page_header.dart';
import 'save_cluster.dart';

/// The save/sync state of the document the [SaveBar] governs. Drives the inline
/// indicator (a coloured dot + message) and which actions are live.
enum SaveState { clean, unsaved, saving, saved, error }

/// What committing an edit screen does, which sets the words of its save
/// status.
///
/// - [save]: an explicit-save form. Unsaved edits read a muted "Unsaved
///   changes", and a commit "Saving…", then "Saved".
/// - [publish]: a draft-backed document, which keeps its edits itself and
///   whose commit makes them live. Its edits read an amber "Edited" (amber
///   is kept for the publish axis), and a commit "Publishing…", then
///   "Published".
enum SaveFlow { save, publish }

/// A typed secondary action for the [SaveBar]: shown as a menu item under the ⋯
/// overflow, or as an alternative under a split commit. A null [onPressed]
/// renders it disabled; [tooltip] explains why.
class SaveBarAction {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;

  /// The key of the menu row built for this action, to find it by in a test.
  final Key? key;

  const SaveBarAction({
    this.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tooltip,
    this.danger = false,
  });
}

/// Where the bar sits, so its hairline draws on the correct edge: under a top
/// bar, or above a bottom-docked action strip.
enum SaveBarPlacement { top, bottom }

/// The spine of an edit screen: a [leading] slot (title / breadcrumb), an
/// optional doc-[status] tag, and the [SaveCluster] — the save status, the
/// secondary [actions] and the standard Discard / Save / commit (Publish by
/// default). A hairline strip matching the shell bars, its content inset by
/// the page gutter ([PageHeader.gutterOf]) so it lines up with the page's
/// title and actions.
///
/// Save is live only when there's something to save ([SaveState.unsaved] or
/// [SaveState.error]); [SaveState.saving] spins the Save button and
/// [committing] spins the commit, both disabling the rest of the bar while in
/// flight. See [SaveCluster] for the rules.
///
/// A bar narrower than the theme's medium breakpoint
/// (`context.breakpoints.medium`) compacts, and one narrower than
/// [phoneWidth] folds its command actions into the ⋯ menu too.
class SaveBar extends StatelessWidget {
  final Widget? leading;

  /// A caller-provided doc-status tag (e.g. `Tag('Draft', …)`), shown by the
  /// leading slot.
  final Widget? status;

  final SaveState state;

  /// Appended to the "Saved" message, e.g. `'2m ago'` → "Saved · 2m ago".
  final String? savedLabel;

  /// Overrides the default "Couldn’t save" error message.
  final String? errorLabel;

  /// See [SaveCluster.invalidCount].
  final int invalidCount;

  /// See [SaveCluster.invalidLabel].
  final String Function(int count)? invalidLabel;

  /// See [SaveCluster.onShowInvalid].
  final VoidCallback? onShowInvalid;

  final VoidCallback? onDiscard;
  final VoidCallback? onSave;

  /// The primary action: publishes a draft, or saves an explicit-save form
  /// (see [flow]). Shown whenever it is set.
  final VoidCallback? onCommit;

  /// See [SaveCluster.discardLabel].
  final String? discardLabel;

  /// See [SaveCluster.saveLabel].
  final String? saveLabel;

  /// See [SaveCluster.commitLabel].
  final String? commitLabel;

  /// See [SaveCluster.commitMenuLabel].
  final String? commitMenuLabel;

  /// See [SaveCluster.moreLabel].
  final String? moreLabel;

  /// The commit in flight — spins its button and disables the bar.
  final bool committing;

  /// Whether the commit is actionable. When `false` the button is shown
  /// disabled (greyed) rather than hidden — presence is declared by
  /// [onCommit], its availability by this flag.
  final bool commitEnabled;

  /// Secondary controls living *inside* the bar, between the save indicator and
  /// the primary actions: history, a mode toggle, comments, an overflow menu…
  /// Separated from the primary buttons by a hairline. Below [phoneWidth] the
  /// labelled [IconAction]s among them that are plain commands — not
  /// [IconAction.selected], no [IconAction.expanded] — fold into the ⋯ menu;
  /// a toggle, a disclosure and any other widget stay in the row (see
  /// [SaveCluster.foldActions]).
  final List<Widget> actions;

  /// Less-common actions collapsed into a single ⋯ overflow menu, appended after
  /// [actions]. Disabled entries (null `onPressed`) still show, greyed.
  final List<SaveBarAction> overflowActions;

  /// Alternatives under a split commit button (Schedule, Unpublish…). When
  /// non-empty, the commit renders as a [SplitButton] whose caret opens this
  /// menu; below [phoneWidth] they join the ⋯ menu instead.
  final List<SaveBarAction> commitMenu;

  /// Tooltip shown on a disabled commit (e.g. "No changes to publish").
  final String? commitDisabledHint;

  /// What a commit does, and so what the status says: [SaveFlow.save] by
  /// default, [SaveFlow.publish] for a draft-backed editor.
  final SaveFlow flow;

  final SaveBarPlacement placement;

  /// The key of the Save button, to find it by in a test.
  final Key? saveKey;

  /// The key of the commit button, to find it by in a test.
  final Key? commitKey;

  /// The key of the Discard button, or of its row when a narrow bar folds it
  /// into its menu, to find it by in a test.
  final Key? discardKey;

  const SaveBar({
    super.key,
    this.leading,
    this.status,
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
    this.placement = SaveBarPlacement.top,
    this.saveKey,
    this.commitKey,
    this.discardKey,
  });

  static const height = 56.0;

  /// Below this bar width, a phone's, the command [IconAction]s among
  /// [actions] and a split commit's alternatives fold into the ⋯ menu too,
  /// so a bar with every slot filled still fits a 320-wide window.
  static const phoneWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final hairline = BorderSide(color: context.colors.border);
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: PageHeader.gutterOf(context)),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: placement == SaveBarPlacement.top
            ? Border(bottom: hairline)
            : Border(top: hairline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: _LeadingSide(leading: leading, status: status),
            ),
            const Gap(AdminSpacing.lg),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(0, constraints.maxWidth - AdminSpacing.lg),
              ),
              child: SaveCluster(
                state: state,
                savedLabel: savedLabel,
                errorLabel: errorLabel,
                invalidCount: invalidCount,
                invalidLabel: invalidLabel,
                onShowInvalid: onShowInvalid,
                onDiscard: onDiscard,
                onSave: onSave,
                onCommit: onCommit,
                saveKey: saveKey,
                commitKey: commitKey,
                discardKey: discardKey,
                discardLabel: discardLabel,
                saveLabel: saveLabel,
                commitLabel: commitLabel,
                commitMenuLabel: commitMenuLabel,
                moreLabel: moreLabel,
                committing: committing,
                commitEnabled: commitEnabled,
                actions: actions,
                overflowActions: overflowActions,
                commitMenu: commitMenu,
                commitDisabledHint: commitDisabledHint,
                flow: flow,
                compact: constraints.maxWidth < context.breakpoints.medium,
                foldActions: constraints.maxWidth < phoneWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar's leading side, in what the controls leave it: the [leading]
/// title shrinks last. It keeps its whole width up to [_titleRoom] — a short
/// title such as "Edit page" never ellipsises for the tag — and a longer one
/// leaves [_statusRoom] for the [status] tag once the side is wider than
/// both. The tag takes what the title leaves, so a `Tag` ellipsises inside
/// its pill — until that is less than [_statusFloor], where the tag steps
/// aside rather than draw an empty pill.
class _LeadingSide extends StatelessWidget {
  final Widget? leading;
  final Widget? status;

  const _LeadingSide({required this.leading, required this.status});

  /// What the title keeps before the tag may take any of it.
  static const _titleRoom = 160.0;

  /// Room for a short status such as "Changed" or "Scheduled".
  static const _statusRoom = 96.0;

  /// A pill's padding around one glyph and its ellipsis.
  static const _statusFloor = 40.0;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    final status = this.status;
    if (leading == null) {
      return Row(children: [if (status != null) Flexible(child: status)]);
    }
    final title = DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: leading,
    );
    if (status == null) return Row(children: [Flexible(child: title)]);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(
                  width,
                  math.max(_titleRoom, width - _statusRoom),
                ),
              ),
              child: title,
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    constraints.maxWidth - AdminSpacing.md < _statusFloor
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AdminSpacing.md,
                        ),
                        child: status,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
